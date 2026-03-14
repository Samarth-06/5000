/// Crop advisory / pest warning from /cropadvisory/info
class CropAdvisory {
  final String cropName;
  final String? disease;
  final String? pest;
  final String symptoms;
  final String solution;
  final String? affectedPart;

  CropAdvisory({
    required this.cropName,
    this.disease,
    this.pest,
    required this.symptoms,
    required this.solution,
    this.affectedPart,
  });

  String get title => disease ?? pest ?? 'Advisory';
  bool get isDisease => disease != null;

  factory CropAdvisory.fromJson(Map<String, dynamic> json) {
    return CropAdvisory(
      cropName: json['Crop_name']?.toString() ?? '',
      disease: json['Disease']?.toString(),
      pest: json['Pest']?.toString(),
      symptoms: json['Symptoms']?.toString() ?? '',
      solution: json['Solution']?.toString() ?? '',
      affectedPart: json['Affected_Part']?.toString(),
    );
  }
}

/// Crop calendar from /display/crop/calender/v2
class CropCalendarEntry {
  final String range;
  final String recommended;

  CropCalendarEntry({required this.range, required this.recommended});

  factory CropCalendarEntry.fromJson(Map<String, dynamic> json) {
    return CropCalendarEntry(
      range: json['Range']?.toString() ?? '',
      recommended: json['Recommended']?.toString() ?? '',
    );
  }
}
