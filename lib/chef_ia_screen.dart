import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'branding_service.dart';
import 'constants.dart';
import 'gemini_service.dart';

class ChefIaScreen extends StatefulWidget {
  const ChefIaScreen({super.key});

  @override
  State<ChefIaScreen> createState() => _ChefIaScreenState();
}

class _ChefIaScreenState extends State<ChefIaScreen> {
  final TextEditingController _messageController = TextEditingController();
  final GeminiService _geminiService = GeminiService();

  late List<Map<String, String>> _uiMessages;

  bool _isLoading = false;
  List<Map<String, dynamic>> _vraisPlats = [];

  @override
  void initState() {
    super.initState();
    final brand = BrandingData.defaults();
    _uiMessages = [
      {
        "role": "assistant",
        "message":
            "Bienvenue chez ${brand.nom} ! 🍳 Je suis le Chef IA. Quel plat puis-je vous conseiller ce soir ?"
      }
    ];
    _chargerMenuDepuisFirestore();
  }

  // Charger le menu une fois en arrière-plan pour alimenter l'IA
  void _chargerMenuDepuisFirestore() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('plats').get();
      setState(() {
        _vraisPlats = snapshot.docs
            .map((doc) => {...doc.data(), 'id': doc.id})
            .where((plat) =>
                plat['disponible'] ?? true) // Uniquement les plats disponibles
            .toList();
      });
    } catch (e) {
      print("Erreur chargement menu pour l'IA: $e");
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  // Génération du Prompt Système avec le menu inclus de manière structurée
  String _buildSystemInstruction() {
    final brand = BrandingData.defaults();

    // Convertir la liste des vrais plats en texte lisible par l'IA
    String menuText = _vraisPlats.map((p) {
      return "- ${p['nom']} (${p['categorie']}) : Prix: ${p['prix']} MRU. Description: ${p['description'] ?? 'Pas de description'}.";
    }).join("\n");

    if (_vraisPlats.isEmpty) {
      menuText = "Le menu est actuellement indisponible ou vide.";
    }

    return "Tu es le Chef IA de ${brand.nom}, un service de livraison de repas de confiance à ${brand.ville} (secteur ${brand.zone}).\n"
        "Voici la liste RÉELLE et ACTUELLE des plats disponibles dans notre cuisine :\n"
        "$menuText\n\n"
        "CONSIGNES STRICTES :\n"
        "1. Tu ne dois RECOMMANDER OU PARLER QUE des plats présents dans la liste ci-dessus. Ne propose aucun plat imaginaire.\n"
        "2. Sois accueillant, chaleureux, expert en cuisine et exprime-toi avec quelques emojis (🍳, 🍔, 🍕, 🌶️).\n"
        "3. Si l'utilisateur demande le prix, donne le prix exact écrit dans la liste.\n"
        "4. Réponds toujours de manière concise et claire (maximum 3-4 phrases par réponse). Si le client parle en arabe ou en anglais, réponds dans sa langue.";
  }

  void _envoyerMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _messageController.clear();
    setState(() {
      _uiMessages.add({"role": "user", "message": text});
      _isLoading = true;
    });

    final prompt = '${_buildSystemInstruction()}\n\nUtilisateur : $text';

    String reponse = await _geminiService.generateChatResponse(prompt);

    setState(() {
      _uiMessages.add({"role": "assistant", "message": reponse});
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Column(
        children: [
          // En-tête personnalisé
          Container(
            padding: const EdgeInsets.fromLTRB(16, 45, 16, 16),
            color: const Color(0xFF1A1A22),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: kPrimaryColor.withOpacity(0.15),
                  child: const Icon(Icons.psychology, color: kPrimaryColor),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Chef Conseiller IA 🧑‍🍳",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    Text("En ligne • Connecté au menu",
                        style: TextStyle(color: Colors.green, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),

          // Zone des messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _uiMessages.length,
              itemBuilder: (context, index) {
                final msg = _uiMessages[index];
                final isUser = msg["role"] == "user";
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser ? kPrimaryColor : const Color(0xFF1A1A22),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 0),
                        bottomRight: Radius.circular(isUser ? 0 : 16),
                      ),
                    ),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.78),
                    child: Text(
                      msg["message"] ?? '',
                      style: TextStyle(
                          color: isUser ? Colors.white : Colors.white70,
                          fontSize: 14),
                    ),
                  ),
                );
              },
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: Center(
                  child: CircularProgressIndicator(color: kPrimaryColor)),
            ),

          // Barre d'écriture
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF1A1A22),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText:
                          "Demandez au Chef... (ex: Que me conseillez-vous ?)",
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _envoyerMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: kPrimaryColor),
                  onPressed: _envoyerMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
