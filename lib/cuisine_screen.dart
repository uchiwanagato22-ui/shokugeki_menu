import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'premium_staff_widgets.dart';
import 'widgets/developer_contact_button.dart';
import 'login_screen.dart';

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
      actions: [
        // 🎯 AJOUT : Bouton de déconnexion sécurisé
        IconButton(
          tooltip: 'Se déconnecter',
          icon: const Icon(Icons.logout, color: Colors.redAccent),
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            if (!mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          },
        ),
      ],
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: _db
              .collection('commandes')
              .where('statut', isEqualTo: 'en_cuisine')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const EmptyStaffState(
                icon: Icons.warning_amber_rounded,
                title: 'Erreur',
                message: 'Erreur de chargement des données de la cuisine.',
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const EmptyStaffState(
                icon: Icons.restaurant,
                title: 'Cuisine vide',
                message: 'Aucun plat à préparer pour le moment. Bon repos !',
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final commande = docs[index];
                final data = commande.data() as Map<String, dynamic>;
                final articles = (data['articles'] as List? ?? []);
                final note = data['note_client']?.toString() ?? '';

                // Restauration de ton sous-widget modulaire d'origine
                return _KitchenTicketCard(
                  commandeId: commande.id,
                  articles: articles,
                  note: note,
                  onReady: () => _marquerPret(commande.id),
                );
              },
            );
          },
        ),
        const SizedBox(height: 20),
        const Center(child: DeveloperContactButton()),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  WIDGET COMPOSANT : TICKET CUISINE (RESTAURÉ)
// ═══════════════════════════════════════════════════════════════
class _KitchenTicketCard extends StatelessWidget {
  final String commandeId;
  final List<dynamic> articles;
  final String note;
  final VoidCallback onReady;

  const _KitchenTicketCard({
    required this.commandeId,
    required this.articles,
    required this.note,
    required this.onReady,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(
              'Ticket #${commandeId.substring(0, 5).toUpperCase()}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const Divider(),
            ...articles.map((article) {
              final item = article is Map ? article : <String, dynamic>{};
              return Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.amber,
                      radius: 16,
                      child: Text(
                        'x${item['quantite'] ?? 1}',
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
    );
  }
}