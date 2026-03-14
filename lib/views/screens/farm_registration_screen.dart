import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../models/farm_hive_model.dart';
import '../../viewmodels/farm_providers.dart';
import '../widgets/glass_card.dart';

class FarmRegistrationScreen extends ConsumerStatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final List<LatLng>? polygonPoints;

  const FarmRegistrationScreen({
    Key? key,
    this.initialLatitude,
    this.initialLongitude,
    this.polygonPoints,
  }) : super(key: key);

  @override
  ConsumerState<FarmRegistrationScreen> createState() =>
      _FarmRegistrationScreenState();
}

class _FarmRegistrationScreenState
    extends ConsumerState<FarmRegistrationScreen> {
  final _nameCtrl = TextEditingController();
  final _cropTypeCtrl = TextEditingController(text: 'Pomegranate');
  final _areaCtrl = TextEditingController(text: '5.0');
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;
  bool _isRegistering = false;

  @override
  void initState() {
    super.initState();
    _latCtrl = TextEditingController(
      text: (widget.initialLatitude ?? 18.5204).toStringAsFixed(6),
    );
    _lngCtrl = TextEditingController(
      text: (widget.initialLongitude ?? 73.8567).toStringAsFixed(6),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cropTypeCtrl.dispose();
    _areaCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a farm name'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isRegistering = true);

    final farm = FarmHiveModel(
      id: const Uuid().v4(),
      name: name,
      cropType: _cropTypeCtrl.text.trim(),
      latitude: double.tryParse(_latCtrl.text) ?? 18.5204,
      longitude: double.tryParse(_lngCtrl.text) ?? 73.8567,
      areaInAcres: double.tryParse(_areaCtrl.text) ?? 5.0,
    );

    // Try to add polygon via API
    if (widget.polygonPoints != null && widget.polygonPoints!.isNotEmpty) {
      final api = ref.read(sat2farmApiProvider);
      final polygonData = {
        'name': name,
        'geo_json': {
          'type': 'Feature',
          'properties': {},
          'geometry': {
            'type': 'Polygon',
            'coordinates': [
              widget.polygonPoints!
                  .map((p) => [p.longitude, p.latitude])
                  .toList(),
            ],
          },
        },
      };
      final result = await api.addPolygon(polygonData);
      if (result != null) {
        farm.agroPolygonId = result.farmId;
      }
    }

    await ref.read(farmListProvider.notifier).addFarm(farm);
    ref.read(selectedFarmProvider.notifier).select(farm);

    setState(() => _isRegistering = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Farm "${farm.name}" registered!'),
        backgroundColor: AppColors.primaryAccent,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'REGISTER FARM',
          style: TextStyle(
            color: AppColors.primaryAccent,
            fontSize: 16,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GlassCard(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.agriculture,
                        color: AppColors.primaryAccent,
                        size: 22,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'FARM DETAILS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _field(
                    label: 'Farm Name',
                    icon: Icons.edit,
                    ctrl: _nameCtrl,
                    hint: 'My Pomegranate Farm',
                  ),
                  const SizedBox(height: 16),
                  _field(
                    label: 'Crop Type',
                    icon: Icons.grass,
                    ctrl: _cropTypeCtrl,
                  ),
                  const SizedBox(height: 16),
                  _field(
                    label: 'Area (Acres)',
                    icon: Icons.square_foot,
                    ctrl: _areaCtrl,
                    isNumber: true,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          label: 'Latitude',
                          icon: Icons.location_on,
                          ctrl: _latCtrl,
                          isNumber: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          label: 'Longitude',
                          icon: Icons.location_on,
                          ctrl: _lngCtrl,
                          isNumber: true,
                        ),
                      ),
                    ],
                  ),
                  if (widget.polygonPoints != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primaryAccent.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.timeline,
                            color: AppColors.primaryAccent,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Polygon: ${widget.polygonPoints!.length} vertices',
                            style: const TextStyle(
                              color: AppColors.primaryAccent,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isRegistering ? null : _register,
                      icon: _isRegistering
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(Icons.check_circle, size: 18),
                      label: Text(
                        _isRegistering ? 'REGISTERING...' : 'REGISTER FARM',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required IconData icon,
    required TextEditingController ctrl,
    bool isNumber = false,
    String? hint,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: Colors.white24),
        prefixIcon: Icon(icon, color: AppColors.primaryAccent, size: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primaryAccent.withOpacity(0.4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primaryAccent,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.black.withOpacity(0.25),
      ),
    );
  }
}
