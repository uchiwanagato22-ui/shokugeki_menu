import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'director_ia_service.dart';
import 'firestore_service.dart';
import 'menu_pdf_service.dart';
import 'premium_staff_widgets.dart';
import 'restaurant_setup_seed.dart';
import 'branding_settings_screen.dart';
import 'stats_screen.dart';
import 'widgets/developer_contact_button.dart';
import 'login_screen.dart';
import 'app_config.dart';
import 'constants.dart';

class DirectorDashboardScreen extends StatefulWidget {
  const DirectorDashboardScreen({super.key});

  @override
  State<DirectorDashboardScreen> createState() => _DirectorDashboardScreenState();
}

class _DirectorDashboardScreenState extends State<DirectorDashboardScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final DirectorIAService _iaService = DirectorIAService();

  // ── Onglets ──────────────────────────────────────────
  late TabController _tabController;

  // ── Menu ─────────────────────────────────────────────
  final _nomPlatController = TextEditingController();
  final _prixPlatController = TextEditingController();
  final _categorieController = TextEditingController();
  final _descController = TextEditingController();
  bool _isUploading = false;
  bool _isSeeding = false;
  File? _imageSelectionnee;

  // ── Chat IA ───────────────────────────────────────────
  final _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _iaChatInitialise = false;
  bool _iaLoading = false;

  // ── Données live pour l'IA ────────────────────────────
  double _caLive = 0;
  int _commandesLive = 0;
  List<String> _platsLive = [];
  Map<String, int> _paiementsLive = {};

  // ── Cloudinary ────────────────────────────────────────
  static const String _cloudName = "dr1rbdtph";
  static const String _uploadPreset = "shokugeki_preset";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nomPlatController.dispose();
    _prixPlatController.dispose();
    _categorieController.dispose();
    _descController.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════
  //  CHAT IA
  // ════════════════════════════════════════════════════

  Future<void> _demarrerChatIA() async {
    setState(() { _iaLoading = true; _iaChatInitialise = true; });
    final rapport = await _iaService.genererRapportStrategique(
      chiffreAffaires: _caLive,
      totalCommandes: _commandesLive,
      listePlatsVendus: _platsLive,
      paiements: _paiementsLive,
    );
    if (!mounted) return;
    setState(() {
      _messages.add({'role': 'assistant', 'content': rapport});
      _iaLoading = false;
    });
    _scrollBas();
  }

  Future<void> _envoyerMessage() async {
    final texte = _chatController.text.trim();
    if (texte.isEmpty || _iaLoading) return;

    _chatController.clear();
    setState(() {
      _messages.add({'role': 'user', 'content': texte});
      _iaLoading = true;
    });
    _scrollBas();

    final reponse = await _iaService.envoyerMessage(
      messageUtilisateur: texte,
      historique: List.from(_messages)..removeLast(),
      ca: _caLive,
      commandes: _commandesLive,
      plats: _platsLive,
      paiements: _paiementsLive,
    );

    if (!mounted) return;
    setState(() {
      _messages.add({'role': 'assistant', 'content': reponse});
      _iaLoading = false;
    });
    _scrollBas();
  }

  void _scrollBas() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _reinitialiserChat() {
    setState(() {
      _messages.clear();
      _iaChatInitialise = false;
    });
  }

  // ════════════════════════════════════════════════════
  //  MENU
  // ════════════════════════════════════════════════════

  Future<String?> _uploadVersCloudinary(File img) async {
    try {
      final uri = Uri.parse("https://api.cloudinary.com/v1_1/$_cloudName/image/upload");
      final req = http.MultipartRequest('POST', uri);
      req.fields['upload_preset'] = _uploadPreset;
      req.files.add(await http.MultipartFile.fromPath('file', img.path));
      final res = await req.send();
      final body = utf8.decode(await res.stream.toBytes());
      if (res.statusCode == 200 || res.statusCode == 201) {
        return (jsonDecode(body) as Map<String, dynamic>)['secure_url'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Cloudinary: $e');
      return null;
    }
  }

  Future<void> _choisirImage() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 72);
    if (img != null) setState(() => _imageSelectionnee = File(img.path));
  }

  Future<void> _installerBaseFirebase() async {
    setState(() => _isSeeding = true);
    try {
      await RestaurantSetupSeed().createDefaultRestaurant();
      if (!mounted) return;
      _snack('Configuration installée ✅', Colors.green);
    } catch (e) {
      if (!mounted) return;
      _snack('Erreur : $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  Future<void> _ajouterPlat() async {
    final nom = _nomPlatController.text.trim();
    final prix = double.tryParse(_prixPlatController.text.trim().replaceAll(',', '.'));
    if (nom.isEmpty || prix == null) { _snack('Nom et prix obligatoires', Colors.amber); return; }

    setState(() => _isUploading = true);
    String imageUrl = 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400&q=80';

    try {
      if (_imageSelectionnee != null) {
        final url = await _uploadVersCloudinary(_imageSelectionnee!);
        if (url != null) imageUrl = url;
      }
      await _db.collection(AppConfig.menu).add({
        'nom': nom,
        'prix': prix,
        'categorie': _categorieController.text.trim().isEmpty ? 'Divers' : _categorieController.text.trim(),
        'description': _descController.text.trim(),
        'image': imageUrl,
        'disponible': true,
        'populaire': false,
        'nouveau': true,
        'date_creation': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      _nomPlatController.clear(); _prixPlatController.clear();
      _categorieController.clear(); _descController.clear();
      setState(() => _imageSelectionnee = null);
      if (!mounted) return;
      _snack('Plat ajouté ✅', Colors.green);
    } catch (e) {
      if (!mounted) return;
      _snack('Erreur : $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _supprimerPlat(String docId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14161D),
        title: const Text('Supprimer ce plat ?', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    await _db.collection(AppConfig.menu).doc(docId).delete();
    if (!mounted) return;
    _snack('Plat supprimé', Colors.orange);
  }

  Future<void> _changerDisponibilite(String docId, bool actuel) async {
    await _db.collection(AppConfig.menu).doc(docId).update({'disponible': !actuel, 'updated_at': FieldValue.serverTimestamp()});
  }

  Future<void> _changerBadge(String docId, String champ, bool actuel) async {
    await _db.collection(AppConfig.menu).doc(docId).update({champ: !actuel, 'updated_at': FieldValue.serverTimestamp()});
  }

  Future<void> _deconnecter() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14161D),
        title: const Text('Déconnexion', style: TextStyle(color: Colors.white)),
        content: const Text('Confirmer ?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Déconnecter', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('staff_role');
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating));
  }

  // ════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return StaffScaffold(
      title: 'Directeur',
      subtitle: 'Ventes, menu et Chef IA.',
      icon: Icons.dashboard_customize,
      palette: StaffPalette.director,
      actions: [
        IconButton(
          tooltip: 'Installer config Firebase',
          onPressed: _isSeeding ? null : _installerBaseFirebase,
          icon: _isSeeding
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.cloud_done),
        ),
        IconButton(
          tooltip: 'Statistiques avancées',
          icon: const Icon(Icons.bar_chart_rounded),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsScreen()));
          },
        ),
        IconButton(
          tooltip: 'Paramètres (promo, Bankily, Masrivi...)',
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const BrandingSettingsScreen()));
          },
        ),
        IconButton(tooltip: 'Déconnexion', icon: const Icon(Icons.logout, color: Colors.redAccent), onPressed: _deconnecter),
      ],
      children: [
        // ── Stats live ──────────────────────────────────
        StreamBuilder<QuerySnapshot>(
          stream: _db.collection(AppConfig.commandes).where('statut', whereNotIn: ['rejete']).snapshots(),
          builder: (context, snapshot) {
            double ca = 0; int total = 0; int livrees = 0; int enCours = 0;
            final plats = <String>[]; final paiements = <String, int>{'cash': 0, 'bankily': 0, 'masrivi': 0};

            if (snapshot.hasData) {
              for (final doc in snapshot.data!.docs) {
                final d = doc.data() as Map<String, dynamic>;
                final statut = d['statut']?.toString() ?? '';
                final montant = (d['total'] as num?)?.toDouble() ?? 0.0;
                final paie = d['mode_paiement']?.toString() ?? 'cash';
                total++; ca += montant;
                if (statut == 'livree' || statut == 'livre') livrees++; else enCours++;
                if (paiements.containsKey(paie)) paiements[paie] = (paiements[paie] ?? 0) + 1;
                final articles = d['articles'];
                if (articles is List) for (final a in articles) if (a is Map && a['nom'] != null) plats.add(a['nom'].toString());
              }
            }

            // Mise à jour des données pour le chat IA
            _caLive = ca; _commandesLive = total; _platsLive = plats; _paiementsLive = paiements;

            return Column(children: [
              Row(children: [
                Expanded(child: StaffMetricCard(label: 'CA total', value: '${ca.toStringAsFixed(0)} MRU', icon: Icons.trending_up, palette: StaffPalette.director)),
                const SizedBox(width: 10),
                Expanded(child: StaffMetricCard(label: 'Commandes', value: '$total', icon: Icons.receipt_long, palette: StaffPalette.director)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _MiniStat(label: 'Livrées ✅', value: '$livrees', color: Colors.green)),
                const SizedBox(width: 8),
                Expanded(child: _MiniStat(label: 'En cours 🔄', value: '$enCours', color: Colors.orange)),
                const SizedBox(width: 8),
                Expanded(child: _MiniStat(
                  label: 'Panier moy.',
                  value: total > 0 ? '${(ca / total).toStringAsFixed(0)} MRU' : '0',
                  color: Colors.purple,
                )),
              ]),
              const SizedBox(height: 10),
              _PaiementRepartition(paiements: paiements, total: total),
            ]);
          },
        ),

        const SizedBox(height: 16),

        // ── Onglets Menu / IA Chat ──────────────────────
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF14161D),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(children: [
            TabBar(
              controller: _tabController,
              indicatorColor: kPrimaryColor,
              labelColor: kPrimaryColor,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(icon: Icon(Icons.restaurant_menu, size: 18), text: 'Menu'),
                Tab(icon: Icon(Icons.add_circle, size: 18), text: 'Ajouter'),
                Tab(icon: Icon(Icons.psychology, size: 18), text: 'Chef IA'),
              ],
            ),
            SizedBox(
              height: 520,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _TabMenu(db: _db, onSupprimer: _supprimerPlat, onDisponibilite: _changerDisponibilite, onBadge: _changerBadge),
                  _TabAjout(
                    nomController: _nomPlatController, prixController: _prixPlatController,
                    categorieController: _categorieController, descController: _descController,
                    image: _imageSelectionnee, isUploading: _isUploading,
                    onImage: _choisirImage, onSubmit: _ajouterPlat,
                  ),
                  _TabChatIA(
                    messages: _messages, loading: _iaLoading, initialise: _iaChatInitialise,
                    scrollController: _chatScrollController, chatController: _chatController,
                    onDemarrer: _demarrerChatIA, onEnvoyer: _envoyerMessage, onReset: _reinitialiserChat,
                  ),
                ],
              ),
            ),
          ]),
        ),

        const SizedBox(height: 20),
        const Center(child: DeveloperContactButton()),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════
//  TAB MENU (liste plats)
// ══════════════════════════════════════════════════════

class _TabMenu extends StatelessWidget {
  final FirebaseFirestore db;
  final Future<void> Function(String) onSupprimer;
  final Future<void> Function(String, bool) onDisponibilite;
  final Future<void> Function(String, String, bool) onBadge;

  const _TabMenu({required this.db, required this.onSupprimer, required this.onDisponibilite, required this.onBadge});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                messenger.showSnackBar(const SnackBar(content: Text('Génération du PDF...'), duration: Duration(seconds: 2)));
                try {
                  await MenuPdfService().genererEtPartager(nomRestaurant: kAppName);
                } catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red));
                }
              },
              icon: const Icon(Icons.picture_as_pdf_rounded, color: kAccentColor),
              label: const Text('Exporter le menu en PDF', style: TextStyle(color: kAccentColor)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kAccentColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: db.collection(AppConfig.menu).orderBy('updated_at', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return const Center(child: Text('Menu vide. Ajoutez des plats.', style: TextStyle(color: Colors.grey)));

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final doc = docs[i];
            final d = doc.data() as Map<String, dynamic>;
            final nom = d['nom']?.toString() ?? 'Sans nom';
            final prix = (d['prix'] as num?)?.toDouble() ?? 0.0;
            final cat = d['categorie']?.toString() ?? 'Divers';
            final img = d['image']?.toString() ?? '';
            final disp = d['disponible'] as bool? ?? true;
            final pop = d['populaire'] as bool? ?? false;
            final nouv = d['nouveau'] as bool? ?? false;

            return Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: disp ? Colors.white.withOpacity(0.05) : Colors.red.withOpacity(0.2)),
              ),
              child: Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: img.isNotEmpty
                      ? Image.network(img, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _imgPlaceholder())
                      : _imgPlaceholder(),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(nom, style: TextStyle(fontWeight: FontWeight.bold, color: disp ? Colors.white : Colors.grey, fontSize: 13)),
                  Text('${prix.toStringAsFixed(0)} MRU  •  $cat', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  const SizedBox(height: 4),
                  Row(children: [
                    _MiniBadge(label: '⭐ POP', active: pop),
                    const SizedBox(width: 4),
                    _MiniBadge(label: '🆕 NEW', active: nouv),
                  ]),
                ])),
                Switch(activeColor: kPrimaryColor, value: disp, onChanged: (_) => onDisponibilite(doc.id, disp)),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                  onSelected: (v) {
                    if (v == 'delete') onSupprimer(doc.id);
                    else if (v == 'populaire') onBadge(doc.id, 'populaire', pop);
                    else if (v == 'nouveau') onBadge(doc.id, 'nouveau', nouv);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'populaire', child: Text(pop ? 'Retirer populaire' : 'Marquer populaire')),
                    PopupMenuItem(value: 'nouveau', child: Text(nouv ? 'Retirer nouveau' : 'Marquer nouveau')),
                    const PopupMenuItem(value: 'delete', child: Text('Supprimer', style: TextStyle(color: Colors.red))),
                  ],
                ),
              ]),
            );
          },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _imgPlaceholder() => Container(
    color: Colors.white10, width: 50, height: 50,
    child: const Icon(Icons.fastfood, color: Colors.grey, size: 20),
  );
}

// ══════════════════════════════════════════════════════
//  TAB AJOUT PLAT
// ══════════════════════════════════════════════════════

class _TabAjout extends StatelessWidget {
  final TextEditingController nomController, prixController, categorieController, descController;
  final File? image;
  final bool isUploading;
  final VoidCallback onImage, onSubmit;

  const _TabAjout({
    required this.nomController, required this.prixController,
    required this.categorieController, required this.descController,
    required this.image, required this.isUploading,
    required this.onImage, required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        _ChampTexte(controller: nomController, label: 'Nom du plat', icon: Icons.fastfood),
        const SizedBox(height: 10),
        _ChampTexte(controller: prixController, label: 'Prix (MRU)', icon: Icons.payments, type: TextInputType.number),
        const SizedBox(height: 10),
        _ChampCategorie(controller: categorieController),
        const SizedBox(height: 10),
        _ChampTexte(controller: descController, label: 'Description courte', icon: Icons.notes, maxLines: 2),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onImage,
              icon: const Icon(Icons.image, size: 18),
              label: Text(image != null ? 'Image choisie ✅' : 'Choisir image'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white70, side: const BorderSide(color: Colors.white24)),
            ),
          ),
          if (image != null) ...[
            const SizedBox(width: 10),
            ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.file(image!, width: 44, height: 44, fit: BoxFit.cover)),
          ],
        ]),
        const SizedBox(height: 14),
        isUploading
            ? const CircularProgressIndicator(color: Color(0xFF2196F3))
            : SizedBox(
                width: double.infinity, height: 46,
                child: ElevatedButton(
                  onPressed: onSubmit,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2196F3), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: const Text('Enregistrer le plat', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════
//  TAB CHAT IA — Interface de conversation
// ══════════════════════════════════════════════════════

class _TabChatIA extends StatelessWidget {
  final List<Map<String, String>> messages;
  final bool loading;
  final bool initialise;
  final ScrollController scrollController;
  final TextEditingController chatController;
  final VoidCallback onDemarrer;
  final VoidCallback onEnvoyer;
  final VoidCallback onReset;

  const _TabChatIA({
    required this.messages, required this.loading, required this.initialise,
    required this.scrollController, required this.chatController,
    required this.onDemarrer, required this.onEnvoyer, required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    if (!initialise) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber.withOpacity(0.2)),
              ),
              child: const Icon(Icons.psychology, color: Colors.amber, size: 48),
            ),
            const SizedBox(height: 20),
            const Text('Chef IA Stratégique', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Analysez vos ventes, obtenez des conseils sur votre menu, posez n\'importe quelle question sur la gestion de votre restaurant.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onDemarrer,
              icon: const Icon(Icons.bolt, color: Colors.white),
              label: const Text('Démarrer l\'analyse', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700, padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14)),
            ),
          ]),
        ),
      );
    }

    return Column(children: [
      // Barre reset
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(children: [
          const Icon(Icons.psychology, color: Colors.amber, size: 16),
          const SizedBox(width: 6),
          const Text('Chef IA', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
          const Spacer(),
          TextButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.refresh, size: 14, color: Colors.grey),
            label: const Text('Réinitialiser', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ]),
      ),

      // Zone messages
      Expanded(
        child: ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: messages.length + (loading ? 1 : 0),
          itemBuilder: (ctx, i) {
            if (i == messages.length) return const _BulleTyping();
            final msg = messages[i];
            final isUser = msg['role'] == 'user';
            return _BulleMessage(texte: msg['content'] ?? '', isUser: isUser);
          },
        ),
      ),

      // Suggestions rapides si premier message reçu
      if (messages.length == 1 && !loading)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(children: [
            _SuggestionChip(label: '💡 Actions pour augmenter les ventes', controller: chatController, onTap: onEnvoyer),
            const SizedBox(width: 8),
            _SuggestionChip(label: '🍽️ Quels plats mettre en avant ?', controller: chatController, onTap: onEnvoyer),
            const SizedBox(width: 8),
            _SuggestionChip(label: '📊 Analyse de la rentabilité', controller: chatController, onTap: onEnvoyer),
          ]),
        ),

      // Champ de saisie
      Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: chatController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onEnvoyer(),
              decoration: InputDecoration(
                hintText: 'Posez votre question au Chef IA…',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                filled: true,
                fillColor: Colors.black.withOpacity(0.3),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: loading ? null : onEnvoyer,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: loading ? Colors.grey : Colors.amber.shade700,
                shape: BoxShape.circle,
              ),
              child: loading
                  ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ]),
      ),
    ]);
  }
}

class _BulleMessage extends StatelessWidget {
  final String texte;
  final bool isUser;
  const _BulleMessage({required this.texte, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => Clipboard.setData(ClipboardData(text: texte)),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isUser ? kPrimaryColor.withOpacity(0.85) : const Color(0xFF1E2030),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isUser ? 16 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 16),
            ),
            border: isUser ? null : Border.all(color: Colors.amber.withOpacity(0.15)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (!isUser)
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  Icon(Icons.psychology, color: Colors.amber, size: 14),
                  SizedBox(width: 4),
                  Text('Chef IA', style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                ]),
              ),
            Text(texte, style: TextStyle(color: isUser ? Colors.white : Colors.white70, fontSize: 13, height: 1.5)),
          ]),
        ),
      ),
    );
  }
}

class _BulleTyping extends StatelessWidget {
  const _BulleTyping();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2030),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.withOpacity(0.15)),
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.psychology, color: Colors.amber, size: 14),
          SizedBox(width: 8),
          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.amber, strokeWidth: 2)),
          SizedBox(width: 8),
          Text('Chef IA réfléchit…', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ]),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onTap;
  const _SuggestionChip({required this.label, required this.controller, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        controller.text = label.replaceAll(RegExp(r'^[^\w]+'), '');
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber.withOpacity(0.2)),
        ),
        child: Text(label, style: const TextStyle(color: Colors.amber, fontSize: 12)),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  WIDGETS PARTAGÉS
// ══════════════════════════════════════════════════════

class _ChampTexte extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? type;
  final int maxLines;
  const _ChampTexte({required this.controller, required this.label, required this.icon, this.type, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller, keyboardType: type, maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey),
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF2196F3))),
      ),
    );
  }
}

// ── Champ catégorie avec suggestions ────────────────────
// Pourquoi : sans ça, un directeur qui tape "Pizza" une fois puis
// "Pizzas" une autre fois se retrouve avec 2 catégories différentes
// dans son menu (et 2 onglets pour le client, au lieu d'un seul).
// On lui propose donc directement ses catégories déjà utilisées.
class _ChampCategorie extends StatelessWidget {
  final TextEditingController controller;
  const _ChampCategorie({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChampTexte(controller: controller, label: 'Catégorie', icon: Icons.category),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: FirestoreService().obtenirMenuTempsReel(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            final vues = <String>{};
            for (final plat in snapshot.data!) {
              final cat = (plat['categorie']?.toString() ?? '').trim();
              if (cat.isNotEmpty) vues.add(cat);
            }
            if (vues.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: vues.map((cat) {
                  return GestureDetector(
                    onTap: () {
                      controller.text = cat;
                      controller.selection = TextSelection.collapsed(offset: cat.length);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(cat, style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.16), color.withOpacity(0.04)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: [
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10.5, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
      ]),
    );
  }
}

class _PaiementRepartition extends StatelessWidget {
  final Map<String, int> paiements;
  final int total;
  const _PaiementRepartition({required this.paiements, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF14161D), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Répartition paiements', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 10),
        Row(children: [
          _PaieBadge(label: 'Cash 💵', count: paiements['cash'] ?? 0, total: total, color: Colors.grey),
          const SizedBox(width: 8),
          _PaieBadge(label: 'Bankily', count: paiements['bankily'] ?? 0, total: total, color: const Color(0xFF006400)),
          const SizedBox(width: 8),
          _PaieBadge(label: 'Masrivi', count: paiements['masrivi'] ?? 0, total: total, color: const Color(0xFFB8860B)),
        ]),
      ]),
    );
  }
}

class _PaieBadge extends StatelessWidget {
  final String label;
  final int count, total;
  final Color color;
  const _PaieBadge({required this.label, required this.count, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? '${(count / total * 100).toStringAsFixed(0)}%' : '0%';
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.2))),
        child: Column(children: [
          Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
          Text(pct, style: TextStyle(color: color.withOpacity(0.7), fontSize: 10)),
        ]),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final bool active;
  const _MiniBadge({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: active ? kPrimaryColor.withOpacity(0.12) : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(label, style: TextStyle(fontSize: 9, color: active ? kPrimaryColor : Colors.grey, fontWeight: FontWeight.w800)),
    );
  }
}
