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

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final AuthService _authService = AuthService();

  // Contrôleurs Client (Email et Mot de passe)
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Contrôleur Personnel (Code secret)
  final _codeController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _connexionClient() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir tous les champs clients")),
      );
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur de connexion client : ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _connexionPersonnel() async {
    if (_codeController.text.isEmpty || _codeController.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez saisir un code secret valide à 4 chiffres")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? role = await _authService.connecterPersonnel(_codeController.text.trim());

      if (role != null) {
        // --- PERSISTANCE DU PERSONNEL SAUVEGARDÉE DANS LE STOCKAGE LOCAL ---
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('staff_role', role);

        if (!mounted) return;

        // Redirection ciblée selon le rôle renvoyé par la base Firestore
        Widget destinationScreen;
        switch (role) {
          case 'directeur':
            destinationScreen = const DirecteurDashboardScreen();
            break;
          case 'caissier':
            destinationScreen = const CaissierDashboardScreen();
            break;
          case 'livreur':
            destinationScreen = const LivreurDashboardScreen();
            break;
          case 'cuisine':
            destinationScreen = const CuisineScreen();
            break;
          default:
            destinationScreen = const LoginScreen();
            break;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => destinationScreen),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Code secret incorrect ou personnel introuvable")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur système lors de la connexion : ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text("Shokugeki Menu 🍣", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: kSurfaceColor,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: kPrimaryColor,
          labelColor: kPrimaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: "Client"),
            Tab(icon: Icon(Icons.badge), text: "Personnel"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : TabBarView(
              controller: _tabController,
              children: [
                // PANNEAU CLIENT
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        "Espace Client",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Adresse Email",
                          labelStyle: TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email, color: Colors.grey),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Mot de passe",
                          labelStyle: TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock, color: Colors.grey),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _connexionClient,
                          style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
                          child: const Text("Se connecter", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RegisterScreen()),
                            );
                          },
                          child: const Text("Créer un compte client gratuit", style: TextStyle(color: kPrimaryColor)),
                        ),
                      ),
                    ],
                  ),
                ),

                // PANNEAU PERSONNEL
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        "Espace Restaurant (Staff)",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 30),
                      TextField(
                        controller: _codeController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Code Secret à 4 chiffres",
                          labelStyle: TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock_person, color: Colors.grey),
                        ),
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 4,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _connexionPersonnel,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                          child: const Text("Valider le Code", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 60),
                      const Center(child: DeveloperContactButton()),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}