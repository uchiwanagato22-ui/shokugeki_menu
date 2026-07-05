import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'widgets/developer_contact_button.dart';
import 'app_config.dart';
import 'constants.dart';
import 'promo_service.dart';
import 'loyalty_service.dart';

enum ModeCommande { livraison, surPlace }
enum ModePaiement { cash, bankily, masrivi }

class ClientCartScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? cartItems;
  final VoidCallback? onCartChanged; // Permet de notifier l'accueil du changement de quantité

  const ClientCartScreen({Key? key, this.cartItems, this.onCartChanged}) : super(key: key);

  @override
  State<ClientCartScreen> createState() => _ClientCartScreenState();
}

class _ClientCartScreenState extends State<ClientCartScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _articles = [];

  // Tarifs des livraisons mis à jour pour Nouakchott
  final Map<String, double> _zonesLivraison = {
    'Tevragh Zeina': 60,
    'Ksar': 50,
    'Arafat': 80,
    'Dar Naim': 90,
    'Sebkha': 70,
    'El Mina': 70,
    'Riyadh': 80,
    'Teyarett': 60,
  };

  String _zone = 'Tevragh Zeina';
  ModeCommande _mode = ModeCommande.livraison;
  ModePaiement _paiement = ModePaiement.cash;
  bool _isSubmitting = false;

  // Numéros Bankily et Masrivi
  static const String kBankilyNumero = '32652300';
  static const String kMasriviNumero = '32652300';

  final _nomCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();

  // Variables pour l'animation tactile des boutons
  String? _activeTogglePressed;
  String? _activePaiementPressed;
  bool _isSubmitButtonPressed = false;

  // ── Code promo ───────────────────────────────────────
  final _promoCtrl = TextEditingController();
  final _promoService = PromoService();
  bool _promoLoading = false;
  String? _promoErreur;
  double _reductionPromo = 0;
  String? _codePromoApplique;

  // ── Points fidélité ──────────────────────────────────
  bool _utiliserPoints = false;
  int _soldePoints = 0;

  double get _reductionPoints {
    if (!_utiliserPoints) return 0;
    final packs = LoyaltyService.instance.packsDisponibles(_soldePoints);
    return LoyaltyService.instance.reductionPour(packs);
  }

  int get _pointsUtilises {
    if (!_utiliserPoints) return 0;
    return LoyaltyService.instance.packsDisponibles(_soldePoints) * LoyaltyService.pointsPourReduction;
  }

  Future<void> _appliquerPromo() async {
    setState(() {
      _promoLoading = true;
      _promoErreur = null;
    });
    final res = await _promoService.verifierCode(_promoCtrl.text, _sousTotal);
    if (!mounted) return;
    setState(() {
      _promoLoading = false;
      if (res.valide) {
        _reductionPromo = res.reduction;
        _codePromoApplique = res.codeApplique;
        _promoErreur = null;
      } else {
        _reductionPromo = 0;
        _codePromoApplique = null;
        _promoErreur = res.erreur;
      }
    });
  }

  void _retirerPromo() {
    setState(() {
      _reductionPromo = 0;
      _codePromoApplique = null;
      _promoCtrl.clear();
      _promoErreur = null;
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.cartItems != null) _articles = List.from(widget.cartItems!);
    
    final user = _auth.currentUser;
    if (user?.displayName != null) _nomCtrl.text = user!.displayName!;
    if (user != null) {
      LoyaltyService.instance.pointsStream(user.uid).first.then((solde) {
        if (mounted) setState(() => _soldePoints = solde);
      }).catchError((_) {});
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose(); 
    _telCtrl.dispose(); 
    _adresseCtrl.dispose();
    _promoCtrl.dispose();
    super.dispose();
  }

  double get _sousTotal => _articles.fold(0, (t, a) => t + ((a['prix'] as num?)?.toDouble() ?? 0) * ((a['quantite'] as num?)?.toInt() ?? 1));
  double get _fraisLivraison => _mode == ModeCommande.livraison ? (_zonesLivraison[_zone] ?? 0) : 0;
  double get _reductionTotale {
    final reduc = _reductionPromo + _reductionPoints;
    final maxReduc = _sousTotal + _fraisLivraison;
    return reduc > maxReduc ? maxReduc : reduc; // jamais de total négatif
  }
  double get _total => (_sousTotal + _fraisLivraison - _reductionTotale).clamp(0, double.infinity);

  Future<void> _commander() async {
    if (_articles.isEmpty) { _snack('Votre panier est vide !', Colors.amber); return; }
    if (_nomCtrl.text.trim().isEmpty) { _snack('Veuillez entrer votre nom', Colors.redAccent); return; }
    if (_telCtrl.text.trim().isEmpty) { _snack('Veuillez entrer votre numéro de téléphone', Colors.redAccent); return; }
    if (_mode == ModeCommande.livraison && _adresseCtrl.text.trim().isEmpty) {
      _snack('Veuillez indiquer des repères précis pour la livraison', Colors.redAccent); return;
    }

    setState(() => _isSubmitting = true);

    double lat = 0, lng = 0;
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        lat = pos.latitude; lng = pos.longitude;
      }
    } catch (_) {}

    try {
      // Structure unifiée prête pour Firebase
      await _db.collection(AppConfig.commandes).add({
        'clientId': _auth.currentUser?.uid ?? 'invite',
        'clientNom': _nomCtrl.text.trim(),
        'clientTelephone': _telCtrl.text.trim(),
        'articles': _articles,
        'statut': 'en_attente',
        'total': _total,
        'sousTotal': _sousTotal,
        'fraisLivraison': _fraisLivraison,
        'code_promo': _codePromoApplique ?? '',
        'reduction_promo': _reductionPromo,
        'points_utilises': _pointsUtilises,
        'reduction_points': _reductionPoints,
        'mode_commande': _mode == ModeCommande.livraison ? 'livraison' : 'sur_place',
        'mode_paiement': _paiement.name,
        'zone': _mode == ModeCommande.livraison ? _zone : 'Sur place',
        'quartier': _mode == ModeCommande.livraison ? _zone : 'Sur place',
        'adresse_reperes': _adresseCtrl.text.trim(),
        'latitude': lat,
        'longitude': lng,
        'date_creation': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Débiter les points fidélité utilisés (si applicable), sans bloquer
      // la confirmation de commande si ça échoue.
      final uid = _auth.currentUser?.uid;
      if (uid != null && _pointsUtilises > 0) {
        LoyaltyService.instance.debiterPoints(uid, _pointsUtilises).catchError((_) {});
      }

      if (!mounted) return;
      
      // Vider le panier d'origine et l'instance locale
      setState(() {
        _articles.clear();
        widget.cartItems?.clear();
      });
      if (widget.onCartChanged != null) widget.onCartChanged!();

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF101323),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: const [
            Icon(Icons.check_circle, color: kSuccessColor, size: 28),
            SizedBox(width: 10),
            Text('Commande validée !', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
          content: Text(
            _mode == ModeCommande.livraison
                ? 'Votre commande est en route pour $_zone.\nTotal : ${_total.toStringAsFixed(0)} MRU\nSuivez l\'avancement dans "Mes commandes".'
                : 'Commande sur place confirmée.\nTotal : ${_total.toStringAsFixed(0)} MRU\nNotre équipe vous prépare cela tout de suite.',
            style: const TextStyle(color: Color(0xFFD1D5DB), height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () { Navigator.pop(context); Navigator.pop(context); },
              child: const Text('Parfait', style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) _snack('Une erreur est survenue : $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _snack(String msg, Color color) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)), 
      backgroundColor: color, 
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );

  void _modifierQte(int i, bool inc) {
    setState(() {
      int q = _articles[i]['quantite'] ?? 1;
      if (inc) { 
        _articles[i]['quantite'] = q + 1;
        if(widget.cartItems != null) widget.cartItems![i]['quantite'] = q + 1;
      } else if (q > 1) { 
        _articles[i]['quantite'] = q - 1;
        if(widget.cartItems != null) widget.cartItems![i]['quantite'] = q - 1;
      } else { 
        _articles.removeAt(i);
        if(widget.cartItems != null) widget.cartItems!.removeAt(i);
      }
    });
    if (widget.onCartChanged != null) widget.onCartChanged!(); // Alerte l'application globale
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07080E), // Look OLED
      appBar: AppBar(
        title: Text('Mon Panier (${_articles.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(children: [
          // ── LISTE DES ARTICLES AVEC SUPPRESSION GLISSÉE ──────────────────
          Expanded(
            flex: 4,
            child: _articles.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.shopping_bag_outlined, size: 65, color: const Color(0xFF1E233D)),
                    const SizedBox(height: 12),
                    const Text('Votre panier est vide', style: TextStyle(color: Colors.grey, fontSize: 15)),
                  ]))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _articles.length,
                    itemBuilder: (_, i) {
                      final a = _articles[i];
                      final prix = (a['prix'] as num?)?.toDouble() ?? 0;
                      final qte = (a['quantite'] as num?)?.toInt() ?? 1;

                      return Dismissible(
                        key: Key(a['id']?.toString() ?? i.toString()),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          setState(() {
                            _articles.removeAt(i);
                            if (widget.cartItems != null) widget.cartItems!.removeAt(i);
                          });
                          if (widget.onCartChanged != null) widget.onCartChanged!();
                          _snack('Plat retiré du panier', Colors.redAccent);
                        },
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.only(right: 20),
                          alignment: Alignment.centerRight,
                          decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 26),
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF101323),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF1E233D)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.fastfood_rounded, color: kPrimaryColor, size: 22),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(a['nom'] ?? 'Plat', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 2),
                              Text('${prix.toStringAsFixed(0)} MRU', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            ])),
                            Row(children: [
                              GestureDetector(onTap: () => _modifierQte(i, false),
                                child: const Icon(Icons.remove_circle_outline_rounded, color: Colors.grey, size: 24)),
                              Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text('$qte', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                              GestureDetector(onTap: () => _modifierQte(i, true),
                                child: const Icon(Icons.add_circle_outline_rounded, color: kPrimaryColor, size: 24)),
                            ]),
                          ]),
                        ),
                      );
                    },
                  ),
          ),

          // ── FORMULAIRE ET FACTURATION ──────────────────────────────
          Expanded(
            flex: 7,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              decoration: const BoxDecoration(
                color: Color(0xFF101323),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const _Label('Mode de commande'),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTapDown: (_) => setState(() => _activeTogglePressed = 'livraison'),
                        onTapCancel: () => setState(() => _activeTogglePressed = null),
                        onTapUp: (_) {
                          setState(() { _mode = ModeCommande.livraison; _activeTogglePressed = null; });
                        },
                        child: AnimatedScale(
                          scale: _activeTogglePressed == 'livraison' ? 0.95 : 1.0,
                          duration: const Duration(milliseconds: 80),
                          child: _Toggle(label: '🛵  Livraison', active: _mode == ModeCommande.livraison),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTapDown: (_) => setState(() => _activeTogglePressed = 'sur_place'),
                        onTapCancel: () => setState(() => _activeTogglePressed = null),
                        onTapUp: (_) {
                          setState(() { _mode = ModeCommande.surPlace; _activeTogglePressed = null; });
                        },
                        child: AnimatedScale(
                          scale: _activeTogglePressed == 'sur_place' ? 0.95 : 1.0,
                          duration: const Duration(milliseconds: 80),
                          child: _Toggle(label: '🪑  Sur place', active: _mode == ModeCommande.surPlace),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  const _Label('Vos informations'),
                  const SizedBox(height: 10),
                  _Champ(ctrl: _nomCtrl, label: 'Nom complet', icon: Icons.person_outline_rounded),
                  const SizedBox(height: 12),
                  _Champ(ctrl: _telCtrl, label: 'Numéro de téléphone', icon: Icons.phone_android_rounded, type: TextInputType.phone),

                  if (_mode == ModeCommande.livraison) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _zone,
                      dropdownColor: const Color(0xFF07080E),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      decoration: _inputDeco('Zone de livraison (Nouakchott)', Icons.location_on_outlined),
                      items: _zonesLivraison.entries.map((e) =>
                        DropdownMenuItem(value: e.key, child: Text('${e.key}  (${e.value.toStringAsFixed(0)} MRU)'))
                      ).toList(),
                      onChanged: (v) => setState(() => _zone = v!),
                    ),
                    const SizedBox(height: 12),
                    _Champ(ctrl: _adresseCtrl, label: 'Repères d\'adresse précis (Boutique, Carrefour...)', icon: Icons.map_rounded, maxLines: 2),
                  ],

                  const SizedBox(height: 20),

                  const _Label('Mode de paiement'),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTapDown: (_) => setState(() => _activePaiementPressed = 'cash'),
                        onTapCancel: () => setState(() => _activePaiementPressed = null),
                        onTapUp: (_) { setState(() { _paiement = ModePaiement.cash; _activePaiementPressed = null; }); },
                        child: AnimatedScale(
                          scale: _activePaiementPressed == 'cash' ? 0.95 : 1.0,
                          duration: const Duration(milliseconds: 80),
                          child: _PaiBtn(label: 'Cash 💵', active: _paiement == ModePaiement.cash, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTapDown: (_) => setState(() => _activePaiementPressed = 'bankily'),
                        onTapCancel: () => setState(() => _activePaiementPressed = null),
                        onTapUp: (_) { setState(() { _paiement = ModePaiement.bankily; _activePaiementPressed = null; }); },
                        child: AnimatedScale(
                          scale: _activePaiementPressed == 'bankily' ? 0.95 : 1.0,
                          duration: const Duration(milliseconds: 80),
                          child: _PaiBtn(label: 'Bankily', active: _paiement == ModePaiement.bankily, color: const Color(0xFF2E7D32)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTapDown: (_) => setState(() => _activePaiementPressed = 'masrivi'),
                        onTapCancel: () => setState(() => _activePaiementPressed = null),
                        onTapUp: (_) { setState(() { _paiement = ModePaiement.masrivi; _activePaiementPressed = null; }); },
                        child: AnimatedScale(
                          scale: _activePaiementPressed == 'masrivi' ? 0.95 : 1.0,
                          duration: const Duration(milliseconds: 80),
                          child: _PaiBtn(label: 'Masrivi', active: _paiement == ModePaiement.masrivi, color: const Color(0xFFB8860B)),
                        ),
                      ),
                    ),
                  ]),

                  if (_paiement == ModePaiement.bankily)
                    _PaiInfo(color: const Color(0xFF2E7D32), titre: 'Paiement Bankily ✨', numero: kBankilyNumero),
                  if (_paiement == ModePaiement.masrivi)
                    _PaiInfo(color: const Color(0xFFB8860B), titre: 'Paiement Masrivi ✨', numero: kMasriviNumero),

                  const SizedBox(height: 20),

                  // ── Code promo ─────────────────────────────
                  if (_codePromoApplique == null) ...[
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _promoCtrl,
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Code promo',
                            hintStyle: const TextStyle(color: Colors.grey),
                            prefixIcon: const Icon(Icons.local_offer_outlined, color: kAccentColor),
                            errorText: _promoErreur,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _promoLoading ? null : _appliquerPromo,
                          child: _promoLoading
                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Appliquer'),
                        ),
                      ),
                    ]),
                  ] else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kSuccessColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kSuccessColor.withOpacity(0.3)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.check_circle, color: kSuccessColor, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Code "$_codePromoApplique" appliqué (-${_reductionPromo.toStringAsFixed(0)} MRU)',
                              style: const TextStyle(color: Colors.white, fontSize: 13)),
                        ),
                        GestureDetector(
                          onTap: _retirerPromo,
                          child: const Icon(Icons.close, color: Colors.grey, size: 18),
                        ),
                      ]),
                    ),

                  // ── Points fidélité ────────────────────────
                  if (_soldePoints >= LoyaltyService.pointsPourReduction) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: kSurfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kAccentColor.withOpacity(0.25)),
                      ),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeColor: kAccentColor,
                        title: Text(
                          'Utiliser mes points ($_soldePoints pts)',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '-${LoyaltyService.instance.reductionPour(LoyaltyService.instance.packsDisponibles(_soldePoints)).toStringAsFixed(0)} MRU de réduction',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        value: _utiliserPoints,
                        onChanged: (v) => setState(() => _utiliserPoints = v),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFF1E233D)),

                  _PrixLigne('Sous-total', '${_sousTotal.toStringAsFixed(0)} MRU'),
                  if (_mode == ModeCommande.livraison)
                    _PrixLigne('Frais de livraison', '${_fraisLivraison.toStringAsFixed(0)} MRU'),
                  if (_reductionTotale > 0)
                    _PrixLigne('Réduction', '-${_reductionTotale.toStringAsFixed(0)} MRU'),
                  const Divider(color: Color(0xFF1E233D)),
                  _PrixLigne('Montant Total', '${_total.toStringAsFixed(0)} MRU', gras: true),
                  const SizedBox(height: 20),

                  _isSubmitting
                      ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                      : SizedBox(
                          width: double.infinity, height: 54,
                          child: GestureDetector(
                            onTapDown: (_) => setState(() => _isSubmitButtonPressed = true),
                            onTapCancel: () => setState(() => _isSubmitButtonPressed = false),
                            onTapUp: (_) {
                              setState(() => _isSubmitButtonPressed = false);
                              _commander();
                            },
                            child: AnimatedScale(
                              scale: _isSubmitButtonPressed ? 0.97 : 1.0,
                              duration: const Duration(milliseconds: 80),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: kPrimaryColor,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(color: kPrimaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    _mode == ModeCommande.surPlace ? 'COMMANDER SUR PLACE' : 'CONFIRMER LA COMMANDE',
                                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                  const SizedBox(height: 14),
                  const Center(child: DeveloperContactButton()),
                  const SizedBox(height: 12),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
    labelText: label, labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
    prefixIcon: Icon(icon, color: kPrimaryColor, size: 20),
    filled: true, fillColor: const Color(0xFF07080E),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF1E233D))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kPrimaryColor)),
  );
}

// ── WIDGETS INTERNES PRIVÉS CORRIGÉS ───────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) =>
    Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5));
}

class _Champ extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final TextInputType? type;
  final int maxLines;
  const _Champ({required this.ctrl, required this.label, required this.icon, this.type, this.maxLines = 1});

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl, keyboardType: type, maxLines: maxLines,
    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
    decoration: InputDecoration(
      labelText: label, labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      prefixIcon: Icon(icon, color: kPrimaryColor, size: 20),
      filled: true, fillColor: const Color(0xFF07080E),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF1E233D))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kPrimaryColor)),
    ),
  );
}

class _Toggle extends StatelessWidget {
  final String label;
  final bool active;
  const _Toggle({required this.label, required this.active});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(
      color: active ? kPrimaryColor : const Color(0xFF07080E),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: active ? kPrimaryColor : const Color(0xFF1E233D)),
      boxShadow: active ? [
        BoxShadow(color: kPrimaryColor.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 2))
      ] : [],
    ),
    child: Center(child: Text(label, style: TextStyle(color: active ? Colors.white : Colors.grey, fontWeight: FontWeight.w900, fontSize: 13))),
  );
}

class _PaiBtn extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  const _PaiBtn({required this.label, required this.active, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      color: active ? color.withOpacity(0.12) : const Color(0xFF07080E),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: active ? color : const Color(0xFF1E233D), width: active ? 1.5 : 1),
    ),
    child: Center(child: Text(label, style: TextStyle(color: active ? color : Colors.grey, fontWeight: FontWeight.w900, fontSize: 13))),
  );
}

class _PaiInfo extends StatelessWidget {
  final Color color;
  final String titre;
  final String numero;
  const _PaiInfo({required this.color, required this.titre, required this.numero});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withOpacity(0.05),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(children: [
      Icon(Icons.account_balance_wallet_rounded, color: color, size: 24),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titre, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 4),
        Text('Envoyez le montant exact au : $numero\nPuis indiquez vos coordonnées pour la validation.',
          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, height: 1.5)),
      ])),
    ]),
  );
}

class _PrixLigne extends StatelessWidget {
  final String label, valeur;
  final bool gras;
  const _PrixLigne(this.label, this.valeur, {this.gras = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: gras ? Colors.white : Colors.grey, fontWeight: gras ? FontWeight.w900 : FontWeight.w500, fontSize: gras ? 16 : 14)),
      Text(valeur, style: TextStyle(color: gras ? kPrimaryColor : Colors.white, fontWeight: FontWeight.bold, fontSize: gras ? 18 : 14)),
    ]),
  );
}