import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/developer_contact_button.dart';

class CaissierDashboardScreen extends StatefulWidget {
  const CaissierDashboardScreen({Key? key}) : super(key: key);

  @override
  State<CaissierDashboardScreen> createState() => _CaissierDashboardScreenState();
}

class _CaissierDashboardScreenState extends State<CaissierDashboardScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Mettre à jour le statut d'une commande
  Future<void> _modifierStatut(String docId, String nouveauStatut) async {
    try {
      await _db.collection('commandes').doc(docId).update({
        'statut': nouveauStatut,
        'date_validation_caissier': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Commande mise à jour : $nouveauStatut")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur de mise à jour : ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Espace Caisse & Validation"),
        backgroundColor: Colors.blueGrey.shade900,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Text(
              "Commandes en attente de validation",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            
            // Flux en temps réel des commandes dont le statut est 'en_attente'
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _db.collection('commandes')
                    .where('statut', isEqualTo: 'en_attente')
                    .orderBy('date_commande', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text("Erreur de chargement : ${snapshot.error}"));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text("Aucune nouvelle commande pour le moment. ☕"),
                    );
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var doc = snapshot.data!.docs[index];
                      Map<String, dynamic> commande = doc.data() as Map<String, dynamic>;
                      List articles = commande['articles'] ?? [];

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        elevation: 4,
                        child: ExpansionTile(
                          title: Text(
                            "${commande['client_nom']} - ${commande['total']} MRU",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text("Quartier : ${commande['quartier']} | Tél : ${commande['client_telephone']}"),
                          trailing: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: commande['mode_paiement'] == 'A la livraison' ? Colors.orange.shade100 : Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              commande['mode_paiement'],
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Détails des plats :", style: TextStyle(fontWeight: FontWeight.bold)),
                                  const Divider(),
                                  ...articles.map((item) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                                    child: Text("• ${item['nom']} (x${item['quantite']})"),
                                  )).toList(),
                                  const SizedBox(height: 10),
                                  Text("📍 Repères : ${commande['reperes_adresse']}"),
                                  const SizedBox(height: 15),
                                  
                                  // Boutons d'action pour le caissier
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () => _modifierStatut(doc.id, 'rejete'),
                                        icon: const Icon(Icons.cancel, color: Colors.white),
                                        label: const Text("Rejeter", style: TextStyle(color: Colors.white)),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () => _modifierStatut(doc.id, 'en_cuisine'),
                                        icon: const Icon(Icons.soup_kitchen, color: Colors.white),
                                        label: const Text("Envoyer Cuisine", style: TextStyle(color: Colors.white)),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const DeveloperContactButton(),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}