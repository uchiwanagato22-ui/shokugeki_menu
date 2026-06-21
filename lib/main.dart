import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Ajouté pour la persistance de session
import 'package:url_launcher/url_launcher.dart';

// --- IMPORTS RÉELS ET VÉRIFIÉS ---
import 'directeur_dashboard_screen.dart'; 
import 'caissier_dashboard_screen.dart';
import 'livreur_dashboard_screen.dart';
import 'restaurant_workflows.dart'; 
import 'default_menu_plats.dart'; 
import 'notification_service.dart'; 
import 'cuisine_screen.dart';
import 'chef_ia_screen.dart';
import 'login_screen.dart';

const Color kPrimaryColor = Color(0xFF2196F3); 
const Color kBackgroundColor = Color(0xFF090A0F);
const Color kSurfaceColor = Color(0xFF14161D);
const Color kAccentColor = Color(0xFFFFD700);
const String kAppName = "Shokugeki Menu";
const String kDeveloperPhone = "+22232652300";

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Notification reçue en arrière-plan : ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ShokugekiMenuApp());
}

class ShokugekiMenuApp extends StatelessWidget {
  const ShokugekiMenuApp({super.key});

  Future<FirebaseApp> _initialiserConfigurationComplete() async {
    FirebaseApp app = await Firebase.initializeApp().timeout(
      const Duration(seconds: 8),
      onTimeout: () => throw Exception("Firebase ne répond pas."),
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await NotificationService.instance.init();

    final menuSnapshot = await FirebaseFirestore.instance.collection('menu').limit(1).get();
    if (menuSnapshot.docs.isEmpty) {
      for (var plat in kPlatsExempleMauritanie) {
        await FirebaseFirestore.instance.collection('menu').add({
          'nom': plat['nom'],
          'description': plat['description'],
          'prix': plat['prix'],
          'categorie': plat['categorie'],
          'image': plat['image'],
          'disponible': true,
          'date_creation': FieldValue.serverTimestamp(),
        });
      }
    }
    
    return app;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shokugeki Menu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: kBackgroundColor,
        primaryColor: kPrimaryColor,
        colorScheme: const ColorScheme.dark(
          primary: kPrimaryColor,
          surface: kSurfaceColor,
        ),
      ),
      home: FutureBuilder(
        future: _initialiserConfigurationComplete(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && !snapshot.hasError) {
            // Écoute en temps réel de l'état d'authentification pour éviter la déconnexion automatique
            return StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, authSnapshot) {
                if (authSnapshot.connectionState == ConnectionState.active) {
                  User? user = authSnapshot.data;
                  if (user == null) {
                    return const LoginScreen();
                  } else {
                    return const ClientMainScreen();
                  }
                }
                return const Scaffold(
                  backgroundColor: kBackgroundColor,
                  body: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
                );
              },
            );
          }
          if (snapshot.hasError) {
            return const Scaffold(
              backgroundColor: kBackgroundColor,
              body: Center(child: Text("Erreur d'initialisation Firebase", style: TextStyle(color: Colors.red))),
            );
          }
          return const Scaffold(
            backgroundColor: kBackgroundColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu_rounded, size: 80, color: kPrimaryColor),
                  SizedBox(height: 24),
                  CircularProgressIndicator(color: kPrimaryColor),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ClientMainScreen extends StatefulWidget {
  const ClientMainScreen({super.key});

  @override
  State<ClientMainScreen> createState() => _ClientMainScreenState();
}

class _ClientMainScreenState extends State<ClientMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const MenuClientPage(),
    const Center(child: Text("Mes Commandes 📦", style: TextStyle(color: Colors.white, fontSize: 18))),
    const ChefIaScreen(),
    const AboutContactPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: kSurfaceColor,
        indicatorColor: kPrimaryColor.withOpacity(0.2),
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.restaurant_menu, color: Colors.white), label: "Menu"),
          NavigationDestination(icon: Icon(Icons.receipt_long, color: Colors.white), label: "Commandes"),
          NavigationDestination(icon: Icon(Icons.psychology, color: Colors.white), label: "Chef IA"),
          NavigationDestination(icon: Icon(Icons.info_outline, color: Colors.white), label: "Infos"),
        ],
      ),
    );
  }
}

class MenuClientPage extends StatelessWidget {
  const MenuClientPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Le Menu Shokugeki 🍳", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: kSurfaceColor,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('menu').orderBy('nom').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Erreur de chargement du menu.", style: TextStyle(color: Colors.white)));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text("Aucun plat disponible pour le moment.", style: TextStyle(color: Colors.grey)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final plat = docs[index].data() as Map<String, dynamic>;
              final bool disponible = plat['disponible'] ?? true;

              if (!disponible) return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kSurfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: plat['image'] != null && plat['image'].toString().startsWith('http')
                          ? Image.network(plat['image'], width: 80, height: 80, fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => 
                                  Container(width: 80, height: 80, color: Colors.grey[900], child: const Icon(Icons.fastfood, color: Colors.grey)))
                          : Container(width: 80, height: 80, color: Colors.grey[900], child: const Icon(Icons.fastfood, color: Colors.grey)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(plat['nom'] ?? 'Plat anonyme', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(plat['description'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 8),
                          Text("${plat['prix']} MRU", style: const TextStyle(color: kAccentColor, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_shopping_cart, color: kPrimaryColor),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("${plat['nom']} ajouté au panier !")),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AboutContactPage extends StatelessWidget {
  const AboutContactPage({super.key});

  Future<void> _lancerUrl(Uri url) async {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint("Impossible d'ouvrir : $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Contact & Infos 📍"), backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 45,
              backgroundColor: kSurfaceColor,
              child: Icon(Icons.restaurant_menu_rounded, size: 50, color: kPrimaryColor),
            ),
            const SizedBox(height: 16),
            const Text("Shokugeki Restaurant", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            _infoRow(Icons.location_on, "Adresse", "Nouakchott, Mauritanie"),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                final whatsappUrl = Uri.parse("https://wa.me/$kDeveloperPhone");
                _lancerUrl(whatsappUrl);
              },
              style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
              child: const Text("Contacter Nagato"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: kPrimaryColor),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        )
      ],
    );
  }
}