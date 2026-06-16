import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/developer_contact_button.dart';

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
    if (_nomController.text.isEmpty || _emailController.text.isEmpty || _telController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez remplir tous les champs.")));
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Compte créé avec succès !")));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur d'inscription : ${e.toString()}")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inscription Client"),
        centerTitle: true,
        backgroundColor: Colors.deepOrange,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              TextField(
                controller: _nomController,
                decoration: const InputDecoration(labelText: "Nom complet", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Adresse Email", border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _telController,
                decoration: const InputDecoration(labelText: "Numéro de téléphone (Livrson)", border: OutlineInputBorder(), prefixText: "+ "),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Mot de passe", border: OutlineInputBorder()),
                obscureText: true,
              ),
              const SizedBox(height: 25),
              _isLoading 
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _creerCompte,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                      child: const Text("Créer mon compte", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
              const SizedBox(height: 30),
              const DeveloperContactButton(),
            ],
          ),
        ),
      ),
    );
  }
}