import 'package:flutter/material.dart';
import 'constants.dart';
import 'client_home_screen.dart';
import 'directeur_dashboard_screen.dart';
import 'caissier_dashboard_screen.dart';
import 'livreur_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _inputController = TextEditingController();
  bool _isLoading = false;

  void _verifierConnexion() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    String code = _inputController.text.trim();

    // --- LE DISPATCHING ACTIF ET COMPLET SELON TES CODES SECRETS ---
    if (code == "3265" || code == "2000") {
      // Rôle : Directeur / Gérant
      setState(() => _isLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => const DirectorDashboardScreen()),
      );
    } else if (code == "2300") {
      // Rôle : Caissier
      setState(() => _isLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => const CaissierDashboardScreen()),
      );
    } else if (code == "3223") {
      // Rôle : Livreur
      setState(() => _isLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LivreurDashboardScreen()),
      );
    } else {
      // Tout autre code ou numéro de téléphone = Client
      setState(() => _isLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ClientHomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.restaurant_menu,
                    size: 80, color: kPrimaryColor),
                const SizedBox(height: 16),
                const Text(
                  "Shokugeki Menu",
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _inputController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Numéro de téléphone ou Code Secret",
                    labelStyle: const TextStyle(color: Colors.grey),
                    hintText: "Ex: 46XXXXXX ou 2000, 2300, 3265",
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF1A1A22),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon:
                        const Icon(Icons.lock_outline, color: kPrimaryColor),
                  ),
                  validator: (val) =>
                      val!.isEmpty ? "Veuillez remplir ce champ" : null,
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator(color: kPrimaryColor)
                    : ElevatedButton(
                        onPressed: _verifierConnexion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Entrer",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
