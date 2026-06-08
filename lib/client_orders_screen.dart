import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'constants.dart';

class ClientOrdersScreen extends StatelessWidget {
  const ClientOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String? userPhone = FirebaseAuth.instance.currentUser?.phoneNumber;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text("SUIVI DE MES COMMANDES", style: TextStyle(color: kSecondaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('commandes').orderBy('date_commande', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
          
          var docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text("Vous n'avez pas encore passé de commande. 🍔"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index];
              String statut = data['statut'] ?? 'En attente';
              String cmdId = docs[index].id.substring(0, 5).toUpperCase();

              return Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black10, blurRadius: 4)]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Commande #$cmdId", style: const TextStyle(fontWeight: FontWeight.bold, color: kSecondaryColor)),
                    Text("Plats : ${data['plats']}", style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 12),
                    // Frise chronologique visuelle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStep(label: "Reçue", active: true, color: Colors.green),
                        _buildLine(active: statut == "En cuisine" || statut == "En cours de livraison" || statut == "Livré"),
                        _buildStep(label: "Cuisine", active: statut == "En cuisine" || statut == "En cours de livraison" || statut == "Livré", color: Colors.orange),
                        _buildLine(active: statut == "En cours de livraison" || statut == "Livré"),
                        _buildStep(label: "Livraison", active: statut == "En cours de livraison" || statut == "Livré", color: Colors.blue),
                        _buildLine(active: statut == "Livré"),
                        _buildStep(label: "Livré", active: statut == "Livré", color: kPrimaryColor),
                      ],
                    ),
                    if (statut == "Rejeté / Fraude suspectée") ...[
                      const SizedBox(height: 10),
                      const Text("⚠️ Commande rejetée : Problème avec le reçu Bankily.", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12))
                    ]
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStep({required String label, required bool active, required Color color}) {
    return Column(
      children: [
        Icon(active ? Icons.check_circle : Icons.radio_button_unchecked, color: active ? color : Colors.grey, size: 20),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: active ? Colors.black : Colors.grey, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _buildLine({required bool active}) {
    return Expanded(child: Container(height: 2, color: active ? Colors.green : Colors.grey.withOpacity(0.3)));
  }
}