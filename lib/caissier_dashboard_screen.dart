import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'premium_staff_widgets.dart';
import 'widgets/developer_contact_button.dart';

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
      ],
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: _db
              .collection('commandes')
              .where('statut', isEqualTo: 'en_attente')
              .orderBy('date_commande', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return EmptyStaffState(
                icon: Icons.warning_amber,
                title: 'Erreur de chargement',
                message: snapshot.error.toString(),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return const EmptyStaffState(
                icon: Icons.receipt_long,
                title: 'Aucune commande en attente',
                message: 'La caisse est calme. Les nouvelles commandes arriveront ici.',
              );
            }

            final total = docs.fold<double>(0, (sum, doc) {
              final data = doc.data() as Map<String, dynamic>;
              return sum + readMoney(data['total']);
            });

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: StaffMetricCard(
                        label: 'A valider',
                        value: docs.length.toString(),
                        icon: Icons.pending_actions,
                        palette: StaffPalette.cashier,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StaffMetricCard(
                        label: 'Valeur',
                        value: '${total.toStringAsFixed(0)} MRU',
                        icon: Icons.payments,
                        palette: StaffPalette.cashier,
                      ),
                    ),
                  ],
                ),
                StaffSectionTitle(
                  title: 'Commandes en attente',
                  trailing: '${docs.length} ticket(s)',
                ),
                ...docs.map((doc) {
                  final commande = doc.data() as Map<String, dynamic>;
                  return _CashierOrderCard(
                    commande: commande,
                    onReject: () => _modifierStatut(doc.id, 'rejete'),
                    onSendKitchen: () => _modifierStatut(doc.id, 'en_cuisine'),
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

class _CashierOrderCard extends StatelessWidget {
  const _CashierOrderCard({
    required this.commande,
    required this.onReject,
    required this.onSendKitchen,
  });

  final Map<String, dynamic> commande;
  final VoidCallback onReject;
  final VoidCallback onSendKitchen;

  @override
  Widget build(BuildContext context) {
    final articles = readArticles(commande);
    final total = readMoney(commande['total']);
    final paiement = readText(commande, 'mode_paiement', 'Paiement non precise');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  readText(commande, 'client_nom', 'Client'),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: paiement.toLowerCase().contains('livraison')
                      ? const Color(0xFFFFF7ED)
                      : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  paiement,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${readText(commande, 'quartier', 'Quartier non precise')} - ${readText(commande, 'client_telephone', 'Telephone absent')}',
            style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600),
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
    );
  }
}
