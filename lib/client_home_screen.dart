import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'about_contact_screen.dart';
import 'chef_ia_screen.dart';
import 'client_cart_screen.dart';
import 'client_menu_screen.dart';
import 'client_orders_screen.dart';
import 'constants.dart';
import 'login_screen.dart';
import 'notification_service.dart';
import 'widgets/developer_contact_button.dart';
import 'widgets/loyalty_badge.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> with SingleTickerProviderStateMixin {
  int _index = 0;
  final List<Map<String, dynamic>> _cartItems = [];

  late final AnimationController _headerCtrl;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    _initNotifications();

    // Petite animation d'entrée pour l'en-tête de la page d'accueil
    _headerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic));
    _headerCtrl.forward();
  }

  Future<void> _initNotifications() async {
    await NotificationService.instance.init();
    await NotificationService.instance.sauvegarderTokenUtilisateur();
    NotificationService.instance.demarrerSuiviCommandes();
  }

  @override
  void dispose() {
    NotificationService.instance.arreterSuivi();
    _headerCtrl.dispose();
    super.dispose();
  }

  int get _cartCount =>
      _cartItems.fold(0, (t, i) => t + ((i['quantite'] as num?)?.toInt() ?? 1));

  void _ouvrirPanier() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientCartScreen(cartItems: _cartItems),
      ),
    ).then((_) => setState(() {}));
  }

  // ✅ Déconnexion client propre
  Future<void> _deconnecter() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.logout, color: Colors.redAccent, size: 22),
          SizedBox(width: 10),
          Text('Déconnexion', style: TextStyle(color: Colors.white, fontSize: 17)),
        ]),
        content: const Text(
          'Tu vas être déconnecté. Tu pourras te reconnecter à tout moment.',
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;
    NotificationService.instance.arreterSuivi();
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName?.split(' ').first ?? 'Vous';

    return Scaffold(
      backgroundColor: kBackgroundColor,

      // ✅ AppBar avec bouton déconnexion
      appBar: _index == 0 ? AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: FadeTransition(
          opacity: _headerFade,
          child: SlideTransition(
            position: _headerSlide,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(
                  'Bonjour $userName 👋',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(width: 8),
                if (user != null) LoyaltyBadge(uid: user.uid),
              ]),
              const Text('Que voulez-vous manger ?', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
          ),
        ),
        actions: [
          // Panier dans l'AppBar si items
          if (_cartCount > 0)
            IconButton(
              onPressed: _ouvrirPanier,
              icon: Stack(children: [
                const Icon(Icons.shopping_bag_outlined, color: Colors.white),
                Positioned(
                  right: 0, top: 0,
                  child: Container(
                    width: 16, height: 16,
                    decoration: const BoxDecoration(color: kPrimaryColor, shape: BoxShape.circle),
                    child: Center(child: Text('$_cartCount', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
                  ),
                ),
              ]),
            ),
          // Bouton déconnexion
          IconButton(
            tooltip: 'Se déconnecter',
            onPressed: _deconnecter,
            icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 22),
          ),
          const SizedBox(width: 4),
        ],
      ) : null,

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
        backgroundColor: kSurfaceColor,
        indicatorColor: kPrimaryColor.withOpacity(0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu, color: Colors.white70),
            selectedIcon: Icon(Icons.restaurant_menu, color: kPrimaryColor),
            label: 'Menu',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long, color: Colors.white70),
            selectedIcon: Icon(Icons.receipt_long, color: kPrimaryColor),
            label: 'Commandes',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology, color: Colors.white70),
            selectedIcon: Icon(Icons.psychology, color: kPrimaryColor),
            label: 'Chef IA',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline, color: Colors.white70),
            selectedIcon: Icon(Icons.info_outline, color: kPrimaryColor),
            label: 'Contact',
          ),
        ],
      ),

      floatingActionButton: _index == 0 && _cartCount > 0
          ? FloatingActionButton.extended(
              onPressed: _ouvrirPanier,
              backgroundColor: kPrimaryColor,
              icon: const Icon(Icons.shopping_bag, color: Colors.white),
              label: Text(
                'Panier ($_cartCount)',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }
}
