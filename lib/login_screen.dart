import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';
import 'register_screen.dart';
import 'client_home_screen.dart';
import 'caissier_dashboard_screen.dart';
import 'cuisine_screen.dart';
import 'directeur_dashboard_screen.dart';
import 'livreur_dashboard_screen.dart';
import 'widgets/developer_contact_button.dart';
import 'constants.dart';
import 'app_config.dart';
import 'staff_access_service.dart';
import 'staff_portal_screen.dart';
import 'restaurant_app_config.dart';

// ═══════════════════════════════════════════════════════
//  ÉCRAN DE CONNEXION — v2 (UNIFIÉ & MULTI-TENANT)
//  ✅ Connexion Client via Email/Password standard
//  ✅ Connexion Personnel UNIFIÉE via StaffAccessService
//  ✅ Utilise la sous-collection 'staffCodes' (Plus de doublon avec 'personnel')
// ═══════════════════════════════════════════════════════

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
  
  // ✅ Instanciation du service d'accès unifié du personnel
  final StaffAccessService _staffAccessService = StaffAccessService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _connexionClient() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnack("Remplis tous les champs", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential? userCredential = await _authService.connecterClient(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (userCredential != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ClientHomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'user-not-found':
          msg = "Aucun compte avec cet email.";
          break;
        case 'wrong-password':
          msg = "Mot de passe incorrect.";
          break;
        case 'invalid-email':
          msg = "Email invalide.";
          break;
        case 'user-disabled':
          msg = "Ce compte est désactivé.";
          break;
        case 'too-many-requests':
          msg = "Trop de tentatives. Réessaie plus tard.";
          break;
        default:
          msg = "Erreur de connexion : ${e.message}";
      }
      _showSnack(msg, isError: true);
    } catch (e) {
      _showSnack("Erreur inattendue : $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _connexionPersonnel() async {
    if (_codeController.text.length != 4) {
      _showSnack("Code 4 chiffres obligatoire", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ✅ CORRECTION : On utilise le même canal que l'autre écran secret
      // On interroge 'restaurants/shokugeki/staffCodes' de façon propre.
      final result = await _staffAccessService.verifyCode(
        restaurantId: AppConfig.restaurantId,
        code: _codeController.text.trim(),
      );

      if (!result.allowed || result.role == null) {
        _showSnack(result.errorMessage ?? "Code incorrect ou désactivé", isError: true);
        return;
      }

      // Conversion du StaffRole (enum) en String pour SharedPreferences
      String roleStr = '';
      switch (result.role) {
        case StaffRole.directeur: roleStr = 'directeur'; break;
        case StaffRole.caissier: roleStr = 'caissier'; break;
        case StaffRole.livreur: roleStr = 'livreur'; break;
        case StaffRole.cuisine: roleStr = 'cuisine'; break;
        default: roleStr = '';
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('staff_role', roleStr);

      if (!mounted) return;

      // ✅ Redirection vers les bons Dashboards selon l'enum fortement typé
      Widget screen;
      switch (result.role) {
        case StaffRole.directeur:
          screen = DirectorDashboardScreen();
          break;
        case StaffRole.caissier:
          screen = CaissierDashboardScreen();
          break;
        case StaffRole.livreur:
          screen = LivreurDashboardScreen();
          break;
        case StaffRole.cuisine:
          screen = CuisineScreen();
          break;
        default:
          screen = const LoginScreen();
          break;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StaffRoleShell(role: result.role!, staffName: result.staffName, child: screen),
        ),
      );
    } catch (e) {
      _showSnack("Erreur système : $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text("Shokugeki Menu 🍣"),
        backgroundColor: kSurfaceColor,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: kPrimaryColor,
          labelColor: kPrimaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: "Client"),
            Tab(icon: Icon(Icons.badge), text: "Staff"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : TabBarView(
              controller: _tabController,
              children: [
                // ── ONGLET CLIENT ──
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      const Icon(Icons.restaurant_menu_rounded,
                          size: 60, color: kPrimaryColor),
                      const SizedBox(height: 24),
                      const Text(
                        "Connecte-toi pour commander",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Email",
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Mot de passe",
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _connexionClient,
                          child: const Text("SE CONNECTER"),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen()),
                        ),
                        child: const Text(
                          "Pas encore de compte ? S'inscrire",
                          style: TextStyle(color: kPrimaryColor),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── ONGLET STAFF ──
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      const Icon(Icons.admin_panel_settings_rounded,
                          size: 60, color: kPrimaryColor),
                      const SizedBox(height: 24),
                      const Text(
                        "Accès réservé au personnel",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        obscureText: true,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 12),
                        decoration: InputDecoration(
                          labelText: "Code PIN (4 chiffres)",
                          counterText: '',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _connexionPersonnel,
                          icon: const Icon(Icons.login),
                          label: const Text("ACCÈS PERSONNEL"),
                        ),
                      ),
                      const SizedBox(height: 40),
                      const Center(child: DeveloperContactButton()),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}