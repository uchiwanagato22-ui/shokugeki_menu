import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'constants.dart';

class ClientOrdersScreen extends StatefulWidget {
  const ClientOrdersScreen({super.key});

  @override
  State<ClientOrdersScreen> createState() => _ClientOrdersScreenState();
}

class _ClientOrdersScreenState extends State<ClientOrdersScreen> {
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  final Set<String> _notationsDemandees = {};

  Future<void> _noterCommande(String docId, int note) async {
    await FirebaseFirestore.instance.collection('commandes').doc(docId).update({'note': note});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Merci pour votre note ! ⭐"), backgroundColor: Colors.green),
      );
    }
  }

  void _afficherNotation(String docId) {
    int note = 5;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          backgroundColor: kSurfaceColor,
          title: const Text("Noter votre commande", style: TextStyle(color: Colors.white)),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              return IconButton(
                icon: Icon(i < note ? Icons.star : Icons.star_border, color: kAccentColor),
                onPressed: () => setDialog(() => note = i + 1),
              );
            }),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Annuler", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
              onPressed: () {
                _noterCommande(docId, note);
                Navigator.pop(ctx);
              },
              child: const Text("Valider", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return const Scaffold(
        backgroundColor: kBackgroundColor,
        body: Center(child: Text("Veuillez vous connecter pour voir vos commandes.", style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text("Vos Commandes", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('commandes')
            .where('clientId', isEqualTo: _uid)
            .orderBy('date_creation', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Erreur de chargement des données", style: TextStyle(color: Colors.red)));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text("Vous n'avez pas encore passé de commande.", style: TextStyle(color: Colors.grey)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              String statut = data['statut'] ?? 'en_attente';
              var note = data['note'];
              double total = (data['total'] ?? 0.0) as double;

              if (statut == 'livree' && note == null && !_notationsDemandees.contains(doc.id)) {
                _notationsDemandees.add(doc.id);
                WidgetsBinding.instance.addPostFrameCallback((_) => _afficherNotation(doc.id));
              }

              bool step1 = true;
              bool step2 = statut == 'en_preparation' || statut == 'en_livraison' || statut == 'livree';
              bool step3 = statut == 'en_livraison' || statut == 'livree';
              bool step4 = statut == 'livree';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: kSurfaceColor, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Commande #${doc.id.substring(0, 5)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        Text("$total MRU", style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStep(label: "Reçue", active: step1, color: Colors.blue),
                        _buildLine(active: step2),
                        _buildStep(label: "Cuisine", active: step2, color: Colors.orange),
                        _buildLine(active: step3),
                        _buildStep(label: "Livraison", active: step3, color: Colors.purple),
                        _buildLine(active: step4),
                        _buildStep(label: "Livrée", active: step4, color: Colors.green),
                      ],
                    ),
                    if (statut == 'livree' && note == null) ...[
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => _ouvrirNotation(doc.id),
                        child: const Text("Toucher ici pour laisser une note ⭐", 
                            style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                    if (note != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text("Votre note : ", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ...List.generate(5, (i) => Icon(
                                i < (note as int) ? Icons.star : Icons.star_border,
                                color: kAccentColor,
                                size: 16,
                              )),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStep({required String label, required bool active, required Color color}) {
    return Column(
      children: [
        Icon(active ? Icons.check_circle : Icons.radio_button_unchecked, color: active ? color : Colors.grey, size: 20),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: active ? Colors.white : Colors.grey, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _buildLine({required bool active}) {
    return Expanded(child: Container(height: 2, color: active ? kPrimaryColor : Colors.grey.withOpacity(0.3)));
  }
}