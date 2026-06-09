import 'package:flutter/material.dart';
import 'branding_service.dart';
import 'constants.dart';
import 'firestore_service.dart';
import 'widgets/plat_detail_sheet.dart';
import 'widgets/restaurant_logo.dart';

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
  final FirestoreService _firestore = FirestoreService();
  final BrandingService _branding = BrandingService();
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = "Tout";
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _ajouterAuPanier(Map<String, dynamic> plat) {
    final existing = widget.cartItems.indexWhere((item) => item['id'] == plat['id']);
    if (existing >= 0) {
      widget.cartItems[existing]['quantite'] = (widget.cartItems[existing]['quantite'] as int) + 1;
    } else {
      widget.cartItems.add({
        'id': plat['id'],
        'nom': plat['nom'],
        'prix': plat['prix'],
        'quantite': 1,
      });
    }
    widget.onCartChanged();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${plat['nom']} ajouté au panier"),
        duration: const Duration(seconds: 1),
        backgroundColor: kPrimaryColor,
      ),
    );
  }

  List<Map<String, dynamic>> _filtrerPlats(List<Map<String, dynamic>> plats) {
    var result = plats.where((p) => p['disponible'] == true).toList();
    if (_selectedCategory != "Tout") {
      result = result.where((p) => p['categorie'] == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((p) {
        return (p['nom'] as String).toLowerCase().contains(q) ||
            (p['description'] as String).toLowerCase().contains(q);
      }).toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BrandingData>(
      stream: _branding.watchBranding(),
      builder: (context, brandingSnap) {
        final brand = brandingSnap.data ?? BrandingData.defaults();
        return Scaffold(
          backgroundColor: kBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Row(
              children: [
                const RestaurantLogo(size: 36, rounded: true),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(brand.nom, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kSecondaryColor)),
                      Row(
                        children: [
                          Icon(Icons.location_on, color: kPrimaryColor, size: 14),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(brand.deliveryLocation, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_bag_outlined, color: kSecondaryColor, size: 28),
                    onPressed: widget.onOpenCart,
                  ),
                  if (widget.cartCount > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: kPrimaryColor, shape: BoxShape.circle),
                        child: Text('${widget.cartCount}',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _firestore.obtenirLeMenu(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
              }
              if (snapshot.hasError) {
                return const Center(child: Text("Impossible de charger le menu.", style: TextStyle(color: Colors.red)));
              }

              final allPlats = snapshot.data ?? [];
              final categories = ["Tout", ...allPlats.map((p) => p['categorie'] as String).toSet().toList()..sort()];
              final filteredPlats = _filtrerPlats(allPlats);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (brand.promoActive && brand.promoMessage.isNotEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [kPrimaryColor, kPrimaryColor.withValues(alpha: 0.8)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_offer, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(brand.promoMessage,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        decoration: const InputDecoration(
                          hintText: "De quoi avez-vous envie ?",
                          prefixIcon: Icon(Icons.search, color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                  ),
                  if (categories.length > 1)
                    SizedBox(
                      height: 50,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(left: 16),
                        children: categories.map((cat) {
                          final sel = _selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: ChoiceChip(
                              label: Text(cat),
                              selected: sel,
                              selectedColor: kPrimaryColor,
                              labelStyle: TextStyle(color: sel ? Colors.white : kSecondaryColor, fontWeight: FontWeight.bold),
                              onSelected: (_) => setState(() => _selectedCategory = cat),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(allPlats.isEmpty ? "Menu en préparation" : "Notre Menu",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kSecondaryColor)),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filteredPlats.isEmpty
                        ? Center(
                            child: Text(
                              allPlats.isEmpty ? "Le restaurant prépare son menu." : "Aucun plat trouvé.",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.72,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: filteredPlats.length,
                            itemBuilder: (context, index) => _buildPlatCard(filteredPlats[index]),
                          ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPlatCard(Map<String, dynamic> plat) {
    final hasImage = plat['image'].toString().isNotEmpty;
    return GestureDetector(
      onTap: () => afficherDetailPlat(context, plat: plat, onAjouter: () => _ajouterAuPanier(plat)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: hasImage
                    ? Image.network(plat['image'], fit: BoxFit.cover, width: double.infinity, errorBuilder: (_, __, ___) => _placeholder())
                    : _placeholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plat['nom'], maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${plat['prix']} MRU",
                          style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
                      GestureDetector(
                        onTap: () => _ajouterAuPanier(plat),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: kSecondaryColor, shape: BoxShape.circle),
                          child: const Icon(Icons.add, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFEEEEEE),
      child: const Icon(Icons.restaurant, color: Colors.grey, size: 40),
    );
  }
}
