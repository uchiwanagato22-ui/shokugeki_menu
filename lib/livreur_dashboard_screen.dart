import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'premium_staff_widgets.dart';
import 'widgets/developer_contact_button.dart';

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
    final lat = readMoney(commande['latitude']);
    final lng = readMoney(commande['longitude']);
    final quartier = Uri.encodeComponent(readText(commande, 'quartier'));
    final uri = lat != 0 && lng != 0
        ? Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng')
        : Uri.parse('https://www.google.com/maps/search/?api=1&query=$quartier');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _marquerLivree(String docId) async {
    await _db.collection('commandes').doc(docId).update({
      'statut': 'livre',
      'delivered_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Commande livree et validee.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StaffScaffold(
      title: 'Livraison',
      subtitle: 'Commandes pretes, appel client, itineraire et validation de livraison.',
      icon: Icons.delivery_dining,
      palette: StaffPalette.delivery,
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: _db.collection('commandes').where('statut', isEqualTo: 'pret').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return EmptyStaffState(
                icon: Icons.warning_amber,
                title: 'Erreur livraison',
                message: snapshot.error.toString(),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return const EmptyStaffState(
                icon: Icons.delivery_dining,
                title: 'Aucune course disponible',
                message: 'Les commandes pretes sortiront ici des que la cuisine valide.',
              );
            }

            return Column(
              children: [
                StaffMetricCard(
                  label: 'Courses a livrer',
                  value: docs.length.toString(),
                  icon: Icons.route,
                  palette: StaffPalette.delivery,
                ),
                StaffSectionTitle(
                  title: 'Commandes pretes',
                  trailing: '${docs.length} course(s)',
                ),
                ...docs.map((doc) {
                  final commande = doc.data() as Map<String, dynamic>;
                  return _DeliveryCard(
                    commande: commande,
                    onCall: () => _appelerClient(readText(commande, 'client_telephone')),
                    onMap: () => _ouvrirMaps(commande),
                    onDelivered: () => _marquerLivree(doc.id),
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

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD1FAE5)),
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
              Text(
                "${readMoney(commande['total']).toStringAsFixed(0)} MRU",
                style: const TextStyle(
                  color: Color(0xFF047857),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _InfoLine(
            icon: Icons.place,
            text: readText(commande, 'quartier', 'Adresse non precisee'),
          ),
          _InfoLine(
            icon: Icons.phone,
            text: readText(commande, 'client_telephone', 'Telephone absent'),
          ),
          if (readText(commande, 'reperes_adresse').isNotEmpty)
            _InfoLine(
              icon: Icons.notes,
              text: readText(commande, 'reperes_adresse'),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton.filledTonal(
                tooltip: 'Appeler',
                onPressed: onCall,
                icon: const Icon(Icons.phone),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onMap,
                  icon: const Icon(Icons.navigation),
                  label: const Text('Itineraire'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onDelivered,
                  icon: const Icon(Icons.check),
                  label: const Text('Livree'),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF059669)),
                ),
              ),
            ],
          ),
        ],
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
          Icon(icon, size: 18, color: const Color(0xFF059669)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
