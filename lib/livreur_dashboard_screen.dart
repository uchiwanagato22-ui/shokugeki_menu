import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'premium_staff_widgets.dart';
import 'widgets/developer_contact_button.dart';
import 'app_config.dart';
import 'constants.dart';
import 'login_screen.dart';

class LivreurDashboardScreen extends StatefulWidget {
  const LivreurDashboardScreen({super.key});
  @override
  State<LivreurDashboardScreen> createState() => _LivreurDashboardScreenState();
}

class _LivreurDashboardScreenState extends State<LivreurDashboardScreen> {
  final _db = FirebaseFirestore.instance;
  int _livreesSession = 0;

  Future<void> _appeler(String tel) async {
    if (tel.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: tel.replaceAll(' ', ''));
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _snack("❌ Impossible de lancer l'appel", Colors.red);
      }
    } catch (e) {
      _snack("❌ Erreur lors de l'appel : $e", Colors.red);
    }
  }

  Future<void> _ouvrirMaps(Map<String, dynamic> data) async {
    final lat = (data['latitude'] as num?)?.toDouble() ?? 0.0;
    final lng = (data['longitude'] as num?)?.toDouble() ?? 0.0;
    final zone = data['zone']?.toString() ?? data['quartier']?.toString() ?? '';
    final reperes = data['adresse_reperes']?.toString() ?? '';

    // ✅ URLs officielles et standardisées pour ouvrir directement l'application Google Maps
    final Uri uri = (lat != 0.0 && lng != 0.0)
        ? Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng')
        : Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent("$zone $reperes Nouakchott")}');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _snack('❌ Impossible d\'ouvrir Google Maps', Colors.red);
      }
    } catch (e) {
      _snack('❌ Erreur de navigation : $e', Colors.red);
    }
  }

  Future<void> _marquerEnRoute(String docId) async {
    try {
      await _db.collection(AppConfig.commandes).doc(docId).update({
        'statut': 'en_livraison',
        'pickup_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      _snack('🛵 En route ! Bonne course !', Colors.teal);
    } catch (e) {
      _snack('❌ Erreur de mise à jour : $e', Colors.red);
    }
  }

  Future<void> _marquerLivree(String docId) async {
    try {
      await _db.collection(AppConfig.commandes).doc(docId).update({
        'statut': 'livree',
        'delivered_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      setState(() => _livreesSession++);
      _snack('🎉 Livrée ! Bravo !', Colors.green);
    } catch (e) {
      _snack('❌ Erreur de validation : $e', Colors.red);
    }
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
      title: 'Livreur 🛵',
      subtitle: 'Gérez vos livraisons en temps réel.',
      icon: Icons.delivery_dining,
      palette: StaffPalette.delivery,
      actions: [
        IconButton(tooltip: 'Déconnexion', icon: const Icon(Icons.logout, color: Colors.redAccent), onPressed: _deconnecter),
      ],
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: _db.collection(AppConfig.commandes)
              .where('statut', whereIn: ['pret', 'pret_pour_livraison', 'en_livraison'])
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Erreur Firebase Livreur : ${snapshot.error}',
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;

            // Séparer prêtes et en route
            final pretes = docs.where((d) {
              final s = (d.data() as Map)['statut']?.toString() ?? '';
              return s == 'pret' || s == 'pret_pour_livraison';
            }).toList();
            final enRoute = docs.where((d) => (d.data() as Map)['statut']?.toString() == 'en_livraison').toList();

            return Column(children: [
              // Métriques
              Row(children: [
                Expanded(child: StaffMetricCard(label: 'À récupérer', value: '${pretes.length}', icon: Icons.inventory_2, palette: StaffPalette.delivery)),
                const SizedBox(width: 10),
                Expanded(child: StaffMetricCard(label: 'En route', value: '${enRoute.length}', icon: Icons.delivery_dining, palette: StaffPalette.delivery)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _MiniStat(label: 'Livrées (session)', value: '$_livreesSession', color: Colors.green)),
              ]),
              const SizedBox(height: 14),

              if (docs.isEmpty)
                const EmptyStaffState(icon: Icons.delivery_dining, title: 'Aucune course', message: 'Les commandes prêtes apparaîtront ici.')
              else ...[
                if (pretes.isNotEmpty) ...[
                  StaffSectionTitle(title: '📦 À récupérer au resto', trailing: '${pretes.length}'),
                  ...pretes.map((doc) => _LivraisonCard(
                    docId: doc.id, data: doc.data() as Map<String, dynamic>,
                    onAppeler: () => _appeler(_getTel(doc.data() as Map<String, dynamic>)),
                    onMaps: () => _ouvrirMaps(doc.data() as Map<String, dynamic>),
                    onAction: () => _marquerEnRoute(doc.id),
                    actionLabel: '🛵 Parti en livraison',
                    actionColor: Colors.teal,
                  )),
                ],
                if (enRoute.isNotEmpty) ...[
                  StaffSectionTitle(title: '🛵 En route', trailing: '${enRoute.length}'),
                  ...enRoute.map((doc) => _LivraisonCard(
                    docId: doc.id, data: doc.data() as Map<String, dynamic>,
                    onAppeler: () => _appeler(_getTel(doc.data() as Map<String, dynamic>)),
                    onMaps: () => _ouvrirMaps(doc.data() as Map<String, dynamic>),
                    onAction: () => _marquerLivree(doc.id),
                    actionLabel: '✅ Livraison confirmée',
                    actionColor: Colors.green,
                  )),
                ],
              ],
              const SizedBox(height: 16),
              const DeveloperContactButton(),
            ]);
          },
        ),
      ],
    );
  }

  String _getTel(Map<String, dynamic> d) =>
    d['clientTelephone']?.toString() ?? d['client_telephone']?.toString() ?? d['telephone']?.toString() ?? '';
}

class _LivraisonCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final VoidCallback onAppeler, onMaps, onAction;
  final String actionLabel;
  final Color actionColor;

  const _LivraisonCard({
    required this.docId, required this.data,
    required this.onAppeler, required this.onMaps, required this.onAction,
    required this.actionLabel, required this.actionColor,
  });

  @override
  Widget build(BuildContext context) {
    final nom = data['clientNom']?.toString() ?? data['client_nom']?.toString() ?? 'Client';
    final tel = data['clientTelephone']?.toString() ?? data['client_telephone']?.toString() ?? '';
    final zone = data['zone']?.toString() ?? data['quartier']?.toString() ?? 'Zone inconnue';
    final adresse = data['adresse_reperes']?.toString() ?? '';
    final total = (data['total'] as num?)?.toDouble() ?? 0;
    final paiement = data['mode_paiement']?.toString() ?? 'cash';
    final surPlace = data['mode_commande']?.toString() == 'sur_place';
    final articles = data['articles'] as List? ?? [];
    final ref = docId.length > 6 ? docId.substring(0, 6).toUpperCase() : docId.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF9BE5C7)),
        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFFECFDF5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(children: [
            const Icon(Icons.delivery_dining, color: Color(0xFF059669), size: 22),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Course #$ref', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              Text(surPlace ? '🪑 Sur place' : '🛵 $zone', style: const TextStyle(color: Color(0xFF059669), fontSize: 12, fontWeight: FontWeight.w600)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${total.toStringAsFixed(0)} MRU', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              _PaiBadge(paiement: paiement),
            ]),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Infos client
            _Row(Icons.person_rounded, nom, bold: true),
            if (tel.isNotEmpty) GestureDetector(
              onTap: onAppeler,
              child: _Row(Icons.phone_rounded, tel, color: const Color(0xFF059669), bold: true),
            ),
            if (!surPlace && adresse.isNotEmpty) _Row(Icons.location_on, adresse),
            const SizedBox(height: 10),

            // Articles avec images
            const Text('Commande', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
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
                        ? CachedNetworkImage(imageUrl: imgUrl, width: 40, height: 40, fit: BoxFit.cover,
                            placeholder: (_, __) => Container(width: 40, height: 40, color: Colors.grey.shade100,
                                child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                            errorWidget: (_, __, ___) => _fallbackImg())
                        : _fallbackImg(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text('${item['quantite'] ?? 1}x ${item['nom'] ?? 'Plat'}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                ]),
              );
            }),

            const SizedBox(height: 12),

            // Boutons action
            Row(children: [
              if (tel.isNotEmpty) ...[
                _ActionBtn(icon: Icons.call, label: 'Appeler', color: const Color(0xFF059669), onTap: onAppeler),
                const SizedBox(width: 8),
              ],
              if (!surPlace) ...[
                _ActionBtn(icon: Icons.navigation_rounded, label: 'Maps', color: Colors.blue, onTap: onMaps),
                const SizedBox(width: 8),
              ],
              Expanded(child: FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(backgroundColor: actionColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              )),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _fallbackImg() => Container(width: 40, height: 40, color: Colors.grey.shade100,
      child: const Icon(Icons.fastfood, color: Colors.grey, size: 20));
}

class _Row extends StatelessWidget {
  final IconData icon; final String text; final bool bold; final Color? color;
  const _Row(this.icon, this.text, {this.bold = false, this.color});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(children: [
      Icon(icon, size: 16, color: color ?? const Color(0xFF059669)),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: TextStyle(color: color ?? Colors.black87, fontWeight: bold ? FontWeight.w700 : FontWeight.normal, fontSize: 14))),
    ]),
  );
}

class _ActionBtn extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
      ]),
    ),
  );
}

class _PaiBadge extends StatelessWidget {
  final String paiement;
  const _PaiBadge({required this.paiement});
  @override
  Widget build(BuildContext context) {
    Color c; String l;
    switch (paiement) {
      case 'bankily': c = const Color(0xFF2E7D32); l = 'Bankily 💚'; break;
      case 'masrivi': c = const Color(0xFFB8860B); l = 'Masrivi 💛'; break;
      default: c = Colors.grey; l = 'Cash 💵';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: c.withOpacity(0.3))),
      child: Text(l, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value; final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.2))),
    child: Column(children: [
      Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
    ]),
  );
}