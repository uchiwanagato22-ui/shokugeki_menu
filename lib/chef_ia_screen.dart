import 'app_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'branding_service.dart';
import 'chef_ia_client_screen.dart';
import 'constants.dart';
import 'gemini_service.dart';
import 'widgets/developer_contact_button.dart';

class ChefIaScreen extends StatefulWidget {
  const ChefIaScreen({super.key});

  @override
  State<ChefIaScreen> createState() => _ChefIaScreenState();
}

class _ChefIaScreenState extends State<ChefIaScreen> {
  final TextEditingController _messageController = TextEditingController();
  final GeminiService _geminiService = GeminiService();
  final ScrollController _scrollController = ScrollController();

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
            "Bienvenue dans les cuisines de ${brand.nom} ! 🍳 Je suis le Chef suprême IA. Donne-moi ton budget en MRU ou tes envies, et je te compose un festin inégalable !"
      }
    ];
    _chargerMenuDepuisFirestore();
  }

  void _chargerMenuDepuisFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection(AppConfig.menu).get();
      setState(() {
        _vraisPlats = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e) {
      debugPrint("Erreur chargement menu Chef IA: $e");
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _envoyerMessage() async {
    final texte = _messageController.text.trim();
    if (texte.isEmpty || _isLoading) return;

    _messageController.clear();
    setState(() {
      _uiMessages.add({"role": "user", "message": texte});
      _isLoading = true;
    });
    _scrollToBottom();

    String contexteMenu = _vraisPlats.isNotEmpty
        ? _vraisPlats.map((p) => "- ${p['nom']} : ${p['prix']} MRU (${p['description'] ?? ''})").join("\n")
        : "Aucun plat disponible.";

    final brand = BrandingData.defaults();
    final superPrompt = """
Tu es le Chef Suprême IA de '${brand.nom}' à Nouakchott. Ton style est passionné, charismatique et ultra-professionnel. Tu t'adresses à un client mauritanien. Tu doit obligatoirement utiliser la monnaie 'MRU'.
Voici la liste REELLE des plats disponibles :
$contexteMenu

Règles :
1. Propose des combinaisons adaptées au budget en MRU donné.
2. Ne conseille JAMAIS un plat absent de la liste.
3. Sois dynamique et concis.
Client dit : $texte
""";

    try {
      // CORRECTION ICI : Appel de la bonne méthode présente dans gemini_service.dart
      final reponseIA = await _geminiService.generateChatResponse(superPrompt);
      setState(() {
        _uiMessages.add({"role": "assistant", "message": reponseIA});
      });
    } catch (e) {
      setState(() {
        _uiMessages.add({"role": "assistant", "message": "Désolé, mes fourneaux ont eu un problème technique. Réessaie !"});
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text("Le Chef Suprême IA 🍳", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kSurfaceColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.purpleAccent),
            tooltip: 'Chat recommandations',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChefIaClientScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChefIaClientScreen()),
                ),
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.purple.withOpacity(0.25),
                        Colors.deepPurple.withOpacity(0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.purple.withOpacity(0.4)),
                  ),
                  child: const Row(
                    children: [
                      Text('👩‍🍳', style: TextStyle(fontSize: 22)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Chat recommandations',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Suggestions rapides sur le menu',
                              style: TextStyle(color: Colors.purpleAccent, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: Colors.purpleAccent, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _uiMessages.length,
              itemBuilder: (context, index) {
                final m = _uiMessages[index];
                final isUser = m["role"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser ? kPrimaryColor : kSurfaceColor,
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(0),
                        bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
                      ),
                    ),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    child: Text(
                      m["message"] ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.3),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
            ),
          Container(
            color: kSurfaceColor,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(color: kBackgroundColor, borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "Ex: J'ai 600 MRU, tu me proposes quoi ?",
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _envoyerMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: kPrimaryColor,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 18),
                      onPressed: _envoyerMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}