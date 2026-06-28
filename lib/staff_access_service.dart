import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_config.dart';
import 'restaurant_app_config.dart';

// ═══════════════════════════════════════════════════════
//  STAFF ACCESS SERVICE — Multi-tenant v2 (CORRIGÉ)
//  ✅ Lit les codes dans restaurants/{id}/staffCodes/
//  ✅ Gère le paramètre optionnel ou le fallback par défaut
//  ✅ Fallback sur codes hardcodés si Firestore indispo
// ═══════════════════════════════════════════════════════

class StaffAccessResult {
  const StaffAccessResult({required this.allowed, this.role, this.staffName, this.errorMessage});
  final bool allowed;
  final StaffRole? role;
  final String? staffName;
  final String? errorMessage;
}

class StaffAccessService {
  StaffAccessService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // CORRECTION : Ajout du paramètre 'restaurantId' nommé et optionnel pour correspondre à l'appel de l'UI
  Future<StaffAccessResult> verifyCode({
    String? restaurantId, 
    required String code,
  }) async {
    final normalizedCode = code.trim();
    if (!RegExp(r'^\d{4}$').hasMatch(normalizedCode)) {
      return const StaffAccessResult(allowed: false, errorMessage: 'Le code doit contenir 4 chiffres.');
    }

    try {
      // Choix de l'ID passé par l'écran ou de celui configuré globalement
      final targetId = restaurantId ?? AppConfig.restaurantId;

      // ✅ Multi-tenant : lit de manière sécurisée dans le bon dossier du restaurant
      final query = await _firestore
          .collection('restaurants')
          .doc(targetId)
          .collection('staffCodes')
          .where('code', isEqualTo: normalizedCode)
          .where('active', isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();
        final role = staffRoleFromFirestore((data['role'] ?? '').toString());
        if (role == null) {
          return const StaffAccessResult(allowed: false, errorMessage: 'Rôle invalide.');
        }
        return StaffAccessResult(allowed: true, role: role, staffName: data['name']?.toString());
      }
    } catch (e) {
      debugPrint('StaffAccessService Firestore error: $e');
      // Firestore indispo → fallback codes hardcodés
    }

    // Fallback : codes par défaut
    final fallbackRole = defaultStaffCodes[normalizedCode];
    if (fallbackRole != null) {
      return StaffAccessResult(allowed: true, role: fallbackRole, staffName: fallbackRole.label);
    }

    return const StaffAccessResult(allowed: false, errorMessage: 'Code incorrect ou désactivé.');
  }
}
