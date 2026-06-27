import 'package:google_generative_ai/google_generative_ai.dart';

const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
const String geminiModel = String.fromEnvironment('GEMINI_MODEL', defaultValue: 'gemini-2.5-flash');

// ✅ NOUVEAU : le service gère maintenant une vraie conversation multi-tour
class DirectorIAService {
  final GenerativeModel _model = GenerativeModel(
    model: geminiModel,
    apiKey: geminiApiKey,
  );

  // Contexte système injecté dans chaque session de chat
  String _buildSystemPrompt({
    required double ca,
    required int commandes,
    required List<String> plats,
    required Map<String, int> paiements,
  }) {
    final panierMoyen = commandes > 0 ? (ca / commandes).toStringAsFixed(0) : '0';
    final platsCount = <String, int>{};
    for (final p in plats) platsCount[p] = (platsCount[p] ?? 0) + 1;
    final topPlats = (platsCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
        .take(5)
        .map((e) => '${e.key} (${e.value}x)')
        .join(', ');

    return """
Tu es le Chef IA Stratégique du restaurant. Tu es un consultant expert en gestion de restaurant, 
finance, marketing et optimisation des ventes. Tu parles en français, de façon directe, 
professionnelle mais accessible pour un patron de restaurant à Nouakchott, Mauritanie.

DONNÉES TEMPS RÉEL DU RESTAURANT :
- Chiffre d'affaires total : ${ca.toStringAsFixed(0)} MRU
- Nombre de commandes : $commandes
- Panier moyen : $panierMoyen MRU
- Top plats vendus : $topPlats
- Paiements — Cash: ${paiements['cash'] ?? 0} | Bankily: ${paiements['bankily'] ?? 0} | Masrivi: ${paiements['masrivi'] ?? 0}
- Contexte : Restaurant à Nouakchott, Mauritanie, application mobile de commande

Réponds toujours en te basant sur ces données réelles. Sois concis (max 4-5 phrases par réponse),
actionnable et pratique. Utilise des emojis stratégiquement pour rendre la lecture agréable.
""";
  }

  // Démarrer une analyse complète (premier message du chat)
  Future<String> genererRapportStrategique({
    required double chiffreAffaires,
    required int totalCommandes,
    required List<String> listePlatsVendus,
    Map<String, int>? paiements,
  }) async {
    if (geminiApiKey.isEmpty) {
      return "⚠️ Clé API Gemini introuvable. Ajoute GEMINI_API_KEY dans les variables d'environnement Codemagic.";
    }

    final pmt = paiements ?? {};
    final systemPrompt = _buildSystemPrompt(
      ca: chiffreAffaires,
      commandes: totalCommandes,
      plats: listePlatsVendus,
      paiements: pmt,
    );

    const analysePrompt = """
Fais une analyse complète de la situation actuelle du restaurant. Structure ta réponse ainsi :

📊 **PERFORMANCE**
- Bilan chiffres clés

🍽️ **TOP MENU**
- Plats stars à mettre en avant

💡 **ACTION PRIORITAIRE**
- 1 action concrète à faire aujourd'hui pour augmenter les ventes
""";

    try {
      final chat = _model.startChat(history: [
        Content.text("$systemPrompt\n\nCommence la session."),
      ]);
      final response = await chat.sendMessage(Content.text(analysePrompt));
      return response.text ?? "Impossible de générer le rapport.";
    } catch (e) {
      return "❌ Erreur IA : $e";
    }
  }

  // Envoyer un message dans une conversation existante
  Future<String> envoyerMessage({
    required String messageUtilisateur,
    required List<Map<String, String>> historique,
    required double ca,
    required int commandes,
    required List<String> plats,
    required Map<String, int> paiements,
  }) async {
    if (geminiApiKey.isEmpty) {
      return "⚠️ Clé API Gemini non configurée.";
    }

    try {
      final systemPrompt = _buildSystemPrompt(ca: ca, commandes: commandes, plats: plats, paiements: paiements);

      // Reconstruire l'historique Gemini
      final history = <Content>[
        Content.text("$systemPrompt\n\nCommence la session."),
      ];

      for (final msg in historique) {
        if (msg['role'] == 'user') {
          history.add(Content.text(msg['content']!));
        } else {
          history.add(Content.model([TextPart(msg['content']!)]));
        }
      }

      final chat = _model.startChat(history: history);
      final response = await chat.sendMessage(Content.text(messageUtilisateur));
      return response.text ?? "Aucune réponse générée.";
    } catch (e) {
      return "❌ Erreur : $e";
    }
  }
}
