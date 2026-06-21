import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'premium_staff_widgets.dart';
import 'widgets/developer_contact_button.dart';
import 'constants.dart';

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
      final String rechercheTexte = Uri.encodeComponent("$quartier $reperes Nouakchott");
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$rechercheTexte');
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Impossible d'ouvrir Google Maps"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _marquerLivree(String docId) async {
    await _db.collection('commandes').doc(docId).update({'statut': 'livree'});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Espace Livreur 🚴'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('commandes').where('statut', isEqualTo: 'en_livraison').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("Aucune livraison en cours 🍽️", style: TextStyle(color: Colors.grey)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return _LivreurOrderCard(
                commande: data,
                onCall: () => _appelerClient(data['clientTelephone'] ?? ''),
                onMap: () => _ouvrirMaps(data),
                onDelivered: () => _marquerLivree(doc.id),
              );
            },
          );
        },
      ),
    );
  }
}

class _LivreurOrderCard extends StatelessWidget {
  const _LivreurOrderCard({
    required this.commande,
    required this.onCall,
    required this.onMap,
    required this.onDelivered,
  });

  final Map<String, dynamic> commande;
  final VoidCallback onCall;
  final VoidCallback onMap;
  final VoidCallback onDelivered;

  @override
  Widget build(BuildContext context) {
    final String nom = commande['clientNom'] ?? 'Client';
    final String tel = commande['clientTelephone'] ?? 'Inconnu';
    final String quartier = commande['quartier'] ?? 'Non spécifié';
    final String reperes = commande['adresse_reperes'] ?? 'Aucun repère';
    final double total = (commande['total'] ?? 0.0) as double;

    return Card(
      color: kSurfaceColor,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(nom, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text("$total MRU", style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(color: Colors.white10, height: 20),
            _InfoLine(icon: Icons.phone, text: tel),
            _InfoLine(icon: Icons.location_on, text: "$quartier - $reperes"),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  onPressed: onCall,
                  icon: const Icon(Icons.phone, color: Colors.white),
                  style: IconButton.styleFrom(backgroundColor: kPrimaryColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onMap,
                    icon: const Icon(Icons.navigation),
                    label: const Text('Itinéraire Maps'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.blueGrey),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onDelivered,
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