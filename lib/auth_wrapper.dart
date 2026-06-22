import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- IMPORTS DE TES ÉCRANS ---
import 'directeur_dashboard_screen.dart'; 
import 'caissier_dashboard_screen.dart';
import 'livreur_dashboard_screen.dart';
import 'cuisine_screen.dart';
import 'login_screen.dart';
import 'client_home_screen.dart';
import 'constants.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  String? _cachedStaffRole;
  bool _isLoadingCache = true;

  @override
  void initState() {
    super.initState();
    _chargerSessionPersonnelDepuisLeCache();
  }

  /// Récupère le rôle du staff stocké localement au redémarrage
  Future<void> _chargerSessionPersonnelDepuisLeCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedRole = prefs.getString('staff_role');
      if (mounted) {
        setState(() {
          _cachedStaffRole = savedRole;
          _isLoadingCache = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCache = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Écran de chargement pendant la lecture du stockage local
    if (_isLoadingCache) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: kPrimaryColor),
        ),
      );
    }

    // CONDITION 1 : Si un membre du personnel s'est connecté auparavant (Persistance)
    // CORRIGÉ : Plus aucun 'const' ici pour éviter le crash de compilation finale !
    if (_cachedStaffRole != null) {
      switch (_cachedStaffRole!.trim().toLowerCase()) {
        case 'directeur':
          return DirecteurDashboardScreen();
        case 'caissier':
          return CaissierDashboardScreen();
        case 'livreur':
          return LivreurDashboardScreen();
        case 'cuisine':
          return CuisineScreen();
        default:
          return const LoginScreen();
      }
    }

    // CONDITION 2 : Si aucun staff n'est mémorisé, on gère la session Client via Firebase
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: kPrimaryColor),
            ),
          );
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          // Le client possède une session active
          return const ClientHomeScreen();
        }

        // Si personne n'est connecté
        return const LoginScreen();
      },
    );
  }
}