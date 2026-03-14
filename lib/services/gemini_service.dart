import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/constants/app_constants.dart';

/// Gemini AI advisor for farm-related questions and recommendations.
class GeminiService {
  GenerativeModel? _model;

  GenerativeModel get model {
    _model ??= GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: AppConstants.geminiApiKey,
    );
    return _model!;
  }

  Future<String> translateText({
    required String text,
    required String targetLanguageCode,
  }) async {
    if (text.trim().isEmpty || targetLanguageCode == 'en') return text;
    if (AppConstants.geminiApiKey.isEmpty ||
        AppConstants.geminiApiKey == 'YOUR_GEMINI_API_KEY') {
      return text;
    }

    const languageNames = <String, String>{
      'hi': 'Hindi',
      'mr': 'Marathi',
      'kn': 'Kannada',
      'ta': 'Tamil',
      'te': 'Telugu',
    };
    final targetLanguage = languageNames[targetLanguageCode] ?? 'English';

    try {
      final prompt =
          'Translate the following agriculture advisory text to $targetLanguage. '
          'Keep key technical terms (NDVI, LSWI, RVI, SM) unchanged.\n\n$text';
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text?.trim().isNotEmpty == true
          ? response.text!.trim()
          : text;
    } catch (_) {
      return text;
    }
  }

  /// Send farm context + user question to Gemini and get a recommendation.
  Future<String> getAdvice({
    required String cropType,
    required double ndvi,
    required double soilMoisture,
    required double temperature,
    required double rainProbability,
    String? pestAdvisory,
    String? cropCalendar,
    String? userQuestion,
  }) async {
    if (AppConstants.geminiApiKey.isEmpty ||
        AppConstants.geminiApiKey == 'YOUR_GEMINI_API_KEY') {
      return _fallbackAdvice(ndvi, soilMoisture, temperature, rainProbability);
    }

    final systemPrompt =
        '''You are an experienced agricultural expert and farm advisor.
Analyze the following farm data and provide practical, actionable recommendations for irrigation, pest control, fertilizer, and general crop management.
Keep your response concise (3‒5 bullet points) and farmer-friendly.''';

    final dataPrompt =
        '''
Farm Data:
- Crop: $cropType
- NDVI (vegetation health): ${ndvi.toStringAsFixed(3)} ${ndvi > 0.6
            ? "(Healthy)"
            : ndvi > 0.4
            ? "(Moderate)"
            : "(Poor)"}
- Soil Moisture: ${soilMoisture.toStringAsFixed(1)}%
- Temperature: ${temperature.toStringAsFixed(1)}°C
- Rain Probability: ${rainProbability.toStringAsFixed(0)}%
${pestAdvisory != null ? '- Pest/Disease Alert: $pestAdvisory' : ''}
${cropCalendar != null ? '- Crop Calendar: $cropCalendar' : ''}
${userQuestion != null ? '\nFarmer Question: $userQuestion' : '\nProvide a general farm health assessment and recommendations.'}
''';

    try {
      final chat = model.startChat(history: [Content.text(systemPrompt)]);
      final response = await chat.sendMessage(Content.text(dataPrompt));
      return response.text ?? 'No response from AI advisor.';
    } catch (e) {
      return _fallbackAdvice(ndvi, soilMoisture, temperature, rainProbability);
    }
  }

  /// Offline rule-based fallback when Gemini is unavailable.
  String _fallbackAdvice(
    double ndvi,
    double soilMoisture,
    double temp,
    double rain,
  ) {
    final lines = <String>[];
    if (ndvi < 0.4)
      lines.add(
        '⚠️ Vegetation health is poor (NDVI ${ndvi.toStringAsFixed(2)}). Consider applying NPK fertilizer and checking for pest damage.',
      );
    if (soilMoisture < 30 && rain < 30)
      lines.add(
        '💧 Soil moisture is low and rain unlikely. Start drip irrigation immediately.',
      );
    if (soilMoisture > 60)
      lines.add(
        '✅ Soil moisture is adequate. No irrigation needed at this time.',
      );
    if (rain > 60)
      lines.add(
        '🌧️ High rain probability (${rain.toInt()}%). Delay irrigation and ensure proper drainage.',
      );
    if (temp > 35)
      lines.add(
        '🌡️ High temperature detected. Provide shade or mulching to prevent heat stress.',
      );
    if (ndvi > 0.6)
      lines.add(
        '🌿 Crop health looks good. Continue current management practices.',
      );
    if (lines.isEmpty)
      lines.add(
        '📊 Farm conditions are within normal range. Monitor regularly.',
      );
    return lines.join('\n\n');
  }
}
