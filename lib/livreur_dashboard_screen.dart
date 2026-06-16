import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/developer_contact_button.dart';

class LivreurDashboardScreen extends StatefulWidget {
  const LivreurDashboardScreen({Key? key}) : super(key: key);

  @override
  State<LivreurDashboardScreen> createState() => _LivreurDashboardScreenState();
}

class _LivreurDashboardScreenState extends State<LivreurDashboardScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fonction pour appeler le client directement au téléphone
  Future<void> _appelerClient(String telephone) async {
    if (telephone.isEmpty) return;
    // Nettoyage du numéro pour s'assurer qu'il passe correctement
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: telephone.replaceAll(' ', ''),
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible de lancer l'appel")),
      );
    }
  }

  // Fonction surpuissante pour ouvrir Google Maps avec le combo GPS + Repères visuels
  Future<void> _ouvrirItineraireMaps(double lat, double lng, String reperes) async {
    // On encode le texte pour éviter les espaces et caractères spéciaux dans l'URL
    final String queryText = Uri.encodeComponent("$reperes");
    
    // Structure d'URL universelle combinant les coordonnées géographiques et le repère africain
    final String urlString = "https://www.google.com/maps/search/?api=1&query=$lat,$lng&query_place_id=$queryText";
    final Uri googleMapsUrl = Uri.parse(urlString);

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      // Alternative standard si l'application Maps n'est pas installée
      final Uri webMapsUrl = Uri.parse("https://maps.google.com/?q=$lat,$lng");
      if (await canLaunchUrl(webMapsUrl)) {
        await launchUrl(webMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Impossible d'ouvrir Google Maps")),
        );
      }
    }
  }

  // Clôturer la livraison et encaisser l'argent
  Future<void> _marquerCommandeLivree(String docId) async {
    try {
      await _db.collection('commandes').doc(docId).update({
        'statut': 'livre',
        'date_livraison_terminee': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Félicitations ! Commande livrée et validée. 🎉")),
      );
    } catch (e) {
      print("Erreur validation livraison : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Courses & Livraisons"),
        backgroundColor: Colors.amber.shade900,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Text(
              "Plats prêts à être livrés",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            const SizedBox(height: 10),

            // Écoute en temps réel des commandes dont le statut est 'pret'
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _db.collection('commandes')
                    .where('statut', isEqualTo: 'pret')
                    .orderBy('date_fin_preparation', descending: true)
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
                      child: Text("Aucune livraison en attente. Tout est à jour ! 🛵"),
                    );
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var doc = snapshot.data!.docs[index];
                      Map<String, dynamic> commande = doc.data() as Map<String, dynamic>;
                      
                      double lat = (commande['latitude'] ?? 0.0) as double;
                      double lng = (commande['longitude'] ?? 0.0) as double;
                      String reperes = commande['reperes_adresse'] ?? "";
                      String telephone = commande['client_telephone'] ?? "";

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // En-tête de la carte de livraison
                              Row(
                                mainAxisAlignment: MainAxisAlignment.between,
                                children: [
                                  Text(
                                    "Client : ${commande['client_nom']}",
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, py: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      "${commande['quartier']}",
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(),
                              
                              const SizedBox(height: 5),
                              Text("🏠 Repère indiqué : ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                              Text(reperes, style: const TextStyle(fontSize: 15, color: Colors.black87)),
                              const SizedBox(height: 8),
                              
                              Row(
                                mainAxisAlignment: MainAxisAlignment.between,
                                children: [
                                  Text("💰 Somme à encaisser :", style: TextStyle(color: Colors.grey.shade600)),
                                  Text(
                                    "${commande['total']} MRU",
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                                  ),
                                ],
                              ),
                              Text(
                                "Méthode : ${commande['mode_paiement']}",
                                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.blueGrey),
                              ),
                              const SizedBox(height: 15),

                              // Actions du livreur : Appeler, Naviguer, Clôturer
                              Row(
                                children: [
                                  // Bouton Appeler
                                  IconButton(
                                    onPressed: () => _appelerClient(telephone),
                                    icon: const Icon(Icons.phone, color: Colors.blue, size: 28),
                                    style: IconButton.styleFrom(backgroundColor: Colors.blue.shade50),
                                  ),
                                  const SizedBox(width: 10),
                                  
                                  // Bouton GPS Navigation
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _ouvrirItineraireMaps(lat, lng, reperes),
                                      icon: const Icon(Icons.navigation, color: Colors.white),
                                      label: const Text("Itinéraire", style: TextStyle(color: Colors.white)),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade800),
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Bouton Terminer
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _marquerCommandeLivree(doc.id),
                                      icon: const Icon(Icons.check, color: Colors.white),
                                      label: const Text("Livré ✓", style: TextStyle(color: Colors.white)),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600),
                                    ),
                                  ),
                                ],
                              )
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