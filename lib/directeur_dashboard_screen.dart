import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'director_ia_service.dart';
import 'premium_staff_widgets.dart';
import 'restaurant_setup_seed.dart';
import 'widgets/developer_contact_button.dart';

class DirectorDashboardScreen extends StatefulWidget {
  const DirectorDashboardScreen({super.key});

  @override
  State<DirectorDashboardScreen> createState() => _DirectorDashboardScreenState();
}

class _DirectorDashboardScreenState extends State<DirectorDashboardScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final DirectorIAService _iaService = DirectorIAService();

  final _nomPlatController = TextEditingController();
  final _prixPlatController = TextEditingController();
  final _categorieController = TextEditingController();

  String _rapportIA =
      "Lancez l'analyse IA pour obtenir un rapport simple sur les ventes, les plats forts et les actions a faire.";
  bool _isAnalysing = false;
  bool _isUploading = false;
  bool _isSeeding = false;
  File? _imageSelectionnee;

  @override
  void dispose() {
    _nomPlatController.dispose();
    _prixPlatController.dispose();
    _categorieController.dispose();
    super.dispose();
  }

  Future<void> _choisirImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 72);
    if (image != null) {
      setState(() => _imageSelectionnee = File(image.path));
    }
  }

  Future<void> _installerBaseFirebase() async {
    setState(() => _isSeeding = true);
    try {
      await RestaurantSetupSeed().createDefaultRestaurant();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuration restaurant installee.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur configuration : $e')),
      );
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  Future<void> _ajouterNouveauPlat() async {
    final nom = _nomPlatController.text.trim();
    final prix = double.tryParse(_prixPlatController.text.trim().replaceAll(',', '.'));
    final categorie = _categorieController.text.trim();

    if (nom.isEmpty || prix == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez un nom et un prix valide.')),
      );
      return;
    }

    setState(() => _isUploading = true);
    String imageUrl = 'https://via.placeholder.com/400x300.png?text=Plat';

    try {
      if (_imageSelectionnee != null) {
        final fileName = 'plats/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final uploadTask = await _storage.ref().child(fileName).putFile(_imageSelectionnee!);
        imageUrl = await uploadTask.ref.getDownloadURL();
      }

      await _db.collection('menu').add({
        'nom': nom,
        'prix': prix,
        'categorie': categorie.isEmpty ? 'Specialites' : categorie,
        'image': imageUrl,
        'disponible': true,
        'populaire': false,
        'nouveau': true,
        'description': '',
        'date_creation': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      _nomPlatController.clear();
      _prixPlatController.clear();
      _categorieController.clear();
      setState(() => _imageSelectionnee = null);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nouveau plat ajoute au menu.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur ajout plat : $e')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _supprimerPlat(String docId) async {
    await _db.collection('menu').doc(docId).delete();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plat supprime.')),
    );
  }

  Future<void> _changerDisponibilite(String docId, bool statutActuel) async {
    await _db.collection('menu').doc(docId).update({
      'disponible': !statutActuel,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _changerBadge(String docId, String champ, bool valeurActuelle) async {
    await _db.collection('menu').doc(docId).update({
      champ: !valeurActuelle,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _lancerAnalyseIA({
    required double chiffreAffaires,
    required int totalCommandes,
    required List<String> platsVendus,
  }) async {
    setState(() => _isAnalysing = true);
    final rapport = await _iaService.genererRapportStrategique(
      chiffreAffaires: chiffreAffaires,
      totalCommandes: totalCommandes,
      listePlatsVendus: platsVendus,
    );
    if (!mounted) return;
    setState(() {
      _rapportIA = rapport;
      _isAnalysing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StaffScaffold(
      title: 'Directeur',
      subtitle: 'Pilotage restaurant, menu, ventes, IA et configuration abonnement.',
      icon: Icons.dashboard_customize,
      palette: StaffPalette.director,
      actions: [
        IconButton(
          tooltip: 'Installer config',
          onPressed: _isSeeding ? null : _installerBaseFirebase,
          icon: _isSeeding
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.cloud_done),
        ),
      ],
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: _db.collection('commandes').where('statut', isEqualTo: 'livre').snapshots(),
          builder: (context, snapshot) {
            double chiffreAffaires = 0;
            int totalCommandes = 0;
            final platsVendus = <String>[];

            if (snapshot.hasData) {
              totalCommandes = snapshot.data!.docs.length;
              for (final doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                chiffreAffaires += readMoney(data['total']);
                for (final article in readArticles(data)) {
                  if (article is Map && article['nom'] != null) {
                    platsVendus.add(article['nom'].toString());
                  }
                }
              }
            }

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: StaffMetricCard(
                        label: 'Chiffre livre',
                        value: '${chiffreAffaires.toStringAsFixed(0)} MRU',
                        icon: Icons.trending_up,
                        palette: StaffPalette.director,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StaffMetricCard(
                        label: 'Commandes',
                        value: totalCommandes.toString(),
                        icon: Icons.receipt_long,
                        palette: StaffPalette.director,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _DirectorIaPanel(
                  rapport: _rapportIA,
                  loading: _isAnalysing,
                  onAnalyze: () => _lancerAnalyseIA(
                    chiffreAffaires: chiffreAffaires,
                    totalCommandes: totalCommandes,
                    platsVendus: platsVendus,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        _MenuCreationPanel(
          nomController: _nomPlatController,
          prixController: _prixPlatController,
          categorieController: _categorieController,
          imageSelectionnee: _imageSelectionnee,
          loading: _isUploading,
          onPickImage: _choisirImage,
          onSave: _ajouterNouveauPlat,
        ),
        const SizedBox(height: 12),
        _MenuManagementPanel(
          db: _db,
          onAvailability: _changerDisponibilite,
          onBadge: _changerBadge,
          onDelete: _supprimerPlat,
        ),
        const SizedBox(height: 12),
        const DeveloperContactButton(),
      ],
    );
  }
}

class _DirectorIaPanel extends StatelessWidget {
  const _DirectorIaPanel({
    required this.rapport,
    required this.loading,
    required this.onAnalyze,
  });

  final String rapport;
  final bool loading;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFF7C3AED)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Consultant IA du restaurant',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            rapport,
            style: const TextStyle(color: Color(0xFF475569), height: 1.4),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: loading ? null : onAnalyze,
              icon: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.analytics),
              label: Text(loading ? 'Analyse en cours...' : 'Lancer analyse IA'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCreationPanel extends StatelessWidget {
  const _MenuCreationPanel({
    required this.nomController,
    required this.prixController,
    required this.categorieController,
    required this.imageSelectionnee,
    required this.loading,
    required this.onPickImage,
    required this.onSave,
  });

  final TextEditingController nomController;
  final TextEditingController prixController;
  final TextEditingController categorieController;
  final File? imageSelectionnee;
  final bool loading;
  final VoidCallback onPickImage;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ajouter un plat',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nomController,
            decoration: const InputDecoration(
              labelText: 'Nom du plat',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: prixController,
                  decoration: const InputDecoration(
                    labelText: 'Prix MRU',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: categorieController,
                  decoration: const InputDecoration(
                    labelText: 'Categorie',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: onPickImage,
                icon: const Icon(Icons.image),
                label: const Text('Image'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  imageSelectionnee == null ? 'Aucune image choisie' : 'Image prete',
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
              ),
              if (imageSelectionnee != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    imageSelectionnee!,
                    height: 46,
                    width: 46,
                    fit: BoxFit.cover,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: loading ? null : onSave,
              icon: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(loading ? 'Enregistrement...' : 'Enregistrer le plat'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuManagementPanel extends StatelessWidget {
  const _MenuManagementPanel({
    required this.db,
    required this.onAvailability,
    required this.onBadge,
    required this.onDelete,
  });

  final FirebaseFirestore db;
  final void Function(String docId, bool current) onAvailability;
  final void Function(String docId, String field, bool current) onBadge;
  final void Function(String docId) onDelete;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: db.collection('menu').orderBy('date_creation', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const EmptyStaffState(
            icon: Icons.menu_book,
            title: 'Menu vide',
            message: 'Ajoutez vos premiers plats pour commencer a vendre.',
          );
        }

        return Column(
          children: [
            StaffSectionTitle(
              title: 'Gestion du menu',
              trailing: '${docs.length} plat(s)',
            ),
            ...docs.map((doc) {
              final plat = doc.data() as Map<String, dynamic>;
              final disponible = plat['disponible'] != false;
              final populaire = plat['populaire'] == true;
              final nouveau = plat['nouveau'] == true;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        readText(plat, 'image', 'https://via.placeholder.com/80'),
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 56,
                          height: 56,
                          color: const Color(0xFFF1F5F9),
                          child: const Icon(Icons.fastfood),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            readText(plat, 'nom', 'Plat'),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              decoration:
                                  disponible ? TextDecoration.none : TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "${readMoney(plat['prix']).toStringAsFixed(0)} MRU - ${readText(plat, 'categorie', 'Menu')}",
                            style: const TextStyle(color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            children: [
                              _MiniBadge(
                                label: disponible ? 'Disponible' : 'Retire',
                                active: disponible,
                              ),
                              if (populaire) const _MiniBadge(label: 'Populaire', active: true),
                              if (nouveau) const _MiniBadge(label: 'Nouveau', active: true),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'available') onAvailability(doc.id, disponible);
                        if (value == 'popular') onBadge(doc.id, 'populaire', populaire);
                        if (value == 'new') onBadge(doc.id, 'nouveau', nouveau);
                        if (value == 'delete') onDelete(doc.id);
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'available',
                          child: Text(disponible ? 'Retirer du menu' : 'Remettre au menu'),
                        ),
                        PopupMenuItem(
                          value: 'popular',
                          child: Text(populaire ? 'Retirer populaire' : 'Marquer populaire'),
                        ),
                        PopupMenuItem(
                          value: 'new',
                          child: Text(nouveau ? 'Retirer nouveau' : 'Marquer nouveau'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Supprimer'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
    required this.label,
    required this.active,
  });

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFF5F3FF) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: active ? const Color(0xFF6D28D9) : const Color(0xFF64748B),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
