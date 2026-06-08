import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'constants.dart';
import 'role_router.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool _isRegistering = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _gererConnexion() async {
    if (!_formKey.currentState!.validate()) return;

    String emailInput = _emailController.text.trim();
    String passwordInput = _passwordController.text.trim();

    // 🔑 COUPE-CIRCUIT STAFF AMÉLIORÉ (Utilise tes vraies constantes de constants.dart)
    if (emailInput == kCodeDirecteur || emailInput == kCodeCaissier || emailInput == kCodeLivreur) {
      String role = "client";
      if (emailInput == kCodeDirecteur) role = "directeur";
      if (emailInput == kCodeCaissier) role = "caissier";
      if (emailInput == kCodeLivreur) role = "livreur";

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => RoleRouter(userRole: role)),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isRegistering) {
        await _auth.createUserWithEmailAndPassword(email: emailInput, password: passwordInput);
      } else {
        await _auth.signInWithEmailAndPassword(email: emailInput, password: passwordInput);
      }
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RoleRouter(userRole: 'client')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur d'authentification : ${e.toString()}"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSecondaryColor,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.restaurant_menu, size: 80, color: kPrimaryColor),
                  const SizedBox(height: 16),
                  Text(
                    kAppName.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Code PIN ou Email",
                      labelStyle: const TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: kPrimaryColor), borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v == null || v.isEmpty ? "Ce champ est obligatoire" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Mot de passe (Clients)",
                      labelStyle: const TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: kPrimaryColor), borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const CircularProgressIndicator(color: kPrimaryColor)
                      : ElevatedButton(
                          onPressed: _gererConnexion,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            _isRegistering ? "S'inscrire" : "Se connecter",
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                  TextButton(
                    onPressed: () => setState(() => _isRegistering = !_isRegistering),
                    child: Text(
                      _isRegistering ? "Déjà un compte ? Connexion" : "Nouveau client ? Créer un compte",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}