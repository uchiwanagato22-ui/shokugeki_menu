import 'package:flutter/material.dart';
import 'client_menu_screen.dart';
import 'caissier_dashboard_screen.dart';
import 'directeur_dashboard_screen.dart';
import 'livreur_dashboard_screen.dart';

class RoleRouter extends StatelessWidget {
  final String userRole;

  const RoleRouter({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    // Distribution automatique et sécurisée des écrans selon le rôle
    switch (userRole.toLowerCase()) {
      case 'directeur':
        return const DirecteurDashboardScreen();
      case 'caissier':
        return const CaissierDashboardScreen();
      case 'livreur':
        return const LivreurDashboardScreen();
      case 'client':
      default:
        return const ClientMenuScreen();
    }
  }
}