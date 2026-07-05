import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app_config.dart';
import 'restaurant_app_config.dart';

// ═══════════════════════════════════════════════════════
//  STAFF ACCESS SERVICE — Multi-tenant v3 (sécurisé)
//  ✅ Ne lit plus JAMAIS "staffCodes" directement depuis le
//     téléphone : tout passe par la Cloud Function
//     "verifyStaffCode", qui tourne côté serveur.
//  ✅ Ouvre une vraie session Firebase Auth (avec le rôle et le
//     restaurant comme "claims") après un code valide, pour que
//     les règles Firestore puissent enfin protéger le menu, les
//     commandes, les promos, etc. selon le rôle réel du staff.
//  ⚠️ Le fallback "codes en dur dans l'app" a été retiré : il
//     rendait cette correction inutile (n'importe qui aurait pu
//     décompiler l'app et retrouver les codes quand même).
// ═══════════════════════════════════════════════════════

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
  StaffAccessService({FirebaseFunctions? functions, FirebaseAuth? auth})
      : _functions = functions ?? FirebaseFunctions.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  // Vérification code personnel — via Cloud Function (sécurisé)
  Future<StaffAccessResult> verifyCode({
    String? restaurantId,
    required String code,
  }) async {
    final normalizedCode = code.trim();

    if (!RegExp(r'^\d{4}$').hasMatch(normalizedCode)) {
      return const StaffAccessResult(
        allowed: false,
        errorMessage: 'Le code doit contenir 4 chiffres.',
      );
    }

    final targetId = restaurantId ?? AppConfig.restaurantId;

    try {
      final callable = _functions.httpsCallable('verifyStaffCode');
      final response = await callable.call(<String, dynamic>{
        'restaurantId': targetId,
        'code': normalizedCode,
      });

      final data = Map<String, dynamic>.from(response.data as Map);
      final role = staffRoleFromFirestore((data['role'] ?? '').toString());

      if (role == null) {
        return const StaffAccessResult(allowed: false, errorMessage: 'Rôle invalide.');
      }

      // On échange le jeton temporaire contre une vraie session Firebase.
      // Sans ça, les écritures du staff (menu, commandes...) seraient
      // encore vues par Firestore comme venant d'un simple visiteur.
      final token = data['authToken']?.toString();
      if (token != null && token.isNotEmpty) {
        await _auth.signInWithCustomToken(token);
      }

      return StaffAccessResult(
        allowed: true,
        role: role,
        staffName: data['staffName']?.toString(),
      );
    } on FirebaseFunctionsException catch (e) {
      debugPrint('StaffAccessService Cloud Function error: ${e.code} ${e.message}');
      if (e.code == 'resource-exhausted') {
        return StaffAccessResult(allowed: false, errorMessage: e.message);
      }
      return const StaffAccessResult(
        allowed: false,
        errorMessage: 'Code incorrect ou désactivé.',
      );
    } catch (e) {
      debugPrint('StaffAccessService error: $e');
      return const StaffAccessResult(
        allowed: false,
        errorMessage: 'Connexion impossible. Vérifiez votre connexion internet.',
      );
    }
  }

  // À appeler quand le staff quitte son espace (retour à l'accueil,
  // changement de rôle...) pour fermer la session Firebase ouverte.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {}
  }
}