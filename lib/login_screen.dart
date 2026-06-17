import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'caissier_dashboard_screen.dart';
import 'cuisine_screen.dart';
import 'directeur_dashboard_screen.dart';
import 'livreur_dashboard_screen.dart';
import 'restaurant_app_config.dart';
import 'staff_access_service.dart';
import 'subscription_guard.dart';
import '../widgets/developer_contact_button.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final AuthService _authService = AuthService();

  // Controllers Client
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Controller Personnel
  final _codeController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _verifierBlocageApplication();
  }

  Future<void> _verifierBlocageApplication() async {
    Map<String, dynamic> statut =
        await _authService.verifierStatutApplication();
    if (!statut['is_active']) {
      _afficherDialogueBlocage(statut['message']);
    }
  }

  void _afficherDialogueBlocage(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 10),
            Text("Application Bloquée"),
          ],
        ),
        content: Text(message),
        actions: [
          const Center(child: DeveloperContactButton()),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Future<void> _connexionClient() async {
    setState(() => _isLoading = true);
    try {
      var user = await _authService.connecterClient(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (user != null) {
        // Redirection vers l'accueil client
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Connexion réussie !")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : ${e.toString()}")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _connexionPersonnel() async {
    if (_codeController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);

    final result = await StaffAccessService().verifyCode(
      restaurantId: defaultRestaurantId,
      code: _codeController.text.trim(),
    );

    setState(() => _isLoading = false);

    final role = result.role;
    if (result.allowed && role != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Accès autorisé : ${role.label}")),
      );

      Widget cible;
      switch (role) {
        case StaffRole.caissier:
          cible = const CaissierDashboardScreen();
          break;
        case StaffRole.livreur:
          cible = const LivreurDashboardScreen();
          break;
        case StaffRole.cuisine:
          cible = const CuisineScreen();
          break;
        case StaffRole.directeur:
          cible = const DirectorDashboardScreen();
          break;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SubscriptionGuard(
            restaurantId: defaultRestaurantId,
            child: cible,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? "Code secret incorrect."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Logo de l'application
              Image.asset('assets/icon/logo.png', height: 100,
                  errorBuilder: (c, e, s) {
                return const Icon(Icons.restaurant_menu,
                    size: 80, color: Colors.deepOrange);
              }),
              const SizedBox(height: 10),
              const Text(
                "SHOKUGEKI MENU",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2),
              ),
              const SizedBox(height: 30),

              // Sélecteur d'onglets (Client vs Personnel)
              TabBar(
                controller: _tabController,
                labelColor: Colors.deepOrange,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.deepOrange,
                tabs: const [
                  Tab(text: "Espace Client"),
                  Tab(text: "Personnel"),
                ],
              ),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Vue Client
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          TextField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                                labelText: "Adresse Email",
                                border: OutlineInputBorder()),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: _passwordController,
                            decoration: const InputDecoration(
                                labelText: "Mot de passe",
                                border: OutlineInputBorder()),
                            obscureText: true,
                          ),
                          const SizedBox(height: 20),
                          _isLoading
                              ? const CircularProgressIndicator()
                              : SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _connexionClient,
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.deepOrange),
                                    child: const Text("Se connecter",
                                        style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                          TextButton(
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const RegisterScreen())),
                            child: const Text("Créer un compte client"),
                          )
                        ],
                      ),
                    ),

                    // Vue Personnel
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          const Text(
                              "Entrez votre code d'accès secret à 4 chiffres :"),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _codeController,
                            decoration: const InputDecoration(
                              labelText: "Code Secret",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.lock),
                            ),
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            textAlign: TextAlign.center,
                            maxLength: 4,
                          ),
                          const SizedBox(height: 20),
                          _isLoading
                              ? const CircularProgressIndicator()
                              : SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _connexionPersonnel,
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.black),
                                    child: const Text("Valider Code",
                                        style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const DeveloperContactButton(),
            ],
          ),
        ),
      ),
    );
  }
}
