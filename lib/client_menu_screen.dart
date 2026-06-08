import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'constants.dart';
import 'client_cart_screen.dart';
import 'chef_ia_screen.dart';
import 'client_orders_screen.dart'; // Importation du nouvel écran créé ci-dessous

class ClientMenuScreen extends StatefulWidget {
  const ClientMenuScreen({super.key});

  @override
  State<ClientMenuScreen> createState() => _ClientMenuScreenState();
}

class _ClientMenuScreenState extends State<ClientMenuScreen> {
  String _selectedCategory = "Tout";
  final List<Map<String, dynamic>> _userCart = [];
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  void _ajouterAuPanier(Map<String, dynamic> plat) {
    setState(() {
      int index = _userCart.indexWhere((item) => item["nom"] == plat["nom"]);
      if (index != -1) {
        _userCart[index]["quantite"]++;
      } else {
        _userCart.add({"nom": plat["nom"], "prix": plat["prix"], "quantite": 1});
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${plat["nom"]} ajouté au panier ! 🛒"), duration: const Duration(seconds: 1), backgroundColor: kPrimaryColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("SHOKUGEKI MENU", style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
        actions: [
          // 🆕 NOUVEAU : Bouton pour voir le suivi de ses commandes en direct
          IconButton(
            icon: const Icon(Icons.assignment, color: Colors.blue),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ClientOrdersScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: kSecondaryColor),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ClientCartScreen(cartItems: _userCart))),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kPrimaryColor,
        child: const Icon(Icons.support_agent, color: Colors.white),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChefIaScreen())),
      ),
      body: Column(
        children: [
          // Liste des catégories
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ["Tout", "Burgers", "Plats", "Boissons"].map((cat) {
                bool isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(color: isSelected ? kPrimaryColor : Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Text(cat, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                  ),
                );
              }).toList(),
            ),
          ),
          // Menu Dynamique Firestore
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.collection('menu').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
                var docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var plat = docs[index];
                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title: Text(plat['nom'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${plat['prix']} MRU"),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_shopping_cart, color: kPrimaryColor),
                          onPressed: () => _ajouterAuPanier({'nom': plat['nom'], 'prix': plat['prix']}),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}