import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'constants.dart';
import 'firestore_service.dart';
import 'widgets/plat_detail_sheet.dart';

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
  final FirestoreService _firestoreService = FirestoreService(); // Instance de ton service

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
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Notre Menu 🍽️",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Fait maison, livré rapidement",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                  if (widget.cartCount > 0)
                    IconButton(
                      icon: const Icon(Icons.shopping_cart, color: kPrimaryColor),
                      onPressed: widget.onOpenCart,
                    ),
                ],
              ),
            ),

            // --- BARRE DE CATÉGORIES ---
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: kDefaultCategories.length,
                itemBuilder: (context, index) {
                  String cat = kDefaultCategories[index];
                  bool isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) setState(() => _selectedCategory = cat);
                      },
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      backgroundColor: const Color(0xFF1A1A22),
                      selectedColor: kAccentColor,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // --- LISTE DES PLATS DYNAMIQUE (STREAMBUILDER) ---
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _firestoreService.obtenirLeMenu(), // Ton flux de données Firebase
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text("Erreur de chargement du menu ❌",
                          style: TextStyle(color: Colors.red)),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: kPrimaryColor),
                    );
                  }

                  final tousLesPlats = snapshot.data ?? [];

                  // Filtrer les plats selon la catégorie sélectionnée ET leur disponibilité
                  final platsFiltres = tousLesPlats.where((plat) {
                    // Masquer le plat si le gérant l'a marqué comme indisponible
                    bool dispo = plat['disponible'] ?? true;
                    if (!dispo) return false;

                    if (_selectedCategory == "Tout") return true;
                    return plat['categorie'] == _selectedCategory;
                  }).toList();

                  if (platsFiltres.isEmpty) {
                    return const Center(
                      child: Text(
                        "Aucun plat disponible dans cette catégorie. 🍕",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    );
                  }

                  // Grille des plats
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: platsFiltres.length,
                    itemBuilder: (context, index) {
                      final plat = platsFiltres[index];
                      
                      // Vérification ultra sécurisée si l'image est une URL internet valide (Postimages, ImgBB, Unsplash...)
                      final String imageUrl = plat['image']?.toString().trim() ?? '';
                      final bool hasValidUrl = imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

                      return InkWell(
                        onTap: () {
                          // Ouvre la feuille de détails présente dans ton fichier plat_detail_sheet.dart
                          afficherDetailPlat(
                            context,
                            plat: plat,
                            onAjouter: () {
                              // Logique d'ajout au panier existante
                              final existingIndex = widget.cartItems.indexWhere((item) => item['id'] == plat['id']);
                              if (existingIndex >= 0) {
                                widget.cartItems[existingIndex]['quantite']++;
                              } else {
                                widget.cartItems.add({
                                  'id': plat['id'],
                                  'nom': plat['nom'],
                                  'prix': plat['prix'],
                                  'quantite': 1,
                                });
                              }
                              widget.onCartChanged();
                            },
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A22),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.03)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image du plat avec mise en cache ou Placeholder gratuit
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                  child: hasValidUrl
                                      ? CachedNetworkImage(
                                          imageUrl: imageUrl,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(
                                            color: const Color(0xFF2A2A32),
                                            child: const Center(
                                              child: CircularProgressIndicator(color: kPrimaryColor, strokeWidth: 2),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) => _placeholderImage(),
                                        )
                                      : _placeholderImage(),
                                ),
                              ),
                              
                              // Infos du plat
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      plat['nom'] ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "${plat['prix']} MRU",
                                          style: const TextStyle(
                                              color: kPrimaryColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: kSecondaryColor,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.add,
                                              color: Colors.white, size: 14),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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

  Widget _placeholderImage() {
    return Container(
      color: const Color(0xFF2A2A32),
      width: double.infinity,
      child: const Icon(Icons.fastfood, color: Colors.grey, size: 36),
    );
  }
}