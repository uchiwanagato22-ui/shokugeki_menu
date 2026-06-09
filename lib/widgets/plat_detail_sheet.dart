import 'package:flutter/material.dart';
import '../constants.dart';

void afficherDetailPlat(
  BuildContext context, {
  required Map<String, dynamic> plat,
  required VoidCallback onAjouter,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      final hasImage = plat['image'].toString().isNotEmpty;
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            if (hasImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  plat['image'],
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(),
                ),
              )
            else
              _placeholder(),
            const SizedBox(height: 16),
            Text(
              plat['nom'],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kSecondaryColor),
            ),
            const SizedBox(height: 6),
            Text(
              "${plat['prix']} MRU",
              style: const TextStyle(fontSize: 20, color: kPrimaryColor, fontWeight: FontWeight.bold),
            ),
            if (plat['categorie'] != null) ...[
              const SizedBox(height: 6),
              Chip(
                label: Text(plat['categorie'], style: const TextStyle(fontSize: 12)),
                backgroundColor: kPrimaryColor.withValues(alpha: 0.1),
                side: BorderSide.none,
              ),
            ],
            if (plat['description'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                plat['description'],
                style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  onAjouter();
                },
                icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                label: const Text("Ajouter au panier", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kSecondaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _placeholder() {
  return Container(
    height: 140,
    width: double.infinity,
    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
    child: const Icon(Icons.restaurant, size: 48, color: Colors.grey),
  );
}
