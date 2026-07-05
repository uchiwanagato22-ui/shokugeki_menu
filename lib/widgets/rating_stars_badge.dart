import 'package:flutter/material.dart';
import '../constants.dart';

/// Petit badge "⭐ 4.5 (12)" à poser sur une carte de plat.
/// N'affiche rien si le plat n'a pas encore d'avis (nombreAvis == 0).
class RatingStarsBadge extends StatelessWidget {
  final double moyenne;
  final int nombreAvis;
  final double taille;

  const RatingStarsBadge({
    super.key,
    required this.moyenne,
    required this.nombreAvis,
    this.taille = 12,
  });

  @override
  Widget build(BuildContext context) {
    if (nombreAvis == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: kAccentColor, size: taille + 4),
          const SizedBox(width: 2),
          Text(
            moyenne.toStringAsFixed(1),
            style: TextStyle(
              color: Colors.white,
              fontSize: taille,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            ' ($nombreAvis)',
            style: TextStyle(color: Colors.white70, fontSize: taille - 1),
          ),
        ],
      ),
    );
  }
}
