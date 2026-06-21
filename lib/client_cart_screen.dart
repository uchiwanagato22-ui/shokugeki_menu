import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'widgets/developer_contact_button.dart';
import 'constants.dart';

class ClientCartScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? cartItems;

  const ClientCartScreen({Key? key, this.cartItems}) : super(key: key);

  @override
  State<ClientCartScreen> createState() => _ClientCartScreenState();
}

class _ClientCartScreenState extends State<ClientCartScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Liste de simulation du panier (sera connectée à ton State Management ou Singleton de gestion de panier)
  List<Map<String, dynamic>> _articlesPanier = [];

  // Configuration des zones de livraison de Nouakchott (facilement modifiable pour Dakar, Bamako, etc.)
  final Map<String, double> _zonesLivraison = {
    "Tevragh Zeina": 60.0,
    "Ksar": 50.0,
    "Arafat": 80.0,
    "Dar Naim": 90.0,
    "Sebkha": 70.0,
    "El Mina": 70.0,
  };

  String _zoneSelectionnee = "Tevragh Zeina";
  bool _isSubmitting = false;

  // Contrôleurs pour capturer les informations du client de manière dynamique
  final _nomController = TextEditingController();
  final _telController = TextEditingController();
  final _adresseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Si des éléments de panier sont passés en paramètre, on les initialise
    if (widget.cartItems != null) {
      _articlesPanier = widget.cartItems!;
    } else {
      // Simulation locale si aucun élément n'est transmis pour les tests UI
      _articlesPanier = [
        {
          "id": "p1",
          "nom": "Yassa au Poulet Suprême",
          "prix": 250.0,
          "quantite": 2,
          "categorie": "Poulet"
        },
        {
          "id": "p2",
          "nom": "Thieboudienne Penda Mbaye",
          "prix": 300.0,
          "quantite": 1,
          "categorie": "Divers"
        },
        {
          "id": "p3",
          "nom": "Burger Shokugeki Explosif",
          "prix": 180.0,
          "quantite": 1,
          "categorie": "Burgers"
        }
      ];
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _telController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  // Calcul dynamique du montant total des plats uniquement
  double _calculerTotal() {
    return _articlesPanier.fold(0.0, (total, item) {
      final prix = (item['prix'] ?? 0.0) as double;
      final qte = (item['quantite'] ?? 1) as int;
      return total + (prix * qte);
    });
  }

  // Logique métier critique : Envoi de la commande vers Firebase Firestore avec tracking GPS optionnel
  Future<void> _validerCommande() async {
    if (_articlesPanier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Votre panier est vide. Ajoutez des plats d'abord !"),
            backgroundColor: Colors.amber),
      );
      return;
    }

    if (_nomController.text.trim().isEmpty ||
        _telController.text.trim().isEmpty ||
        _adresseController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Veuillez remplir toutes les informations de livraison."),
            backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      double totalPlats = _calculerTotal();
      double fraisLivraison = _zonesLivraison[_zoneSelectionnee] ?? 0.0;

      // Initialisation par défaut des coordonnées GPS
      double lat = 0.0;
      double lng = 0.0;

      // Tentative de récupération géolocalisée (Non-bloquante si l'utilisateur refuse)
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          Position position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high);
          lat = position.latitude;
          lng = position.longitude;
        }
      } catch (geoError) {
        // En cas d'erreur ou de refus du GPS, l'application continue sans crash
        print("Échec de récupération GPS (utilisation du mode texte uniquement) : $geoError");
      }

      // Payload final à pousser vers Firestore
      await _db.collection('commandes').add({
        'clientId': _auth.currentUser?.uid ?? "invite_anonymous",
        'clientNom': _nomController.text.trim(),
        'clientTelephone': _telController.text.trim(),
        'articles': _articlesPanier,
        'statut': 'en_attente', // Statuts : en_attente -> en_preparation -> en_livraison -> livree
        'total': totalPlats + fraisLivraison,
        'zone': _zoneSelectionnee,
        'quartier': _zoneSelectionnee, 
        'adresse_reperes': _adresseController.text.trim(),
        'latitude': lat,
        'longitude': lng,
        'date_creation': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        // Effacer le panier local après confirmation de commande réussie
        setState(() {
          _articlesPanier.clear();
        });

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: kSurfaceColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 30),
                SizedBox(width: 10),
                Text("Succès !", style: TextStyle(color: Colors.white)),
              ],
            ),
            content: const Text(
              "Votre commande a été transmise avec succès à la cuisine de Shokugeki Menu. Suivez son statut en temps réel !",
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Ferme le dialogue
                  Navigator.pop(context); // Quitte l'écran de panier
                },
                child: const Text("Parfait",
                    style: TextStyle(
                        color: kPrimaryColor, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Une erreur est survenue lors de la validation : $e"),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // Suppression unitaire d'un plat du panier
  void _supprimerArticle(int index) {
    setState(() {
      _articlesPanier.removeAt(index);
    });
  }

  // Modification dynamique de la quantité d'un plat (+ ou -)
  void _modifierQuantite(int index, bool incrementer) {
    setState(() {
      int qteActuelle = _articlesPanier[index]['quantite'] ?? 1;
      if (incrementer) {
        _articlesPanier[index]['quantite'] = qteActuelle + 1;
      } else {
        if (qteActuelle > 1) {
          _articlesPanier[index]['quantite'] = qteActuelle - 1;
        } else {
          _supprimerArticle(index);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double totalPlats = _calculerTotal();
    double fraisLivraison = _zonesLivraison[_zoneSelectionnee] ?? 0.0;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text("Mon Panier Premium",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Section Haute : Liste déroulante des plats présents dans le panier actuel
            Expanded(
              flex: 4,
              child: _articlesPanier.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_outlined,
                              size: 80, color: Colors.grey.withOpacity(0.4)),
                          const SizedBox(height: 16),
                          const Text(
                            "Votre panier est désespérément vide...",
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                                fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: _articlesPanier.length,
                      itemBuilder: (context, index) {
                        final item = _articlesPanier[index];
                        final double prixPlat = (item['prix'] ?? 0.0) as double;
                        final int qtePlat = (item['quantite'] ?? 1) as int;

                        return Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: kSurfaceColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              )
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: kPrimaryColor.withOpacity(0.1),
                              child: const Icon(Icons.fastfood,
                                  color: kPrimaryColor),
                            ),
                            title: Text(
                              item['nom'] ?? 'Plat inconnu',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Text(
                                "$prixPlat MRU / unité",
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                            trailing: SizedBox(
                              width: 130,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // Bouton décrémenter
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline,
                                        color: Colors.grey),
                                    onPressed: () =>
                                        _modifierQuantite(index, false),
                                  ),
                                  Text(
                                    "$qtePlat",
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  // Bouton incrémenter
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline,
                                        color: kPrimaryColor),
                                    onPressed: () =>
                                        _modifierQuantite(index, true),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Section Basse : Formulaire de livraison intelligent et récapitulatif financier de la transaction
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: kSurfaceColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Informations de livraison",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Input Nom du destinataire
                      TextField(
                        controller: _nomController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Nom complet du destinataire",
                          labelStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(Icons.person, color: Colors.grey),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: kPrimaryColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Input Téléphone Mauritanie
                      TextField(
                        controller: _telController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Numéro de contact (Ex: 32652300)",
                          labelStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(Icons.phone, color: Colors.grey),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: kPrimaryColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Menu déroulant pour le choix des zones géographiques tarifées
                      DropdownButtonFormField<String>(
                        value: _zoneSelectionnee,
                        dropdownColor: kSurfaceColor,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Sélectionnez votre zone / Quartier",
                          labelStyle: const TextStyle(color: Colors.grey),
                          prefixIcon:
                              const Icon(Icons.map_outlined, color: Colors.grey),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: kPrimaryColor),
                          ),
                        ),
                        items: _zonesLivraison.keys.map((String zone) {
                          return DropdownMenuItem<String>(
                            value: zone,
                            child: Text(zone),
                          );
                        }).toList(),
                        onChanged: (String? valeurNouvelle) {
                          setState(() {
                            _zoneSelectionnee = valeurNouvelle!;
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // Input Repères textuels précis de l'adresse
                      TextField(
                        controller: _adresseController,
                        maxLines: 2,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Repères précis (Ex: En face de la pharmacie X, porte verte)",
                          labelStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(Icons.home_work_outlined,
                              color: Colors.grey),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: kPrimaryColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Facturation & Détail de la transaction financière
                      const Text(
                        "Détails de la facture",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Sous-total des plats :",
                              style: TextStyle(color: Colors.grey)),
                          Text("$totalPlats MRU",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Frais d'expédition programmée :",
                              style: TextStyle(color: Colors.grey)),
                          Text("$fraisLivraison MRU",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(color: Colors.white24, thickness: 1),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total Net à Régler (Cash) :",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          Text("${totalPlats + fraisLivraison} MRU",
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: kPrimaryColor)),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Bouton de Validation final
                      _isSubmitting
                          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                          : SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _validerCommande,
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: kPrimaryColor,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12))),
                                child: const Text("Confirmer et commander",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                      const SizedBox(height: 15),
                      const Center(child: DeveloperContactButton()),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}