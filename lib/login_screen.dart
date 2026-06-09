import 'package:flutter/material.dart';
import 'constants.dart';
import 'client_home_screen.dart';
import 'directeur_dashboard_screen.dart';
// import 'caissier_dashboard_screen.dart';
// import 'livreur_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _inputController =
      TextEditingController(); // Reçoit le numéro ou le code secret
  bool _isLoading = false;

  void _verifierConnexion() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    String code = _inputController.text.trim();

    // --- LE DISPATCHING COMPLET SELON TES CODES SECRETS ---
    if (code == "2000") {
      // Rôle : Directeur / Gérant
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const DirectorDashboardScreen()));
    } else if (code == "2300") {
      // Rôle : Caissier
      _afficherMessage("Accès Caisse accordé ! 🛒");
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const CaissierDashboardScreen()));
    } else if (code == "3265") {
      // Rôle : Livreur
      _afficherMessage("Accès Livreur accordé ! 🏍️");
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LivreurDashboardScreen()));
    } else if (code.length >= 8) {
      // Si c'est un numéro de téléphone (ex: 8 chiffres en Mauritanie), c'est un Client !
      _afficherMessage("Bienvenue chez Shokugeki Menu ! 🍔");
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => const ClientHomeScreen()));
    } else {
      _afficherMessage("Code ou numéro invalide. ❌");
    }

    setState(() => _isLoading = false);
  }

  void _afficherMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "SHOKUGEKI MENU",
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: kSecondaryColor,
                      letterSpacing: 2),
                ),
                const SizedBox(height: 8),
                const Text("Connexion sécurisée Staff & Clients",
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _inputController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Numéro de téléphone ou Code Secret",
                    hintText: "Ex: 46XXXXXX ou 2000, 2300, 3265",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.lock_outline),
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
                          backgroundColor: kSecondaryColor,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Entrer",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
