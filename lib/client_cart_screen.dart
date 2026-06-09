import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'branding_service.dart';
import 'constants.dart';

class ClientCartScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;

  const ClientCartScreen({super.key, required this.cartItems});

  @override
  State<ClientCartScreen> createState() => _ClientCartScreenState();
}

class _ClientCartScreenState extends State<ClientCartScreen> {
  final BrandingService _branding = BrandingService();
  String _paymentMethod = "Cash";
  final TextEditingController _transactionController = TextEditingController();
  final TextEditingController _addressDetailsController = TextEditingController();
  final TextEditingController _promoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _reduction = 0;
  bool _promoAppliquee = false;

  int _subtotal() {
    return widget.cartItems.fold(0, (total, item) => total + (item["prix"] * item["quantite"] as int));
  }

  void _modifierQuantite(int index, int delta) {
    final q = (widget.cartItems[index]['quantite'] as int) + delta;
    if (q <= 0) {
      widget.cartItems.removeAt(index);
    } else {
      widget.cartItems[index]['quantite'] = q;
    }
    setState(() {});
  }

  void _appliquerPromo(BrandingData brand) {
    if (_promoController.text.trim().toUpperCase() == brand.codePromo.toUpperCase()) {
      setState(() {
        _reduction = brand.reductionPromoMru;
        _promoAppliquee = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Code promo appliqué : -$_reduction MRU 🎉"), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Code promo invalide"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _transactionController.dispose();
    _addressDetailsController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  void _passerCommande(int deliveryFee) async {
    if (!_formKey.currentState!.validate()) return;

    final User? currentUser = FirebaseAuth.instance.currentUser;
    String clientNom = "Client Anonyme";
    String clientPhone = "Non renseigné";
    String? clientUid = currentUser?.uid;

    if (currentUser != null) {
      var userDoc = await FirebaseFirestore.instance.collection('utilisateurs').doc(currentUser.uid).get();
      if (userDoc.exists) {
        clientNom = userDoc.data()?['nom'] ?? currentUser.email ?? clientNom;
        clientPhone = userDoc.data()?['telephone'] ?? clientPhone;
      } else {
        clientNom = currentUser.email ?? clientNom;
      }
    }

    final total = (_subtotal() + deliveryFee - _reduction).clamp(0, 999999);

    try {
      await FirebaseFirestore.instance.collection('commandes').add({
        'client': clientNom,
        'phone': clientPhone,
        'client_uid': clientUid,
        'plats': widget.cartItems.map((item) => "${item['quantite']}x ${item['nom']}").join(", "),
        'total': total,
        'reduction_promo': _reduction,
        'type_paiement': _paymentMethod,
        'ref_transaction': _paymentMethod == "Bankily" || _paymentMethod == "Masrvi" ? _transactionController.text.trim() : '-',
        'statut': 'En attente de validation',
        'adresse': _addressDetailsController.text.trim(),
        'date_commande': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Commande enregistrée ! En attente de validation... 🚀"), backgroundColor: Colors.green),
        );
        widget.cartItems.clear();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur : ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BrandingData>(
      stream: _branding.watchBranding(),
      builder: (context, brandingSnap) {
        final brand = brandingSnap.data ?? BrandingData.defaults();
        final total = (_subtotal() + brand.fraisLivraison - _reduction).clamp(0, 999999);

        return Scaffold(
          backgroundColor: kBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text("MON PANIER", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
          ),
          body: Form(
            key: _formKey,
            child: widget.cartItems.isEmpty
                ? const Center(child: Text("Votre panier est vide 🛒", style: TextStyle(fontSize: 16, color: Colors.grey)))
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: widget.cartItems.length,
                            itemBuilder: (context, index) {
                              final item = widget.cartItems[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item["nom"], style: const TextStyle(fontWeight: FontWeight.bold)),
                                            Text("${item["prix"]} MRU / unité", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                                        onPressed: () => _modifierQuantite(index, -1),
                                      ),
                                      Text("${item["quantite"]}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline, color: kPrimaryColor),
                                        onPressed: () => _modifierQuantite(index, 1),
                                      ),
                                      Text(
                                        "${item["prix"] * item["quantite"]} MRU",
                                        style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _promoController,
                                decoration: const InputDecoration(hintText: "Code promo", labelText: "Promo"),
                                enabled: !_promoAppliquee,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _promoAppliquee ? null : () => _appliquerPromo(brand),
                              style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
                              child: const Text("OK", style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _paymentMethod,
                          decoration: const InputDecoration(labelText: "Moyen de paiement"),
                          items: ["Cash", "Bankily", "Masrvi"]
                              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                              .toList(),
                          onChanged: (val) => setState(() => _paymentMethod = val!),
                        ),
                        if (_paymentMethod != "Cash") ...[
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _transactionController,
                            decoration: const InputDecoration(labelText: "ID Transaction"),
                            validator: (v) => v == null || v.trim().isEmpty ? "Obligatoire" : null,
                          ),
                        ],
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _addressDetailsController,
                          decoration: InputDecoration(hintText: "Ex: ${brand.zone}...", labelText: "Adresse précise"),
                          validator: (v) => v == null || v.trim().isEmpty ? "Obligatoire" : null,
                        ),
                        const SizedBox(height: 12),
                        _lignePrix("Sous-total", "${_subtotal()} MRU"),
                        _lignePrix("Livraison", "${brand.fraisLivraison} MRU"),
                        if (_reduction > 0) _lignePrix("Réduction promo", "-$_reduction MRU", color: Colors.green),
                        const Divider(),
                        _lignePrix("Total", "$total MRU", bold: true),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _passerCommande(brand.fraisLivraison),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kSecondaryColor,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text("Confirmer ma commande", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _lignePrix(String label, String valeur, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 16 : 14)),
          Text(valeur, style: TextStyle(color: color ?? (bold ? kPrimaryColor : Colors.grey), fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 20 : 14)),
        ],
      ),
    );
  }
}
