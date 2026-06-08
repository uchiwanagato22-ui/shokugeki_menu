import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'constants.dart';

class ClientCartScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;

  const ClientCartScreen({super.key, required this.cartItems});

  @override
  State<ClientCartScreen> createState() => _ClientCartScreenState();
}

class _ClientCartScreenState extends State<ClientCartScreen> {
  String _paymentMethod = "Cash"; 
  final TextEditingController _transactionController = TextEditingController();
  final TextEditingController _addressDetailsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int get _subtotal {
    return widget.cartItems.fold(0, (sum, item) => sum + (item["prix"] * item["quantite"] as int));
  }
  
  int get _deliveryFee => 50; // Livraison Nouakchott fixe
  int get _total => _subtotal + _deliveryFee;

  @override
  void dispose() {
    _transactionController.dispose();
    _addressDetailsController.dispose();
    super.dispose();
  }

  void _passerCommande() async {
    if (!_formKey.currentState!.validate()) return;

    final User? currentUser = FirebaseAuth.instance.currentUser;
    String clientNom = "Client Anonyme";
    String clientPhone = "Non renseigné";

    // Récupération des infos réelles du profil inscrit
    if (currentUser != null) {
      var userDoc = await FirebaseFirestore.instance.collection('utilisateurs').doc(currentUser.uid).get();
      if (userDoc.exists) {
        clientNom = userDoc.data()?['nom'] ?? clientNom;
        clientPhone = userDoc.data()?['telephone'] ?? clientPhone;
      }
    }

    try {
      await FirebaseFirestore.instance.collection('commandes').add({
        'client': clientNom,
        'phone': clientPhone,
        'plats': widget.cartItems.map((item) => "${item['quantite']}x ${item['nom']}").join(", "),
        'total': _total,
        'type_paiement': _paymentMethod,
        'ref_transaction': _paymentMethod == "Bankily" || _paymentMethod == "Masrvi" ? _transactionController.text.trim() : '-',
        'statut': 'En en attente de validation',
        'adresse': _addressDetailsController.text.trim(),
        'date_commande': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Commande bien enregistrée ! En attente de validation par la caisse... 🚀"), backgroundColor: Colors.green),
        );
        setState(() {
          widget.cartItems.clear(); 
        });
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur de base de données : ${e.toString()} ❌"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("MON PANIER", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: widget.cartItems.isEmpty
            ? const Center(child: Text("Votre panier est vide 🛒", style: TextStyle(fontSize: 16, color: Colors.grey)))
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: widget.cartItems.length,
                        itemBuilder: (context, index) {
                          final item = widget.cartItems[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              title: Text(item["nom"], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text("Quantité : ${item["quantite"]}"),
                              trailing: Text("${item["prix"] * item["quantite"]} MRU", style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    // Options de paiement
                    DropdownButtonFormField<String>(
                      value: _paymentMethod,
                      decoration: const InputDecoration(labelText: "Moyen de paiement"),
                      items: ["Cash", "Bankily", "Masrvi"].map((method) => DropdownMenuItem(value: method, child: Text(method))).toList(),
                      onChanged: (val) => setState(() => _paymentMethod = val!),
                    ),
                    if (_paymentMethod != "Cash") ...[
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _transactionController,
                        decoration: const InputDecoration(hintText: "Numéro de transaction / Référence Reçu", labelText: "ID Transaction"),
                        validator: (value) => value == null || value.trim().isEmpty ? "Obligatoire pour validation mobile" : null,
                      ),
                    ],
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _addressDetailsController,
                      decoration: const InputDecoration(hintText: "Ex: Tevragh Zeina, en face de la mosquée...", labelText: "Adresse précise"),
                      validator: (value) => value == null || value.trim().isEmpty ? "L'adresse est obligatoire" : null,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total (Livraison incluse) :", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text("$_total MRU", style: const TextStyle(fontSize: 20, color: kPrimaryColor, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _passerCommande,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kSecondaryColor,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Confirmer ma commande", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}