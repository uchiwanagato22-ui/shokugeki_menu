import 'package:flutter/material.dart';
import 'constants.dart';
import 'director_ia_service.dart';

class DirectorDashboardScreen extends StatefulWidget {
  const DirectorDashboardScreen({super.key});

  @override
  State<DirectorDashboardScreen> createState() => _DirectorDashboardScreenState();
}

class _DirectorDashboardScreenState extends State<DirectorDashboardScreen> {
  final DirectorIaService _iaService = DirectorIaService();
  final TextEditingController _controller = TextEditingController();
  
  final List<Map<String, String>> _iaMessages = [
    {
      "role": "assistant",
      "message": "Bonjour Directeur Nagato. 👑 Je suis votre assistant de gestion Shokugeki. Demandez-moi combien on a gagné ou un résumé complet de la boutique !"
    }
  ];
  bool _isLoading = false;

  void _poserQuestionALia() async {
    if (_controller.text.trim().isEmpty) return;

    String question = _controller.text.trim();
    setState(() {
      _iaMessages.add({"role": "user", "message": question});
      _controller.clear();
      _isLoading = true;
    });

    String reponse = await _iaService.repondreAuDirecteur(question);

    setState(() {
      _iaMessages.add({"role": "assistant", "message": reponse});
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), 
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 4,
        title: const Text(
          "BUREAU DU DIRECTEUR",
          style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.white, size: 30),
                SizedBox(width: 12),
                Text("Rapports & Audit IA", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _iaMessages.length,
                        itemBuilder: (context, index) {
                          final msg = _iaMessages[index];
                          bool isUser = msg["role"] == "user";

                          return Align(
                            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isUser ? kPrimaryColor : const Color(0xFF334155),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                              child: Text(
                                msg["message"]!,
                                style: TextStyle(
                                  color: isUser ? Colors.black : Colors.white,
                                  fontWeight: isUser ? FontWeight.bold : FontWeight.normal,
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
                        child: CircularProgressIndicator(color: kPrimaryColor),
                      ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(color: Color(0xFF0F172A), borderRadius: BorderRadius.vertical(bottom: Radius.circular(16))),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: "Ex: Combien on a gagné aujourd'hui ?",
                                hintStyle: TextStyle(color: Colors.grey),
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => _poserQuestionALia(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.bolt, color: kPrimaryColor, size: 28),
                            onPressed: _poserQuestionALia,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}