import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

// Constantes de Design Cyber-Premium
const Color kPrimaryColor = Color(0xFF2196F3); 
const Color kBackgroundColor = Color(0xFF090A0F);
const Color kSurfaceColor = Color(0xFF14161D);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ShokugekiMenuApp());
}

class ShokugekiMenuApp extends StatelessWidget {
  const ShokugekiMenuApp({super.key});

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
      home: const LoginScreen(),
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
      // 1. On cherche d'abord si c'est un Code Secret du Personnel
      final staffQuery = await FirebaseFirestore.instance
          .collection('personnel')
          .where('code_secret', isEqualTo: entree)
          .limit(1)
          .get();

      if (staffQuery.docs.isNotEmpty) {
        final data = staffQuery.docs.first.data();
        final role = data['role']?.toString().trim() ?? '';

        Widget cible = const ClientMainScreen();
        if (role == 'directeur') cible = const DirecteurDashboard();
        if (role == 'caissier') cible = const CaissierDashboard();
        if (role == 'cuisine') cible = const KitchenDashboard();
        if (role == 'livreur') cible = const LivreurDashboard();

        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => cible));
        }
        return;
      }

      // 2. Si ce n'est pas un code staff, on considère que c'est un numéro client
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
                  hintText: "Ex: 46XXXXXX ou 2300, 3265...",
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
    const Center(child: Text("Contact : Nouakchott, Mauritanie", style: TextStyle(color: Colors.white54))),
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
// 3. LA CUISINE (REÇOIT ET PRÉPARE)
// =========================================================================
class KitchenDashboard extends StatelessWidget {
  const KitchenDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("CUISINE - LIVE"), backgroundColor: kSurfaceColor),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('commandes').where('statut', isEqualTo: 'en_preparation').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("Aucune commande en préparation. 🍳", style: TextStyle(color: Colors.white38)));

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return Container(
                decoration: BoxDecoration(color: kSurfaceColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.amber.withOpacity(0.5))),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("COMMANDE #${doc.id.substring(0,4)}", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Expanded(child: Text(data['details'] ?? 'Plat Shokugeki unique', style: const TextStyle(fontSize: 16))),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        onPressed: () => doc.reference.update({'statut': 'pret_pour_livraison'}),
                        child: const Text("Prêt !", style: TextStyle(color: Colors.white)),
                      ),
                    )
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

// =========================================================================
// 4. LE LIVREUR (ADRESSE DÉTAILLÉE + GOOGLE MAPS DIRECT)
// =========================================================================
class LivreurDashboard extends StatelessWidget {
  const LivreurDashboard({super.key});

  Future<void> _ouvrirMaps(String quartier) async {
    final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('$quartier, Nouakchott, Mauritanie')}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SUIVI DES COURSES (NOUAKCHOTT)"), backgroundColor: kSurfaceColor),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('commandes').where('statut', isEqualTo: 'pret_pour_livraison').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("Aucune course disponible. ☕", style: TextStyle(color: Colors.white38)));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final quartier = data['quartier'] ?? "Tevragh Zeina";
              final reperes = data['indications_adresse'] ?? "Près du rond-point";

              return Card(
                color: kSurfaceColor,
                margin: const EdgeInsets.bottom(16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Client: ${data['client_nom'] ?? 'Anonyme'}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text("📍 Quartier : $quartier", style: const TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold)),
                      Text("🏠 Repères : $reperes", style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _ouvrirMaps(quartier),
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.cyan)),
                              child: const Text("Google Maps", style: TextStyle(color: Colors.cyan)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => doc.reference.update({'statut': 'livre'}),
                              style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
                              child: const Text("Livré ✓", style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// =========================================================================
// 5. LE CAISSIER (VALIDATION COMPTABLE)
// =========================================================================
class CaissierDashboard extends StatelessWidget {
  const CaissierDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("CONSOLE CAISSE & STATS"), backgroundColor: kSurfaceColor),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('commandes').where('statut', isEqualTo: 'en_attente').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatCard("Recette", "0 MRU", Colors.green),
                    _buildStatCard("Validées", "${docs.length}", kPrimaryColor),
                    _buildStatCard("Fraudes", "0", Colors.redAccent),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(alignment: Alignment.centerLeft, child: Text("COMMANDES DU JOUR", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white54))),
              ),
              Expanded(
                child: docs.isEmpty
                    ? const Center(child: Text("Aucune commande enregistrée aujourd'hui. 📅", style: TextStyle(color: Colors.white38)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          return Card(
                            color: kSurfaceColor,
                            child: ListTile(
                              title: Text(data['client_nom'] ?? 'Commande'),
                              subtitle: Text("Total: ${data['total'] ?? 0} MRU"),
                              trailing: IconButton(
                                icon: const Icon(Icons.check_circle, color: Colors.green),
                                onPressed: () => doc.reference.update({'statut': 'en_preparation'}),
                              ),
                            ),
                          );
                        },
                      ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String titre, String valeur, Color couleur) {
    return Container(
      width: 105,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: kSurfaceColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lens, size: 12, color: couleur),
          const SizedBox(height: 8),
          Text(titre, style: const TextStyle(fontSize: 12, color: Colors.white54)),
          Text(valeur, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// =========================================================================
// 6. LE DIRECTEUR & L'IA AUDIT
// =========================================================================
class DirecteurDashboard extends StatelessWidget {
  const DirecteurDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("BUREAU DU DIRECTEUR"), backgroundColor: kSurfaceColor),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("📊 Rapports & Audit IA", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Expanded(
              child: ChatInterface(
                msgBot: "Je suis votre assistant de gestion Shokugeki. Demandez-moi combien on a gagné ou un résumé complet de la boutique !",
                hintText: "Ex: Combien on a gagné aujourd'hui...",
              ),
            )
          ],
        ),
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

    // Simulation de réponse de l'IA sans plantage API
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