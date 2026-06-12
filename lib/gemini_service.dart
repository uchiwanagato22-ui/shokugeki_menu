import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static bool get isConfigured => _apiKey.isNotEmpty;

  final GenerativeModel _model;

  GeminiService()
      : _model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: _apiKey,
        );

  Future<String> generateChatResponse(String prompt) async {
    if (_apiKey.isEmpty) {
      return "Chef IA indisponible : clé Gemini non configurée.";
    }

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        return "Je n'ai pas pu générer de réponse pour le moment.";
      }
      return text.trim();
    } catch (e) {
      return "Désolé, j'ai rencontré une petite erreur technique. Réessaie !";
    }
  }
}