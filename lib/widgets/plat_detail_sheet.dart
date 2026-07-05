import 'package:flutter/material.dart';
import '../constants.dart';

void afficherDetailPlat(
  BuildContext context, {
  required Map<String, dynamic> plat,
  required VoidCallback onAjouter,
}) {
  bool isPressed = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF07080E), // Fond OLED identique au reste de l'app
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (ctx) {
      // Sécurité sur la récupération de l'image
      final hasImage = plat['image'] != null && plat['image'].toString().isNotEmpty;
      final nomPlat = plat['nom'] ?? 'Plat';
      final prixPlat = plat['prix'] != null ? "${plat['prix']} MRU" : "0 MRU";
      final categorie = plat['categorie'];
      final description = plat['description'];
      
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Petite barre supérieure de la bottom sheet
                Center(
                  child: Container(
                    width: 45,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E233D), 
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Gestion de l'image du plat
                if (hasImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      plat['image'],
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    ),
                  )
                else
                  _placeholder(),
                const SizedBox(height: 20),
                
                // Nom du plat
                Text(
                  nomPlat,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                ),
                const SizedBox(height: 6),
                
                // Prix du plat
                Text(
                  prixPlat,
                  style: const TextStyle(fontSize: 20, color: kPrimaryColor, fontWeight: FontWeight.w900),
                ),
                
                // Badge Catégorie
                if (categorie != null && categorie.toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(categorie, style: const TextStyle(fontSize: 12, color: kPrimaryColor, fontWeight: FontWeight.bold)),
                    backgroundColor: kPrimaryColor.withOpacity(0.12),
                    side: const BorderSide(color: Color(0xFF1E233D)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ],
                
                // Description du plat
                if (description != null && description.toString().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    description,
                    style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14, height: 1.6),
                  ),
                ],
                const SizedBox(height: 24),
                
                // Bouton d'action avec retour haptique visuel (Scale)
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTapDown: (_) => setSheetState(() => isPressed = true),
                    onTapCancel: () => setSheetState(() => isPressed = false),
                    onTapUp: (_) {
                      setSheetState(() => isPressed = false);
                      Navigator.pop(ctx); // Ferme la fiche
                      onAjouter();        // Déclenche l'action d'ajout au panier
                    },
                    child: AnimatedScale(
                      scale: isPressed ? 0.96 : 1.0,
                      duration: const Duration(milliseconds: 80),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: kPrimaryColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: kPrimaryColor.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "Ajouter au panier",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      );
    },
  );
}

Widget _placeholder() {
  return Container(
    height: 180,
    width: double.infinity,
    decoration: BoxDecoration(
      color: const Color(0xFF101323), 
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFF1E233D)),
    ),
    child: const Icon(Icons.restaurant_menu_rounded, size: 48, color: Colors.grey),
  );
}