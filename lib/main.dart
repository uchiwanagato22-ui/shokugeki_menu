import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'login_screen.dart';
import 'constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialisation de ton Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ShokugekiMenuApp());
}

class ShokugekiMenuApp extends StatelessWidget {
  const ShokugekiMenuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: kBackgroundColor,
        primaryColor: kPrimaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPrimaryColor,
          primary: kPrimaryColor,
          secondary: kSecondaryColor,
        ),
        useMaterial3: true,
      ),
      // 🔒 ÉCOUTE EN TEMPS RÉEL DE TON INTERRUPTEUR FIRESTORE
      home: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('configuration')
            .doc('statut')
            .snapshots(),
        builder: (context, snapshot) {
          // Écran d'attente pendant que Firebase charge
          if (!snapshot.hasData) {
            return const Scaffold(
              backgroundColor: Color(0xFF111115),
              body: Center(
                child: CircularProgressIndicator(color: kPrimaryColor),
              ),
            );
          }

          // Extraction des données du document 'statut'
          var data = snapshot.data!.data() as Map<String, dynamic>?;
          bool isActive = data?['is_active'] ?? true;
          String messageBlocage = data?['message_blocage'] ?? "Service temporairement indisponible. Veuillez contacter l'administrateur.";

          // 🚨 SI TU METS FAUX (false) SUR FIRESTORE : L'APPLICATION SE COUPE DIRECTEMENT
          if (!isActive) {
            return Scaffold(
              backgroundColor: const Color(0xFF7F1D1D), // Rouge sombre
              body: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.block_rounded, size: 90, color: Colors.white),
                      const SizedBox(height: 24),
                      Text(
                        messageBlocage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // ✅ SI C'EST VRAI (true) : L'APPLI CONTINUE NORMALEMENT VERS LE LOGIN
          return const LoginScreen();
        },
      ),
    );
  }
}