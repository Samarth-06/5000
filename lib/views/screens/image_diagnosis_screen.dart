import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodels/farm_providers.dart';
import '../../models/dashboard_models.dart';
import '../widgets/glass_card.dart';

class ImageDiagnosisScreen extends ConsumerStatefulWidget {
  const ImageDiagnosisScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ImageDiagnosisScreen> createState() =>
      _ImageDiagnosisScreenState();
}

class _ImageDiagnosisScreenState extends ConsumerState<ImageDiagnosisScreen> {
  String? _selectedImagePath;
  bool _isUploading = false;
  bool _isLoadingAdvisory = false;
  List<ImageReport> _reports = [];
  String? _error;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImagePath = picked.path);
    }
  }

  Future<void> _pickCamera() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() => _selectedImagePath = picked.path);
    }
  }

  Future<void> _uploadAndAnalyze() async {
    if (_selectedImagePath == null) return;
    setState(() {
      _isUploading = true;
      _error = null;
    });

    final api = ref.read(sat2farmApiProvider);
    final supa = ref.read(supabaseServiceProvider);
    final farm = ref.read(selectedFarmProvider);

    // Upload image
    final upload = await api.saveImage(_selectedImagePath!);
    if (upload == null || !upload.isSuccess) {
      setState(() {
        _isUploading = false;
        _isLoadingAdvisory = false;
        _error = 'Image upload failed. Please try again.';
      });
      return;
    }

    setState(() {
      _isUploading = false;
      _isLoadingAdvisory = true;
    });

    // Get advisory
    final reports = await api.getImageAdvisory();
    setState(() {
      _reports = reports;
      _isLoadingAdvisory = false;
    });

    // Store to Supabase
    if (reports.isNotEmpty && farm != null) {
      try {
        for (final report in reports) {
          await supa.insertImageReport(report.toSupabase(farm.id));
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'IMAGE DIAGNOSIS',
          style: TextStyle(
            color: AppColors.primaryAccent,
            letterSpacing: 1.5,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Upload section
            GlassCard(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(
                    Icons.camera_alt,
                    color: AppColors.primaryAccent,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'CROP IMAGE ANALYSIS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Upload a crop image to detect diseases',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.photo_library, size: 18),
                          label: const Text('Gallery'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryAccent,
                            side: const BorderSide(
                              color: AppColors.primaryAccent,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickCamera,
                          icon: const Icon(Icons.camera, size: 18),
                          label: const Text('Camera'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.secondaryAccent2,
                            side: const BorderSide(
                              color: AppColors.secondaryAccent2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_selectedImagePath != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryAccent.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.image,
                            color: AppColors.primaryAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Image selected ✓',
                              style: TextStyle(
                                color: AppColors.primaryAccent,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: (_isUploading || _isLoadingAdvisory)
                            ? null
                            : _uploadAndAnalyze,
                        icon: (_isUploading || _isLoadingAdvisory)
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Icon(Icons.search, size: 18),
                        label: Text(
                          _isUploading
                              ? 'Uploading...'
                              : _isLoadingAdvisory
                              ? 'Analyzing...'
                              : 'ANALYZE CROP',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ],

            // Results
            if (_reports.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Row(
                children: [
                  Icon(Icons.biotech, color: AppColors.softPurple, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'DIAGNOSIS RESULTS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._reports.map(
                (r) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.redAccent.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🌿', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                          Text(
                            r.cropName,
                            style: const TextStyle(
                              color: AppColors.primaryAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white12, height: 20),
                      _resultRow(
                        '🦠',
                        'Disease',
                        r.diseaseName,
                        Colors.redAccent,
                      ),
                      if (r.symptoms.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _resultRow(
                          '🩺',
                          'Symptoms',
                          r.symptoms,
                          Colors.orangeAccent,
                        ),
                      ],
                      const SizedBox(height: 8),
                      _resultRow(
                        '💊',
                        'Solution',
                        r.solution,
                        AppColors.primaryAccent,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _resultRow(String emoji, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
