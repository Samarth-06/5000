import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../models/farm_hive_model.dart';
import '../../viewmodels/farm_providers.dart';
import '../widgets/glass_card.dart';
import '../widgets/farm_parallax_background.dart';
import 'dashboard_shell.dart';

class FarmRegistrationScreen extends ConsumerStatefulWidget {
  final bool isFirstLaunch;
  final double? preLat;
  final double? preLng;
  final List<LatLng>? polygonPoints;
  const FarmRegistrationScreen({
    Key? key,
    this.isFirstLaunch = true,
    this.preLat,
    this.preLng,
    this.polygonPoints,
  }) : super(key: key);

  @override
  ConsumerState<FarmRegistrationScreen> createState() => _FarmRegistrationScreenState();
}

class _FarmRegistrationScreenState extends ConsumerState<FarmRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _latCtrl = TextEditingController(text: '21.1458');
  final _lngCtrl = TextEditingController(text: '79.0882');
  final _areaCtrl = TextEditingController(text: '5.0');
  String _selectedCrop = 'Wheat';
  bool _isRegistering = false;

  final List<String> _crops = ['Wheat', 'Rice', 'Cotton', 'Maize', 'Sugarcane', 'Soybean', 'Pulses'];

  @override
  void initState() {
    super.initState();
    if (widget.preLat != null) _latCtrl.text = widget.preLat!.toStringAsFixed(6);
    if (widget.preLng != null) _lngCtrl.text = widget.preLng!.toStringAsFixed(6);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _areaCtrl.dispose();
    super.dispose();
  }

  Future<void> _registerFarm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isRegistering = true);

    final farm = FarmHiveModel(
      id: const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      cropType: _selectedCrop,
      latitude: double.parse(_latCtrl.text.trim()),
      longitude: double.parse(_lngCtrl.text.trim()),
      areaInAcres: double.parse(_areaCtrl.text.trim()),
    );

    // Try to register polygon on Agromonitoring and store ID
    final agroService = ref.read(agroApiProvider);
    final polygonId = await agroService.createPolygon(
      name: farm.name,
      lat: farm.latitude,
      lng: farm.longitude,
    );
    if (polygonId != null) farm.agroPolygonId = polygonId;

    await ref.read(farmListProvider.notifier).addFarm(farm);
    ref.read(selectedFarmProvider.notifier).select(farm);

    if (!mounted) return;
    setState(() => _isRegistering = false);

    if (widget.isFirstLaunch) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const DashboardShell()));
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FarmParallaxBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primaryAccent.withOpacity(0.4)),
                        ),
                        child: const Icon(Icons.agriculture, color: AppColors.primaryAccent, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('REGISTER FARM', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5)),
                          Text(widget.isFirstLaunch ? 'Set up your first farm' : 'Add a new farm',
                              style: const TextStyle(color: Colors.white54, fontSize: 14)),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 36),

                  // Farm Name
                  GlassCard(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('Farm Details', Icons.eco),
                        const SizedBox(height: 16),
                        _buildField('Farm Name', _nameCtrl, Icons.landscape,
                            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
                        const SizedBox(height: 16),
                        _cropDropdown(),
                        const SizedBox(height: 16),
                        _buildField('Area (Acres)', _areaCtrl, Icons.area_chart,
                            keyboardType: TextInputType.number,
                            validator: (v) => double.tryParse(v ?? '') == null ? 'Enter valid number' : null),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Coordinates
                  GlassCard(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('GPS Coordinates', Icons.gps_fixed),
                        const SizedBox(height: 4),
                        const Text('Enter your farm\'s coordinates or use GPS',
                            style: TextStyle(color: Colors.white38, fontSize: 12)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildField('Latitude', _latCtrl, Icons.arrow_upward,
                                  keyboardType: TextInputType.number,
                                  validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid' : null),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildField('Longitude', _lngCtrl, Icons.arrow_forward,
                                  keyboardType: TextInputType.number,
                                  validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid' : null),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // TODO: actual GPS detection
                              _latCtrl.text = '21.1458';
                              _lngCtrl.text = '79.0882';
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                content: Text('GPS location detected! (demo)'),
                                backgroundColor: Color(0xFF228B22),
                              ));
                            },
                            icon: const Icon(Icons.my_location, color: AppColors.secondaryAccent2),
                            label: const Text('Detect My Location', style: TextStyle(color: AppColors.secondaryAccent2)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.secondaryAccent2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Register Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isRegistering ? null : _registerFarm,
                      icon: _isRegistering
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Icon(Icons.satellite_alt),
                      label: Text(_isRegistering ? 'REGISTERING...' : 'REGISTER & SCAN SATELLITE',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryAccent, size: 18),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: AppColors.primaryAccent, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.8)),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon,
      {TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: AppColors.primaryAccent, size: 20),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primaryAccent.withOpacity(0.3))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryAccent, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent)),
        filled: true,
        fillColor: Colors.black.withOpacity(0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _cropDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCrop,
      dropdownColor: const Color(0xFF161B22),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Crop Type',
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(Icons.grass, color: AppColors.primaryAccent, size: 20),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primaryAccent.withOpacity(0.3))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryAccent, width: 1.5)),
        filled: true,
        fillColor: Colors.black.withOpacity(0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: _crops.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      onChanged: (v) => setState(() => _selectedCrop = v!),
    );
  }
}
