import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../viewmodels/farm_providers.dart';
import '../widgets/glass_card.dart';
import 'farm_registration_screen.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapCtrl = MapController();
  LatLng? _pinnedLocation;
  bool _showNdviOverlay = false;
  bool _isDrawingPolygon = false;
  final List<LatLng> _polygonPoints = [];

  @override
  Widget build(BuildContext context) {
    final farms = ref.watch(farmListProvider);
    final selectedFarm = ref.watch(selectedFarmProvider);
    final dashState = ref.watch(dashboardProvider);
    final ndvi = dashState.vegetation?.ndvi ?? dashState.summary?.ndvi ?? 0.0;

    // Farm polygon from API/generated
    final polyCoords = dashState.farmPolygonCoords;
    List<LatLng> farmBoundary = [];
    if (polyCoords != null && polyCoords.isNotEmpty) {
      farmBoundary = polyCoords.map((c) => LatLng(c[1], c[0])).toList();
    }

    final mapTilerKey = AppConstants.mapTilerApiKey;
    final tileUrl =
        'https://api.maptiler.com/maps/satellite/{z}/{x}/{y}.jpg?key=$mapTilerKey';

    return Scaffold(
      body: Stack(
        children: [
          // Map with MapTiler tiles
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: selectedFarm != null
                  ? LatLng(selectedFarm.latitude, selectedFarm.longitude)
                  : const LatLng(18.5204, 73.8567),
              initialZoom: 16.0,
              onTap: (_, latLng) {
                if (_isDrawingPolygon) {
                  setState(() => _polygonPoints.add(latLng));
                } else {
                  setState(() => _pinnedLocation = latLng);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: tileUrl,
                userAgentPackageName: 'com.sat2farm.app',
                maxZoom: 20,
              ),

              // Farm boundary polygon from /showPolygon or generated
              if (farmBoundary.isNotEmpty)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: farmBoundary,
                      color: AppColors.primaryAccent.withOpacity(0.1),
                      borderColor: AppColors.primaryAccent,
                      borderStrokeWidth: 2.5,
                    ),
                  ],
                ),

              // NDVI grid inside the farm polygon
              if (_showNdviOverlay && farmBoundary.isNotEmpty)
                _buildNdviGridOverlay(farmBoundary, ndvi),

              // Farm markers
              MarkerLayer(
                markers: farms.map((f) {
                  final isSelected = selectedFarm?.id == f.id;
                  return Marker(
                    point: LatLng(f.latitude, f.longitude),
                    width: isSelected ? 50 : 40,
                    height: isSelected ? 50 : 40,
                    child: GestureDetector(
                      onTap: () {
                        ref.read(selectedFarmProvider.notifier).select(f);
                        _mapCtrl.move(LatLng(f.latitude, f.longitude), 16);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryAccent
                              : AppColors.secondaryAccent2,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (isSelected
                                          ? AppColors.primaryAccent
                                          : AppColors.secondaryAccent2)
                                      .withOpacity(0.6),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.agriculture,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              // Pinned marker
              if (_pinnedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _pinnedLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.redAccent,
                        size: 40,
                      ),
                    ),
                  ],
                ),

              // User-drawn polygon
              if (_polygonPoints.isNotEmpty)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: _polygonPoints,
                      color: AppColors.primaryAccent.withOpacity(0.2),
                      borderColor: AppColors.primaryAccent,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
            ],
          ),

          // Top info bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  if (selectedFarm != null)
                    GlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.agriculture,
                            color: AppColors.primaryAccent,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedFarm.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '${selectedFarm.cropType} • ${selectedFarm.areaInAcres} acres',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_showNdviOverlay)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _ndviColor(ndvi).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'NDVI: ${ndvi.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: _ndviColor(ndvi),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Right side controls
          Positioned(
            bottom: 80,
            right: 12,
            child: Column(
              children: [
                _mapButton(
                  icon: _showNdviOverlay ? Icons.layers_clear : Icons.layers,
                  color: _showNdviOverlay
                      ? AppColors.primaryAccent
                      : Colors.white70,
                  onTap: () =>
                      setState(() => _showNdviOverlay = !_showNdviOverlay),
                  tooltip: 'Show Vegetation Index',
                ),
                const SizedBox(height: 8),
                _mapButton(
                  icon: _isDrawingPolygon ? Icons.check : Icons.draw,
                  color: _isDrawingPolygon
                      ? AppColors.primaryAccent
                      : Colors.white70,
                  onTap: () {
                    if (_isDrawingPolygon && _polygonPoints.length >= 3) {
                      setState(() => _isDrawingPolygon = false);
                      _showPolygonActions(context);
                    } else if (_isDrawingPolygon) {
                      setState(() {
                        _isDrawingPolygon = false;
                        _polygonPoints.clear();
                      });
                    } else {
                      setState(() {
                        _isDrawingPolygon = true;
                        _polygonPoints.clear();
                      });
                    }
                  },
                  tooltip: _isDrawingPolygon ? 'Finish' : 'Draw Polygon',
                ),
                const SizedBox(height: 8),
                _mapButton(
                  icon: Icons.add_location_alt,
                  color: AppColors.secondaryAccent2,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FarmRegistrationScreen(
                        initialLatitude:
                            _pinnedLocation?.latitude ?? selectedFarm?.latitude,
                        initialLongitude:
                            _pinnedLocation?.longitude ??
                            selectedFarm?.longitude,
                        polygonPoints: _polygonPoints.isNotEmpty
                            ? _polygonPoints
                            : null,
                      ),
                    ),
                  ),
                  tooltip: 'Register Farm',
                ),
                const SizedBox(height: 8),
                if (selectedFarm != null)
                  _mapButton(
                    icon: Icons.center_focus_strong,
                    color: AppColors.goldAccent,
                    onTap: () => _mapCtrl.move(
                      LatLng(selectedFarm.latitude, selectedFarm.longitude),
                      16,
                    ),
                    tooltip: 'Center',
                  ),
              ],
            ),
          ),

          // NDVI legend
          if (_showNdviOverlay)
            Positioned(
              bottom: 80,
              left: 12,
              child: GlassCard(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NDVI Scale',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _legendRow(const Color(0xFF8B4513), '0.0–0.2 Poor'),
                    _legendRow(const Color(0xFFDAA520), '0.2–0.4 Stressed'),
                    _legendRow(const Color(0xFF90EE90), '0.4–0.6 Moderate'),
                    _legendRow(const Color(0xFF006400), '0.6–1.0 Healthy'),
                  ],
                ),
              ),
            ),

          if (mapTilerKey.isEmpty)
            const Positioned(
              top: 80,
              left: 12,
              right: 12,
              child: Card(
                color: Color(0xCC8B0000),
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(
                    'MapTiler API key missing. Set MAPTILER_API_KEY in .env to load map tiles.',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),

          // Drawing mode indicator
          if (_isDrawingPolygon)
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Tap map to draw polygon (${_polygonPoints.length} points)',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build a 20x20 NDVI grid inside the farm polygon bounds.
  Widget _buildNdviGridOverlay(List<LatLng> boundary, double baseNdvi) {
    // Find bounding box
    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
    for (final p in boundary) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    const gridSize = 20;
    final latStep = (maxLat - minLat) / gridSize;
    final lngStep = (maxLng - minLng) / gridSize;
    List<Polygon> cells = [];
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        final cellCenter = LatLng(
          minLat + (i + 0.5) * latStep,
          minLng + (j + 0.5) * lngStep,
        );

        // Only include cells inside the polygon
        if (!_isPointInPolygon(cellCenter, boundary)) continue;

        final color = _ndviColor(baseNdvi.clamp(0.0, 1.0));

        cells.add(
          Polygon(
            points: [
              LatLng(minLat + i * latStep, minLng + j * lngStep),
              LatLng(minLat + i * latStep, minLng + (j + 1) * lngStep),
              LatLng(minLat + (i + 1) * latStep, minLng + (j + 1) * lngStep),
              LatLng(minLat + (i + 1) * latStep, minLng + j * lngStep),
            ],
            color: color.withOpacity(0.45),
            borderColor: color.withOpacity(0.15),
            borderStrokeWidth: 0.5,
          ),
        );
      }
    }

    return PolygonLayer(polygons: cells);
  }

  /// Ray-casting point-in-polygon test.
  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    bool inside = false;
    int j = polygon.length - 1;
    for (int i = 0; i < polygon.length; i++) {
      if ((polygon[i].latitude > point.latitude) !=
              (polygon[j].latitude > point.latitude) &&
          point.longitude <
              (polygon[j].longitude - polygon[i].longitude) *
                      (point.latitude - polygon[i].latitude) /
                      (polygon[j].latitude - polygon[i].latitude) +
                  polygon[i].longitude) {
        inside = !inside;
      }
      j = i;
    }
    return inside;
  }

  Color _ndviColor(double ndvi) {
    if (ndvi < 0.2) return const Color(0xFF8B4513);
    if (ndvi < 0.4) return const Color(0xFFDAA520);
    if (ndvi < 0.6) return const Color(0xFF90EE90);
    return const Color(0xFF006400);
  }

  Widget _legendRow(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _mapButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117).withOpacity(0.85),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.2), blurRadius: 8),
            ],
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  void _showPolygonActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Farm Polygon Created',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_polygonPoints.length} vertices defined',
              style: const TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FarmRegistrationScreen(
                        initialLatitude: _polygonPoints.first.latitude,
                        initialLongitude: _polygonPoints.first.longitude,
                        polygonPoints: _polygonPoints,
                      ),
                    ),
                  );
                },
                child: const Text('REGISTER FARM WITH POLYGON'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() => _polygonPoints.clear());
                Navigator.pop(context);
              },
              child: const Text(
                'DISCARD',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
