import 'package:flutter/material.dart';

enum StaffRole {
  caissier,
  cuisine,
  livreur,
  directeur,
}

extension StaffRoleLabel on StaffRole {
  String get label {
    switch (this) {
      case StaffRole.caissier:
        return 'Caissier';
      case StaffRole.cuisine:
        return 'Cuisine';
      case StaffRole.livreur:
        return 'Livreur';
      case StaffRole.directeur:
        return 'Directeur';
    }
  }

  String get firestoreValue {
    switch (this) {
      case StaffRole.caissier:
        return 'caissier';
      case StaffRole.cuisine:
        return 'cuisine';
      case StaffRole.livreur:
        return 'livreur';
      case StaffRole.directeur:
        return 'directeur';
    }
  }

}

StaffRole? staffRoleFromFirestore(String value) {
  for (final role in StaffRole.values) {
    if (role.firestoreValue == value) return role;
  }
  return null;
}

class RestaurantAppConfig {
  const RestaurantAppConfig({
    required this.restaurantId,
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    required this.phone,
    required this.address,
    required this.subscriptionActive,
    this.logoUrl,
    this.coverUrl,
    this.subscriptionMessage,
  });

  final String restaurantId;
  final String name;
  final Color primaryColor;
  final Color secondaryColor;
  final String phone;
  final String address;
  final bool subscriptionActive;
  final String? logoUrl;
  final String? coverUrl;
  final String? subscriptionMessage;

  factory RestaurantAppConfig.demo() {
    return const RestaurantAppConfig(
      restaurantId: 'shokugeki',
      name: 'Shokugeki Menu',
      primaryColor: Color(0xFFD92D20),
      secondaryColor: Color(0xFF111827),
      phone: '+33 0 00 00 00 00',
      address: 'Adresse du restaurant',
      subscriptionActive: true,
    );
  }

  factory RestaurantAppConfig.fromFirestore(
    Map<String, dynamic> data, {
    required String restaurantId,
  }) {
    return RestaurantAppConfig(
      restaurantId: restaurantId,
      name: (data['name'] ?? 'Restaurant').toString(),
      primaryColor: _readColor(data['primaryColor'], const Color(0xFFD92D20)),
      secondaryColor: _readColor(data['secondaryColor'], const Color(0xFF111827)),
      phone: (data['phone'] ?? '').toString(),
      address: (data['address'] ?? '').toString(),
      subscriptionActive: data['subscriptionActive'] == true,
      logoUrl: data['logoUrl']?.toString(),
      coverUrl: data['coverUrl']?.toString(),
      subscriptionMessage: data['subscriptionMessage']?.toString(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'restaurantId': restaurantId,
      'name': name,
      'primaryColor': _colorToHex(primaryColor),
      'secondaryColor': _colorToHex(secondaryColor),
      'phone': phone,
      'address': address,
      'subscriptionActive': subscriptionActive,
      'logoUrl': logoUrl,
      'coverUrl': coverUrl,
      'subscriptionMessage': subscriptionMessage,
    };
  }

  static Color _readColor(dynamic value, Color fallback) {
    if (value is int) return Color(value);
    if (value is String) {
      final cleaned = value.replaceAll('#', '').replaceAll('0x', '');
      final parsed = int.tryParse(cleaned.length == 6 ? 'FF$cleaned' : cleaned, radix: 16);
      if (parsed != null) return Color(parsed);
    }
    return fallback;
  }

  static String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }
}

const String defaultRestaurantId = 'shokugeki';

// ⚠️ L'ancienne table "defaultStaffCodes" (fallback local si Firestore
// était indisponible) a été retirée : elle exposait les codes staff
// en clair dans le binaire de l'app, ce qui rendait inutile toute
// protection côté serveur. La vérification passe maintenant TOUJOURS
// par la Cloud Function "verifyStaffCode" (voir staff_access_service.dart).

const Map<StaffRole, String> defaultStaffCodeByRole = {
  StaffRole.caissier: '3265',
  StaffRole.livreur: '2300',
  StaffRole.directeur: '6523',
  StaffRole.cuisine: '1955',
};
