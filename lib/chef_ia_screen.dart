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
        'role': 'assistant',
        'message':
            'Bienvenue dans les cuisines de ${brand.nom} ! 🍳 Je suis le Chef suprême IA. Donne-moi ton budget en MRU ou tes envies, et je te compose un festin inégalable !',
      },
    ];
    _chargerMenuDepuisFirestore();
  }

  void _chargerMenuDepuisFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('menu').get();
      setState(() {
        _vraisPlats = snapshot.docs.map((doc) {
          final data = doc.data();
          return {...data, 'id': doc.id};
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
      _uiMessages.add({'role': 'user', 'message': texte});
      _isLoading = true;
    });
    _scrollToBottom();

    final contexteMenu = _vraisPlats.isNotEmpty
        ? _vraisPlats
            .map((p) =>
                '- ${p['nom']} : ${(p['prix'] as num?)?.toDouble() ?? 0.0} MRU (${p['description'] ?? 'Pas de description'})')
            .join('\n')
        : 'Aucun plat disponible pour le moment.';

    final brand = BrandingData.defaults();

    final superPrompt = superPrompt = 'Tu es le Chef Suprême IA de "${brand.nom}" à "${brand.ville}". Ton style est passionné, charismatique et ultra-professionnel (comme un chef de Shonen culinaire).\n\nTu t\'adresses à un client mauritanien. Tu dois obligatoirement utiliser la monnaie \'MRU\'.\n\nVoici la liste REELLE et STRICTE des plats disponibles dans nos cuisines actuellement :\n\n$contexteMenu\n\nRègles absolues que tu dois respecter :\n1. Si le client mentionne un budget (ex: 500 MRU), propose-lui une combinaison de plats de notre liste qui ne dépasse pas cette somme.\n2. Ne mentionne et ne conseille JAMAIS un plat qui n\'est pas explicitement écrit dans la liste ci-dessus.\n3. Sois concis, dynamique, donne envie et ajoute quelques emojis stylés.\n\nMessage du client : "$texte"';

    try {
      final reponseIA = await _geminiService.generateChatResponse(superPrompt);
      setState(() {
        _uiMessages.add({'role': 'assistant', 'message': reponseIA});
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _uiMessages.add({
          'role': 'assistant',
          'message': 'Désolé, mes brûleurs ont eu un raté. Réessaye pour voir ! 🔥'
        });
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'CHEF IA EXPERT',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
        ),
        backgroundColor: kSurfaceColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: kAccentColor),
            onPressed: () {
              setState(() {
                _uiMessages = [
                  {
                    'role': 'assistant',
                    'message': 'C'est reparti pour un nouveau round ! Des envies particulières ? 🍳'
                  }
                ];
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _uiMessages.length,
              itemBuilder: (context, index) {
                final msg = _uiMessages[index];
                final isUser = msg['role'] == 'user';

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? kPrimaryColor : kSurfaceColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 0),
                        bottomRight: Radius.circular(isUser ? 0 : 16),
                      ),
                      border: !isUser
                          ? Border.all(
                              color: kPrimaryColor.withOpacity(0.45),
                              width: 1.2,
                            )
                          : null,
                      boxShadow: !isUser
                          ? [
                              BoxShadow(
                                color: kPrimaryColor.withOpacity(0.18),
                                blurRadius: 18,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      msg['message'] ?? '',
                      style: TextStyle(
                        color: isUser
                            ? Colors.white
                            : Colors.white.withOpacity(0.92),
                        fontSize: 14.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 12.0),
              child: Center(
                child: CircularProgressIndicator(color: kPrimaryColor),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: kSurfaceColor,
              border: Border(
                top: BorderSide(color: Color(0xFF1E1E24), width: 1),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: kBackgroundColor,
                        borderRadius: BorderRadius.circular(24),
                      ),
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

