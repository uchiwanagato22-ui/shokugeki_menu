import 'package:cloud_firestore/cloud_firestore.dart';

import 'restaurant_app_config.dart';

class StaffAccessResult {
  const StaffAccessResult({
    required this.allowed,
    this.role,
    this.staffName,
    this.errorMessage,
  });

  final bool allowed;
  final StaffRole? role;
  final String? staffName;
  final String? errorMessage;
}

class StaffAccessService {
  StaffAccessService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<StaffAccessResult> verifyCode({
    required String restaurantId,
    required String code,
  }) async {
    final normalizedCode = code.trim();
    if (!RegExp(r'^\d{4}$').hasMatch(normalizedCode)) {
      return const StaffAccessResult(
        allowed: false,
        errorMessage: 'Le code doit contenir 4 chiffres.',
      );
    }

    try {
      final restaurantDoc =
          await _firestore.collection('restaurants').doc(restaurantId).get();
      final restaurantData = restaurantDoc.data();
      if (restaurantData != null && restaurantData['subscriptionActive'] == false) {
        return const StaffAccessResult(
          allowed: false,
          errorMessage: 'Abonnement inactif. Acces personnel bloque.',
        );
      }

      final query = await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('staffCodes')
          .where('code', isEqualTo: normalizedCode)
          .where('active', isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();
        final role = staffRoleFromFirestore((data['role'] ?? '').toString());
        if (role == null) {
          return const StaffAccessResult(
            allowed: false,
            errorMessage: 'Role personnel invalide.',
          );
        }

        return StaffAccessResult(
          allowed: true,
          role: role,
          staffName: data['name']?.toString(),
        );
      }
    } catch (_) {
      // The copied app must still open during setup before Firestore is ready.
    }

    final fallbackRole = defaultStaffCodes[normalizedCode];
    if (fallbackRole != null) {
      return StaffAccessResult(
        allowed: true,
        role: fallbackRole,
        staffName: fallbackRole.label,
      );
    }

    return const StaffAccessResult(
      allowed: false,
      errorMessage: 'Code incorrect ou desactive.',
    );
  }
}
