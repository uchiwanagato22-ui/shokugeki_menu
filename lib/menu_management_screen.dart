import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'constants.dart';
import 'firestore_service.dart';
import 'storage_service.dart';
import 'default_menu_plats.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  final FirestoreService _firestore = FirestoreService();
  final StorageService _storage = StorageService();

  void _ouvrirFormulaire({Map<String, dynamic>? plat}) {
    final nomController = TextEditingController(text: plat?['nom'] ?? '');
    final descController = TextEditingController(text: plat?['description'] ?? '');
    final prixController = TextEditingController(text: plat != null ? '${plat['prix']}' : '');
    final imageController = TextEditingController(text: plat?['image'] ?? '');
    String categorie = plat?['categorie'] ?? kDefaultCategories.first;
    bool disponible = plat?['disponible'] ?? true;
    bool uploadEnCours = false;
    final isEdition = plat != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdition ? "Modifier le plat" : "Ajouter un nouveau plat",
                      style: const TextStyle(
                        color: kAccentColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _champ("Nom du plat", nomController),
                    const SizedBox(height: 12),
                    _champ("Description", descController, maxLines: 3),
                    const SizedBox(height: 12),
                    _champ("Prix (MRU)", prixController, keyboard: TextInputType.number),
                    const SizedBox(height: 12),
                    const Text("Photo du plat", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: uploadEnCours
                                ? null
                                : () async {
                                    setModalState(() => uploadEnCours = true);
                                    try {
                                      final url = await _storage.choisirEtUploaderImage(source: ImageSource.gallery);
                                      if (url != null) imageController.text = url;
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("Erreur upload : $e"), backgroundColor: Colors.red),
                                        );
                                      }
                                    } finally {
                                      setModalState(() => uploadEnCours = false);
                                    }
                                  },
                            icon: const Icon(Icons.photo_library, size: 18),
                            label: const Text("Galerie"),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: uploadEnCours
                                ? null
                                : () async {
                                    setModalState(() => uploadEnCours = true);
                                    try {
                                      final url = await _storage.choisirEtUploaderImage(source: ImageSource.camera);
                                      if (url != null) imageController.text = url;
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("Erreur caméra : $e"), backgroundColor: Colors.red),
                                        );
                                      }
                                    } finally {
                                      setModalState(() => uploadEnCours = false);
                                    }
                                  },
                            icon: const Icon(Icons.camera_alt, size: 18),
                            label: const Text("Caméra"),
                          ),
                        ),
                      ],
                    ),
                    if (uploadEnCours) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(color: kAccentColor),
                    ],
                    if (imageController.text.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(imageController.text, height: 80, width: double.infinity, fit: BoxFit.cover),
                      ),
                    ],
                    const SizedBox(height: 8),
                    _champ("URL image (optionnel)", imageController),
                    const SizedBox(height: 12),
                    const Text("Catégorie", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: categorie,
                      dropdownColor: const Color(0xFF2A2A32),
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(),
                      items: kDefaultCategories
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) => setModalState(() => categorie = val!),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Visible sur le menu client",
                          style: TextStyle(color: Colors.white)),
                      value: disponible,
                      activeColor: Colors.green,
                      onChanged: (val) => setModalState(() => disponible = val),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text("Annuler"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: kAccentColor),
                            onPressed: () async {
                              final nom = nomController.text.trim();
                              final prix = int.tryParse(prixController.text.trim());
                              if (nom.isEmpty || prix == null || prix <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Nom et prix valides obligatoires"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              try {
                                if (isEdition) {
                                  await _firestore.modifierPlat(
                                    id: plat!['id'],
                                    nom: nom,
                                    description: descController.text.trim(),
                                    prix: prix,
                                    categorie: categorie,
                                    image: imageController.text.trim(),
                                    disponible: disponible,
                                  );
                                } else {
                                  await _firestore.ajouterPlat(
                                    nom: nom,
                                    description: descController.text.trim(),
                                    prix: prix,
                                    categorie: categorie,
                                    image: imageController.text.trim(),
                                    disponible: disponible,
                                  );
                                }
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(isEdition ? "Plat modifié !" : "Plat ajouté au menu !"),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                            child: Text(
                              isEdition ? "Enregistrer" : "Ajouter",
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      nomController.dispose();
      descController.dispose();
      prixController.dispose();
      imageController.dispose();
    });
  }

  Future<void> _importerMenuExemple() async {
    try {
      final count = await _firestore.importerPlatsExemple(kPlatsExempleMauritanie);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$count plats importés avec photos ! 🍽️"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur import : $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _confirmerSuppression(Map<String, dynamic> plat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A22),
        title: const Text("Supprimer ce plat ?", style: TextStyle(color: Colors.white)),
        content: Text(
          "\"${plat['nom']}\" sera définitivement supprimé.",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _firestore.supprimerPlat(plat['id']);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Plat supprimé"), backgroundColor: Colors.orange),
                );
              }
            },
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111115),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A22),
        title: const Text(
          "GESTION DU MENU",
          style: TextStyle(color: kAccentColor, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          TextButton.icon(
            onPressed: _importerMenuExemple,
            icon: const Icon(Icons.download, color: kPrimaryColor, size: 18),
            label: const Text("Exemples", style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kAccentColor,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text("Nouveau plat", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        onPressed: () => _ouvrirFormulaire(),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestore.obtenirLeMenu(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kAccentColor));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text("Erreur : ${snapshot.error}", style: const TextStyle(color: Colors.red)),
            );
          }

          final plats = snapshot.data ?? [];
          if (plats.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.restaurant_menu, size: 64, color: Colors.grey.shade700),
                    const SizedBox(height: 16),
                    const Text(
                      "Aucun plat dans le menu.\nImportez les exemples (Kebab, Thieboudienne...)\nou ajoutez vos propres plats.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _importerMenuExemple,
                      icon: const Icon(Icons.restaurant, color: Colors.black),
                      label: const Text("Importer menu exemple", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: kAccentColor),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: plats.length,
            itemBuilder: (context, index) {
              final plat = plats[index];
              final disponible = plat['disponible'] == true;
              return Card(
                color: const Color(0xFF1A1A22),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: plat['image'].toString().isNotEmpty
                            ? Image.network(
                                plat['image'],
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _placeholderImage(),
                              )
                            : _placeholderImage(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plat['nom'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${plat['prix']} MRU · ${plat['categorie']}",
                              style: const TextStyle(color: kPrimaryColor, fontSize: 13),
                            ),
                            if (plat['description'].toString().isNotEmpty)
                              Text(
                                plat['description'],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Switch(
                            value: disponible,
                            activeColor: Colors.green,
                            onChanged: (val) =>
                                _firestore.basculerDisponibilite(plat['id'], val),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: kAccentColor, size: 20),
                                onPressed: () => _ouvrirFormulaire(plat: plat),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                onPressed: () => _confirmerSuppression(plat),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Widget _placeholderImage() {
    return Container(
      width: 64,
      height: 64,
      color: const Color(0xFF2A2A32),
      child: const Icon(Icons.fastfood, color: Colors.grey),
    );
  }

  Widget _champ(String label, TextEditingController controller,
      {int maxLines = 1, TextInputType? keyboard}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      inputFormatters: keyboard == TextInputType.number
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label: label),
    );
  }

  InputDecoration _inputDecoration({String? label}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFF2A2A32),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    );
  }
}
