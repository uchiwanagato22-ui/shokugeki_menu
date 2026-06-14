import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

// Importations de tes dashboards spécifiques pour éviter les erreurs de classes
import 'director_dashboard_screen.dart';
import 'caissier_dashboard_screen.dart';
import 'livreur_dashboard_screen.dart';
import 'restaurant_workflows_2.dart'; // Contient la vue KitchenDashboard mise à jour

// =========================================================================
// CONSTANTES DE DESIGN CYBER-PREMIUM & INFOS BUSINESS
// =========================================================================
const Color kPrimaryColor = Color(0xFF2196F3); 
const Color kBackgroundColor = Color(0xFF090A0F);
const Color kSurfaceColor = Color(0xFF14161D);
const Color kAccentColor = Color(0xFFFFD700);

// Infos de développeur (Uchiwa Nagato)
const String kDeveloperPhone = "+22232652300";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ShokugekiMenuApp());
}

class ShokugekiMenuApp extends StatelessWidget {
  const ShokugekiMenuApp({super.key});

  Future<void> _initFirebase() async {
    await Firebase.initializeApp().timeout(
      const Duration(seconds: 8),
      onTimeout: () => print("Firebase n'a pas répondu à temps, passage en mode local."),
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
          if (snapshot.connectionState == ConnectionState.done) {
            return const LoginScreen();
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

// =========================================================================
// 1. ÉCRAN D'ACCÈS UNIQUE (CONNEXION STAFF & CLIENT)
// =========================================================================
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

        // FIX : Redirection vers les exacts bons noms de tes fichiers dashboards
        Widget cible = const ClientMainScreen();
        if (role == 'directeur') cible = const DirectorDashboardScreen();
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

// =========================================================================
// 2. INTERFACE CLIENT (MENU, SÉLECTION ET CHEF IA)
// =========================================================================
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
                  return const Center(child: Text("Aucun plat disponible dans cette catégorie. 🍕", style: TextStyle(color: Colors.white38)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final item = docs[index].data() as Map<String, dynamic>;
                    return Card(
                      color: kSurfaceColor,
                      margin: const EdgeInsets.bottom(16),
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

// =========================================================================
// ÉCRAN CONTACT ET PROMOTION BUSINESS (NAGATO)
// =========================================================================
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
      appBar: AppBar(
        title: const Text("Contact & Infos 📍"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
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
            const Text(
              "Shokugeki Restaurant",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const Text(
              "Le meilleur goût numérique de Nouakchott !",
              style: TextStyle(fontSize: 13, color: Colors.white54, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 32),
            
            _infoRow(Icons.location_on, "Adresse", "Nouakchott, Mauritanie"),
            const SizedBox(height: 12),
            _infoRow(Icons.access_time, "Horaires", "7j/7 - De 12h00 à 02h00 du matin"),
            const SizedBox(height: 12),
            _infoRow(Icons.phone, "Téléphone Resto", "+222 46000000"),
            
            const SizedBox(height: 40),
            const Divider(color: Colors.white10),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kPrimaryColor.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.code, color: kPrimaryColor, size: 22),
                      SizedBox(width: 8),
                      Text(
                        "Développé par Uchiwa Nagato",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Vous gérez un commerce, une boutique ou un restaurant à Nouakchott ? Donnez un coup de boost à votre business avec votre propre application mobile !",
                    style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      final message = Uri.encodeComponent("Salut Nagato ! J'ai vu l'application Shokugeki Menu et je voudrais commander un service (site web ou application) pour mon projet.");
                      final whatsappUrl = Uri.parse("https://wa.me/$kDeveloperPhone?text=$message");
                      _lancerUrl(whatsappUrl);
                    },
                    icon: const Icon(Icons.bolt, color: Colors.black),
                    label: const Text(
                      "Demander une Application / Site Web",
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      minimumSize: const Size(double.infinity, 50),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kSurfaceColor, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Icon(icon, color: kPrimaryColor, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// Interface de Chat Automatique pour l'IA
class ChefIAPage extends StatelessWidget {
  const ChefIAPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chef Conseiller IA 👨‍🍳"), backgroundColor: kSurfaceColor),
      body: const ChatInterface(
        msgBot: "Bienvenue chez Shokugeki Menu ! 🍳 Je suis le Chef IA. Quel plat puis-je vous conseiller ce soir ?",
        hintText: "Demandez au Chef... (ex: Que me conseillez-vous ?)",
      ),
    );
  }
}

class ChatInterface extends StatefulWidget {
  final String msgBot;
  final String hintText;
  const ChatInterface({super.key, required this.msgBot, required this.hintText});

  @override
  State<ChatInterface> createState() => _ChatInterfaceState();
}

class _ChatInterfaceState extends State<ChatInterface> {
  final List<Map<String, String>> _messages = [];
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _messages.add({"sender": "bot", "text": widget.msgBot});
  }

  void _envoyerMessage() {
    final texte = _textController.text.trim();
    if (texte.isEmpty) return;

    setState(() {
      _messages.add({"sender": "user", "text": texte});
      _textController.clear();
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          if (widget.hintText.contains("Chef")) {
            _messages.add({"sender": "bot", "text": "Je vous recommande notre fameux Cyber Burger Shokugeki avec sa sauce secrète, un pur délice ! 🍔"});
          } else {
            _messages.add({"sender": "bot", "text": "Le chiffre d'affaires actuel est stable. Toutes les caisses sont opérationnelles et synchronisées à Nouakchott. 📈"});
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final m = _messages[index];
              final isUser = m["sender"] == "user";
              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isUser ? kPrimaryColor : kSurfaceColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  child: Text(m["text"] ?? '', style: const TextStyle(fontSize: 15)),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    filled: true,
                    fillColor: kSurfaceColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send, color: kPrimaryColor),
                onPressed: _envoyerMessage,
              )
            ],
          ),
        )
      ],
    );
  }
}