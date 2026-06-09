import 'package:flutter/material.dart';
import 'client_home_screen.dart';
import 'directeur_dashboard_screen.dart';
import 'caissier_dashboard_screen.dart';
import 'livreur_dashboard_screen.dart'; // <-- NOTRE NOUVEL IMPORT DE CONFIANCE !

class RoleRouter extends StatelessWidget {
  final String userRole; // "client", "directeur", "caissier", "livreur"

  const RoleRouter({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    switch (userRole) {
      case "directeur":
        return const DirectorDashboardScreen();
      case "caissier":
        return const CaissierDashboardScreen();
      case "livreur":
        return const LivreurDashboardScreen(); // <-- APPEL LE VRAI ÉCRAN ICI
      case "client":
      default:
        return const ClientHomeScreen();
    }
  }
}
