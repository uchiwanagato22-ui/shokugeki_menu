import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'directeur_dashboard_screen.dart';
import 'caissier_dashboard_screen.dart';
import 'livreur_dashboard_screen.dart';
import 'restaurant_workflows.dart';
import 'default_menu_plats.dart';
import 'notification_service.dart';
import 'cuisine_screen.dart';
import 'chef_ia_screen.dart';
import 'login_screen.dart';
import 'auth_service.dart';
import 'client_home_screen.dart';
import 'constants.dart';
import 'welcome_character_screen.dart'; // 👈 Ajout de l'import de ton écran

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  debugPrint("Notification arrière-plan : ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const ShokugekiMenuApp());
}

class ShokugekiMenuApp extends StatelessWidget {
  const ShokugekiMenuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: kPrimaryColor,
        scaffoldBackgroundColor: kBackgroundColor,
        cardColor: kSurfaceColor,
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          titleLarge: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
          bodyMedium: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
            elevation: 4,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kSurfaceColor,
          labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          prefixIconColor: kPrimaryColor,
          suffixIconColor: kPrimaryColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: kSurfaceColor,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        colorScheme: const ColorScheme.dark(
          primary: kPrimaryColor,
          secondary: kSecondaryColor,
          surface: kSurfaceColor,
        ),
      ),
      // 🚀 Intégration du FutureBuilder pour gérer dynamiquement l'affichage du Welcome Screen
      home: FutureBuilder<bool>(
        future: WelcomeCharacterScreen.doitAfficher(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: kPrimaryColor),
              ),
            );
          }
          return snapshot.data == true
              ? const WelcomeCharacterScreen()
              : const AppScreenWrapper();
        },
      ),
    );
  }
}

class AppScreenWrapper extends StatefulWidget {
  const AppScreenWrapper({super.key});

  @override
  State<AppScreenWrapper> createState() => _AppScreenWrapperState();
}

class _AppScreenWrapperState extends State<AppScreenWrapper> {
  final AuthService _authService = AuthService();
  bool _isCheckingStatus = true;
  bool _isAppActive = true;
  String _blockingMessage = "Application temporairement inaccessible.";

  @override
  void initState() {
    super.initState();
    _controlerActivationApplication();
  }

  Future<void> _controlerActivationApplication() async {
    try {
      final statut = await _authService.verifierStatutApplication();
      if (mounted) {
        setState(() {
          _isAppActive = statut['is_active'] ?? false;
          _blockingMessage = statut['message'] ?? "Application suspendue.";
          _isCheckingStatus = false;
        });
      }
    } catch (e) {
      debugPrint("Erreur vérification statut : $e");
      if (mounted) {
        setState(() {
          _isAppActive = true;
          _isCheckingStatus = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingStatus) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: kSurfaceColor,
                child: Icon(Icons.restaurant_menu_rounded, size: 40, color: kPrimaryColor),
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(color: kPrimaryColor),
              SizedBox(height: 16),
              Text(
                "Initialisation sécurisée...",
                style: TextStyle(color: Colors.grey, fontSize: 13, letterSpacing: 0.5),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isAppActive) {
      return AppBlockScreen(message: _blockingMessage);
    }

    return const AuthGatewayRouter();
  }
}

class AppBlockScreen extends StatelessWidget {
  final String message;
  const AppBlockScreen({super.key, required this.message});

  Future<void> _contacterNagato() async {
    final cleanPhone = kDeveloperPhone.replaceAll(RegExp(r'[^\d+]'), '');
    final customText = Uri.encodeComponent(
        "Bonjour Nagato, je vous contacte concernant la suspension de mon application Shokugeki Menu.");
    final whatsappUri =
        Uri.parse("https://wa.me/${cleanPhone.replaceAll('+', '')}?text=$customText");
    if (!await launchUrl(whatsappUri, mode: LaunchMode.externalApplication)) {
      debugPrint("Impossible de lancer WhatsApp");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06070B),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.redAccent.withOpacity(0.2), width: 1.5),
                ),
                child: const Icon(Icons.gpp_maybe_rounded, size: 70, color: Colors.redAccent),
              ),
              const SizedBox(height: 32),
              const Text(
                "ACCÈS RESTREINT",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kSurfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.03)),
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _contacterNagato,
                  icon: const Icon(Icons.support_agent_rounded),
                  label: const Text("CONTACTER LE SUPPORT / NAGATO"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthGatewayRouter extends StatefulWidget {
  const AuthGatewayRouter({super.key});

  @override
  State<AuthGatewayRouter> createState() => _AuthGatewayRouterState();
}

class _AuthGatewayRouterState extends State<AuthGatewayRouter> {
  String? _cachedStaffRole;
  bool _isLoadingCache = true;

  @override
  void initState() {
    super.initState();
    _chargerSessionPersonnel();
  }

  Future<void> _chargerSessionPersonnel() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final savedRole = prefs.getString('staff_role');
      if (mounted) {
        setState(() {
          _cachedStaffRole = savedRole;
          _isLoadingCache = false;
        });
      }
    } catch (e) {
      debugPrint("Erreur lecture session : $e");
      if (mounted) setState(() => _isLoadingCache = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingCache) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: kPrimaryColor)));
    }

    if (_cachedStaffRole != null) {
      return _routerVersEcranPersonnel(_cachedStaffRole!);
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: kPrimaryColor)));
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const ClientHomeScreen();
        }
        return const LoginScreen();
      },
    );
  }

  Widget _routerVersEcranPersonnel(String role) {
    switch (role.trim().toLowerCase()) {
      case 'directeur':
        return DirectorDashboardScreen();
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
}

class ShokugekiRestaurantInfoView extends StatelessWidget {
  const ShokugekiRestaurantInfoView({super.key});

  Future<void> _lancerUrl(Uri url) async {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint("Impossible d'ouvrir : $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBackgroundColor,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 45,
                backgroundColor: kSurfaceColor,
                child: Icon(Icons.restaurant_menu_rounded, size: 50, color: kPrimaryColor),
              ),
              const SizedBox(height: 16),
              const Text(
                "Shokugeki Restaurant",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 32),
              _buildInfoRow(Icons.location_on, "Adresse", "Nouakchott, Mauritanie"),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.developer_mode_rounded, "Développeur", "Nagato Business"),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  final whatsappUrl = Uri.parse(
                      "https://wa.me/${kDeveloperPhone.replaceAll('+', '')}");
                  _lancerUrl(whatsappUrl);
                },
                style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
                child: const Text("Contacter Nagato",
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: kPrimaryColor, size: 20),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}