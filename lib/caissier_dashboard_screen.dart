import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'premium_staff_widgets.dart';
import 'widgets/developer_contact_button.dart';
import 'login_screen.dart';

class CaissierDashboardScreen extends StatefulWidget {
  const CaissierDashboardScreen({super.key});

  @override
  State<CaissierDashboardScreen> createState() => _CaissierDashboardScreenState();
}

class _CaissierDashboardScreenState extends State<CaissierDashboardScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> _modifierStatut(String docId, String nouveauStatut) async {
    await _db.collection('commandes').doc(docId).update({
      'statut': nouveauStatut,
      'updated_at': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Commande mise a jour : $nouveauStatut')),
    );
  }

  String readText(DocumentSnapshot doc, String key) {
    final data = doc.data() as Map<String, dynamic>?;
    return data?[key]?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return StaffScaffold(
      title: 'Caisse',
      subtitle: 'Validez les commandes client, controlez les paiements et envoyez en cuisine.',
      icon: Icons.point_of_sale,
      palette: StaffPalette.cashier,
      actions: [
        IconButton(
          tooltip: 'Actualiser',
          onPressed: () => setState(() {}),
          icon: const Icon(Icons.refresh),
        ),
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
              .where('statut', isEqualTo: 'en_attente')
              .orderBy('date_creation', descending: false)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Erreur de chargement des données.'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const EmptyStaffState(
                icon: Icons.check_circle_outline,
                title: 'Aucune commande',
                message: 'Toutes les commandes en attente ont été traitées !',
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
                final total = (data['total'] ?? 0.0) as num;

                // Restauration de ton sous-widget modulaire d'origine
                return _CommandeCard(
                  commande: commande,
                  articles: articles,
                  total: total,
                  readText: readText,
                  onReject: () => _modifierStatut(commande.id, 'rejete'),
                  onSendKitchen: () => _modifierStatut(commande.id, 'en_cuisine'),
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
//  WIDGET COMPOSANT : CARTE COMMANDE (RESTAURÉ)
// ═══════════════════════════════════════════════════════════════
class _CommandeCard extends StatelessWidget {
  final DocumentSnapshot commande;
  final List<dynamic> articles;
  final num total;
  final String Function(DocumentSnapshot, String) readText;
  final VoidCallback onReject;
  final VoidCallback onSendKitchen;

  const _CommandeCard({
    required this.commande,
    required this.articles,
    required this.total,
    required this.readText,
    required this.onReject,
    required this.onSendKitchen,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Commande #${commande.id.substring(0, 5).toUpperCase()}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (readText(commande, 'reperes_adresse').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                readText(commande, 'reperes_adresse'),
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
            ],
            const Divider(height: 22),
            ...articles.map((article) {
              final item = article is Map ? article : <String, dynamic>{};
              return Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  children: [
                    Expanded(child: Text(item['nom']?.toString() ?? 'Plat')),
                    Text('x${item['quantite'] ?? 1}'),
                  ],
                ),
              );
            }),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${total.toStringAsFixed(0)} MRU',
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close),
                  label: const Text('Rejeter'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: onSendKitchen,
                  icon: const Icon(Icons.soup_kitchen),
                  label: const Text('Cuisine'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}