import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

// =========================================================================
// CONSTANTES DE DESIGN CYBER-PREMIUM & INFOS BUSINESS
// =========================================================================
const Color kPrimaryColor = Color(0xFF2196F3); 
const Color kBackgroundColor = Color(0xFF090A0F);
const Color kSurfaceColor = Color(0xFF14161D);
const Color kAccentColor = Color(0xFFFFD700);

// Infos développeur pour le bouton Business
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
// SERVICE IA REPRENANT LES CALCULS COMPTABLES FIRESTORE DU DIRECTEUR
// =========================================================================
class DirectorIaService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> repondreAuDirecteur(String question) async {
    String q = question.toLowerCase();

    try {
      QuerySnapshot cmdSnapshot = await _db.collection('commandes').get();
      List<DocumentSnapshot> docs = cmdSnapshot.docs;

      int chiffreAffaires = 0;
      int commandesAttente = 0;
      int commandesLivrees = 0;

      for (var doc in docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        int total = data['total'] ?? 0;
        String statut = data['statut'] ?? '';

        if (statut != "Rejeté / Fraude suspectée" && statut != "en_attente") {
          chiffreAffaires += total;
        }

        if (statut == "en_attente") {
          commandesAttente++;
        } else if (statut == "livre") {
          commandesLivrees++;
        }
      }

      if (q.contains("gagné") || q.contains("chiffre d'affaires") || q.contains("argent") || q.contains("ca") || q.contains("prix")) {
        return "Chef Nagato, d'après les calculs en temps réel de Firestore, le chiffre d'affaires actuel de la boutique est de **$chiffreAffaires MRU**. 💰";
      } else if (q.contains("attente") || q.contains("valider") || q.contains("caisse") || q.contains("nombre")) {
        return "Directeur, il y a actuellement **$commandesAttente commande(s) en attente** à la caisse. **$commandesLivrees** commandes ont été livrées aujourd'hui sur un total de **${docs.length}** enregistrées. 🚀";
      } else if (q.contains("statut") || q.contains("résumé") || q.contains("rapport")) {
        return "Voici le rapport flash Shokugeki, Chef :\n\n• Chiffre d'affaires : **$chiffreAffaires MRU**\n• Commandes en attente : **$commandesAttente**\n• Commandes livrées : **$commandesLivrees**\n• Total commandes enregistrées : **${docs.length}**\n\nTout tourne correctement à Nouakchott ! 🔥";
      }

      return "Je suis à vos ordres, Directeur. Je peux vous donner le chiffre d'affaires exact, le statut des commandes ou le résumé global de la journée ! 🍳";
    } catch (e) {
      return "Désolé Chef, j'ai eu un problème pour lire la base de données : ${e.toString()}";
    }
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
                  return const Center(child: Text("Aucun plat disponible. 🍕", style: TextStyle(color: Colors.white38)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final item = docs[index].data() as Map<String, dynamic>;
                    String? urlImg = item['image_url'];
                    
                    return Card(
                      color: kSurfaceColor,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: kBackgroundColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: urlImg != null && urlImg.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        urlImg,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => const Icon(Icons.fastfood, color: Colors.grey),
                                      ),
                                    )
                                  : const Icon(Icons.fastfood, color: Colors.grey),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['nom'] ?? 'Plat', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                  const SizedBox(height: 4),
                                  Text(item['description'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                                ],
                              ),
                            ),
                            Text("${item['prix'] ?? '0'} MRU", style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const CircleAvatar(
              radius: 45,
              backgroundColor: kSurfaceColor,
              child: Icon(Icons.restaurant_menu_rounded, size: 50, color: kPrimaryColor),
            ),
            const SizedBox(height: 16),
            const Text("Shokugeki Restaurant", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text("Le goût premium de Nouakchott !", style: TextStyle(fontSize: 13, color: Colors.white54, fontStyle: FontStyle.italic)),
            const SizedBox(height: 32),
            _infoRow(Icons.location_on, "Adresse", "Nouakchott, Mauritanie"),
            const SizedBox(height: 12),
            _infoRow(Icons.phone, "Téléphone Resto", "+222 46000000"),
            const SizedBox(height: 40),
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
                      Text("Développé par Uchiwa Nagato", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Besoin d'une application ou d'un système de gestion automatisé comme celui-ci pour votre business ?",
                    style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      final message = Uri.encodeComponent("Salut Nagato ! Je souhaite commander une application ou un système de gestion pour mon business.");
                      _lancerUrl(Uri.parse("https://wa.me/$kDeveloperPhone?text=$message"));
                    },
                    icon: const Icon(Icons.bolt, color: Colors.black),
                    label: const Text("Commander mon Application", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      minimumSize: const Size(double.infinity, 50),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
            ],
          )
        ],
      ),
    );
  }
}

// =========================================================================
// 6. LE COMPTOIR DU DIRECTEUR (GESTION DU MENU + VRAI CHAT IA)
// =========================================================================
class DirecteurDashboard extends StatefulWidget {
  const DirecteurDashboard({super.key});

  @override
  State<DirecteurDashboard> createState() => _DirecteurDashboardState();
}

class _DirecteurDashboardState extends State<DirecteurDashboard> {
  final DirectorIaService _iaService = DirectorIaService();
  final TextEditingController _iaController = TextEditingController();
  
  final _nomController = TextEditingController();
  final _prixController = TextEditingController();
  final _descController = TextEditingController();
  final _urlImgController = TextEditingController();
  String _selectedCatAjout = "Burgers";

  final List<Map<String, String>> _iaMessages = [
    {"role": "assistant", "message": "Bonjour Directeur Nagato. 👑 Je suis connecté en temps réel à Firestore. Demandez-moi combien on a gagné, l'état des caisses ou un résumé complet !"}
  ];
  bool _iaLoading = false;

  void _parlerAvecIA() async {
    String question = _iaController.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _iaMessages.add({"role": "user", "message": question});
      _iaController.clear();
      _iaLoading = true;
    });

    String reponse = await _iaService.repondreAuDirecteur(question);

    setState(() {
      _iaMessages.add({"role": "assistant", "message": reponse});
      _iaLoading = false;
    });
  }

  void _ajouterAuMenu() async {
    final nom = _nomController.text.trim();
    final prix = int.tryParse(_prixController.text.trim()) ?? 0;
    final desc = _descController.text.trim();
    final urlImage = _urlImgController.text.trim();

    if (nom.isEmpty || prix <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.red, content: Text("Veuillez remplir au moins le nom et un prix valide !")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('menu').add({
        'nom': nom,
        'prix': prix,
        'description': desc,
        'image_url': urlImage,
        'categorie': _selectedCatAjout,
      });

      _nomController.clear();
      _prixController.clear();
      _descController.clear();
      _urlImgController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.green, content: Text("Plat enregistré avec succès au menu ! 🎉")),
        );
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("BUREAU DU DIRECTEUR 👑"),
          backgroundColor: kSurfaceColor,
          bottom: const TabBar(
            indicatorColor: kPrimaryColor,
            tabs: [
              Tab(icon: Icon(Icons.psychology), text: "Audit & IA Live"),
              Tab(icon: Icon(Icons.add_box), text: "Ajouter un Plat"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: _iaMessages.length,
                      itemBuilder: (context, index) {
                        final m = _iaMessages[index];
                        bool isUser = m["role"] == "user";
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
                            child: Text(
                              m["message"]!,
                              style: TextStyle(color: isUser ? Colors.black : Colors.white, fontSize: 15, fontWeight: isUser ? FontWeight.bold : FontWeight.normal),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_iaLoading) const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(color: kPrimaryColor)),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _iaController,
                          decoration: InputDecoration(
                            hintText: "Ex: combien on a gagné aujourd'hui ?",
                            filled: true,
                            fillColor: kSurfaceColor,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                          ),
                          onSubmitted: (_) => _parlerAvecIA(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(icon: const Icon(Icons.bolt, color: kPrimaryColor, size: 30), onPressed: _parlerAvecIA),
                    ],
                  )
                ],
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Ajouter un nouveau plat au menu", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryColor)),
                  const SizedBox(height: 20),
                  _buildField(_nomController, "Nom du plat", "Ex: Burger Triple Shokugeki", Icons.fastfood),
                  const SizedBox(height: 16),
                  _buildField(_prixController, "Prix (en MRU)", "Ex: 250", Icons.monetization_on, isNumber: true),
                  const SizedBox(height: 16),
                  _buildField(_descController, "Description", "Ex: Viande premium, cheddar fondu, sauce secrète...", Icons.description),
                  const SizedBox(height: 16),
                  _buildField(_urlImgController, "URL Internet de l'image (100% Gratuit)", "Ex: https://site.com/image.png", Icons.link),
                  const SizedBox(height: 16),
                  const Text("Catégorie du Plat", style: TextStyle(color: Colors.white54, fontSize: 13)),
                  DropdownButton<String>(
                    value: _selectedCatAjout,
                    dropdownColor: kSurfaceColor,
                    isExpanded: true,
                    items: ["Burgers", "Pizzas", "Poulet"].map((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCatAjout = val);
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: _ajouterAuMenu,
                      child: const Text("Enregistrer le Plat ✓", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, String hint, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: kPrimaryColor),
        filled: true,
        fillColor: kSurfaceColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}

// =========================================================================
// DASHBOARDS COMPLÉMENTAIRES (CUISINE, LIVREUR, CAISSIER, CHEF IA)
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

class LivreurDashboard extends StatelessWidget {
  const LivreurDashboard({super.key});
  Future<void> _ouvrirMaps(String quartier) async {
    final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('$quartier, Nouakchott, Mauritanie')}");
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SUIVI DES COURSES"), backgroundColor: kSurfaceColor),
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
                    Container(
                      padding: const EdgeInsets.all(12), 
                      decoration: BoxDecoration(color: kSurfaceColor, borderRadius: BorderRadius.circular(12)), 
                      child: Column(
                        children: [
                          const Text("Validées", style: TextStyle(fontSize: 12, color: Colors.white54)), 
                          Text("${docs.length}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                        ]
                      )
                    ),
                  ],
                ),
              ),
              Expanded(
                child: docs.isEmpty
                    ? const Center(child: Text("Aucune commande en attente. 📅", style: TextStyle(color: Colors.white38)))
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
}

class ChefIAPage extends StatelessWidget {
  const ChefIAPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chef Conseiller IA 👨‍🍳"), backgroundColor: kSurfaceColor),
      body: const ChatInterface(
        msgBot: "Bienvenue chez Shokugeki Menu ! 🍳 Je suis le Chef IA. Quel plat puis-je vous conseiller ce soir ?",
        hintText: "Demandez au Chef...",
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
          _messages.add({"sender": "bot", "text": "Je vous recommande notre fameux Cyber Burger Shokugeki avec sa sauce secrète, un pur délice ! 🍔"});
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
                  decoration: BoxDecoration(color: isUser ? kPrimaryColor : kSurfaceColor, borderRadius: BorderRadius.circular(16)),
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none)
                  )
                )
              ),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.send, color: kPrimaryColor), onPressed: _envoyerMessage)
            ],
          ),
        )
      ],
    );
  }
}