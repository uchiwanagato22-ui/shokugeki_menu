import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'premium_staff_widgets.dart';
import 'widgets/developer_contact_button.dart';
import 'constants.dart';
import 'login_screen.dart';

class LivreurDashboardScreen extends StatefulWidget {
  const LivreurDashboardScreen({super.key});

  @override
  State<LivreurDashboardScreen> createState() => _LivreurDashboardScreenState();
}

class _LivreurDashboardScreenState extends State<LivreurDashboardScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> _appelerClient(String telephone) async {
    if (telephone.trim().isEmpty) return;
    final uri = Uri(scheme: 'tel', path: telephone.replaceAll(' ', ''));
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _ouvrirMaps(Map<String, dynamic> data) async {
    final double lat = (data['latitude'] as num?)?.toDouble() ?? 0.0;
    final double lng = (data['longitude'] as num?)?.toDouble() ?? 0.0;
    final String quartier = data['quartier']?.toString() ?? '';
    final String reperes = data['adresse_reperes']?.toString() ?? '';

    final Uri uri = (lat != 0.0 && lng != 0.0)
        ? Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng')
        : Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('$quartier $reperes Nouakchott')}');

    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _marquerLivree(String docId) async {
    await _db.collection('commandes').doc(docId).update({
      'statut': 'livree',
      'delivered_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Commande livrée ✅'), backgroundColor: Colors.green),
    );
  }

  Future<void> _deconnecter() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14161D),
        title: const Text('Déconnexion', style: TextStyle(color: Colors.white)),
        content: const Text('Confirmer ?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Déconnecter', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('staff_role');
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StaffScaffold(
      title: 'Livreur',
      subtitle: 'Vos courses en attente de livraison.',
      icon: Icons.delivery_dining,
      palette: StaffPalette.delivery,
      actions: [
        IconButton(
          tooltip: 'Se déconnecter',
          icon: const Icon(Icons.logout, color: Colors.redAccent),
          onPressed: _deconnecter,
        ),
      ],
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: _db
              .collection('commandes')
              .where('statut', whereIn: ['pret', 'pret_pour_livraison', 'en_livraison', 'en_cours_de_livraison'])
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return EmptyStaffState(icon: Icons.warning_amber, title: 'Erreur', message: snapshot.error.toString());
            }
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return const EmptyStaffState(
                icon: Icons.delivery_dining,
                title: 'Aucune course',
                message: 'Pas de commande prête à livrer pour le moment.',
              );
            }

            return Column(
              children: [
                StaffMetricCard(
                  label: 'Courses à livrer',
                  value: docs.length.toString(),
                  icon: Icons.delivery_dining,
                  palette: StaffPalette.delivery,
                ),
                StaffSectionTitle(title: 'À livrer maintenant', trailing: '${docs.length} course(s)'),
                ...docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _LivraisonCard(
                    docId: doc.id,
                    data: data,
                    onAppeler: () => _appelerClient(
                      data['clientTelephone']?.toString() ??
                      data['client_telephone']?.toString() ??
                      data['telephone']?.toString() ?? '',
                    ),
                    onMaps: () => _ouvrirMaps(data),
                    onLivree: () => _marquerLivree(doc.id),
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

class _LivraisonCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final VoidCallback onAppeler;
  final VoidCallback onMaps;
  final VoidCallback onLivree;

  const _LivraisonCard({
    required this.docId,
    required this.data,
    required this.onAppeler,
    required this.onMaps,
    required this.onLivree,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ FIX : lecture des deux variantes de clés possibles dans Firestore
    // ✅ Lecture des deux formats : camelCase (nouveau) et snake_case (ancien)
    final nom = data['clientNom']?.toString() ??
        data['client_nom']?.toString() ?? 'Client inconnu';
    final tel = data['clientTelephone']?.toString() ??
        data['client_telephone']?.toString() ??
        data['telephone']?.toString() ?? '';
    final quartier = data['quartier']?.toString() ?? 'Zone non précisée';
    final reperes = data['adresse_reperes']?.toString() ?? '';
    final total = (data['total'] as num?)?.toStringAsFixed(0) ?? '0';
    final paiement = data['mode_paiement']?.toString() ?? 'cash';
    final modeCommande = data['mode_commande']?.toString() ?? 'livraison';
    final articles = data['articles'] as List? ?? [];
    final ref = docId.length > 6 ? docId.substring(0, 6).toUpperCase() : docId.toUpperCase();

    final bool surPlace = modeCommande == 'sur_place';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF9BE5C7)),
      ),
      child: Column(
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFECFDF5),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: Color(0xFF059669)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Commande #$ref', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                    Text(
                      surPlace ? '🪑 Sur place' : '🛵 Livraison — $quartier',
                      style: const TextStyle(color: Color(0xFF059669), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('$total MRU', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  _PaiementBadge(paiement: paiement),
                ]),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Infos client complètes
                _InfoLine(icon: Icons.person, text: nom),
                if (tel.isNotEmpty) _InfoLine(icon: Icons.phone, text: tel),
                if (!surPlace && reperes.isNotEmpty) _InfoLine(icon: Icons.location_on, text: reperes),

                // Articles
                if (articles.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Divider(height: 1, color: Colors.black12),
                  const SizedBox(height: 8),
                  ...articles.map((a) {
                    final item = a is Map ? a : {};
                    return Text(
                      '• ${item['quantite'] ?? 1}x ${item['nom'] ?? 'Plat'}',
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    );
                  }),
                ],

                const SizedBox(height: 12),

                // Boutons action
                Row(children: [
                  if (tel.isNotEmpty) ...[
                    CircleAvatar(
                      backgroundColor: const Color(0xFFECFDF5),
                      child: IconButton(
                        icon: const Icon(Icons.call, color: Color(0xFF059669)),
                        onPressed: onAppeler,
                        tooltip: 'Appeler le client',
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (!surPlace) ...[
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onMaps,
                        icon: const Icon(Icons.navigation_rounded),
                        label: const Text('Maps'),
                        style: FilledButton.styleFrom(backgroundColor: Colors.blueGrey),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onLivree,
                      icon: const Icon(Icons.check_circle_rounded),
                      label: Text(surPlace ? 'Servi' : 'Livrée'),
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF059669)),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaiementBadge extends StatelessWidget {
  final String paiement;
  const _PaiementBadge({required this.paiement});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (paiement) {
      case 'bankily':
        color = const Color(0xFF006400); label = 'Bankily'; break;
      case 'masrivi':
        color = const Color(0xFFB8860B); label = 'Masrivi'; break;
      default:
        color = Colors.grey; label = 'Cash';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.4))),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Icon(icon, size: 16, color: const Color(0xFF059669)),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 14))),
      ]),
    );
  }
}