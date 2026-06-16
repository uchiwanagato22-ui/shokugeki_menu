import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'director_ia_service.dart';
import '../widgets/developer_contact_button.dart';

class DirectorDashboardScreen extends StatefulWidget {
  const DirectorDashboardScreen({Key? key}) : super(key: key);

  @override
  State<DirectorDashboardScreen> createState() => _DirectorDashboardScreenState();
}

class _DirectorDashboardScreenState extends State<DirectorDashboardScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final DirectorIAService _iaService = DirectorIAService();

  // Variables IA
  String _rapportIA = "Cliquez sur 'Lancer l'Analyse IA' pour obtenir le rapport de vos performances.";
  bool _isAnalysing = false;

  // Formulaire d'ajout de plat
  final _nomPlatController = TextEditingController();
  final _prixPlatController = TextEditingController();
  File? _imageSelectionnee;
  bool _isUploading = false;

  // Sélectionner une image depuis la galerie du téléphone
  Future<void> _choisirImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (image != null) {
      setState(() {
        _imageSelectionnee = File(image.path);
      });
    }
  }

  // Ajouter un plat dans Firestore avec Image de couverture
  Future<void> _ajouterNouveauPlat() async {
    if (_nomPlatController.text.isEmpty || _prixPlatController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez remplir le nom et le prix.")));
      return;
    }

    setState(() => _isUploading = true);
    String imageUrl = "";

    try {
      // 1. Upload de l'image sur Firebase Storage si une image est sélectionnée
      if (_imageSelectionnee != null) {
        String nomFichier = "plats/${DateTime.now().millisecondsSinceEpoch}.jpg";
        TaskSnapshot uploadTask = await _storage.ref().child(nomFichier).putFile(_imageSelectionnee!);
        imageUrl = await uploadTask.ref.getDownloadURL();
      }

      // 2. Insertion du plat dans la collection 'menu'
      await _db.collection('menu').add({
        'nom': _nomPlatController.text.trim(),
        'prix': double.parse(_prixPlatController.text.trim()),
        'image': imageUrl.isNotEmpty ? imageUrl : "https://via.placeholder.com/150",
        'disponible': true,
        'date_creation': FieldValue.serverTimestamp(),
      });

      // Nettoyage du formulaire
      _nomPlatController.clear();
      _prixPlatController.clear();
      setState(() => _imageSelectionnee = null);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nouveau plat ajouté au menu ! 🍳")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur d'ajout : ${e.toString()}")));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // Supprimer définitivement un plat du menu
  Future<void> _supprimerPlat(String docId) async {
    try {
      await _db.collection('menu').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Plat supprimé définitivement.")));
    } catch (e) {
      print(e);
    }
  }

  // Modifier la disponibilité d'un plat (Le retirer temporairement sans le supprimer)
  Future<void> _changerDisponibilite(String docId, bool statutActuel) async {
    await _db.collection('menu').doc(docId).update({'disponible': !statutActuel});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Directeur & Pilotage IA"),
        backgroundColor: Colors.purple.shade900,
        centerTitle: true,
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: _db.collection('commandes').where('statut', isEqualTo: 'livre').snapshots(),
          builder: (context, snapshot) {
            double chiffreAffaires = 0.0;
            int totalCommandes = 0;
            List<String> platsVendus = [];

            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              totalCommandes = snapshot.data!.docs.length;
              for (var doc in snapshot.data!.docs) {
                var data = doc.data() as Map<String, dynamic>;
                chiffreAffaires += (data['total'] ?? 0.0);
                
                List articles = data['articles'] ?? [];
                for (var art in articles) {
                  platsVendus.add(art['nom'].toString());
                }
              }
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 📊 SECTION 1 : TABLEAU DE BORD FINANCIER REEL
                  const Text("📊 Performances Financières (Réel)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          color: Colors.green.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Text("Chiffre d'Affaires", style: TextStyle(fontSize: 13, color: Colors.grey)),
                                const SizedBox(height: 5),
                                Text("$chiffreAffaires MRU", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Card(
                          color: Colors.blue.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Text("Commandes Livrées", style: TextStyle(fontSize: 13, color: Colors.grey)),
                                const SizedBox(height: 5),
                                Text("$totalCommandes", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 15),

                  // 🤖 SECTION 2 : ZONE CONSULTANT DIRECTEUR IA (GEMINI)
                  Card(
                    color: Colors.purple.shade50,
                    shape: RoundedRectangleBorder(side: BorderSide(color: Colors.purple.shade200), borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.auto_awesome, color: Colors.purple),
                              SizedBox(width: 8),
                              Text("Rapport Stratégique Directeur IA", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.purple)),
                            ],
                          ),
                          const Divider(),
                          Text(_rapportIA, style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87)),
                          const SizedBox(height: 15),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isAnalysing ? null : () async {
                                setState(() => _isAnalysing = true);
                                String rapport = await _iaService.genererRapportStrategique(
                                  chiffreAffaires: chiffreAffaires,
                                  totalCommandes: totalCommandes,
                                  listePlatsVendus: platsVendus,
                                );
                                setState(() {
                                  _rapportIA = rapport;
                                  _isAnalysing = false;
                                });
                              },
                              icon: _isAnalysing 
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.analytics, color: Colors.white),
                              label: Text(_isAnalysing ? "Analyse en cours..." : "Lancer l'Analyse IA", style: const TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ➕ SECTION 3 : AJOUT DE PLAT (WHITE-LABEL GESTION)
                  const Text("➕ Ajouter un nouveau plat au Menu", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: _nomPlatController,
                            decoration: const InputDecoration(labelText: "Nom du plat", border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _prixPlatController,
                            decoration: const InputDecoration(labelText: "Prix en MRU", border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          
                          // Sélecteur d'image avec aperçu
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _choisirImage,
                                icon: const Icon(Icons.image),
                                label: const Text("Upload Image"),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade700),
                              ),
                              _imageSelectionnee != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(_imageSelectionnee!, height: 50, width: 50, fit: BoxFit.cover),
                                    )
                                  : const Text("Aucune image", style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          const Divider(),
                          _isUploading
                              ? const CircularProgressIndicator()
                              : SizedBox(
                                  width: double.infinity,
                                  height: 45,
                                  child: ElevatedButton(
                                    onPressed: _ajouterNouveauPlat,
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                    child: const Text("Enregistrer le plat", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // 📋 SECTION 4 : RETIRER / SUPPRIMER DES PLATS EXISTANTS
                  const Text("📋 Gestion du Menu Actuel", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: _db.collection('menu').orderBy('date_creation', descending: true).snapshots(),
                    builder: (context, menuSnapshot) {
                      if (!menuSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                      if (menuSnapshot.data!.docs.isEmpty) return const Text("Le menu est vide.");

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: menuSnapshot.data!.docs.length,
                        itemBuilder: (context, idx) {
                          var document = menuSnapshot.data!.docs[idx];
                          Map<String, dynamic> plat = document.data() as Map<String, dynamic>;
                          bool dispo = plat['disponible'] ?? true;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: Image.network(plat['image'], width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.fastfood)),
                              title: Text(plat['nom'], style: TextStyle(decoration: dispo ? TextDecoration.none : TextDecoration.lineThrough, fontWeight: FontWeight.bold)),
                              subtitle: Text("${plat['prix']} MRU"),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Masquer/Retirer temporairement du menu
                                  IconButton(
                                    icon: Icon(dispo ? Icons.visibility : Icons.visibility_off, color: dispo ? Colors.blue : Colors.orange),
                                    onPressed: () => _changerDisponibilite(document.id, dispo),
                                    tooltip: dispo ? "Retirer du menu" : "Afficher sur le menu",
                                  ),
                                  // Supprimer définitivement
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _supprimerPlat(document.id),
                                    tooltip: "Supprimer",
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  const Center(child: DeveloperContactButton()),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}