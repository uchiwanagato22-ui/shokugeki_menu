import 'package:cloud_firestore/cloud_firestore.dart';

import 'restaurant_app_config.dart';

class RestaurantSetupSeed {
  RestaurantSetupSeed({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> createDefaultRestaurant({
    String restaurantId = defaultRestaurantId,
    String name = 'Shokugeki Menu',
  }) async {
    final restaurantRef = _firestore.collection('restaurants').doc(restaurantId);

    await restaurantRef.set({
      'name': name,
      'primaryColor': '#D92D20',
      'secondaryColor': '#111827',
      'phone': '+33 0 00 00 00 00',
      'address': 'Adresse du restaurant',
      'logoUrl': null,
      'coverUrl': null,
      'subscriptionActive': true,
      'subscriptionMessage':
          'Abonnement inactif. Contactez le support pour reactiver le restaurant.',
      'deliveryEnabled': true,
      'pickupEnabled': true,
      'dineInEnabled': true,
      'minimumOrder': 0,
      'deliveryFee': 0,
      'currency': 'MRU',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    for (final entry in defaultStaffCodeByRole.entries) {
      await restaurantRef.collection('staffCodes').doc(entry.key.firestoreValue).set({
        'code': entry.value,
        'role': entry.key.firestoreValue,
        'name': entry.key.label,
        'active': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }
}
