import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/farm_hive_model.dart';
import '../../viewmodels/farm_providers.dart';
import '../widgets/glass_card.dart';
import 'farm_registration_screen.dart';

enum _MapMode { view, drawPolygon }

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  LatLng? _pinnedLocation;
  double _zoom = 12.0;
  _MapMode _mode = _MapMode.view;

  // Polygon drawing
  final List<LatLng> _polygonPoints = [];

  // Search
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _searchLoading = false;
  final _dio = Dio();

  late AnimationController _panelAnim;
  late Animation<Offset> _panelSlide;

  @override
  void initState() {
    super.initState();
    _panelAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _panelSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _panelAnim, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _panelAnim.dispose();
    _searchCtrl.dispose();
    _dio.close();
    super.dispose();
  }

  // ── Nominatim search (free OSM geocoding, no key needed) ─────────────────
  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) {
      setState(() { _searchResults = []; });
      return;
    }
    setState(() => _searchLoading = true);
    try {
      final resp = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'limit': 6,
          'addressdetails': 1,
        },
        options: Options(headers: {'User-Agent': 'SmartFarmApp/1.0'}),
      );
      if (resp.statusCode == 200) {
        final List<dynamic> data = resp.data;
        setState(() {
          _searchResults = data
              .map((e) => {
                    'name': e['display_name'] as String,
                    'lat': double.parse(e['lat']),
                    'lng': double.parse(e['lon']),
                  })
              .toList();
        });
      }
    } catch (_) {
      setState(() { _searchResults = []; });
    } finally {
      setState(() => _searchLoading = false);
    }
  }

  void _goToSearchResult(Map<String, dynamic> result) {
    final latlng = LatLng(result['lat'], result['lng']);
    _mapController.move(latlng, 14.0);
    setState(() {
      _searchResults = [];
      _searchCtrl.text = '';
      _pinnedLocation = latlng;
    });
    _panelAnim.forward();
  }

  // ── GPS: get current location ─────────────────────────────────────────────
  Future<void> _goToCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Please enable location services on your device.');
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          _showSnack('Location permission denied.');
          return;
        }
      }
      if (perm == LocationPermission.deniedForever) {
        _showSnack('Location permission permanently denied. Go to App Settings to enable.');
        return;
      }

      _showSnack('Getting your location…', duration: 2);
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final latlng = LatLng(pos.latitude, pos.longitude);
      _mapController.move(latlng, 15.0);
      setState(() {
        _pinnedLocation = latlng;
      });
      _panelAnim.forward();
    } catch (e) {
      _showSnack('Could not get location: $e');
    }
  }

  void _showSnack(String msg, {int duration = 3}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFF0D150D),
      duration: Duration(seconds: duration),
    ));
  }

  void _onTap(TapPosition _, LatLng latlng) {
    if (_mode == _MapMode.drawPolygon) {
      setState(() => _polygonPoints.add(latlng));
    } else {
      setState(() => _pinnedLocation = latlng);
      if (_searchResults.isNotEmpty) setState(() => _searchResults = []);
      _panelAnim.forward();
    }
  }

  void _clearPin() {
    _panelAnim.reverse().then((_) => setState(() => _pinnedLocation = null));
  }

  void _undoPolygonPoint() {
    if (_polygonPoints.isNotEmpty) setState(() => _polygonPoints.removeLast());
  }

  void _confirmPolygon() {
    if (_polygonPoints.length < 3) {
      _showSnack('Tap at least 3 points to form a farm boundary.');
      return;
    }
    final lat = _polygonPoints.map((p) => p.latitude).reduce((a, b) => a + b) / _polygonPoints.length;
    final lng = _polygonPoints.map((p) => p.longitude).reduce((a, b) => a + b) / _polygonPoints.length;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => FarmRegistrationScreen(
        isFirstLaunch: false,
        preLat: lat,
        preLng: lng,
        polygonPoints: List.from(_polygonPoints),
      ),
    )).then((_) {
      setState(() { _polygonPoints.clear(); _mode = _MapMode.view; });
    });
  }

  @override
  Widget build(BuildContext context) {
    final farms = ref.watch(farmListProvider);
    final selected = ref.watch(selectedFarmProvider);

    final farmMarkers = farms.map((farm) {
      final isSelected = selected?.id == farm.id;
      return Marker(
        point: LatLng(farm.latitude, farm.longitude),
        width: 130, height: 58,
        child: _FarmMarker(
          farm: farm,
          isSelected: isSelected,
          onTap: () {
            ref.read(selectedFarmProvider.notifier).select(farm);
            _mapController.move(LatLng(farm.latitude, farm.longitude), 14);
          },
        ),
      );
    }).toList();

    if (_pinnedLocation != null && _mode == _MapMode.view) {
      farmMarkers.add(Marker(
        point: _pinnedLocation!,
        width: 60, height: 80,
        child: const _PinMarker(),
      ));
    }

    final polygonMarkers = _polygonPoints.asMap().entries.map((e) => Marker(
      point: e.value,
      width: 24, height: 24,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryAccent,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Center(
          child: Text('${e.key + 1}',
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black)),
        ),
      ),
    )).toList();

    final closedPolygon = _polygonPoints.length >= 2
        ? [..._polygonPoints, _polygonPoints.first]
        : _polygonPoints;

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(21.1458, 79.0882),
              initialZoom: _zoom,
              onTap: _onTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.smartfarm.smart_farm',
                tileBuilder: _darkTileBuilder,
              ),
              if (_polygonPoints.length >= 2)
                PolylineLayer(polylines: [
                  Polyline(points: closedPolygon, color: AppColors.primaryAccent.withOpacity(0.8), strokeWidth: 2.5),
                ]),
              if (_polygonPoints.length >= 3)
                PolygonLayer(polygons: [
                  Polygon(
                    points: _polygonPoints,
                    color: AppColors.primaryAccent.withOpacity(0.12),
                    borderColor: AppColors.primaryAccent,
                    borderStrokeWidth: 2,
                  ),
                ]),
              MarkerLayer(markers: [...farmMarkers, ...polygonMarkers]),
            ],
          ),

          // ── Top Toolbar + Search ─────────────────────────────────────────
          _buildTopBar(),

          // ── Search results dropdown ──────────────────────────────────────
          if (_searchResults.isNotEmpty) _buildSearchDropdown(),

          // ── Draw mode banner ─────────────────────────────────────────────
          if (_mode == _MapMode.drawPolygon) _buildDrawBanner(),

          // ── Hint (view, no pin) ──────────────────────────────────────────
          if (_mode == _MapMode.view && _pinnedLocation == null && _searchResults.isEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 130,
              left: 16, right: 16,
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: const Row(children: [
                  Icon(Icons.touch_app, color: AppColors.primaryAccent, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tap to drop a pin — or use Draw Shape to outline your farm',
                      style: TextStyle(color: AppColors.primaryAccent, fontSize: 12),
                    ),
                  ),
                ]),
              ),
            ),

          // ── Zoom + GPS + Mode buttons ────────────────────────────────────
          Positioned(
            right: 12, bottom: 230,
            child: Column(children: [
              _iconBtn(Icons.add, () {
                _zoom = (_zoom + 1).clamp(1.0, 19.0);
                _mapController.move(_mapController.camera.center, _zoom);
              }),
              const SizedBox(height: 8),
              _iconBtn(Icons.remove, () {
                _zoom = (_zoom - 1).clamp(1.0, 19.0);
                _mapController.move(_mapController.camera.center, _zoom);
              }),
              const SizedBox(height: 8),
              // GPS button — NOW ACTIVE
              _iconBtn(Icons.my_location, _goToCurrentLocation,
                  color: AppColors.primaryAccent),
            ]),
          ),

          // ── View mode: pin panel ─────────────────────────────────────────
          if (_mode == _MapMode.view)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: SlideTransition(position: _panelSlide, child: _buildPinPanel()),
            ),

          // ── Draw mode: polygon panel ─────────────────────────────────────
          if (_mode == _MapMode.drawPolygon) _buildPolygonPanel(),
        ],
      ),
    );
  }

  // ── Top bar with search ────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 12, right: 12, bottom: 8,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.90), Colors.transparent],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(children: [
              const Icon(Icons.map_rounded, color: AppColors.primaryAccent, size: 18),
              const SizedBox(width: 8),
              const Text('SATELLITE MAP',
                  style: TextStyle(color: AppColors.primaryAccent,
                      fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.5)),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() {
                  _mode = _mode == _MapMode.drawPolygon ? _MapMode.view : _MapMode.drawPolygon;
                  _polygonPoints.clear();
                  _pinnedLocation = null;
                  _panelAnim.reset();
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _mode == _MapMode.drawPolygon
                        ? AppColors.primaryAccent.withOpacity(0.2) : Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _mode == _MapMode.drawPolygon
                          ? AppColors.primaryAccent : Colors.white24,
                    ),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      _mode == _MapMode.drawPolygon ? Icons.close : Icons.polyline,
                      color: _mode == _MapMode.drawPolygon ? AppColors.primaryAccent : Colors.white60,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _mode == _MapMode.drawPolygon ? 'Cancel' : 'Draw Shape',
                      style: TextStyle(
                          color: _mode == _MapMode.drawPolygon ? AppColors.primaryAccent : Colors.white60,
                          fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 8),

            // ── Search Box ───────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: const Color(0xEE0A0A0A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gridLine.withOpacity(0.8)),
              ),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                onChanged: (v) {
                  if (v.length > 2) _searchLocation(v);
                  else setState(() => _searchResults = []);
                },
                onSubmitted: _searchLocation,
                decoration: InputDecoration(
                  hintText: 'Search location, village, district…',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                  prefixIcon: _searchLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primaryAccent)),
                        )
                      : const Icon(Icons.search, color: AppColors.primaryAccent, size: 20),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, color: Colors.white38, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchResults = []);
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Search results dropdown ────────────────────────────────────────────────
  Widget _buildSearchDropdown() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 110,
      left: 12, right: 12,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xF50A100A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gridLine),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _searchResults.asMap().entries.map((e) {
            final r = e.value;
            final isLast = e.key == _searchResults.length - 1;
            return GestureDetector(
              onTap: () => _goToSearchResult(r),
              child: Container(
                decoration: BoxDecoration(
                  border: isLast ? null : Border(
                    bottom: BorderSide(color: AppColors.gridLine.withOpacity(0.5)),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Row(children: [
                  const Icon(Icons.place_outlined, color: AppColors.primaryAccent, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      r['name'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ]),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Draw mode banner ────────────────────────────────────────────────────────
  Widget _buildDrawBanner() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 135,
      left: 12, right: 12,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          const Icon(Icons.edit_location_alt, color: AppColors.primaryAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _polygonPoints.isEmpty
                  ? 'Tap corners of your farm to draw its boundary'
                  : '${_polygonPoints.length} points placed • Tap to continue',
              style: const TextStyle(color: AppColors.primaryAccent, fontSize: 12),
            ),
          ),
          if (_polygonPoints.isNotEmpty)
            GestureDetector(
              onTap: _undoPolygonPoint,
              child: const Icon(Icons.undo, color: Colors.white54, size: 18),
            ),
        ]),
      ),
    );
  }

  // ── Pin panel ───────────────────────────────────────────────────────────────
  Widget _buildPinPanel() {
    if (_pinnedLocation == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: const Color(0xFF0A100A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.primaryAccent.withOpacity(0.3)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Row(children: [
          const Icon(Icons.place, color: AppColors.primaryAccent, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('LOCATION PINNED',
                  style: TextStyle(color: AppColors.primaryAccent, fontWeight: FontWeight.bold, letterSpacing: 1)),
              Text(
                'Lat: ${_pinnedLocation!.latitude.toStringAsFixed(6)}\n'
                'Lng: ${_pinnedLocation!.longitude.toStringAsFixed(6)}',
                style: const TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'monospace'),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _clearPin,
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Clear'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white54, side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(flex: 2,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => FarmRegistrationScreen(
                    isFirstLaunch: false,
                    preLat: _pinnedLocation!.latitude,
                    preLng: _pinnedLocation!.longitude),
              )),
              icon: const Icon(Icons.agriculture, size: 18),
              label: const Text('REGISTER FARM', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
        ]),
      ]),
    );
  }

  // ── Polygon panel ───────────────────────────────────────────────────────────
  Widget _buildPolygonPanel() {
    final hasEnough = _polygonPoints.length >= 3;
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: const Color(0xFF0A100A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.primaryAccent.withOpacity(0.3)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 14),
          Row(children: [
            const Icon(Icons.polyline, color: AppColors.primaryAccent, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _polygonPoints.isEmpty ? 'No points yet' : '${_polygonPoints.length} vertices',
                style: const TextStyle(color: AppColors.primaryAccent, fontWeight: FontWeight.bold),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _polygonPoints.isNotEmpty ? _undoPolygonPoint : null,
                icon: const Icon(Icons.undo, size: 16),
                label: const Text('Undo'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white60, side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(flex: 2,
              child: ElevatedButton.icon(
                onPressed: hasEnough ? _confirmPolygon : null,
                icon: const Icon(Icons.agriculture, size: 18),
                label: Text(hasEnough ? 'USE THIS SHAPE' : 'Need ${3 - _polygonPoints.length} more',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: const Color(0xCC040904),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: (color ?? AppColors.primaryAccent).withOpacity(0.5)),
          boxShadow: [BoxShadow(color: (color ?? AppColors.primaryAccent).withOpacity(0.15), blurRadius: 8)],
        ),
        child: Icon(icon, color: color ?? AppColors.primaryAccent, size: 20),
      ),
    );
  }

  Widget _darkTileBuilder(BuildContext context, Widget tileWidget, TileImage tile) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        0.2, 0, 0, 0, 0,
        0, 0.4, 0, 0, 0,
        0, 0, 0.3, 0, 0,
        0, 0, 0, 1, 0,
      ]),
      child: tileWidget,
    );
  }
}

// ─── Farm Marker ──────────────────────────────────────────────────────────────
class _FarmMarker extends StatelessWidget {
  final FarmHiveModel farm;
  final bool isSelected;
  final VoidCallback onTap;
  const _FarmMarker({required this.farm, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primaryAccent : AppColors.secondaryGreen;
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color, width: isSelected ? 1.5 : 1),
            boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6)],
          ),
          child: Text('🌾 ${farm.name}',
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        Container(width: 2, height: 6, color: color),
        Container(width: 8, height: 8,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: color,
                boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 8)])),
      ]),
    );
  }
}

// ─── Pin Drop Marker ──────────────────────────────────────────────────────────
class _PinMarker extends StatelessWidget {
  const _PinMarker();
  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: AppColors.dangerRed.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: AppColors.dangerRed, blurRadius: 10)],
        ),
        child: const Icon(Icons.agriculture, color: Colors.white, size: 18),
      ),
      Container(width: 2, height: 18, color: AppColors.dangerRed),
      Container(width: 7, height: 7,
          decoration: BoxDecoration(color: AppColors.dangerRed, shape: BoxShape.circle)),
    ]);
  }
}
