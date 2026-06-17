import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'premium_staff_widgets.dart';
import 'widgets/developer_contact_button.dart';

class CuisineScreen extends StatefulWidget {
  const CuisineScreen({super.key});

  @override
  State<CuisineScreen> createState() => _CuisineScreenState();
}

class _CuisineScreenState extends State<CuisineScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> _marquerPret(String docId) async {
    await _db.collection('commandes').doc(docId).update({
      'statut': 'pret',
      'kitchen_done_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Commande marquee prete.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StaffScaffold(
      title: 'Cuisine',
      subtitle: 'Tickets de preparation clairs, priorite aux commandes les plus anciennes.',
      icon: Icons.restaurant,
      palette: StaffPalette.kitchen,
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: _db
              .collection('commandes')
              .where('statut', isEqualTo: 'en_cuisine')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return EmptyStaffState(
                icon: Icons.warning_amber,
                title: 'Erreur cuisine',
                message: snapshot.error.toString(),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return const EmptyStaffState(
                icon: Icons.local_dining,
                title: 'Aucune commande en preparation',
                message: 'Les prochains tickets envoyes par la caisse arriveront ici.',
              );
            }

            return Column(
              children: [
                StaffMetricCard(
                  label: 'Tickets actifs',
                  value: docs.length.toString(),
                  icon: Icons.kitchen,
                  palette: StaffPalette.kitchen,
                ),
                StaffSectionTitle(
                  title: 'A preparer maintenant',
                  trailing: '${docs.length} ticket(s)',
                ),
                ...docs.map((doc) {
                  final commande = doc.data() as Map<String, dynamic>;
                  return _KitchenTicket(
                    commande: commande,
                    onReady: () => _marquerPret(doc.id),
                  );
                }),
                const SizedBox(height: 12),
                const DeveloperContactButton(),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _KitchenTicket extends StatelessWidget {
  const _KitchenTicket({
    required this.commande,
    required this.onReady,
  });

  final Map<String, dynamic> commande;
  final VoidCallback onReady;

  @override
  Widget build(BuildContext context) {
    final articles = readArticles(commande);
    final note = readText(commande, 'note_client');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF1D7AF)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF7ED),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer, color: Color(0xFFD97706)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    readText(commande, 'client_nom', 'Client'),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  "${readMoney(commande['total']).toStringAsFixed(0)} MRU",
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                ...articles.map((article) {
                  final item = article is Map ? article : <String, dynamic>{};
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 34,
                          width: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD97706),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${item['quantite'] ?? 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item['nom']?.toString() ?? 'Plat',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Note client : $note',
                      style: const TextStyle(color: Color(0xFF92400E)),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: onReady,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Commande prete'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
