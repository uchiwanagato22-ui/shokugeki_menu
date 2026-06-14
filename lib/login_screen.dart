import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Contrôleurs Client
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nomController = TextEditingController();
  final _telephoneController = TextEditingController();

  // Contrôleur Staff (Code Secret)
  final _staffCodeController = TextEditingController();
  
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isSignUpMode = false;
  bool _isStaffMode = false; // Bascule entre Mode Client et Mode Staff

  // Soumission globale
  Future<void> _handleSubmit() async {
    setState(() => _isLoading = true);

    try {
      if (_isStaffMode) {
        // --- CONNEXION STAFF PAR CODE SECRET ---
        final codeSecret = _staffCodeController.text.trim();
        if (codeSecret.length < 4) {
          _showSnackBar("Le code secret doit comporter au moins 4 chiffres.", const Color(0xFF7F1D1D));
          setState(() => _isLoading = false);
          return;
        }

        // Requête de vérification dans Firestore
        final staffQuery = await FirebaseFirestore.instance
            .collection('personnel')
            .where('code_secret', isEqualTo: codeSecret)
            .limit(1)
            .get();

        if (staffQuery.docs.isEmpty) {
          _showSnackBar("Code secret incorrect. Accès refusé.", const Color(0xFF7F1D1D));
        } else {
          final staffData = staffQuery.docs.first.data();
          String role = staffData['role'] ?? 'inconnu';
          _showSnackBar("Accès accordé : ${role.toUpperCase()}", Colors.green);
          
          // Ici, ton Gatekeeper redirigera vers le bon dashboard :
          // 'directeur', 'caissier', 'livreur', ou 'cuisine' !
        }
      } else {
        // --- MODE CLIENT (Email/Mot de passe) ---
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();

        if (_isSignUpMode) {
          // Inscription Client
          UserCredential userCredential = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(email: email, password: password);

          await FirebaseFirestore.instance
              .collection('utilisateurs')
              .doc(userCredential.user!.uid)
              .set({
            'nom': _nomController.text.trim(),
            'email': email,
            'telephone': _telephoneController.text.trim(),
            'role': 'client',
            'date_creation': FieldValue.serverTimestamp(),
          });
        } else {
          // Connexion Client
          await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
        }
      }
    } on FirebaseAuthException catch (e) {
      String msg = "Erreur d'authentification.";
      if (e.code == 'user-not-found') msg = "Compte introuvable.";
      if (e.code == 'wrong-password') msg = "Mot de passe incorrect.";
      _showSnackBar(msg, const Color(0xFF7F1D1D));
    } catch (e) {
      _showSnackBar("Erreur système.", const Color(0xFF7F1D1D));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: bgColor, content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A0F),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              children: [
                // Logo Épuré Cyber
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isStaffMode ? Icons.shield_outlined : Icons.restaurant_menu_rounded, 
                    size: 60, 
                    color: kPrimaryColor
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _isStaffMode ? "Espace Personnel" : (_isSignUpMode ? "Créer un compte" : kAppName),
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),

                if (_isStaffMode) ...[
                  // --- FORMULAIRE CODE SECRET STAFF ---
                  TextField(
                    controller: _staffCodeController,
                    keyboardType: TextInputType.number,
                    obscureText: true, // Masque le code secret pour la sécurité
                    style: const TextStyle(color: Colors.white, fontSize: 22, letterSpacing: 8),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      labelText: "Entrez votre Code Agent",
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14, letterSpacing: 0),
                      filled: true,
                      fillColor: const Color(0xFF14161D),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kPrimaryColor, width: 2)),
                    ),
                  ),
                ] else ...[
                  // --- FORMULAIRE CLIENT ---
                  if (_isSignUpMode) ...[
                    TextField(
                      controller: _nomController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputStyle("Nom complet", Icons.person_outline),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _telephoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputStyle("Numéro de téléphone", Icons.phone_android),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputStyle("Adresse Email", Icons.email_outlined),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Mot de passe",
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                      prefixIcon: const Icon(Icons.lock_outline, color: kPrimaryColor),
                      suffixIcon: IconButton(
                        icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility, color: Colors.white.withOpacity(0.4)),
                        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF14161D),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kPrimaryColor, width: 2)),
                    ),
                  ),
                ],

                const SizedBox(height: 32),
                
                // Bouton Principal
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : Text(_isStaffMode ? "S'authentifier" : (_isSignUpMode ? "S'inscrire" : "Connexion"), style: const TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
                
                const SizedBox(height: 20),

                // Liens de basculement alternatifs
                if (!_isStaffMode)
                  TextButton(
                    onPressed: () => setState(() => _isSignUpMode = !_isSignUpMode),
                    child: Text(_isSignUpMode ? "Déjà membre ? Connexion" : "Nouveau ? Créer un compte", style: const TextStyle(color: kPrimaryColor)),
                  ),
                  
                // Bouton pour basculer entre Mode Client et Mode Équipe Restaurant
                TextButton(
                  onPressed: () => setState(() {
                    _isStaffMode = !_isStaffMode;
                    _isSignUpMode = false;
                  }),
                  child: Text(
                    _isStaffMode ? "Accès Client (Email)" : "Accès Personnel (Code Secret)", 
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
      prefixIcon: Icon(icon, color: kPrimaryColor),
      filled: true,
      fillColor: const Color(0xFF14161D),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kPrimaryColor, width: 2)),
    );
  }
}