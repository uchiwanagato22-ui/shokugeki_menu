import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'constants.dart';
import 'firestore_service.dart';
import 'widgets/plat_detail_sheet.dart'; // Importation exacte ajustée à ton dossier widgets/

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
  final FirestoreService _firestoreService = FirestoreService();

  Widget _placeholderImage() {
    return Container(
      color: const Color(0xFF2A2A32),
      width: 80,
      height: 80,
      child: const Icon(Icons.fastfood, color: Colors.grey, size: 36),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- EN-TÊTE DU MENU ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Notre Menu Shokugeki",
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.shopping_bag, color: kPrimaryColor),
                    onPressed: widget.onOpenCart,
                  ),
                ],
              ),
            ),

            // --- FILTRE DES CATÉGORIES ---
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: ["Tout", "Poulet", "Burgers", "Divers"].map((categorie) {
                  final isSelected = _selectedCategory == categorie;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(categorie),
                      selected: isSelected,
                      selectedColor: kPrimaryColor,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey),
                      backgroundColor: kSurfaceColor,
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedCategory = categorie;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),

            // --- LISTE DES PLATS DEPUIS FIRESTORE (COLLECTION MENU) ---
            Expanded(
              child: StreamBuilder<dynamic>(
                stream: _firestoreService.streamMenu(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text("Erreur de chargement du menu", style: TextStyle(color: Colors.red)),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: kPrimaryColor),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  // Filtrage selon la catégorie sélectionnée
                  final platsFiltres = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    if (_selectedCategory == "Tout") return true;
                    return data['categorie'] == _selectedCategory;
                  }).toList();

                  if (platsFiltres.isEmpty) {
                    return const Center(
                      child: Text("Aucun plat disponible", style: TextStyle(color: Colors.grey)),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: platsFiltres.length,
                    itemBuilder: (context, index) {
                      final doc = platsFiltres[index];
                      final plat = doc.data() as Map<String, dynamic>;
                      plat['id'] = doc.id; // Injecte l'ID du document Firebase

                      final imageUrl = plat['image']?.toString() ?? '';

                      return Card(
                        color: kSurfaceColor,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Image mise en cache
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: imageUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => _placeholderImage(),
                                        errorWidget: (context, url, error) => _placeholderImage(),
                                      )
                                    : _placeholderImage(),
                              ),
                              const SizedBox(width: 16),
                              // Informations textuelles
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      plat['nom'] ?? 'Plat sans nom',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      plat['description'] ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "${plat['prix']} MRU",
                                      style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              // Action : Appel direct de ta fonction globale afficherDetailPlat
                              IconButton(
                                icon: const Icon(Icons.add_circle, color: kPrimaryColor, size: 30),
                                onPressed: () {
                                  afficherDetailPlat(
                                    context,
                                    plat: plat,
                                    onAjouter: () {
                                      final itemDansPanier = {
                                        'id': plat['id'],
                                        'nom': plat['nom'],
                                        'prix': (plat['prix'] as num).toDouble(),
                                        'quantite': 1,
                                        'categorie': plat['categorie']
                                      };
                                      widget.cartItems.add(itemDansPanier);
                                      widget.onCartChanged();
                                    },
                                  );
                                },
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
          ],
        ),
      ),
    );
  }
}