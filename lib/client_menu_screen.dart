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
  final FirestoreService _firestoreService = FirestoreService();

  Widget _placeholderImage() {
    return Container(
      color: const Color(0xFF1E202C),
      child: const Center(
        child: Icon(Icons.fastfood, color: Colors.grey, size: 48),
      ),
    );
  }

  void _ajouterAuPanierDirect(Map<String, dynamic> plat) {
    // Vérifie si l'article existe déjà pour incrémenter la quantité
    final index = widget.cartItems.indexWhere((item) => item['id'] == plat['id']);
    
    if (index != -1) {
      widget.cartItems[index]['quantite'] = (widget.cartItems[index]['quantite'] as int) + 1;
    } else {
      widget.cartItems.add({
        'id': plat['id'],
        'nom': plat['nom'],
        'prix': (plat['prix'] as num).toDouble(),
        'quantite': 1,
        'categorie': plat['categorie']
      });
    }
    
    // Notifier le HomeScreen du changement
    widget.onCartChanged();

    // Petit feedback sonore visuel ultra propre
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: kSuccessColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "🔥 ${plat['nom']} ajouté au panier !",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: kSurfaceColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: "VOIR",
          textColor: kPrimaryColor,
          onPressed: widget.onOpenCart,
        ),
      ),
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
            // --- EN-TÊTE DU MENU CYBER ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kAppName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 22, 
                          fontWeight: FontWeight.w900, 
                          color: Colors.white, 
                          letterSpacing: 1.0
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Faites votre choix parmi nos délices",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // --- BARRE DES CATÉGORIES ---
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: kDefaultCategories.length,
                itemKind: null, // Évite les soucis sur certaines versions
                itemBuilder: (context, i) {
                  final cat = kDefaultCategories[i];
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: kPrimaryColor,
                      backgroundColor: kSurfaceColor,
                      onSelected: (val) {
                        if (val) setState(() => _selectedCategory = cat);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // --- STREAM DES PLATS FORMAT 16:9 ---
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _firestoreService.obtenirMenuTempsReel(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text("Aucun plat disponible pour le moment.", style: TextStyle(color: Colors.grey)),
                    );
                  }

                  // Filtrage par catégorie
                  final plats = snapshot.data!.where((p) {
                    if (_selectedCategory == "Tout") return p['disponible'] ?? true;
                    return (p['categorie'] == _selectedCategory) && (p['disponible'] ?? true);
                  }).toList();

                  if (plats.isEmpty) {
                    return const Center(
                      child: Text("Aucun plat dans cette catégorie.", style: TextStyle(color: Colors.grey)),
                    );
                  }

                  return ListView.builder(
                    itemCount: plats.length,
                    padding: const EdgeInsets.only(bottom: 80),
                    itemBuilder: (context, index) {
                      final plat = plats[index];
                      final hasImage = plat['image'] != null && plat['image'].toString().isNotEmpty;

                      return GestureDetector(
                        onTap: () {
                          // Permet quand même d'ouvrir les détails au clic sur la carte
                          afficherDetailPlat(
                            context,
                            plat: plat,
                            onAjouter: () => _ajouterAuPanierDirect(plat),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          decoration: BoxDecoration(
                            color: kSurfaceColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.03)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // FORMAT BANNÈRE PREMIUM IMAGE 16:9
                              AspectRatio(
                                aspectRatio: 16 / 9,
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                  child: hasImage
                                      ? CachedNetworkImage(
                                          imageUrl: plat['image'],
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => const Center(
                                            child: CircularProgressIndicator(color: kPrimaryColor),
                                          ),
                                          errorWidget: (context, url, error) => _placeholderImage(),
                                        )
                                      : _placeholderImage(),
                                ),
                              ),
                              
                              // DETAILS DU PLAT ET BOUTON ACTION
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            plat['nom'] ?? 'Plat sans nom',
                                            style: const TextStyle(
                                              fontSize: 18, 
                                              fontWeight: FontWeight.bold, 
                                              color: Colors.white
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "${plat['prix']} MRU",
                                            style: const TextStyle(
                                              color: kAccentColor, 
                                              fontWeight: FontWeight.w900, 
                                              fontSize: 16
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    
                                    // BOUTON AJOUT PANIER ULTRA FLUIDE
                                    ElevatedButton.icon(
                                      onPressed: () => _ajouterAuPanierDirect(plat),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: kPrimaryColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        elevation: 2,
                                      ),
                                      icon: const Icon(Icons.add_shopping_cart, size: 16),
                                      label: const Text(
                                        "Ajouter",
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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