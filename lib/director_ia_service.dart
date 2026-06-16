import 'package:google_generative_ai/google_generative_ai.dart';

// Codemagic injectera directement ta clé ici lors du build grâce à cette ligne
const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: ''); 

class DirectorIAService {
  // Initialisation du modèle Gemini 1.5 Flash
  final GenerativeModel _model = GenerativeModel(
    model: 'gemini-1.5-flash',
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
    
    Sois direct, utilise des émojis et parle comme un conseiller en finance d'entreprise.
    """;

    try {
      if (geminiApiKey.isEmpty) {
        return "Clé API Gemini introuvable. Vérifiez les variables d'environnement.";
      }
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? "Impossible de générer le rapport pour le moment.";
    } catch (e) {
      return "Erreur lors de l'analyse IA : $e";
    }
  }
}