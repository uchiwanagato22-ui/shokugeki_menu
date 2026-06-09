import 'package:flutter/material.dart';
import 'about_contact_screen.dart';
import 'chef_ia_screen.dart';
import 'client_cart_screen.dart';
import 'client_menu_screen.dart';
import 'client_orders_screen.dart';
import 'constants.dart';
import 'notification_service.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  int _index = 0;
  final List<Map<String, dynamic>> _cartItems = [];

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    await NotificationService.instance.init();
    await NotificationService.instance.sauvegarderTokenUtilisateur();
    NotificationService.instance.demarrerSuiviCommandes();
  }

  @override
  void dispose() {
    NotificationService.instance.arreterSuivi();
    super.dispose();
  }

  int get _cartCount => _cartItems.fold(0, (t, i) => t + (i['quantite'] as int));

  void _ouvrirPanier() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ClientCartScreen(cartItems: _cartItems)),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          ClientMenuScreen(
            cartItems: _cartItems,
            cartCount: _cartCount,
            onCartChanged: () => setState(() {}),
            onOpenCart: _ouvrirPanier,
          ),
          const ClientOrdersScreen(),
          const ChefIaScreen(),
          const AboutContactScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: Colors.white,
        indicatorColor: kPrimaryColor.withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.restaurant_menu), label: "Menu"),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: "Commandes"),
          NavigationDestination(icon: Icon(Icons.psychology), label: "Chef IA"),
          NavigationDestination(icon: Icon(Icons.info_outline), label: "Contact"),
        ],
      ),
      floatingActionButton: _index == 0 && _cartCount > 0
          ? FloatingActionButton.extended(
              onPressed: _ouvrirPanier,
              backgroundColor: kPrimaryColor,
              icon: const Icon(Icons.shopping_bag, color: Colors.white),
              label: Text("Panier ($_cartCount)", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }
}
