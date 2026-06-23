import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _ouvrirMaps(Map<String, dynamic> commande) async {
    final double lat = (commande['latitude'] ?? 0.0) as double;
    final double lng = (commande['longitude'] ?? 0.0) as double;
    final String quartier = commande['quartier'] ?? '';
    final String reperes = commande['adresse_reperes'] ?? '';

    Uri uri;
    if (lat != 0.0 && lng != 0.0) {
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    } else {
      final String rechercheTexte = Uri.encodeComponent('$quartier $reperes Nouakchott');
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$rechercheTexte');
    }
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _marquerLivree(String docId) async {
    await _db.collection('commandes').doc(docId).update({
      'statut': 'livree',
      'delivered_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Commande marquée livrée avec succès !'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StaffScaffold(
      title: 'Livreur',
      subtitle: 'Suivi de vos courses et itinéraires...',
      icon: Icons.delivery_dining,
      palette: StaffPalette.delivery,
      actions: [
        // 🎯 Bouton Déconnexion sécurisé
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
              .where('statut', isEqualTo: 'pret')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Center(child: Text('Erreur de données'));
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const EmptyStaffState(
                icon: Icons.delivery_dining,
                title: 'Aucune course',
                message: 'Pas de commande en attente de livraison pour le moment.',
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final commande = docs[index];
                final data = commande.data() as Map<String, dynamic>;
                final telephone = data['telephone']?.toString() ?? '';
                final quartier = data['quartier']?.toString() ?? 'Non spécifié';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Livraison #${commande.id.substring(0, 5).toUpperCase()}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const Divider(),
                        _InfoLine(icon: Icons.phone, text: telephone.isNotEmpty ? telephone : 'Aucun numéro'),
                        _InfoLine(icon: Icons.location_on, text: quartier),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (telephone.isNotEmpty) ...[
                              IconButton(
                                icon: const Icon(Icons.call, color: Colors.green),
                                onPressed: () => _appelerClient(telephone),
                              ),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _ouvrirMaps(data),
                                icon: const Icon(Icons.navigation),
                                label: const Text('Maps'),
                                style: FilledButton.styleFrom(backgroundColor: Colors.blueGrey),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _marquerLivree(commande.id),
                                icon: const Icon(Icons.check),
                                label: const Text('Livrée'),
                                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF059669)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(icon, size: 18, color: kPrimaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}