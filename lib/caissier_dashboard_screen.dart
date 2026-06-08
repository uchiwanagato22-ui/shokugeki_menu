import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'constants.dart';

class CaissierDashboardScreen extends StatefulWidget {
  const CaissierDashboardScreen({super.key});

  @override
  State<CaissierDashboardScreen> createState() =>
      _CaissierDashboardScreenState();
}

class _CaissierDashboardScreenState extends State<CaissierDashboardScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- ACTIONS DE MODIFICATION DU STATUT DE LA COMMANDE ---
  void _validerCommande(String docId, String cmdId) {
    _db.collection('commandes').doc(docId).update({'statut': 'En cuisine'});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text("Commande $cmdId envoyée en cuisine ! 🍳"),
          backgroundColor: Colors.green),
    );
  }

  void _rejeterCommande(String docId, String cmdId) {
    _db
        .collection('commandes')
        .doc(docId)
        .update({'statut': 'Rejeté / Fraude suspectée'});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text("Commande $cmdId bloquée ! ❌"),
          backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111115), // Fond sombre pro
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        elevation: 0,
        title: const Text(
          "CONSOLE CAISSE & STATS",
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2),
        ),
      ),
      body: Column(
        children: [
          // 📈 SECTION STATISTIQUES EN TEMPS RÉEL (BUSINESS DASHBOARD)
          StreamBuilder<QuerySnapshot>(
            stream: _db.collection('commandes').snapshots(),
            builder: (context, snapshot) {
              int totalRecette = 0;
              int commandesValideesCount = 0;
              int fraudesBloqueesCount = 0;

              if (snapshot.hasData) {
                for (var doc in snapshot.data!.docs) {
                  var data = doc.data() as Map<String, dynamic>;
                  String statut = data['statut'] ?? '';
                  int total = data['total'] ?? 0;

                  // On calcule la recette sur tout ce qui n'est ni en attente ni rejeté
                  if (statut != 'En attente de validation' &&
                      statut != 'Rejeté / Fraude suspectée') {
                    totalRecette += total;
                    commandesValideesCount++;
                  }
                  if (statut == 'Rejeté / Fraude suspectée') {
                    fraudesBloqueesCount++;
                  }
                }
              }

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Carte Recette Totale
                    Expanded(
                      child: _buildStatCard(
                        title: "Recette",
                        value: "$totalRecette MRU",
                        icon: Icons.monetization_on_rounded,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Carte Commandes Validées
                    Expanded(
                      child: _buildStatCard(
                        title: "Validées",
                        value: "$commandesValideesCount",
                        icon: Icons.check_circle_rounded,
                        color: kPrimaryColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Carte Fraudes Bloquées (Sécurité Bankily/Masrvi)
                    Expanded(
                      child: _buildStatCard(
                        title: "Fraudes",
                        value: "$fraudesBloqueesCount",
                        icon: Icons.shield_rounded,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "COMMANDES DU JOUR",
                style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 📥 LISTE FLUX EN DIRECT DES COMMANDES
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('commandes')
                  .orderBy('date_commande', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: kPrimaryColor));
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Text("Aucune commande enregistrée aujourd'hui. 🗓️",
                        style: TextStyle(color: Colors.white70)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final docId = docs[index].id;
                    final cmd = docs[index].data() as Map<String, dynamic>;
                    final String cmdId = docId.substring(0, 5).toUpperCase();
                    final String statut =
                        cmd["statut"] ?? "En attente de validation";

                    return Card(
                      color: const Color(0xFF1A1A22),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Commande #$cmdId",
                                    style: const TextStyle(
                                        color: kPrimaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statut == "En cuisine"
                                        ? Colors.green.withOpacity(0.2)
                                        : (statut.contains("Rejeté")
                                            ? Colors.red.withOpacity(0.2)
                                            : Colors.orange.withOpacity(0.2)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    statut,
                                    style: TextStyle(
                                      color: statut == "En cuisine"
                                          ? Colors.green
                                          : (statut.contains("Rejeté")
                                              ? Colors.red
                                              : Colors.orange),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text("Client : ${cmd["client"] ?? "Inconnu"}",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500)),
                            Text("Tél : ${cmd["phone"] ?? "-"}",
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                            Text(
                                "Adresse : ${cmd["adresse"] ?? "Non spécifiée"}",
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                            const Divider(color: Colors.white10, height: 20),
                            Text("Plats : ${cmd["plats"] ?? ""}",
                                style: const TextStyle(
                                    color: kAccentColor,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text(
                                "Paiement : ${cmd["type_paiement"]} (${cmd["ref_transaction"]})",
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 6),
                            Text("Total à encaisser : ${cmd["total"]} MRU",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),

                            // Boutons d'actions si la commande est en attente
                            if (statut == "En attente de validation") ...[
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          _rejeterCommande(docId, cmdId),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                            color: Colors.redAccent),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                      ),
                                      child: const Text("Faux ID / Rejeter",
                                          style: TextStyle(
                                              color: Colors.redAccent,
                                              fontSize: 12)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          _validerCommande(docId, cmdId),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                      ),
                                      child: const Text("Valider & Cuisine",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12)),
                                    ),
                                  ),
                                ],
                              )
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- COMPOSANT DES MINI-CARTES DE STATISTIQUES ---
  Widget _buildStatCard(
      {required String title,
      required String value,
      required IconData icon,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(title,
              style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
