import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

// --- ATTENTION : VÉRIFIE BIEN LE NOM DE TES ÉCRANS ICI ---
import 'directeur_dashboard_screen.dart'; // Corrigé si ton fichier est en français
import 'caissier_dashboard_screen.dart';
import 'livreur_dashboard_screen.dart';
// Si ton fichier s'appelle autrement pour la cuisine, change cette ligne :
import 'restaurant_workflows_2.dart'; 

const Color kPrimaryColor = Color(0xFF2196F3); 
const Color kBackgroundColor = Color(0xFF090A0F);
const Color kSurfaceColor = Color(0xFF14161D);
const Color kAccentColor = Color(0xFFFFD700);
const String kAppName = "Shokugeki Menu";
const String kDeveloperPhone = "+22232652300";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ShokugekiMenuApp());
}

class ShokugekiMenuApp extends StatelessWidget {
  const ShokugekiMenuApp({super.key});

  Future<FirebaseApp> _initFirebase() async {
    // CORRECTION : On retourne correctement l'initialisation ou on lève une exception en cas de timeout
    return await Firebase.initializeApp().timeout(
      const Duration(seconds: 8),
      onTimeout: () => throw Exception("Firebase n'a pas répondu à temps."),
    );
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
        future: _initFirebase(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && !snapshot.hasError) {
            return const LoginScreen();
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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _inputController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verifierAuthentification() async {
    final entree = _inputController.text.trim();
    if (entree.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final staffQuery = await FirebaseFirestore.instance
          .collection('personnel')
          .where('code_secret', isEqualTo: entree)
          .limit(1)
          .get();

      if (staffQuery.docs.isNotEmpty) {
        final data = staffQuery.docs.first.data();
        final role = data['role']?.toString().trim() ?? '';

        Widget cible = const ClientMainScreen();
        
        // CORRECTION : Suppression des 'const' invalides devant les classes ici
        if (role == 'directeur') cible = const DirecteurDashboardScreen();
        if (role == 'caissier') cible = const CaissierDashboardScreen();
        if (role == 'cuisine') cible = const KitchenDashboard();
        if (role == 'livreur') cible = const LivreurDashboardScreen();

        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => cible));
        }
        return;
      }

      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ClientMainScreen()));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.red, content: Text("Erreur de connexion.")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.restaurant_menu_rounded, size: 80, color: kPrimaryColor),
              const SizedBox(height: 16),
              const Text(
                "Shokugeki Menu",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _inputController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Numéro de téléphone ou Code Secret",
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  prefixIcon: const Icon(Icons.lock_outline, color: kPrimaryColor),
                  hintText: "Ex: 46XXXXXX ou code staff...",
                  filled: true,
                  fillColor: kSurfaceColor,
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kPrimaryColor, width: 2)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifierAuthentification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Entrer", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
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
    const Center(child: Text("Vos Commandes s'afficheront ici", style: TextStyle(color: Colors.white54))),
    const ChefIAPage(),
    const AboutContactPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: kSurfaceColor,
        selectedItemColor: kPrimaryColor,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: "Menu"),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: "Commandes"),
          BottomNavigationBarItem(icon: Icon(Icons.psychology), label: "Chef IA"),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: "Contact"),
        ],
      ),
    );
  }
}

class MenuClientPage extends StatefulWidget {
  const MenuClientPage({super.key});

  @override
  State<MenuClientPage> createState() => _MenuClientPageState();
}

class _MenuClientPageState extends State<MenuClientPage> {
  String _selectedCategory = "Tout";
  final List<String> _categories = ["Tout", "Burgers", "Pizzas", "Poulet"];

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('menu');
    if (_selectedCategory != "Tout") {
      query = query.where('categorie', isEqualTo: _selectedCategory);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notre Menu 🍽️", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0, top: 8, bottom: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: Colors.amber,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text("Aucun plat disponible.", style: TextStyle(color: Colors.white38)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final item = docs[index].data() as Map<String, dynamic>;
                    return Card(
                      color: kSurfaceColor,
                      // CORRECTION : Remplacement de EdgeInsets.bottom par EdgeInsets.only
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(item['nom'] ?? 'Plat', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        subtitle: Text(item['description'] ?? '', style: const TextStyle(color: Colors.white54)),
                        trailing: Text("${item['categorie'] == 'Burgers' ? '250' : '200'} MRU", style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AboutContactPage extends StatelessWidget {
  const AboutContactPage({super.key});

  Future<void> _lancerUrl(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
        Text("$label: $value"),
      ],
    );
  }
}

class ChefIAPage extends StatelessWidget {
  const ChefIAPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text("Chef IA")));
  }
}