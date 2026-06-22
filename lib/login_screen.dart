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

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;

  final AuthService _authService = AuthService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();

  bool _isLoading = false;

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Remplis tous les champs")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential? userCredential =
          await _authService.connecterClient(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (userCredential != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ClientHomeScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur client: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _connexionPersonnel() async {
    if (_codeController.text.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Code 4 chiffres obligatoire")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? role =
          await _authService.connecterPersonnel(_codeController.text.trim());

      if (role == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Code incorrect")),
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('staff_role', role);

      if (!mounted) return;

      Widget screen;

      // CORRIGÉ : Tous les mots-clés 'const' problématiques ont été supprimés ici
      switch (role.trim().toLowerCase()) {
        case 'directeur':
          screen = DirecteurDashboardScreen();
          break;

        case 'caissier':
          screen = CaissierDashboardScreen();
          break;

        case 'livreur':
          screen = LivreurDashboardScreen();
          break;

        case 'cuisine':
          screen = CuisineScreen();
          break;

        default:
          screen = const LoginScreen();
          break;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => screen),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur système: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
          tabs: const [
            Tab(icon: Icon(Icons.person), text: "Client"),
            Tab(icon: Icon(Icons.badge), text: "Staff"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // CLIENT
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextField(
                        controller: _emailController,
                        decoration:
                            const InputDecoration(labelText: "Email"),
                      ),
                      TextField(
                        controller: _passwordController,
                        decoration:
                            const InputDecoration(labelText: "Password"),
                        obscureText: true,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _connexionClient,
                        child: const Text("Login Client"),
                      ),
                    ],
                  ),
                ),

                // STAFF
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextField(
                        controller: _codeController,
                        decoration:
                            const InputDecoration(labelText: "Code 4 chiffres"),
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        obscureText: true,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _connexionPersonnel,
                        child: const Text("Login Staff"),
                      ),
                      const SizedBox(height: 40),
                      const DeveloperContactButton(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}