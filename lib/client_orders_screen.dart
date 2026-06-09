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
          title: const Text("Noter votre commande"),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              return IconButton(
                icon: Icon(i < note ? Icons.star : Icons.star_border, color: kAccentColor, size: 32),
                onPressed: () => setDialog(() => note = i + 1),
              );
            }),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Plus tard")),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _noterCommande(docId, note);
              },
              child: const Text("Envoyer"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(title: const Text("MES COMMANDES"), backgroundColor: Colors.white),
        body: const Center(child: Text("Connectez-vous pour voir vos commandes.")),
      );
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text("MES COMMANDES", style: TextStyle(color: kSecondaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('commandes')
            .where('client_uid', isEqualTo: _uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
          }

          final docs = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final ta = (a.data() as Map)['date_commande'];
              final tb = (b.data() as Map)['date_commande'];
              if (ta == null || tb == null) return 0;
              return (tb as Timestamp).compareTo(ta as Timestamp);
            });
          if (docs.isEmpty) {
            return const Center(child: Text("Vous n'avez pas encore passé de commande. 🍔"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final statut = data['statut'] ?? 'En attente';
              final cmdId = doc.id.substring(0, 5).toUpperCase();
              final note = data['note'];

              if (statut == 'Livré' && note == null && !_notationsDemandees.contains(doc.id)) {
                _notationsDemandees.add(doc.id);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _afficherNotation(doc.id);
                });
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Commande #$cmdId", style: const TextStyle(fontWeight: FontWeight.bold, color: kSecondaryColor)),
                        Text("${data['total']} MRU", style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text("Plats : ${data['plats']}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStep(label: "Reçue", active: true, color: Colors.green),
                        _buildLine(active: statut != 'En attente de validation' && !statut.contains('Rejeté')),
                        _buildStep(
                          label: "Cuisine",
                          active: statut == 'En cuisine' || statut == 'En cours de livraison' || statut == 'Livré',
                          color: Colors.orange,
                        ),
                        _buildLine(active: statut == 'En cours de livraison' || statut == 'Livré'),
                        _buildStep(
                          label: "Livraison",
                          active: statut == 'En cours de livraison' || statut == 'Livré',
                          color: Colors.blue,
                        ),
                        _buildLine(active: statut == 'Livré'),
                        _buildStep(label: "Livré", active: statut == 'Livré', color: kPrimaryColor),
                      ],
                    ),
                    if (statut.contains('Rejeté')) ...[
                      const SizedBox(height: 10),
                      const Text("⚠️ Commande rejetée : vérifiez votre paiement.",
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                    if (note != null) ...[
                      const SizedBox(height: 8),
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
        Text(label, style: TextStyle(fontSize: 9, color: active ? Colors.black : Colors.grey, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _buildLine({required bool active}) {
    return Expanded(child: Container(height: 2, color: active ? Colors.green : Colors.grey.withValues(alpha: 0.3)));
  }
}
