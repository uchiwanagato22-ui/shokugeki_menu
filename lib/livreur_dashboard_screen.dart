import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'constants.dart';

class LivreurDashboardScreen extends StatefulWidget {
  const LivreurDashboardScreen({super.key});

  @override
  State<LivreurDashboardScreen> createState() => _LivreurDashboardScreenState();
}

class _LivreurDashboardScreenState extends State<LivreurDashboardScreen> {
  bool _isAvailable = true;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> _ouvrirMaps(String adresse) async {
    final String query = Uri.encodeComponent("$adresse, Nouakchott, Mauritanie");
    final Uri googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Impossible d'ouvrir Google Maps ❌"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111115),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A22),
        title: const Text("ZONE LIVREUR", style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
        actions: [
          Row(
            children: [
              Text(_isAvailable ? "EN LIGNE" : "OFFLINE",
                  style: TextStyle(color: _isAvailable ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
              Switch(
                value: _isAvailable,
                activeThumbColor: Colors.green,
                onChanged: (val) => setState(() => _isAvailable = val),
              ),
            ],
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("SUIVI DES COURSES (NOUAKCHOTT)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Expanded(
              child: _isAvailable
                  ? StreamBuilder<QuerySnapshot>(
                      stream: _db.collection('commandes').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
                        }

                        // Le livreur intercepte uniquement ce qui sort tout chaud de la cuisine
                        final filtrerDocs = snapshot.data!.docs.where((doc) {
                          String status = doc['statut'] ?? '';
                          return status == 'pret_pour_livraison';
                        }).toList();

                        if (filtrerDocs.isEmpty) {
                          return const Center(
                              child: Text("Aucune course prête pour le moment. ☕", style: TextStyle(color: Colors.grey)));
                        }

                        return ListView.builder(
                          itemCount: filtrerDocs.length,
                          itemBuilder: (context, index) {
                            var doc = filtrerDocs[index];
                            String docId = doc.id;
                            String cmdId = docId.substring(0, 5).toUpperCase();
                            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: const Color(0xFF1A1A22), borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Commande #$cmdId", style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                                        child: const Text("À LIVRER", style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                                      )
                                    ],
                                  ),
                                  const Divider(color: Colors.white10, height: 20),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text("📍 Adresse : ${data['adresse']}", style: const TextStyle(color: Colors.white70)),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.near_me, color: Colors.blueAccent, size: 22),
                                        onPressed: () => _ouvrirMaps(data['adresse'] ?? ''),
                                        tooltip: "Lancer le GPS",
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text("📞 Client : ${data['client'] ?? 'Inconnu'}", style: const TextStyle(color: Colors.white70)),
                                  Text("📞 Téléphone : ${data['phone'] ?? '-'}", style: const TextStyle(color: Colors.white70)),
                                  Text("🍔 Plats : ${data['plats'] ?? ''}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                  const SizedBox(height: 8),
                                  Text("Total : ${data['total']} MRU", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      await _db.collection('commandes').doc(docId).update({'statut': 'livre'});
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("Commande $cmdId marquée comme Livrée ! 🎉"), backgroundColor: kPrimaryColor),
                                      );
                                    },
                                    icon: const Icon(Icons.check_circle, color: Colors.white),
                                    label: const Text("Marquer comme Livré", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 42)),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      })
                  : const Center(child: Text("Passez en ligne pour charger le radar.", style: TextStyle(color: Colors.grey))),
            ),
          ],
        ),
      ),
    );
  }
}