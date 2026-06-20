import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/developer_contact_button.dart';

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

  String? _zoneSelectionnee;
  double _fraisLivraison = 0.0;
  String _modePaiement =
      "A la livraison"; // Options : "A la livraison", "Bankily / Masrvi"

  final _reperesController = TextEditingController();
  bool _isLocating = false;
  bool _isSubmitting = false;

  double _latitude = 0.0;
  double _longitude = 0.0;
  bool _gpsCapture = false;

  @override
  void initState() {
    super.initState();
    _syncCartItemsFromWidget();
    _chargerReperesFavoris();
  }

  void _syncCartItemsFromWidget() {
    if (widget.cartItems != null) {
      _articlesPanier = List<Map<String, dynamic>>.from(widget.cartItems!);
    } else {
      _articlesPanier = [];
    }
  }

  @override
  void didUpdateWidget(covariant ClientCartScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cartItems != widget.cartItems) {
      setState(() {
        _syncCartItemsFromWidget();
      });
    }
  }

  // Charge automatiquement les repères favoris du client pour lui faire gagner du temps
  Future<void> _chargerReperesFavoris() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc =
          await _db.collection('clients').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['reperes_favoris'] != null &&
            data['reperes_favoris'].toString().isNotEmpty) {
          setState(() {
            _reperesController.text = data['reperes_favoris'];
          });
        }
      }
    }
  }

  // Calcul du sous-total des articles
  double get _sousTotal {
    return _articlesPanier.fold(
        0, (sum, item) => sum + (item['prix'] * item['quantite']));
  }

  // Capturer la position GPS exacte du client
  Future<void> _capturerPositionGPS() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text("Les permissions GPS sont définitivement refusées.")),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _gpsCapture = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Position GPS capturée avec succès ! 🎯")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur de géolocalisation : ${e.toString()}")),
      );
    } finally {
      setState(() => _isLocating = false);
    }
  }

  // Envoyer la commande à Firestore
  Future<void> _validerCommande() async {
    if (_zoneSelectionnee == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Veuillez choisir votre quartier pour la livraison.")));
      return;
    }
    if (_reperesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              "Veuillez indiquer un repère précis (ex: Près de la Mosquée verte).")));
      return;
    }
    if (!_gpsCapture) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              "Veuillez cliquer sur le bouton GPS pour localiser votre adresse.")));
      return;
    }

    setState(() => _isSubmitting = true);
    User? user = _auth.currentUser;

    try {
      // 1. On récupère les infos de contact du client
      String nomClient = "Client Anonyme";
      String telClient = "Non renseigné";

      if (user != null) {
        DocumentSnapshot clientDoc =
            await _db.collection('clients').doc(user.uid).get();
        if (clientDoc.exists) {
          nomClient = clientDoc.get('nom') ?? "Client";
          telClient = clientDoc.get('telephone') ?? "";
        }

        // Mettre à jour les repères favoris du client pour sa prochaine commande
        await _db.collection('clients').doc(user.uid).update({
          'reperes_favoris': _reperesController.text.trim(),
        });
      }

      // 2. On crée le document de la commande avec le statut initial en minuscule
      await _db.collection('commandes').add({
        'client_id': user?.uid ?? 'invite',
        'client_nom': nomClient,
        'client_telephone': telClient,
        'articles': _articlesPanier,
        'sous_total': _sousTotal,
        'frais_livraison': _fraisLivraison,
        'total': _sousTotal + _fraisLivraison,
        'quartier': _zoneSelectionnee,
        'reperes_adresse': _reperesController.text.trim(),
        'latitude': _latitude,
        'longitude': _longitude,
        'mode_paiement': _modePaiement,
        'statut': 'en_attente', // Géré par le caissier au niveau 3
        'date_commande': FieldValue.serverTimestamp(),
      });

      // 3. Succès et nettoyage
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("Commande Envoyée ! 🎉"),
          content: const Text(
              "Votre commande a bien été reçue par le caissier. Suivez votre notification de confirmation."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Ferme le dialogue
                Navigator.pop(context); // Retour à l'accueil
              },
              child: const Text("Super"),
            )
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Erreur lors de la validation : ${e.toString()}")),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalGeneral = _sousTotal + _fraisLivraison;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mon Panier Shokugeki"),
        backgroundColor: Colors.deepOrange,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Liste des articles
            Expanded(
              flex: 2,
              child: ListView.builder(
                itemCount: _articlesPanier.length,
                itemBuilder: (context, index) {
                  final item = _articlesPanier[index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: ListTile(
                      title: Text(item['nom'],
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle:
                          Text("${item['prix']} MRU x ${item['quantite']}"),
                      trailing: Text(
                        "${item['prix'] * item['quantite']} MRU",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Formulaire de Livraison et Paiement
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12, blurRadius: 10, spreadRadius: 2)
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("1. Options de Livraison",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),

                      // Sélection du Quartier
                      DropdownButtonFormField<String>(
                        value: _zoneSelectionnee,
                        hint: const Text("Sélectionnez votre quartier"),
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 12)),
                        items: _zonesLivraison.keys.map((String zone) {
                          return DropdownMenuItem<String>(
                            value: zone,
                            child:
                                Text("$zone (+${_zonesLivraison[zone]} MRU)"),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _zoneSelectionnee = value;
                            _fraisLivraison = _zonesLivraison[value] ?? 0.0;
                          });
                        },
                      ),
                      const SizedBox(height: 15),

                      // Repères Textuels de l'adresse
                      TextField(
                        controller: _reperesController,
                        decoration: const InputDecoration(
                          labelText:
                              "Repères précis (Mosquée, école, couleur porte...)",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_city),
                        ),
                        maxLength: 150,
                      ),
                      const SizedBox(height: 10),

                      // Bouton de capture GPS
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isLocating ? null : _capturerPositionGPS,
                          icon: Icon(
                              _gpsCapture
                                  ? Icons.gps_fixed
                                  : Icons.gps_not_fixed,
                              color: Colors.deepOrange),
                          label: Text(
                            _isLocating
                                ? "Localisation en cours..."
                                : (_gpsCapture
                                    ? "Position GPS Verrouillée ✓"
                                    : "Capturer ma position GPS exacte"),
                            style: const TextStyle(color: Colors.black87),
                          ),
                          style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color: _gpsCapture
                                      ? Colors.green
                                      : Colors.grey)),
                        ),
                      ),

                      const SizedBox(height: 20),
                      const Text("2. Mode de Paiement",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text("Espèces",
                                  style: TextStyle(fontSize: 13)),
                              value: "A la livraison",
                              groupValue: _modePaiement,
                              onChanged: (val) =>
                                  setState(() => _modePaiement = val!),
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text("Mobile Bank",
                                  style: TextStyle(fontSize: 13)),
                              value: "Bankily / Masrvi",
                              groupValue: _modePaiement,
                              onChanged: (val) =>
                                  setState(() => _modePaiement = val!),
                            ),
                          ),
                        ],
                      ),

                      const Divider(),

                      // Facture Finale
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Sous-total :"),
                          Text("$_sousTotal MRU"),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Livraison :"),
                          Text("+$_fraisLivraison MRU"),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("TOTAL À PAYER :",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange)),
                          Text("$totalGeneral MRU",
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange)),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Bouton de Validation final
                      _isSubmitting
                          ? const Center(child: CircularProgressIndicator())
                          : SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _validerCommande,
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepOrange),
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
