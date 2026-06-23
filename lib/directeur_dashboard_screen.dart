import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'director_ia_service.dart';
import 'premium_staff_widgets.dart';
import 'restaurant_setup_seed.dart';
import 'widgets/developer_contact_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class DirectorDashboardScreen extends StatefulWidget {
  const DirectorDashboardScreen({super.key});

  @override
  State<DirectorDashboardScreen> createState() =>
      _DirectorDashboardScreenState();
}

class _DirectorDashboardScreenState extends State<DirectorDashboardScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
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

  /// Upload d'image vers Cloudinary avec tes vrais paramètres
  Future<String?> _uploadVersCloudinary(File imageLocale) async {
    // =========================================================================
    // TES PARAMÈTRES CONFIGURÉS EN DIRECT :
    // =========================================================================
    const String cloudName = "dr1rbdtph"; 
    const String uploadPreset = "676d6081-ab92-4e98-b500-3e088776e6ed"; 
    // =========================================================================

    try {
      final uri = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = uploadPreset;
      request.files.add(await http.MultipartFile.fromPath('file', imageLocale.path));

      final streamedResponse = await request.send();
      final responseBytes = await streamedResponse.stream.toBytes();
      final responseString = utf8.decode(responseBytes);

      if (streamedResponse.statusCode == 200 || streamedResponse.statusCode == 201) {
        final decoded = jsonDecode(responseString) as Map<String, dynamic>;
        return decoded['secure_url'] as String?;
      }

      debugPrint('Cloudinary upload error: $responseString');
      return null;
    } catch (e) {
      debugPrint('Cloudinary upload exception: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _nomPlatController.dispose();
    _prixPlatController.dispose();
    _categorieController.dispose();
    super.dispose();
  }

  Future<void> _choisirImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 72,
    );
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
    final prix = double.tryParse(
      _prixPlatController.text.trim().replaceAll(',', '.'),
    );
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
        final urlCloudinary = await _uploadVersCloudinary(_imageSelectionnee!);
        if (urlCloudinary == null || urlCloudinary.isEmpty) {
          throw Exception('Echec upload image sur Cloudinary');
        }
        imageUrl = urlCloudinary;
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

  Future<void> _changerBadge(
      String docId, String champ, bool valeurActuelle) async {
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
      subtitle:
          'Pilotage restaurant, menu, ventes, IA et configuration abonnement.',
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
          stream: _db
              .collection('commandes')
              .where('statut', isEqualTo: 'livre')
              .snapshots(),
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
          isUploading: _isUploading,
          onPickImage: _choisirImage,
          onSubmit: _ajouterNouveauPlat,
        ),
        const SizedBox(height: 16),
        const Text(
          'Gestion du menu en direct',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: _db.collection('menu').orderBy('updated_at', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                child: const Text(
                  'Aucun plat au menu. Remplissez le formulaire ci-dessus.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              );
            }

            final docs = snapshot.data!.docs;
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final d = doc.data() as Map<String, dynamic>;
                final String n = d['nom'] ?? 'Sans nom';
                final double p = readMoney(d['prix']);
                final String cat = d['categorie'] ?? 'Divers';
                final String img = d['image'] ?? '';
                final bool disp = d['disponible'] ?? true;
                final bool populaire = d['populaire'] ?? false;
                final bool nouveau = d['nouveau'] ?? false;

                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14161D),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: img.isNotEmpty
                            ? Image.network(img, width: 50, height: 50, fit: BoxFit.cover,
                                errorBuilder: (c, o, s) => Container(
                                      color: Colors.white10,
                                      width: 50,
                                      height: 50,
                                      child: const Icon(Icons.fastfood, color: Colors.grey, size: 20),
                                    ))
                            : Container(color: Colors.white10, width: 50, height: 50),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text('$p MRU', style: const TextStyle(color: Color(0xFF2196F3), fontWeight: FontWeight.bold, fontSize: 12)),
                                const SizedBox(width: 8),
                                Text('•  $cat', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _MiniBadge(label: 'POPULAIRE', active: populaire),
                                const SizedBox(width: 4),
                                _MiniBadge(label: 'NOUVEAU', active: nouveau),
                              ],
                            )
                          ],
                        ),
                      ),
                      Switch(
                        activeColor: const Color(0xFF2196F3),
                        value: disp,
                        onChanged: (v) => _changerDisponibilite(doc.id, disp),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                        onSelected: (val) {
                          if (val == 'delete') {
                            _supprimerPlat(doc.id);
                          } else {
                            _changerBadge(doc.id, val, val == 'popular' ? populaire : nouveau);
                          }
                        },
                        itemBuilder: (context) => [
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
                            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 20),
        const Center(child: DeveloperContactButton()),
      ],
    );
  }
}

class _MenuCreationPanel extends StatelessWidget {
  const _MenuCreationPanel({
    required this.nomController,
    required this.prixController,
    required this.categorieController,
    required this.imageSelectionnee,
    required this.isUploading,
    required this.onPickImage,
    required this.onSubmit,
  });

  final TextEditingController nomController;
  final TextEditingController prixController;
  final TextEditingController categorieController;
  final File? imageSelectionnee;
  final bool isUploading;
  final VoidCallback onPickImage;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF14161D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ajouter un plat au menu',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nomController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Nom du plat',
              labelStyle: TextStyle(color: Colors.grey),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF2196F3))),
              prefixIcon: Icon(Icons.fastfood, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: prixController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Prix (MRU)',
              labelStyle: TextStyle(color: Colors.grey),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF2196F3))),
              prefixIcon: Icon(Icons.payments, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: categorieController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Catégorie (Ex: Burgers, Poulet, Pizzas)',
              labelStyle: TextStyle(color: Colors.grey),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF2196F3))),
              prefixIcon: Icon(Icons.category, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onPickImage,
                  icon: const Icon(Icons.image, size: 18, color: Colors.white),
                  label: const Text('Image du plat', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.05),
                    elevation: 0,
                  ),
                ),
              ),
              if (imageSelectionnee != null) ...[
                const SizedBox(width: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.file(imageSelectionnee!, width: 40, height: 40, fit: BoxFit.cover),
                ),
              ]
            ],
          ),
          const SizedBox(height: 16),
          isUploading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF2196F3)))
              : SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'Enregistrer le plat',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
        ],
      ),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF14161D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: Colors.amber, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Chef IA Stratégie',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
              ),
              const Spacer(),
              if (!loading)
                TextButton.icon(
                  onPressed: onAnalyze,
                  icon: const Icon(Icons.bolt, size: 16, color: Colors.amber),
                  label: const Text('Analyser', style: TextStyle(color: Colors.amber, fontSize: 12)),
                )
            ],
          ),
          const SizedBox(height: 8),
          loading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(color: Colors.amber),
                  ),
                )
              : Text(
                  rapport,
                  style: const TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
                ),
        ],
      ),
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
        color: active ? const Color(0xFF2196F3).withOpacity(0.1) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          color: active ? const Color(0xFF2196F3) : Colors.grey,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}