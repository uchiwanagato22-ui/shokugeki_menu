import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'premium_staff_widgets.dart';
import 'widgets/developer_contact_button.dart';
import 'login_screen.dart';
import 'app_config.dart';
import 'constants.dart';

class CuisineScreen extends StatefulWidget {
  const CuisineScreen({super.key});
  @override
  State<CuisineScreen> createState() => _CuisineScreenState();
}

class _CuisineScreenState extends State<CuisineScreen> {
  final _db = FirebaseFirestore.instance;

  Future<void> _marquerPret(String docId) async {
    await _db.collection(AppConfig.commandes).doc(docId).update({
      'statut': 'pret',
      'kitchen_done_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    _snack('✅ Commande prête — livreur notifié !', Colors.green);
  }

  Future<void> _deconnecter() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14161D),
        title: const Text('Déconnexion', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Déconnecter', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('staff_role');
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
  }

  void _snack(String msg, Color color) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
  );

  @override
  Widget build(BuildContext context) {
    return StaffScaffold(
      title: 'Cuisine 🍳',
      subtitle: 'Préparez les plats et marquez-les prêts.',
      icon: Icons.restaurant,
      palette: StaffPalette.kitchen,
      actions: [
        IconButton(tooltip: 'Déconnexion', icon: const Icon(Icons.logout, color: Colors.redAccent), onPressed: _deconnecter),
      ],
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: _db.collection(AppConfig.commandes).where('statut', isEqualTo: 'en_cuisine').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs;

            return Column(children: [
              StaffMetricCard(
                label: 'Tickets en préparation',
                value: '${docs.length}',
                icon: Icons.soup_kitchen,
                palette: StaffPalette.kitchen,
              ),
              const SizedBox(height: 12),

              if (docs.isEmpty)
                const EmptyStaffState(icon: Icons.restaurant, title: 'Cuisine calme 😌', message: 'Aucun ticket pour le moment. Profitez du calme !')
              else ...[
                StaffSectionTitle(title: 'Tickets actifs', trailing: '${docs.length} en cours'),
                ...docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  return _KitchenTicket(docId: doc.id, data: d, onPret: () => _marquerPret(doc.id));
                }),
              ],
              const SizedBox(height: 16),
              const DeveloperContactButton(),
            ]);
          },
        ),
      ],
    );
  }
}

class _KitchenTicket extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final VoidCallback onPret;
  const _KitchenTicket({required this.docId, required this.data, required this.onPret});

  @override
  Widget build(BuildContext context) {
    final articles = data['articles'] as List? ?? [];
    final clientNom = data['clientNom']?.toString() ?? data['client_nom']?.toString() ?? 'Client';
    final modeCmd = data['mode_commande']?.toString() ?? 'livraison';
    final surPlace = modeCmd == 'sur_place';
    final note = data['note_client']?.toString() ?? '';
    final ref = docId.length > 6 ? docId.substring(0, 6).toUpperCase() : docId.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        // Header ticket
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.orange.shade600, Colors.deepOrange.shade500]),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(children: [
            const Icon(Icons.receipt_long, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Ticket #$ref', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.white)),
              Text(clientNom, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
              child: Text(surPlace ? '🪑 Sur place' : '🛵 Livraison',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ]),
        ),

        // Articles avec images — LE GROS UPGRADE
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('À PRÉPARER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
            const SizedBox(height: 10),

            ...articles.map((a) {
              final item = a is Map ? a : {};
              final nom = item['nom']?.toString() ?? 'Plat';
              final qte = (item['quantite'] as num?)?.toInt() ?? 1;
              final imgUrl = item['image']?.toString() ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade100),
                ),
                child: Row(children: [
                  // Image du plat
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imgUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imgUrl, width: 60, height: 60, fit: BoxFit.cover,
                            placeholder: (_, __) => Container(width: 60, height: 60, color: Colors.grey.shade200,
                                child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                            errorWidget: (_, __, ___) => _imgFallback(),
                          )
                        : _imgFallback(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(nom, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87))),
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: Colors.deepOrange, borderRadius: BorderRadius.circular(10)),
                    child: Center(child: Text('×$qte', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16))),
                  ),
                ]),
              );
            }),

            if (note.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber.shade200)),
                child: Row(children: [
                  const Icon(Icons.sticky_note_2, color: Colors.amber, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Note client : $note', style: const TextStyle(color: Colors.brown, fontSize: 13, fontStyle: FontStyle.italic))),
                ]),
              ),
              const SizedBox(height: 10),
            ],

            SizedBox(
              width: double.infinity, height: 52,
              child: FilledButton.icon(
                onPressed: onPret,
                icon: const Icon(Icons.check_circle_rounded, size: 24),
                label: const Text('MARQUER PRÊTE ✅', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5)),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _imgFallback() => Container(
    width: 60, height: 60,
    decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(8)),
    child: const Icon(Icons.fastfood, color: Colors.orange, size: 28),
  );
}
