import 'package:flutter/material.dart';
import 'constants.dart';

class ClientMenuScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final int cartCount;
  final VoidCallback onCartChanged;
  final VoidCallback onOpenCart;

  const ClientMenuScreen({
    super.key,
    required this.cartItems,
    required this.cartCount,
    required this.onCartChanged,
    required this.onOpenCart,
  });

  @override
  State<ClientMenuScreen> createState() => _ClientMenuScreenState();
}

class _ClientMenuScreenState extends State<ClientMenuScreen> {
  String _selectedCategory = "Tout";

  // Faux catalogue de plats en local pour tester l'UI avant Firebase
  final List<Map<String, dynamic>> _dummyPlats = [
    {
      "id": "p1",
      "nom": "Shokugeki Burger Max",
      "categorie": "Burgers",
      "prix": 250, // Prix en MRU
      "note": "4.9",
      "image":
          "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?q=80&w=500&auto=format&fit=crop"
    },
    {
      "id": "p2",
      "nom": "Pizza Feu Suprême",
      "categorie": "Pizzas",
      "prix": 350,
      "note": "4.8",
      "image":
          "https://images.unsplash.com/photo-1513104890138-7c749659a591?q=80&w=500&auto=format&fit=crop"
    },
    {
      "id": "p3",
      "nom": "Poulet Croustillant Shinra",
      "categorie": "Poulet",
      "prix": 280,
      "note": "4.7",
      "image":
          "https://images.unsplash.com/photo-1562967914-608f82629710?q=80&w=500&auto=format&fit=crop"
    },
    {
      "id": "p4",
      "nom": "Cocktail Shaker Glacé",
      "categorie": "Boissons",
      "prix": 120,
      "note": "4.5",
      "image":
          "https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?q=80&w=500&auto=format&fit=crop"
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Filtrer les plats selon la catégorie sélectionnée
    final filteredPlats = _selectedCategory == "Tout"
        ? _dummyPlats
        : _dummyPlats
            .where((p) => p["categorie"] == _selectedCategory)
            .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      // --- BARRE DU HAUT (Header) ---
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Livraison à",
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            Row(
              children: [
                Icon(Icons.location_on, color: kPrimaryColor, size: 16),
                const SizedBox(width: 4),
                const Text("Nouakchott, TVZ",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: kSecondaryColor)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined,
                color: kSecondaryColor, size: 28),
            onPressed: widget.onOpenCart,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- BARRE DE RECHERCHE ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5)),
                ],
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: "De quoi avez-vous envie aujourd'hui ?",
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),

          // --- HORIZONTAL CATEGORIES BAR ---
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 16),
              children: ["Tout", "Burgers", "Pizzas", "Poulet", "Boissons"]
                  .map((cat) {
                bool isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: kPrimaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : kSecondaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text("Le Menu Spécial",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kSecondaryColor)),
          ),
          const SizedBox(height: 12),

          // --- GRILLE DES PLATS ---
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: filteredPlats.length,
              itemBuilder: (context, index) {
                final plat = filteredPlats[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 5)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image du plat
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                          child: Image.network(
                            plat["image"],
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plat["nom"],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${plat["prix"]} MRU",
                                  style: const TextStyle(
                                      color: kPrimaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: kSecondaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add,
                                      color: Colors.white, size: 16),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
