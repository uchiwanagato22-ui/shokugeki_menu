import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'constants.dart';
import 'director_ia_service.dart';

class DirecteurDashboardScreen extends StatefulWidget {
  const DirecteurDashboardScreen({super.key});

  @override
  State<DirecteurDashboardScreen> createState() => _DirecteurDashboardScreenState();
}

class _DirecteurDashboardScreenState extends State<DirecteurDashboardScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final DirectorIaService _shinraIa = DirectorIaService();
  
  bool _isIaLoading = false;
  String _iaReport = "Cliquez sur le bouton ci-dessus pour lancer l'analyse prédictive de Shinra.ia en temps réel.";

  void _lancerAnalyseShinra() async {
    setState(() => _isIaLoading = true);
    // Demande au service d'analyser Firestore
    String rapportFrais = await _shinraIa.repondreAuDirecteur("rapport");
    setState(() {
      _iaReport = rapportFrais;
      _isIaLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111115),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A22),
        title: const Text("EMPIRE SHOKUGEKI (Directeur)", style: TextStyle(color: kAccentColor, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('commandes').snapshots(),
        builder: (context, snapshot) {
          int caReel = 0;
          int attenteCount = 0;
          int fraudesBloquees = 0;

          if (snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              String statut = doc['statut'] ?? '';
              int total = doc['total'] ?? 0;

              if (statut != "Rejeté / Fraude suspectée" && statut != "En attente de validation") {
                caReel += total;
              }
              if (statut == "En attente de validation") {
                attenteCount++;
              }
              if (statut == "Rejeté / Fraude suspectée") {
                fraudesBloquees++;
              }
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("PERFORMANCES DU RESTAURANT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    _buildStatCard(title: "Recette Réelle", value: "$caReel MRU", icon: Icons.monetization_on, color: Colors.green),
                    _buildStatCard(title: "En attente caisse", value: "$attenteCount", icon: Icons.hourglass_top, color: Colors.orange),
                    _buildStatCard(title: "Anti-Fraude Bankily", value: "$fraudesBloquees", icon: Icons.security, color: Colors.red),
                    _buildStatCard(title: "Statut Système", value: "Actif (Live)", icon: Icons.bolt, color: kAccentColor),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFF1A1A22), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("MODULE SUPERINTELLIGENCE AGENTIQUE", style: TextStyle(color: kAccentColor, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 12),
                      _isIaLoading
                          ? const Center(child: CircularProgressIndicator(color: kAccentColor))
                          : ElevatedButton.icon(
                              onPressed: _lancerAnalyseShinra,
                              icon: const Icon(Icons.psychology, color: Colors.black),
                              label: const Text("Lancer l'Analyse Stratégique Shinra.ia", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(backgroundColor: kAccentColor, minimumSize: const Size(double.infinity, 45)),
                            ),
                      const SizedBox(height: 16),
                      Text(_iaReport, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF1A1A22), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}