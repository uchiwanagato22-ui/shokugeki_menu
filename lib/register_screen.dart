import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'developer_contact_button.dart';
import 'constants.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _creerCompte() async {
    if (_nomController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _telController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Veuillez remplir tous les champs.")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      var credential = await _authService.inscrireClient(
        nom: _nomController.text.trim(),
        email: _emailController.text.trim(),
        telephone: _telController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (credential != null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Compte créé avec succès ! Connectez-vous.")));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de l'inscription : $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text("Créer un compte Client", style: TextStyle(color: Colors.white)),
        backgroundColor: kSurfaceColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            TextField(
              controller: _nomController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Nom complet", labelStyle: TextStyle(color: Colors.grey), border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Adresse Email", labelStyle: TextStyle(color: Colors.grey), border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _telController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                  labelText: "Numéro de téléphone (Livraison)",
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                  prefixText: "+ "),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Mot de passe", labelStyle: TextStyle(color: Colors.grey), border: OutlineInputBorder()),
              obscureText: true,
            ),
            const SizedBox(height: 25),
            _isLoading
                ? const CircularProgressIndicator(color: kPrimaryColor)
                : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _creerCompte,
                      style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
                      child: const Text("Créer mon compte", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
            const SizedBox(height: 30),
            const DeveloperContactButton(),
          ],
        ),
      ),
    );
  }
}