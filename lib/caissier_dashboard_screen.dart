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

class CaissierDashboardScreen extends StatefulWidget {
  const CaissierDashboardScreen({super.key});
  @override
  State<CaissierDashboardScreen> createState() => _CaissierDashboardScreenState();
}

class _CaissierDashboardScreenState extends State<CaissierDashboardScreen> {
  final _db = FirebaseFirestore.instance;
  int _traitees = 0;

  Future<void> _valider(String docId) async {
    await _db.collection(AppConfig.commandes).doc(docId).update({
      'statut': 'en_cuisine',
      'validated_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
    setState(() => _traitees++);
    _snack('✅ Envoyée en cuisine !', Colors.green);
  }

  Future<void> _rejeter(String docId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14161D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Rejeter ?', style: TextStyle(color: Colors.white)),
        content: const Text('Confirmer le rejet de cette commande ?', style: TextStyle(color: Colors.white60)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _db.collection(AppConfig.commandes).doc(docId).update({
      'statut': 'rejete',
      'updated_at': FieldValue.serverTimestamp(),
    });
    _snack('Commande rejetée', Colors.orange);
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
      title: 'Caissier',
      subtitle: 'Valider et router les commandes clients.',
      icon: Icons.point_of_sale,
      palette: StaffPalette.cashier,
      actions: [
        IconButton(tooltip: 'Déconnexion', icon: const Icon(Icons.logout, color: Colors.redAccent), onPressed: _deconnecter),
      ],
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: _db.collection(AppConfig.commandes).where('statut', isEqualTo: 'en_attente').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs;

            return Column(children: [
              // Stats du shift
              Row(children: [
                Expanded(child: StaffMetricCard(label: 'En attente', value: '${docs.length}', icon: Icons.pending_actions, palette: StaffPalette.cashier)),
                const SizedBox(width: 10),
                Expanded(child: StaffMetricCard(label: 'Traitées (session)', value: '$_traitees', icon: Icons.check_circle, palette: StaffPalette.cashier)),
              ]),
              const SizedBox(height: 12),

              if (docs.isEmpty)
                const EmptyStaffState(icon: Icons.inbox_rounded, title: 'Aucune commande', message: 'Les nouvelles commandes apparaîtront ici en temps réel.')
              else ...[
                StaffSectionTitle(title: 'À valider', trailing: '${docs.length} commande(s)'),
                ...docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  return _CaissierCard(
                    docId: doc.id, data: d,
                    onValider: () => _valider(doc.id),
                    onRejeter: () => _rejeter(doc.id),
                  );
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

class _CaissierCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final VoidCallback onValider, onRejeter;
  const _CaissierCard({required this.docId, required this.data, required this.onValider, required this.onRejeter});

  @override
  Widget build(BuildContext context) {
    final nom = data['clientNom']?.toString() ?? data['client_nom']?.toString() ?? 'Client';
    final tel = data['clientTelephone']?.toString() ?? data['client_telephone']?.toString() ?? '';
    final adresse = data['adresse_reperes']?.toString() ?? '';
    final zone = data['zone']?.toString() ?? data['quartier']?.toString() ?? '';
    final total = (data['total'] as num?)?.toDouble() ?? 0;
    final frais = (data['fraisLivraison'] as num?)?.toDouble() ?? (data['frais_livraison'] as num?)?.toDouble() ?? 0;
    final paiement = data['mode_paiement']?.toString() ?? 'cash';
    final modeCmd = data['mode_commande']?.toString() ?? 'livraison';
    final articles = data['articles'] as List? ?? [];
    final surPlace = modeCmd == 'sur_place';
    final ref = docId.length > 6 ? docId.substring(0, 6).toUpperCase() : docId.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFD7F7)),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFFEFF6FF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(children: [
            const Icon(Icons.receipt_long, color: Color(0xFF2563EB)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Commande #$ref', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              Row(children: [
                _Badge(label: surPlace ? '🪑 Sur place' : '🛵 $zone', color: surPlace ? Colors.purple : Colors.blue),
                const SizedBox(width: 6),
                _Badge(label: _labelPaiement(paiement), color: _colorPaiement(paiement)),
              ]),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${total.toStringAsFixed(0)} MRU', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF2563EB))),
              if (frais > 0) Text('+${frais.toStringAsFixed(0)} livraison', style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ]),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Infos client
            _InfoLigne(Icons.person, nom),
            if (tel.isNotEmpty) _InfoLigne(Icons.phone, tel),
            if (!surPlace && adresse.isNotEmpty) _InfoLigne(Icons.location_on, adresse),
            const SizedBox(height: 10),

            // Articles avec images
            const Text('Articles', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 12)),
            const SizedBox(height: 6),
            ...articles.map((a) {
              final item = a is Map ? a : {};
              final imgUrl = item['image']?.toString() ?? '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: imgUrl.isNotEmpty
                        ? CachedNetworkImage(imageUrl: imgUrl, width: 36, height: 36, fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => _platIcon())
                        : _platIcon(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text('${item['quantite'] ?? 1}x ${item['nom'] ?? 'Plat'}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87))),
                  Text('${((item['prix'] as num?)?.toDouble() ?? 0) * ((item['quantite'] as num?)?.toInt() ?? 1)} MRU',
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ]),
              );
            }),

            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: onRejeter,
                icon: const Icon(Icons.cancel, color: Colors.redAccent, size: 18),
                label: const Text('Rejeter', style: TextStyle(color: Colors.redAccent)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
              )),
              const SizedBox(width: 10),
              Expanded(child: FilledButton.icon(
                onPressed: onValider,
                icon: const Icon(Icons.check_circle, size: 18),
                label: const Text('→ Cuisine'),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
              )),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _platIcon() => Container(width: 36, height: 36, color: Colors.grey.shade100,
      child: const Icon(Icons.fastfood, color: Colors.grey, size: 18));

  String _labelPaiement(String p) {
    switch (p) { case 'bankily': return 'Bankily 💚'; case 'masrivi': return 'Masrivi 💛'; default: return 'Cash 💵'; }
  }
  Color _colorPaiement(String p) {
    switch (p) { case 'bankily': return const Color(0xFF2E7D32); case 'masrivi': return const Color(0xFFB8860B); default: return Colors.grey; }
  }
}

class _InfoLigne extends StatelessWidget {
  final IconData icon; final String text;
  const _InfoLigne(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(children: [
      Icon(icon, size: 15, color: const Color(0xFF2563EB)),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500))),
    ]),
  );
}

class _Badge extends StatelessWidget {
  final String label; final Color color;
  const _Badge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.3))),
    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
  );
}
