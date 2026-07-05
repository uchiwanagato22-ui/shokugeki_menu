import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'constants.dart';
import 'firestore_service.dart';
import 'menu_rating_service.dart';
import 'widgets/plat_detail_sheet.dart';
import 'widgets/rating_stars_badge.dart'; 

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

  // États pour les animations tactiles au clic
  int? _pressedButtonIndex;
  int? _pressedRecommendIndex;
  String? _pressedCategoryName;

  Widget _placeholderImage() {
    return Container(
      color: const Color(0xFF161928),
      child: const Center(
        child: Icon(Icons.fastfood, color: Colors.grey, size: 40),
      ),
    );
  }

  void _ajouterAuPanierDirect(Map<String, dynamic> plat) {
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
    
    widget.onCartChanged();

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: kSuccessColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "🔥 ${plat['nom']} ajouté !",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF101323),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      backgroundColor: const Color(0xFF07080E), // Fond Cyber OLED profond
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- EN-TÊTE PREMIUM ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kAppName.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.w900, 
                      color: Colors.white, 
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Découvrez le meilleur de notre cuisine",
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                  ),
                ],
              ),
            ),

            // --- BARRE DES CATÉGORIES ANIMÉE (dynamique, propre à chaque restaurant) ---
            // Avant : liste figée (kDefaultCategories) pensée pour un fast-food.
            // Un restaurant italien, japonais ou un café n'a pas les mêmes catégories.
            // Maintenant : les catégories viennent directement des plats du menu de
            // CE restaurant (celles que le directeur a lui-même créées), donc chaque
            // resto voit ses propres catégories, automatiquement, sans rien coder.
            SizedBox(
              height: 46,
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _firestoreService.obtenirMenuTempsReel(),
                builder: (context, catSnapshot) {
                  final categories = <String>['Tout'];
                  if (catSnapshot.hasData) {
                    final vues = <String>{};
                    for (final plat in catSnapshot.data!) {
                      final cat = (plat['categorie']?.toString() ?? '').trim();
                      if (cat.isNotEmpty && vues.add(cat)) categories.add(cat);
                    }
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: categories.length,
                    itemBuilder: (context, i) {
                      final cat = categories[i];
                      final isSelected = _selectedCategory == cat;
                      final isPressed = _pressedCategoryName == cat;

                      return GestureDetector(
                        onTapDown: (_) => setState(() => _pressedCategoryName = cat),
                        onTapCancel: () => setState(() => _pressedCategoryName = null),
                        onTapUp: (_) {
                          setState(() {
                            _selectedCategory = cat;
                            _pressedCategoryName = null;
                          });
                        },
                        child: AnimatedScale(
                          scale: isPressed ? 0.94 : 1.0,
                          duration: const Duration(milliseconds: 80),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            decoration: BoxDecoration(
                              color: isSelected ? kPrimaryColor : const Color(0xFF101323),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? kPrimaryColor : const Color(0xFF1E233D),
                              ),
                              boxShadow: isSelected ? [
                                BoxShadow(
                                  color: kPrimaryColor.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ] : [],
                            ),
                            child: Center(
                              child: Text(
                                cat,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // --- STREAM PRINCIPAL DE FIRESTORE ---
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _firestoreService.obtenirMenuTempsReel(), // Ton flux original
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text("Aucun plat disponible pour le moment.", style: TextStyle(color: Colors.grey)),
                    );
                  }

                  // 🛠️ CORRECTION : Suppression stricte des doublons par ID unique
                  final uniquePlatsIds = <String>{};
                  final tousPlatsUniques = <Map<String, dynamic>>[];

                  for (var p in snapshot.data!) {
                    final id = p['id']?.toString() ?? '';
                    if (id.isNotEmpty && !uniquePlatsIds.contains(id)) {
                      uniquePlatsIds.add(id);
                      tousPlatsUniques.add(p);
                    }
                  }

                  // Filtrage par catégorie sélectionnée
                  final platsFilgres = tousPlatsUniques.where((p) {
                    final disponible = p['disponible'] ?? true;
                    if (_selectedCategory == "Tout") return disponible;
                    return (p['categorie'] == _selectedCategory) && disponible;
                  }).toList();

                  // Création d'une liste de "Recommandations" (les 3 premiers plats dispos)
                  final platsRecommandes = tousPlatsUniques.take(3).toList();

                  return CustomScrollView(
                    slivers: [
                      // --- NOUVEAU : HORIZONTAL MEILLEURS PLATS (Uniquement sur l'onglet 'Tout') ---
                      if (_selectedCategory == "Tout" && platsRecommandes.isNotEmpty) ...[
                        const SliverToBoxPadding(
                          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: Text(
                            "⭐ LES MEILLEURS PLATS",
                            style: TextStyle(color: kAccentColor, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 150,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: platsRecommandes.length,
                              itemBuilder: (context, rIndex) {
                                final platR = platsRecommandes[rIndex];
                                final hasImg = platR['image'] != null && platR['image'].toString().isNotEmpty;
                                final isPressedR = _pressedRecommendIndex == rIndex;

                                return GestureDetector(
                                  onTapDown: (_) => setState(() => _pressedRecommendIndex = rIndex),
                                  onTapCancel: () => setState(() => _pressedRecommendIndex = null),
                                  onTapUp: (_) {
                                    setState(() => _pressedRecommendIndex = null);
                                    afficherDetailPlat(context, plat: platR, onAjouter: () => _ajouterAuPanierDirect(platR));
                                  },
                                  child: AnimatedScale(
                                    scale: isPressedR ? 0.96 : 1.0,
                                    duration: const Duration(milliseconds: 80),
                                    child: Container(
                                      width: 260,
                                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF101323),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: const Color(0xFF1E233D)),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 100,
                                            height: double.infinity,
                                            child: hasImg 
                                                ? CachedNetworkImage(imageUrl: platR['image'], fit: BoxFit.cover, errorWidget: (c, u, e) => _placeholderImage())
                                                : _placeholderImage(),
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.all(10),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(platR['nom'] ?? 'Plat Star', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                                                  const SizedBox(height: 6),
                                                  Text("${platR['prix']} MRU", style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.w900, fontSize: 13)),
                                                  const SizedBox(height: 4),
                                                  RatingStarsBadge(
                                                    moyenne: MenuRatingService.moyenne(platR),
                                                    nombreAvis: MenuRatingService.nombreAvis(platR),
                                                    taille: 10,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SliverToBoxPadding(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                          child: Text(
                            "📋 TOUT LE MENU",
                            style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                        ),
                      ],

                      // --- LISTE PRINCIPALE DES PLATS ---
                      if (platsFilgres.isEmpty)
                        const SliverFillRemaining(
                          child: Center(child: Text("Aucun plat dans cette catégorie.", style: TextStyle(color: Colors.grey))),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final plat = platsFilgres[index];
                              final hasImage = plat['image'] != null && plat['image'].toString().isNotEmpty;
                              final isButtonPressed = _pressedButtonIndex == index;

                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF101323),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFF1E233D)),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () {
                                    afficherDetailPlat(context, plat: plat, onAjouter: () => _ajouterAuPanierDirect(plat));
                                  },
                                  splashColor: kPrimaryColor.withOpacity(0.08),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Stack(
                                        children: [
                                          AspectRatio(
                                            aspectRatio: 16 / 9,
                                            child: hasImage
                                                ? CachedNetworkImage(
                                                    imageUrl: plat['image'],
                                                    fit: BoxFit.cover,
                                                    placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: kPrimaryColor)),
                                                    errorWidget: (context, url, error) => _placeholderImage(),
                                                  )
                                                : _placeholderImage(),
                                          ),
                                          Positioned(
                                            left: 10,
                                            bottom: 10,
                                            child: RatingStarsBadge(
                                              moyenne: MenuRatingService.moyenne(plat),
                                              nombreAvis: MenuRatingService.nombreAvis(plat),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    plat['nom'] ?? 'Plat sans nom',
                                                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    "${plat['prix']} MRU",
                                                    style: const TextStyle(color: kAccentColor, fontWeight: FontWeight.w900, fontSize: 15),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            
                                            // Bouton Ajouter tactile rétractable
                                            GestureDetector(
                                              onTapDown: (_) => setState(() => _pressedButtonIndex = index),
                                              onTapCancel: () => setState(() => _pressedButtonIndex = null),
                                              onTapUp: (_) {
                                                setState(() => _pressedButtonIndex = null);
                                                _ajouterAuPanierDirect(plat);
                                              },
                                              child: AnimatedScale(
                                                scale: isButtonPressed ? 0.90 : 1.0,
                                                duration: const Duration(milliseconds: 70),
                                                child: AnimatedContainer(
                                                  duration: const Duration(milliseconds: 100),
                                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                                  decoration: BoxDecoration(
                                                    color: kPrimaryColor,
                                                    borderRadius: BorderRadius.circular(12),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: kPrimaryColor.withOpacity(0.25),
                                                        blurRadius: 6,
                                                        offset: const Offset(0, 2),
                                                      )
                                                    ],
                                                  ),
                                                  child: Row(
                                                    children: const [
                                                      Icon(Icons.add_shopping_cart, size: 15, color: Colors.white),
                                                      SizedBox(width: 6),
                                                      Text(
                                                        "Ajouter",
                                                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.white),
                                                      ),
                                                    ],
                                                  ),
                                                ),
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
                            childCount: platsFilgres.length,
                          ),
                        ),
                    ],
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

// Petit widget utilitaire interne pour ajouter des paddings aux éléments de la CustomScrollView
class SliverToBoxPadding extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final Widget child;
  const SliverToBoxPadding({super.key, required this.padding, required this.child});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(child: Padding(padding: padding, child: child));
  }
}