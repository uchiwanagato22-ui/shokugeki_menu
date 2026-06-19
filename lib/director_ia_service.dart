import 'package:google_generative_ai/google_generative_ai.dart';

const String geminiApiKey = String.fromEnvironment(
  'GEMINI_API_KEY',
  defaultValue: '',
);

const String geminiModel = String.fromEnvironment(
  'GEMINI_MODEL',
  defaultValue: 'gemini-2.5-flash',
);

class DirectorIAService {
  final GenerativeModel _model = GenerativeModel(
    model: geminiModel,
    apiKey: geminiApiKey,
  );

  // Fonction pour générer un rapport financier intelligent
  Future<String> genererRapportStrategique({
    required double chiffreAffaires,
    required int totalCommandes,
    required List<String> listePlatsVendus,
  }) async {
    final prompt = """
    Tu es le Directeur IA et consultant financier expert de l'application Shokugeki Menu.
    Voici les données réelles des ventes de la période :
    - Chiffre d'Affaires total : $chiffreAffaires MRU
    - Nombre total de commandes livrées : $totalCommandes
    - Liste brute des plats vendus : ${listePlatsVendus.join(', ')}

    Fais une analyse ultra-rapide, percutante et professionnelle (style tableau de bord exécutif) en 3 points courts :
    1. Diagnostic des performances financières (Panier moyen, rentabilité).
    2. Optimisation du stock et suggestion de prix (Quels plats mettre en avant).
    3. Action commerciale urgente pour augmenter le chiffre d'affaires ce mois-ci.
    
    Sois direct, professionnel, facile a comprendre pour un patron de restaurant.
    """;

    try {
      if (geminiApiKey.isEmpty) {
        return "Cle API Gemini introuvable. Dans Codemagic, ajoute GEMINI_API_KEY dans Environment variables.";
      }
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ??
          "Impossible de générer le rapport pour le moment.";
    } catch (e) {
      return "Erreur IA avec le modele $geminiModel : $e";
    }
  }
}
