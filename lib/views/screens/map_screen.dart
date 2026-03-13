import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
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
    super.dispose();
  }

  void _onTap(TapPosition _, LatLng latlng) {
    if (_mode == _MapMode.drawPolygon) {
      setState(() => _polygonPoints.add(latlng));
    } else {
      setState(() {
        _pinnedLocation = latlng;
      });
      _panelAnim.forward();
    }
  }

  void _clearPin() {
    _panelAnim.reverse().then((_) {
      setState(() => _pinnedLocation = null);
    });
  }

  void _undoPolygonPoint() {
    if (_polygonPoints.isNotEmpty) {
      setState(() => _polygonPoints.removeLast());
    }
  }

  void _confirmPolygon() {
    if (_polygonPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF161B22),
          content: Text('Tap at least 3 points to form a farm boundary.',
              style: TextStyle(color: Colors.white)),
        ),
      );
      return;
    }
    // Compute centroid as the farm's main coordinate
    double lat = _polygonPoints.map((p) => p.latitude).reduce((a, b) => a + b) /
        _polygonPoints.length;
    double lng = _polygonPoints.map((p) => p.longitude).reduce((a, b) => a + b) /
        _polygonPoints.length;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FarmRegistrationScreen(
          isFirstLaunch: false,
          preLat: lat,
          preLng: lng,
          polygonPoints: List.from(_polygonPoints),
        ),
      ),
    ).then((_) {
      setState(() {
        _polygonPoints.clear();
        _mode = _MapMode.view;
      });
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
        width: 130,
        height: 58,
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
      farmMarkers.add(
        Marker(
          point: _pinnedLocation!,
          width: 60,
          height: 80,
          child: const _PinMarker(),
        ),
      );
    }

    // Draw polygon vertex markers
    final polygonMarkers = _polygonPoints
        .asMap()
        .entries
        .map((e) => Marker(
              point: e.value,
              width: 24,
              height: 24,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.goldAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [BoxShadow(color: AppColors.goldAccent.withOpacity(0.6), blurRadius: 8)],
                ),
                child: Center(
                  child: Text('${e.key + 1}',
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black)),
                ),
              ),
            ))
        .toList();

    final closedPolygon = _polygonPoints.length >= 2
        ? [..._polygonPoints, _polygonPoints.first]
        : _polygonPoints;

    return Scaffold(
      body: Stack(
        children: [
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
              // Farm polygon overlay
              if (_polygonPoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: closedPolygon,
                      color: AppColors.goldAccent.withOpacity(0.8),
                      strokeWidth: 2.5,
                    ),
                  ],
                ),
              if (_polygonPoints.length >= 3)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: _polygonPoints,
                      color: AppColors.goldAccent.withOpacity(0.12),
                      borderColor: AppColors.goldAccent,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              MarkerLayer(markers: [...farmMarkers, ...polygonMarkers]),
            ],
          ),

          // ── Top toolbar ─────────────────────────────────────────────────
          _buildTopToolbar(),

          // ── Draw mode info banner ────────────────────────────────────────
          if (_mode == _MapMode.drawPolygon) _buildDrawBanner(),

          // ── No pin: hint ─────────────────────────────────────────────────
          if (_mode == _MapMode.view && _pinnedLocation == null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 72,
              left: 16,
              right: 16,
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: const Row(children: [
                  Icon(Icons.touch_app, color: AppColors.goldAccent, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tap to drop a pin — or use Draw Shape to outline your farm',
                      style: TextStyle(color: AppColors.goldAccent, fontSize: 12),
                    ),
                  ),
                ]),
              ),
            ),

          // ── Zoom + Mode buttons ──────────────────────────────────────────
          Positioned(
            right: 12,
            bottom: 220,
            child: Column(
              children: [
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
                _iconBtn(Icons.my_location, () {
                  if (selected != null) {
                    _mapController.move(LatLng(selected.latitude, selected.longitude), 14);
                  }
                }),
              ],
            ),
          ),

          // ── Pin panel (view mode) ────────────────────────────────────────
          if (_mode == _MapMode.view)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: _panelSlide,
                child: _buildPinPanel(),
              ),
            ),

          // ── Polygon actions (draw mode) ──────────────────────────────────
          if (_mode == _MapMode.drawPolygon) _buildPolygonActionsPanel(),
        ],
      ),
    );
  }

  // ── Top Toolbar ──────────────────────────────────────────────────────────
  Widget _buildTopToolbar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16, right: 16, bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.88), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.map_rounded, color: AppColors.primaryAccent, size: 20),
            const SizedBox(width: 8),
            const Text('SATELLITE MAP',
                style: TextStyle(color: AppColors.primaryAccent,
                    fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.5)),
            const Spacer(),
            // Draw Shape toggle
            GestureDetector(
              onTap: () => setState(() {
                _mode = _mode == _MapMode.drawPolygon ? _MapMode.view : _MapMode.drawPolygon;
                _polygonPoints.clear();
                _pinnedLocation = null;
                _panelAnim.reset();
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _mode == _MapMode.drawPolygon
                      ? AppColors.goldAccent.withOpacity(0.25)
                      : AppColors.primaryAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _mode == _MapMode.drawPolygon
                        ? AppColors.goldAccent
                        : AppColors.primaryAccent.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _mode == _MapMode.drawPolygon ? Icons.close : Icons.polyline,
                      color: _mode == _MapMode.drawPolygon
                          ? AppColors.goldAccent
                          : AppColors.primaryAccent,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _mode == _MapMode.drawPolygon ? 'Cancel' : 'Draw Shape',
                      style: TextStyle(
                        color: _mode == _MapMode.drawPolygon
                            ? AppColors.goldAccent
                            : AppColors.primaryAccent,
                        fontSize: 12, fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Draw mode banner ──────────────────────────────────────────────────────
  Widget _buildDrawBanner() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 72,
      left: 16,
      right: 16,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          const Text('🖊️', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('DRAW MODE',
                    style: TextStyle(color: AppColors.goldAccent,
                        fontWeight: FontWeight.bold, fontSize: 12)),
                Text(
                  _polygonPoints.isEmpty
                      ? 'Tap corners of your farm to draw its boundary'
                      : '${_polygonPoints.length} points • Tap to add more',
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ),
          if (_polygonPoints.isNotEmpty)
            GestureDetector(
              onTap: _undoPolygonPoint,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.undo, color: Colors.white70, size: 16),
              ),
            ),
        ]),
      ),
    );
  }

  // ── Polygon actions panel ─────────────────────────────────────────────────
  Widget _buildPolygonActionsPanel() {
    final hasEnough = _polygonPoints.length >= 3;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1117),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.goldAccent.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: AppColors.goldAccent.withOpacity(0.1), blurRadius: 20)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.polyline, color: AppColors.goldAccent, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('FARM SHAPE',
                          style: TextStyle(color: AppColors.goldAccent,
                              fontWeight: FontWeight.bold, letterSpacing: 1)),
                      Text(
                        _polygonPoints.isEmpty
                            ? 'No points yet'
                            : '${_polygonPoints.length} vertices drawn',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_polygonPoints.length >= 2) ...[
              // Show coordinate summary
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._polygonPoints.take(3).map((p) => Text(
                          'Pt: ${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}',
                          style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace'),
                        )),
                    if (_polygonPoints.length > 3)
                      Text('... +${_polygonPoints.length - 3} more',
                          style: const TextStyle(color: Colors.white24, fontSize: 10)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _polygonPoints.isNotEmpty ? _undoPolygonPoint : null,
                    icon: const Icon(Icons.undo, size: 16),
                    label: const Text('Undo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white60,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: hasEnough ? _confirmPolygon : null,
                    icon: const Icon(Icons.agriculture, size: 18),
                    label: Text(
                      hasEnough ? 'USE THIS SHAPE' : 'Need ${3 - _polygonPoints.length} more',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasEnough ? AppColors.goldAccent : Colors.white24,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinPanel() {
    if (_pinnedLocation == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.primaryAccent.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: AppColors.primaryAccent.withOpacity(0.1), blurRadius: 20)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.place, color: AppColors.primaryAccent, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('LOCATION PINNED',
                        style: TextStyle(color: AppColors.primaryAccent, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    Text(
                      'Lat: ${_pinnedLocation!.latitude.toStringAsFixed(6)}   Lng: ${_pinnedLocation!.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _clearPin,
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Clear'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white54,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FarmRegistrationScreen(
                        isFirstLaunch: false,
                        preLat: _pinnedLocation!.latitude,
                        preLng: _pinnedLocation!.longitude,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.agriculture, size: 18),
                  label: const Text('REGISTER FARM HERE',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xCC0D1117),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primaryAccent.withOpacity(0.4)),
          boxShadow: [BoxShadow(color: AppColors.primaryAccent.withOpacity(0.15), blurRadius: 8)],
        ),
        child: Icon(icon, color: AppColors.primaryAccent, size: 20),
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

// ─── Farm Marker ─────────────────────────────────────────────────────────────
class _FarmMarker extends StatelessWidget {
  final FarmHiveModel farm;
  final bool isSelected;
  final VoidCallback onTap;
  const _FarmMarker({required this.farm, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primaryAccent : AppColors.goldAccent;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color, width: isSelected ? 2 : 1),
              boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)],
            ),
            child: Text('🌾 ${farm.name}',
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          Container(width: 2, height: 8, color: color),
          Container(width: 10, height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle, color: color,
                boxShadow: [BoxShadow(color: color.withOpacity(0.7), blurRadius: 10)],
              )),
        ],
      ),
    );
  }
}

// ─── Pin Drop Marker ─────────────────────────────────────────────────────────
class _PinMarker extends StatelessWidget {
  const _PinMarker();
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: const [BoxShadow(color: Colors.red, blurRadius: 12)],
          ),
          child: const Icon(Icons.agriculture, color: Colors.white, size: 20),
        ),
        Container(width: 2, height: 20, color: Colors.redAccent),
        Container(width: 8, height: 8,
            decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
      ],
    );
  }
}
