import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'login_screen.dart';
import 'constants.dart';
import 'notification_service.dart';
import 'splash_screen.dart';
import 'widgets/restaurant_logo.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.instance.init();
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
      home: SplashScreen(child: const _AppGatekeeper()),
    );
  }
}

class _AppGatekeeper extends StatelessWidget {
  const _AppGatekeeper();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('configuration')
          .doc('statut')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: kSecondaryColor,
            body:
                Center(child: CircularProgressIndicator(color: kPrimaryColor)),
          );
        }

        var data = snapshot.data!.data() as Map<String, dynamic>?;
        bool isActive = data?['is_active'] ?? true;
        String messageBlocage = data?['message_blocage'] ??
            "Service temporairement indisponible. Veuillez contacter l'administrateur.";

        if (!isActive) {
          return Scaffold(
            backgroundColor: const Color(0xFF7F1D1D),
            body: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const RestaurantLogo(size: 70),
                    const SizedBox(height: 24),
                    const Icon(Icons.block_rounded,
                        size: 60, color: Colors.white70),
                    const SizedBox(height: 16),
                    Text(
                      messageBlocage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return const LoginScreen();
      },
    );
  }
}
