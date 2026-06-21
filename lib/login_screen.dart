import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'register_screen.dart';
import 'client_home_screen.dart';
import 'caissier_dashboard_screen.dart';
import 'cuisine_screen.dart';
import 'directeur_dashboard_screen.dart';
import 'livreur_dashboard_screen.dart';
import 'developer_contact_button.dart';
import 'constants.dart'; // Pour kPrimaryColor, kBackgroundColor, kSurfaceColor

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final AuthService _authService = AuthService();

  // Contrôleurs Client (Email et Mot de passe uniquement)
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
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  // --- CONNEXION CLIENT (EMAIL / MOT DE PASSE) ---
  Future<void> _connexionClient() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir votre email et mot de passe.")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await _authService.connecterClient(email, password);
      if (res != null && res.user != null) {
        // Redirection vers l'accueil client
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ClientHomeScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur de connexion : ${e.toString()}")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- CONNEXION PERSONNEL (CODE SECRET 4 CHIFFRES) ---
  Future<void> _connexionPersonnel() async {
    final code = _codeController.text.trim();
    if (code.isEmpty || code.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Le code secret doit contenir exactement 4 chiffres.")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      String? role = await _authService.connecterPersonnel(code);
      if (role != null) {
        Widget redirection;
        switch (role.toLowerCase()) {
          case 'directeur':
            redirection = const DirectorDashboardScreen();
            break;
          case 'caissier':
            redirection = const CaissierDashboardScreen();
            break;
          case 'cuisine':
            redirection = const CuisineScreen(); // À vérifier si le nom correspond
            break;
          case 'livreur':
            redirection = const LivreurDashboardScreen();
            break;
          default:
            throw "Rôle inconnu.";
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => redirection),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Code secret incorrect.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur d'authentification : $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kSurfaceColor,
        elevation: 0,
        title: const Text(
          "Shokugeki Menu 🍳",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: kPrimaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: kPrimaryColor,
          tabs: const [
            Tab(icon: Icon(Icons.shopping_bag), text: "Espace Client"),
            Tab(icon: Icon(Icons.badge), text: "Personnel Resto"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : TabBarView(
              controller: _tabController,
              children: [
                // --- ONGLET 1 : ESPACE CLIENT ---
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        "Connectez-vous pour commander",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 30),
                      // Champ Email
                      TextField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: "Adresse Email",
                          labelStyle: TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Champ Mot de passe
                      TextField(
                        controller: _passwordController,
                        style: const TextStyle(color: Colors.white),
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Mot de passe",
                          labelStyle: TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _connexionClient,
                          style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
                          child: const Text("Se connecter", style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterScreen()),
                          );
                        },
                        child: const Text(
                          "Pas encore de compte ? Inscrivez-vous gratuitement",
                          style: TextStyle(color: kPrimaryColor),
                        ),
                      ),
                      const SizedBox(height: 40),
                      const DeveloperContactButton(),
                    ],
                  ),
                ),

                // --- ONGLET 2 : PERSONNEL RESTO ---
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        "Accès sécurisé équipe",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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
                      const DeveloperContactButton(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}