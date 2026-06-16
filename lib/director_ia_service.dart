import 'package:google_generative_ai/google_generative_ai.dart';
import '../api_keys.example.dart'; // Assure-toi de pointer vers ton fichier de clés final

class DirectorIAService {
  // Initialisation du modèle Gemini Pro
  final GenerativeModel _model = GenerativeModel(
    model: 'gemini-1.5-flash', // Modèle ultra-rapide et économique pour l'analyse de données
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
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? "Impossible de générer l'analyse pour le moment.";
    } catch (e) {
      return "Erreur lors de l'analyse IA : ${e.toString()}";
    }
  }
}