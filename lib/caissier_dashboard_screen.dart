import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'premium_staff_widgets.dart';
import 'widgets/developer_contact_button.dart';
import 'login_screen.dart';
import 'constants.dart';

// ✅ FIX CRITIQUE : Ce fichier contenait CuisineScreen au lieu de CaissierDashboardScreen
// main.dart appelle CaissierDashboardScreen() → crashait au runtime

class CaissierDashboardScreen extends StatefulWidget {
  const CaissierDashboardScreen({super.key});

  @override
  State<CaissierDashboardScreen> createState() => _CaissierDashboardScreenState();
}

class _CaissierDashboardScreenState extends State<CaissierDashboardScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> _validerCommande(String docId) async {
    await _db.collection('commandes').doc(docId).update({
      'statut': 'en_cuisine',
      'validated_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Commande envoyée en cuisine ✅'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _rejeterCommande(String docId) async {
    await _db.collection('commandes').doc(docId).update({
      'statut': 'rejete',
      'updated_at': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Commande rejetée'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  // ✅ Déconnexion propre : efface SharedPreferences + Firebase Auth
  Future<void> _deconnecter() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14161D),
        title: const Text('Déconnexion', style: TextStyle(color: Colors.white)),
        content: const Text('Confirmer la déconnexion ?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Déconnecter',
                style: TextStyle(color: Colors.redAccent)),
          ),
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
      title: 'Caissier',
      subtitle: 'Valider ou rejeter les commandes entrantes.',
      icon: Icons.point_of_sale,
      palette: StaffPalette.cashier,
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
              .where('statut', isEqualTo: 'en_attente')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return EmptyStaffState(
                icon: Icons.warning_amber,
                title: 'Erreur caisse',
                message: snapshot.error.toString(),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return const EmptyStaffState(
                icon: Icons.inbox_rounded,
                title: 'Aucune commande en attente',
                message: 'Les nouvelles commandes clients apparaîtront ici.',
              );
            }

            return Column(
              children: [
                StaffMetricCard(
                  label: 'Commandes en attente',
                  value: docs.length.toString(),
                  icon: Icons.pending_actions,
                  palette: StaffPalette.cashier,
                ),
                StaffSectionTitle(
                  title: 'À traiter',
                  trailing: '${docs.length} commande(s)',
                ),
                ...docs.map((doc) {
                  final commande = doc.data() as Map<String, dynamic>;
                  return _CaissierCard(
                    commande: commande,
                    onValider: () => _validerCommande(doc.id),
                    onRejeter: () => _rejeterCommande(doc.id),
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

class _CaissierCard extends StatelessWidget {
  const _CaissierCard({
    required this.commande,
    required this.onValider,
    required this.onRejeter,
  });

  final Map<String, dynamic> commande;
  final VoidCallback onValider;
  final VoidCallback onRejeter;

  @override
  Widget build(BuildContext context) {
    final articles = commande['articles'];
    final List articlesList = articles is List ? articles : [];
    final total = commande['total'] ?? 0;
    final clientNom = commande['clientNom'] ?? commande['client_nom'] ?? commande['client'] ?? 'Client';
    final adresse = commande['adresse_reperes']?.toString() ?? 'Non précisée';
                final tel = commande['clientTelephone']?.toString() ?? commande['client_telephone']?.toString() ?? '';
                final modeCmd = commande['mode_commande']?.toString() ?? 'livraison';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBFD7F7)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: Color(0xFF2563EB)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    clientNom,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  '$total MRU',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, color: Color(0xFF2563EB)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  _PaiementBadgeCaissier(paiement: commande['mode_paiement']?.toString() ?? 'cash'),
                  const SizedBox(width: 8),
                  _ModeCommandeBadge(mode: commande['mode_commande']?.toString() ?? 'livraison'),
                ]),
                const SizedBox(height: 6),
                Text('📍 $adresse',
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 10),
                ...articlesList.map((a) {
                  final item = a is Map ? a : {};
                  return Text(
                    '• ${item['quantite'] ?? 1}x ${item['nom'] ?? 'Plat'}',
                    style: const TextStyle(fontSize: 14),
                  );
                }),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onRejeter,
                        icon: const Icon(Icons.cancel, color: Colors.redAccent),
                        label: const Text('Rejeter',
                            style: TextStyle(color: Colors.redAccent)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onValider,
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Valider'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _PaiementBadgeCaissier extends StatelessWidget {
  final String paiement;
  const _PaiementBadgeCaissier({required this.paiement});

  @override
  Widget build(BuildContext context) {
    Color color; String label;
    switch (paiement) {
      case 'bankily': color = const Color(0xFF006400); label = 'Bankily 💚'; break;
      case 'masrivi': color = const Color(0xFFB8860B); label = 'Masrivi 💛'; break;
      default: color = Colors.grey; label = 'Cash 💵';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.4))),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

class _ModeCommandeBadge extends StatelessWidget {
  final String mode;
  const _ModeCommandeBadge({required this.mode});

  @override
  Widget build(BuildContext context) {
    final surPlace = mode == 'sur_place';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: surPlace ? Colors.purple.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: surPlace ? Colors.purple.withOpacity(0.4) : Colors.blue.withOpacity(0.4)),
      ),
      child: Text(surPlace ? '🪑 Sur place' : '🛵 Livraison', style: TextStyle(color: surPlace ? Colors.purple : Colors.blue, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}