import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'constants.dart';

class ChefIaScreen extends StatefulWidget {
  const ChefIaScreen({super.key});

  @override
  State<ChefIaScreen> createState() => _ChefIaScreenState();
}

class _ChefIaScreenState extends State<ChefIaScreen> {
  // Clé API de ton projet
  final String geminiApiKey = "AIzaSyAta2x-jysyl2Md5IC_BWO_rteKLyXj-nE";

  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [
    {
      "role": "assistant",
      "message": "Bienvenue dans les cuisines de Shokugeki ! 🍳 Je suis le Chef IA. Quel plat puis-je vous conseiller ou quelle création voulez-vous adapter à vos goûts ce soir ?"
    }
  ];
  bool _isLoading = false;
  late GenerativeModel _model;

  @override
  void initState() {
    super.initState();
    // Utilisation du modèle 1.5 flash ultra rapide
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: geminiApiKey,
    );
  }

  void _envoyerMessage() async {
    String messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "message": messageText});
      _isLoading = true;
    });
    _messageController.clear();

    try {
      final content = [Content.text(messageText)];
      final response = await _model.generateContent(content);
      
      setState(() {
        _isLoading = false;
        _messages.add({
          "role": "assistant",
          "message": response.text ?? "Désolé, je n'ai pas pu générer de suggestion culinaire."
        });
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _messages.add({
          "role": "assistant",
          "message": "Erreur lors de la communication avec les cuisines de Gemini. ❌"
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111115),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A22),
        elevation: 0,
        title: const Text(
          "CHEF IA CULINAIRE",
          style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold, letterSpacing: 1.2),
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
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser ? kPrimaryColor : const Color(0xFF22222B),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 0),
                        bottomRight: Radius.circular(isUser ? 0 : 16),
                      ),
                    ),
                    child: Text(
                      msg["message"]!,
                      style: TextStyle(
                        color: isUser ? Colors.black : Colors.white, 
                        fontSize: 14, 
                        fontWeight: isUser ? FontWeight.bold : FontWeight.normal, // CORRIGÉ ET STABILISÉ ICI
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
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
                    decoration: const InputDecoration(
                      hintText: "Posez votre question culinaire au Chef...",
                      hintStyle: TextStyle(color: Colors.grey),
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