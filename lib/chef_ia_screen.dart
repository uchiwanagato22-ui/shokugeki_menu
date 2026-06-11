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
  late List<Map<String, String>> _messages;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final brand = BrandingData.defaults();
    _messages = [
      {
        "role": "assistant",
        "message":
            "Bienvenue chez ${brand.nom} ! 🍳 Je suis le Chef IA. Quel plat puis-je vous conseiller ce soir ?"
      }
    ];
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _addMessage(String role, String message) {
    _messages.add({"role": role, "message": message});
  }

  String _buildPrompt(String userText) {
    final brand = BrandingData.defaults();
    return [
      "Tu es le Chef IA de ${brand.nom}, un service de livraison de repas à ${brand.ville}.",
      "Réponds en FR, ton style est chaleureux et très court.",
      "Si l'utilisateur demande un plat, propose 2-3 plats avec prix et justification.",
      "Si l'utilisateur parle de promo, offres, gratuit, livraison : répond avec une offre fictive réaliste.",
      "Question utilisateur : $userText",
    ].join("\n");
  }

  void _envoyerMessage() async {
    final userText = _messageController.text.trim();
    if (userText.isEmpty) return;

    if (!GeminiService.isConfigured) {
      setState(() {
        _addMessage(
            "assistant", "Chef IA indisponible : clé Gemini non configurée.");
      });
      return;
    }

    final gemini = GeminiService();

    setState(() {
      _messages.add({"role": "user", "message": userText});
      _messageController.clear();
      _isLoading = true;
    });

    try {
      final prompt = _buildPrompt(userText);
      final botResponse = await gemini.generateText(prompt);

      setState(() {
        _messages.add({"role": "assistant", "message": botResponse});
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({
          "role": "assistant",
          "message": "Erreur Gemini : ${e.toString()}"
        });
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111115), // Thème sombre cuisine
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A22),
        title: const Row(
          children: [
            Icon(Icons.psychology, color: kPrimaryColor),
            SizedBox(width: 10),
            Text("LE CHEF IA SHOKUGEKI",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                bool isUser = msg["role"] == "user";

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser ? kPrimaryColor : const Color(0xFF1A1A22),
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: isUser
                            ? const Radius.circular(0)
                            : const Radius.circular(16),
                        topLeft: !isUser
                            ? const Radius.circular(0)
                            : const Radius.circular(16),
                      ),
                    ),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75),
                    child: Text(
                      msg["message"]!,
                      style: TextStyle(
                          color: isUser ? Colors.black : Colors.white,
                          fontSize: 14,
                          fontWeight:
                              isUser ? FontWeight.bold : FontWeight.normal),
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
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF1A1A22),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText:
                          "Demandez au Chef... (ex: Plat le moins cher ?)",
                      hintStyle: const TextStyle(color: Colors.grey),
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
