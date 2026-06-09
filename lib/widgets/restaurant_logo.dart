import 'package:flutter/material.dart';
import '../restaurant_config.dart';

class RestaurantLogo extends StatelessWidget {
  final double size;
  final bool rounded;

  const RestaurantLogo({super.key, this.size = 80, this.rounded = true});

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      RestaurantConfig.logoAsset,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Icon(
        Icons.restaurant_menu,
        size: size * 0.7,
        color: RestaurantConfig.primaryColor,
      ),
    );

    if (!rounded) return image;

    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.2),
      child: image,
    );
  }
}
