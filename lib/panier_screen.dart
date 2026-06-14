import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'constants.dart';

class PanierScreen extends StatefulWidget {
  final List<Map<String, dynamic>> articlesPanier;
  final int totalCommande;

  const PanierScreen({
    super.key, 
    required this.articlesPanier, 
    required this.totalCommande
  });

  @override
  State<PanierScreen> createState() => _PanierScreenState();
}

class _PanierScreenState extends State<PanierScreen> {
  final _nomController = TextEditingController();
  final _phoneController = TextEditingController();
  final _reperesController = TextEditingController();
  
  String _quartierSelectionne = "Tevragh Zeina";
  final List<String> _quartiersNouakchott = [
    "Tevragh Zeina",
    "Ksar",
    "Sebkha",
    "El Mina",
    "Dar Naim",
    "Arafat",
    "Toujouonine",
    "Riyad",
    "Teyarett"
  ];

  bool _isSending = false;

  Future<void> _validerEtEnvoyerCommande() async {
    if (_nomController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.redAccent, content: Text("Veuillez remplir votre nom et numéro de téléphone.")),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      // 1. Transformation des articles en texte unifié pour la cuisine et le livreur
      String detailsPlats = widget.articlesPanier.map((item) => "${item['quantite']}x ${item['nom']}").join(", ");

      // 2. Envoi sur Firestore avec les champs standardisés
      await FirebaseFirestore.instance.collection('commandes').add({
        'client': _nomController.text.trim(),
        'phone': _phoneController.text.trim(),
        'adresse': "$_quartierSelectionne - ${_reperesController.text.trim().isEmpty ? "Aucun repère fourni" : _reperesController.text.trim()}",
        'plats': detailsPlats,
        'total': widget.totalCommande,
        'statut': 'en_attente', 
        'date_commande': FieldValue.serverTimestamp(),
        'type_paiement': 'Application',
        'ref_transaction': 'En attente',
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF14161D),
            title: const Text("🔥 Commande Envoyée !", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
            content: const Text("Votre commande a été transmise à la caisse. Suivez son statut depuis votre espace.", style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text("Parfait", style: TextStyle(color: Color(0xFF2196F3))),
              )
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.redAccent, content: Text("Erreur lors de l'envoi de la commande.")),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A0F),
      appBar: AppBar(
        title: const Text("Finaliser ma Commande", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF14161D),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("📋 RÉSUMÉ DU PANIER", style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF14161D), borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  ...widget.articlesPanier.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${item['quantite']}x ${item['nom']}", style: const TextStyle(fontSize: 15)),
                        Text("${item['prix'] * item['quantite']} MRU", style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  )),
                  const Divider(color: Colors.white12, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.amber)),
                      Text("${widget.totalCommande} MRU", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.amber)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text("📍 INFORMATIONS DE LIVRAISON", style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 12),
            TextField(
              controller: _nomController,
              style: const TextStyle(color: Colors.white),
              decoration: _buildInputDecoration("Votre nom complet", Icons.person_outline),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: _buildInputDecoration("Numéro de téléphone (WhatsApp/Appel)", Icons.phone_android),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF14161D), borderRadius: BorderRadius.circular(16)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _quartierSelectionne,
                  dropdownColor: const Color(0xFF14161D),
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2196F3)),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  onChanged: (String? nouveauQuartier) {
                    if (nouveauQuartier != null) {
                      setState(() => _quartierSelectionne = nouveauQuartier);
                    }
                  },
                  items: _quartiersNouakchott.map<DropdownMenuItem<String>>((String quartier) {
                    return DropdownMenuItem<String>(
                      value: quartier,
                      child: Text(quartier),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reperesController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white),
              decoration: _buildInputDecoration("Points de repère (ex: À côté de la mosquée, face boutique)", Icons.map_outlined),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSending ? null : _validerEtEnvoyerCommande,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSending 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Confirmer la Commande 🚀", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF2196F3)),
      filled: true,
      fillColor: const Color(0xFF14161D),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF2196F3), width: 1.5)),
    );
  }
}