import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'branding_service.dart';
import 'constants.dart';
import 'delivery_zones_service.dart';
import 'restaurant_config.dart';
import 'widgets/restaurant_logo.dart';

class BrandingSettingsScreen extends StatefulWidget {
  const BrandingSettingsScreen({super.key});

  @override
  State<BrandingSettingsScreen> createState() => _BrandingSettingsScreenState();
}

class _BrandingSettingsScreenState extends State<BrandingSettingsScreen> {
  final BrandingService _brandingService = BrandingService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomController;
  late TextEditingController _sloganController;
  late TextEditingController _villeController;
  late TextEditingController _zoneController;
  late TextEditingController _adresseController;
  late TextEditingController _horairesController;
  late TextEditingController _fraisController;
  late TextEditingController _telController;
  late TextEditingController _whatsappController;
  late TextEditingController _promoController;
  late TextEditingController _codePromoController;
  late TextEditingController _reductionController;
  late TextEditingController _bankilyController;
  late TextEditingController _masriviController;
  bool _promoActive = true;
  bool _isSaving = false;
  bool _charge = false;

  @override
  void initState() {
    super.initState();
    final d = BrandingData.defaults();
    _nomController = TextEditingController(text: d.nom);
    _sloganController = TextEditingController(text: d.slogan);
    _villeController = TextEditingController(text: d.ville);
    _zoneController = TextEditingController(text: d.zone);
    _adresseController = TextEditingController(text: d.adresse);
    _horairesController = TextEditingController(text: d.horaires);
    _fraisController = TextEditingController(text: '${d.fraisLivraison}');
    _telController = TextEditingController(text: d.telephone);
    _whatsappController = TextEditingController(text: d.whatsapp);
    _promoController = TextEditingController(text: d.promoMessage);
    _codePromoController = TextEditingController(text: d.codePromo);
    _reductionController = TextEditingController(text: '${d.reductionPromoMru}');
    _bankilyController = TextEditingController(text: d.bankilyNumero);
    _masriviController = TextEditingController(text: d.masriviNumero);
    _promoActive = d.promoActive;
  }

  @override
  void dispose() {
    for (final c in [
      _nomController, _sloganController, _villeController, _zoneController,
      _adresseController, _horairesController, _fraisController, _telController,
      _whatsappController, _promoController, _codePromoController, _reductionController,
      _bankilyController, _masriviController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _chargerDepuisFirestore(BrandingData b) {
    _nomController.text = b.nom;
    _sloganController.text = b.slogan;
    _villeController.text = b.ville;
    _zoneController.text = b.zone;
    _adresseController.text = b.adresse;
    _horairesController.text = b.horaires;
    _fraisController.text = '${b.fraisLivraison}';
    _telController.text = b.telephone;
    _whatsappController.text = b.whatsapp;
    _promoController.text = b.promoMessage;
    _codePromoController.text = b.codePromo;
    _reductionController.text = '${b.reductionPromoMru}';
    _bankilyController.text = b.bankilyNumero;
    _masriviController.text = b.masriviNumero;
    _promoActive = b.promoActive;
  }

  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await _brandingService.sauvegarderBranding(BrandingData(
        nom: _nomController.text.trim(),
        slogan: _sloganController.text.trim(),
        ville: _villeController.text.trim(),
        zone: _zoneController.text.trim(),
        adresse: _adresseController.text.trim(),
        horaires: _horairesController.text.trim(),
        fraisLivraison: int.parse(_fraisController.text.trim()),
        telephone: _telController.text.trim(),
        whatsapp: _whatsappController.text.trim(),
        promoMessage: _promoController.text.trim(),
        promoActive: _promoActive,
        codePromo: _codePromoController.text.trim().toUpperCase(),
        reductionPromoMru: int.parse(_reductionController.text.trim()),
        bankilyNumero: _bankilyController.text.trim(),
        masriviNumero: _masriviController.text.trim(),
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Identité du restaurant mise à jour !"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111115),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A22),
        title: const Text("IDENTITÉ DU RESTAURANT", style: TextStyle(color: kAccentColor, fontWeight: FontWeight.bold, fontSize: 15)),
      ),
      body: StreamBuilder<BrandingData>(
        stream: _brandingService.watchBranding(),
        builder: (context, snapshot) {
          if (snapshot.hasData && !_charge && !_isSaving) {
            _chargerDepuisFirestore(snapshot.data!);
            _charge = true;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: const RestaurantLogo(size: 90)),
                  const SizedBox(height: 12),
                  Center(child: Text(RestaurantConfig.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
                  const SizedBox(height: 4),
                  const Center(
                    child: Text(
                      "Logo : remplacez assets/icon/logo.png puis relancez l'app",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _section("Informations générales"),
                  _field("Nom du restaurant", _nomController),
                  _field("Slogan", _sloganController),
                  _field("Adresse complète", _adresseController),
                  _field("Ville", _villeController),
                  _field("Quartier / Zone", _zoneController),
                  _field("Horaires d'ouverture", _horairesController, maxLines: 2),
                  const SizedBox(height: 16),
                  _section("Contact & Livraison"),
                  _field("Téléphone", _telController),
                  _field("WhatsApp (avec indicatif)", _whatsappController),
                  _field("Frais de livraison (MRU)", _fraisController, digits: true),
                  const SizedBox(height: 16),
                  _section("Quartiers de livraison"),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text(
                      "Ajoutez vos propres quartiers avec leurs frais. Sans ça, les 9 quartiers de Nouakchott sont utilisés par défaut.",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                  const _ZonesLivraisonEditor(),
                  const SizedBox(height: 16),
                  _section("Promotions"),
                  _field("Message bandeau promo", _promoController, maxLines: 2),
                  _field("Code promo client", _codePromoController),
                  _field("Réduction code promo (MRU)", _reductionController, digits: true),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Afficher le bandeau promo", style: TextStyle(color: Colors.white)),
                    value: _promoActive,
                    activeThumbColor: Colors.green,
                    onChanged: (v) => setState(() => _promoActive = v),
                  ),
                  const SizedBox(height: 16),
                  _section("Paiement mobile"),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      "⚠️ Ce sont VOS numéros — c'est ici que l'argent des clients arrive.",
                      style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
                    ),
                  ),
                  _field("Numéro Bankily", _bankilyController, digits: true),
                  _field("Numéro Masrivi", _masriviController, digits: true),
                  const SizedBox(height: 20),
                  _isSaving
                      ? const Center(child: CircularProgressIndicator(color: kAccentColor))
                      : ElevatedButton.icon(
                          onPressed: _sauvegarder,
                          icon: const Icon(Icons.save, color: Colors.black),
                          label: const Text("Enregistrer", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(backgroundColor: kAccentColor, minimumSize: const Size(double.infinity, 50)),
                        ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _section(String titre) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(titre, style: const TextStyle(color: kAccentColor, fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  Widget _field(String label, TextEditingController c, {bool digits = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        maxLines: maxLines,
        keyboardType: digits ? TextInputType.number : TextInputType.text,
        inputFormatters: digits ? [FilteringTextInputFormatter.digitsOnly] : null,
        style: const TextStyle(color: Colors.white),
        validator: (v) => v == null || v.trim().isEmpty ? "Obligatoire" : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: const Color(0xFF1A1A22),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}

// ── Éditeur de zones de livraison ───────────────────────
// Widget autonome : permet au Directeur d'ajouter, modifier ou
// supprimer les quartiers de livraison propres à SON restaurant,
// au lieu d'une liste figée dans le code (voir delivery_zones_service.dart).
class _ZonesLivraisonEditor extends StatefulWidget {
  const _ZonesLivraisonEditor();

  @override
  State<_ZonesLivraisonEditor> createState() => _ZonesLivraisonEditorState();
}

class _ZonesLivraisonEditorState extends State<_ZonesLivraisonEditor> {
  final _service = DeliveryZonesService();
  final _nomCtrl = TextEditingController();
  final _prixCtrl = TextEditingController();
  bool _ajout = false;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prixCtrl.dispose();
    super.dispose();
  }

  Future<void> _ajouterZone() async {
    final nom = _nomCtrl.text.trim();
    final prix = double.tryParse(_prixCtrl.text.trim());
    if (nom.isEmpty || prix == null) return;
    setState(() => _ajout = true);
    await _service.ajouterOuModifierZone(nom, prix);
    _nomCtrl.clear();
    _prixCtrl.clear();
    if (mounted) setState(() => _ajout = false);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, double>>(
      stream: _service.zonesStream(),
      builder: (context, snapshot) {
        final zones = snapshot.data ?? DeliveryZonesService.zonesParDefaut;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFF1A1A22), borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            ...zones.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Expanded(child: Text(e.key, style: const TextStyle(color: Colors.white, fontSize: 13))),
                    Text('${e.value.toStringAsFixed(0)} MRU', style: const TextStyle(color: kAccentColor, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _service.supprimerZone(e.key),
                      child: const Icon(Icons.close, color: Colors.grey, size: 18),
                    ),
                  ]),
                )),
            const Divider(color: Colors.white12),
            Row(children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _nomCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(hintText: 'Quartier', hintStyle: TextStyle(color: Colors.grey), isDense: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _prixCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(hintText: 'MRU', hintStyle: TextStyle(color: Colors.grey), isDense: true),
                ),
              ),
              const SizedBox(width: 8),
              _ajout
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: kAccentColor))
                  : IconButton(onPressed: _ajouterZone, icon: const Icon(Icons.add_circle, color: kAccentColor)),
            ]),
          ]),
        );
      },
    );
  }
}
