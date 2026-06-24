import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'app_config.dart';
import 'constants.dart';

// ═══════════════════════════════════════════════════════
//  CHEF IA CLIENT — Chat avec l'IA sur le menu
//  ✅ Le client peut demander des recommandations
//  ✅ L'IA connaît le menu du restaurant
//  ✅ Design anime premium
// ═══════════════════════════════════════════════════════

const String _geminiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

class ChefIaClientScreen extends StatefulWidget {
  const ChefIaClientScreen({super.key});
  @override
  State<ChefIaClientScreen> createState() => _ChefIaClientScreenState();
}

class _ChefIaClientScreenState extends State<ChefIaClientScreen>
    with SingleTickerProviderStateMixin {
  final _chatCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _loading = false;
  bool _menuCharge = false;
  String _menuContext = '';
  late AnimationController _pulseCtrl;

  final List<String> _suggestions = [
    '🍔 Recommande-moi un burger',
    '🌶️ C\'est quoi le plat le plus épicé ?',
    '💰 Meilleur rapport qualité/prix ?',
    '🥗 Options végétariennes ?',
    '🎉 Plat spécial pour une occasion ?',
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _chargerMenu();
  }

  @override
  void dispose() {
    _chatCtrl.dispose();
    _scrollCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerMenu() async {
    try {
      final snap = await FirebaseFirestore.instance.collection(AppConfig.menu).get();
      final plats = snap.docs.map((d) {
        final data = d.data();
        return '${data['nom']} (${data['prix']} MRU) — ${data['categorie']}';
      }).join('\n');
      setState(() {
        _menuContext = plats;
        _menuCharge = true;
      });
      _ajouterMessageIA('Salut ! 👋 Je suis le Chef IA de $kAppName.\nJe connais tout notre menu — dis-moi ce dont tu as envie et je te recommande le meilleur plat ! 🍜');
    } catch (e) {
      setState(() => _menuCharge = true);
      _ajouterMessageIA('Bonjour ! Je suis le Chef IA. Comment puis-je vous aider aujourd\'hui ? 😊');
    }
  }

  void _ajouterMessageIA(String texte) {
    setState(() => _messages.add({'role': 'assistant', 'content': texte}));
    _scrollBas();
  }

  Future<void> _envoyer([String? texteForce]) async {
    final texte = texteForce ?? _chatCtrl.text.trim();
    if (texte.isEmpty || _loading) return;
    _chatCtrl.clear();

    setState(() {
      _messages.add({'role': 'user', 'content': texte});
      _loading = true;
    });
    _scrollBas();

    if (_geminiKey.isEmpty) {
      await Future.delayed(const Duration(seconds: 1));
      _ajouterMessageIA('⚠️ Clé Gemini non configurée. Ajoute GEMINI_API_KEY dans les variables Codemagic.');
      setState(() => _loading = false);
      return;
    }

    try {
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _geminiKey);
      final systemPrompt = '''Tu es le Chef IA de $kAppName, un assistant culinaire sympathique et passionné.
Tu connais parfaitement notre menu :

$_menuContext

Réponds en français, de façon chaleureuse et courte (max 3 phrases).
Tu peux utiliser des emojis. Si on te demande un plat hors menu, propose une alternative du menu.
Ne mentionne jamais les prix sauf si on te le demande.''';

      final history = _messages.take(_messages.length - 1).map((m) {
        if (m['role'] == 'user') return Content.text(m['content']!);
        return Content.model([TextPart(m['content']!)]);
      }).toList();

      final chat = model.startChat(history: [
        Content.text(systemPrompt),
        ...history,
      ]);

      final response = await chat.sendMessage(Content.text(texte));
      _ajouterMessageIA(response.text ?? 'Désolé, je n\'ai pas compris. Répète ta question !');
    } catch (e) {
      _ajouterMessageIA('Oups ! Une erreur s\'est produite. Réessaie ! 😅');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollBas() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050008),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D001A),
        elevation: 0,
        title: Row(children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                color: Colors.purple,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                  color: Colors.purple.withOpacity(_pulseCtrl.value),
                  blurRadius: 8, spreadRadius: 2,
                )],
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Chef IA', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Toujours disponible pour vous', style: TextStyle(color: Colors.purple, fontSize: 11)),
          ]),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.purple),
            onPressed: () {
              setState(() => _messages.clear());
              _chargerMenu();
            },
          ),
        ],
      ),
      body: Column(children: [
        // Messages
        Expanded(
          child: !_menuCharge
              ? const Center(child: CircularProgressIndicator(color: Colors.purple))
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  itemCount: _messages.length + (_loading ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == _messages.length) return const _TypingBubble();
                    final msg = _messages[i];
                    final isUser = msg['role'] == 'user';
                    return _MessageBubble(texte: msg['content'] ?? '', isUser: isUser);
                  },
                ),
        ),

        // Suggestions rapides
        if (_messages.length <= 1 && !_loading)
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _suggestions.length,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => _envoyer(_suggestions[i].replaceAll(RegExp(r'^[^\w]+'), '')),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.purple.withOpacity(0.3)),
                  ),
                  child: Text(_suggestions[i], style: const TextStyle(color: Colors.purple, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),

        // Champ de saisie
        Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
          color: const Color(0xFF0D001A),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _chatCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _envoyer(),
                decoration: InputDecoration(
                  hintText: 'Demandez une recommandation...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.purple.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.purple.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Colors.purple),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _loading ? null : () => _envoyer(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48, height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF7B2FBE), Color(0xFF4A00E0)]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.4), blurRadius: 12)],
                ),
                child: _loading
                    ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String texte;
  final bool isUser;
  const _MessageBubble({required this.texte, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => Clipboard.setData(ClipboardData(text: texte)),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: isUser
                ? const LinearGradient(colors: [Color(0xFF7B2FBE), Color(0xFF4A00E0)])
                : null,
            color: isUser ? null : Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isUser ? 18 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 18),
            ),
            border: isUser ? null : Border.all(color: Colors.purple.withOpacity(0.2)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (!isUser)
              const Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Row(children: [
                  Text('👩‍🍳', style: TextStyle(fontSize: 14)),
                  SizedBox(width: 4),
                  Text('Chef IA', style: TextStyle(color: Colors.purple, fontSize: 11, fontWeight: FontWeight.bold)),
                ]),
              ),
            Text(texte, style: TextStyle(
              color: isUser ? Colors.white : Colors.white70,
              fontSize: 14, height: 1.5,
            )),
          ]),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.purple.withOpacity(0.2)),
      ),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Text('👩‍🍳', style: TextStyle(fontSize: 14)),
        SizedBox(width: 10),
        SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.purple, strokeWidth: 2)),
        SizedBox(width: 8),
        Text('Chef IA réfléchit...', style: TextStyle(color: Colors.purple, fontSize: 12)),
      ]),
    ),
  );
}
