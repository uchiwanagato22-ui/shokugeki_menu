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
                    "Notre Menu",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  if (widget.cartCount > 0)
                    IconButton(
                      icon: const Icon(Icons.shopping_cart, color: kPrimaryColor),
                      onPressed: widget.onOpenCart,
                    ),
                ],
              ),
            ),
            
            // --- LISTE DES PLATS DEPUIS FIRESTORE ---
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _firestoreService.streamMenu(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text("Aucun plat disponible pour le moment.", style: TextStyle(color: Colors.grey)),
                    );
                  }

                  final plats = snapshot.data!;
                  // À intégrer dans le ListView.builder de client_menu_screen.dart
return ListView.builder(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  itemCount: plats.length,
  itemBuilder: (context, index) {
    final plat = plats[index];
    // Filtre de catégorie basique
    if (_selectedCategory != "Tout" && plat['categorie'] != _selectedCategory) {
      return const SizedBox.shrink();
    }

    return Card(
      color: kSurfaceColor,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        // Rendre toute la ligne cliquable pour ouvrir la feuille de détails !
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => PlatDetailSheet(
              plat: plat,
              onAjoute: (platAjoute) {
                widget.cartItems.add(platAjoute);
                widget.onCartChanged();
              },
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image du plat
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: plat['image'] != null
                    ? CachedNetworkImage(
                        imageUrl: plat['image'],
                        width: 80,
                        height: 80,
                        fit: cover,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        errorWidget: (context, url, error) => _placeholderImage(),
                      )
                    : _placeholderImage(),
              ),
              const SizedBox(width: 16),
              // Détails textuels
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plat['nom'] ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
              // Le Bouton d'action Plus devient enfin actif !
              IconButton(
                icon: const Icon(Icons.add_circle, color: kPrimaryColor, size: 30),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => PlatDetailSheet(
                      plat: plat,
                      onAjoute: (platAjoute) {
                        widget.cartItems.add(platAjoute);
                        widget.onCartChanged();
                      },
                    ),
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  },
);

  Widget _placeholderImage() {
    return Container(
      color: const Color(0xFF2A2A32),
      width: 100,
      height: 100,
      child: const Icon(Icons.fastfood, color: Colors.grey, size: 36),
    );
  }
}