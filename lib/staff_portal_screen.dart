import 'package:flutter/material.dart';

import 'caissier_dashboard_screen.dart';
import 'cuisine_screen.dart';
import 'directeur_dashboard_screen.dart';
import 'livreur_dashboard_screen.dart';
import 'restaurant_app_config.dart';
import 'staff_access_service.dart';
import 'staff_code_login_screen.dart';
import 'subscription_guard.dart';

class StaffPortalScreen extends StatelessWidget {
  const StaffPortalScreen({
    super.key,
    this.restaurantId = defaultRestaurantId,
  });

  final String restaurantId;

  @override
  Widget build(BuildContext context) {
    return SubscriptionGuard(
      restaurantId: restaurantId,
      child: StaffCodeLoginScreen(
        restaurantId: restaurantId,
        onAccessGranted: (result) => _openDashboard(context, result),
      ),
    );
  }

  void _openDashboard(BuildContext context, StaffAccessResult result) {
    final role = result.role;
    if (role == null) return;

    Widget screen;
    switch (role) {
      case StaffRole.caissier:
        screen = const CaissierDashboardScreen();
        break;
      case StaffRole.livreur:
        screen = const LivreurDashboardScreen();
        break;
      case StaffRole.directeur:
        screen = const DirectorDashboardScreen();
        break;
      case StaffRole.cuisine:
        screen = const CuisineScreen();
        break;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SubscriptionGuard(
          restaurantId: restaurantId,
          child: StaffRoleShell(
            role: role,
            staffName: result.staffName,
            child: screen,
          ),
        ),
      ),
    );
  }
}

class StaffRoleShell extends StatelessWidget {
  const StaffRoleShell({
    super.key,
    required this.role,
    required this.child,
    this.staffName,
  });

  final StaffRole role;
  final String? staffName;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Banner(
      message: role.label.toUpperCase(),
      location: BannerLocation.topEnd,
      color: _roleColor(role),
      child: child,
    );
  }

  Color _roleColor(StaffRole role) {
    switch (role) {
      case StaffRole.caissier:
        return const Color(0xFF2563EB);
      case StaffRole.livreur:
        return const Color(0xFF059669);
      case StaffRole.directeur:
        return const Color(0xFF7C3AED);
      case StaffRole.cuisine:
        return const Color(0xFFD97706);
    }
  }
}
