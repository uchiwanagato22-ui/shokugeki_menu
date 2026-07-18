import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

import 'app_config.dart';
import 'restaurant_app_config.dart';

// ═══════════════════════════════════════════════════════
//  STAFF ACCESS SERVICE — Multi-tenant v4 (sécurisé, sans Blaze)
//  ✅ Ne lit plus JAMAIS "staffCodes" directement depuis le
//     téléphone : tout passe par une fonction serveur qui vérifie
//     le code avec les droits admin (SDK Admin Firebase).
//  ✅ Ouvre une vraie session Firebase Auth (avec le rôle et le
//     restaurant comme "claims") après un code valide — tes règles
//     Firestore (estStaff()) fonctionnent sans aucun changement.
//  ⚠️ Différence avec la v3 : la vérification tourne sur une fonction
//     Vercel (gratuite, aucune carte bancaire) au lieu d'une Cloud
//     Function Firebase (qui demande le plan payant Blaze). Le niveau
//     de sécurité est identique — seul l'hébergeur change.
//     Une fois Blaze débloqué, tu peux repasser sur Cloud Functions
//     si tu préfères tout centraliser chez Firebase — pas obligatoire.
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
  StaffAccessService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  // ⚠️ Remplace par l'URL de ton projet Vercel une fois déployé
  // (ex: https://shokugeki-staff-auth.vercel.app/api/verifyStaffCode)
  static const String _endpoint = 'https://REMPLACE-PAR-TON-URL-VERCEL.vercel.app/api/verifyStaffCode';

  // Vérification code personnel — via fonction serveur (sécurisé)
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
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'restaurantId': targetId, 'code': normalizedCode}),
      ).timeout(const Duration(seconds: 12));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 429) {
        return StaffAccessResult(allowed: false, errorMessage: data['message']?.toString() ?? 'Trop de tentatives.');
      }
      if (response.statusCode != 200) {
        return const StaffAccessResult(allowed: false, errorMessage: 'Code incorrect ou désactivé.');
      }

      final role = staffRoleFromFirestore((data['role'] ?? '').toString());
      if (role == null) {
        return const StaffAccessResult(allowed: false, errorMessage: 'Rôle invalide.');
      }

      // On échange le jeton temporaire contre une vraie session Firebase.
      final token = data['authToken']?.toString();
      if (token != null && token.isNotEmpty) {
        await _auth.signInWithCustomToken(token);
      }

      return StaffAccessResult(
        allowed: true,
        role: role,
        staffName: data['staffName']?.toString(),
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