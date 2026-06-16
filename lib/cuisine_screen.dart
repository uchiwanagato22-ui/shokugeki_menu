import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/developer_contact_button.dart';

class CuisineScreen extends StatefulWidget {
  const CuisineScreen({Key? key}) : super(key: key);

  @override
  State<CuisineScreen> createState() => _CuisineScreenState();
}

class _CuisineScreenState extends State<CuisineScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Marquer la préparation comme terminée
  Future<void> _marquerPret(String docId) async {
    try {
      await _db.collection('commandes').doc(docId).update({
        'statut': 'pret',
        'date_fin_preparation': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Plat marqué comme prêt ! 🍳 En attente de livraison.")),
      );
    } catch (e) {
      print("Erreur mise à jour cuisine: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Écran de Production Cuisine"),
        backgroundColor: Colors.deepOrange.shade900,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.amber.shade100,
              width: double.infinity,
              child: const Center(
                child: Text(
                  "🔥 Préparations culinaires en cours",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
                ),
              ),
            ),
            
            // Flux des commandes envoyées 'en_cuisine'
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _db.collection('commandes')
                    .where('statut', isEqualTo: 'en_cuisine')
                    .orderBy('date_validation_caissier', ascending: true) // Premier arrivé, premier servi
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text("Erreur : ${snapshot.error}"));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text("Aucun plat en commande. Les fourneaux sont calmes ! 🍩"),
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
                        color: Colors.grey.shade50,
                        borderOnForeground: true,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.deepOrange.shade200, width: 1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.between,
                                children: [
                                  Text(
                                    "Commande de : ${commande['client_nom']}",
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                                  ),
                                  const Icon(Icons.timer, color: Colors.orange),
                                ],
                              ),
                              const Divider(),
                              
                              // Liste épurée des plats à cuisiner
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: articles.length,
                                itemBuilder: (context, i) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(color: Colors.deepOrange.shade50, shape: BoxShape.circle),
                                          child: Text("${articles[i]['quantite']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          articles[i]['nom'],
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 15),
                              
                              // Bouton pour valider la fin de cuisson
                              SizedBox(
                                width: double.infinity,
                                height: 45,
                                child: ElevatedButton.icon(
                                  onPressed: () => _marquerPret(doc.id),
                                  icon: const Icon(Icons.check_circle, color: Colors.white),
                                  label: const Text("Plat Prêt ! 🍳", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
                                ),
                              ),
                            ],
                          ),
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