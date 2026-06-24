import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'widgets/developer_contact_button.dart';
import 'app_config.dart';
import 'constants.dart';

// ═══════════════════════════════════════════════════════
//  PANIER CLIENT — v3
//  ✅ Clés Firestore UNIFIÉES avec livreur/caissier :
//     clientNom, clientTelephone (camelCase partout)
//  ✅ mode_commande : 'livraison' | 'sur_place'
//  ✅ mode_paiement : 'cash' | 'bankily' | 'masrivi'
//  ✅ frais_livraison sauvegardé séparément
// ═══════════════════════════════════════════════════════

enum ModeCommande { livraison, surPlace }
enum ModePaiement { cash, bankily, masrivi }

class ClientCartScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? cartItems;
  const ClientCartScreen({Key? key, this.cartItems}) : super(key: key);

  @override
  State<ClientCartScreen> createState() => _ClientCartScreenState();
}

class _ClientCartScreenState extends State<ClientCartScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _articles = [];

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

  // IDs paiement mobile — remplace par tes vrais numéros
  static const String kBankilyNumero = '32652300';
  static const String kMasriviNumero = '32652300';

  final _nomCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.cartItems != null) _articles = List.from(widget.cartItems!);
    // Pré-remplir avec les infos Firebase Auth si dispo
    final user = _auth.currentUser;
    if (user?.displayName != null) _nomCtrl.text = user!.displayName!;
  }

  @override
  void dispose() {
    _nomCtrl.dispose(); _telCtrl.dispose(); _adresseCtrl.dispose();
    super.dispose();
  }

  double get _sousTotal => _articles.fold(0, (t, a) => t + ((a['prix'] as num?)?.toDouble() ?? 0) * ((a['quantite'] as num?)?.toInt() ?? 1));
  double get _fraisLivraison => _mode == ModeCommande.livraison ? (_zonesLivraison[_zone] ?? 0) : 0;
  double get _total => _sousTotal + _fraisLivraison;

  Future<void> _commander() async {
    if (_articles.isEmpty) { _snack('Panier vide !', Colors.amber); return; }
    if (_nomCtrl.text.trim().isEmpty) { _snack('Entrez votre nom', Colors.redAccent); return; }
    if (_telCtrl.text.trim().isEmpty) { _snack('Entrez votre téléphone', Colors.redAccent); return; }
    if (_mode == ModeCommande.livraison && _adresseCtrl.text.trim().isEmpty) {
      _snack('Entrez des repères d\'adresse', Colors.redAccent); return;
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
      // ✅ Toutes les clés en camelCase — cohérent avec livreur et caissier
      await _db.collection(AppConfig.commandes).add({
        'clientId': _auth.currentUser?.uid ?? 'invite',
        'clientNom': _nomCtrl.text.trim(),           // ← camelCase unifié
        'clientTelephone': _telCtrl.text.trim(),      // ← camelCase unifié
        'articles': _articles,
        'statut': 'en_attente',
        'total': _total,
        'sousTotal': _sousTotal,
        'fraisLivraison': _fraisLivraison,            // ← séparé pour le directeur
        'mode_commande': _mode == ModeCommande.livraison ? 'livraison' : 'sur_place',
        'mode_paiement': _paiement.name,              // 'cash' | 'bankily' | 'masrivi'
        'zone': _mode == ModeCommande.livraison ? _zone : 'Sur place',
        'quartier': _mode == ModeCommande.livraison ? _zone : 'Sur place',
        'adresse_reperes': _adresseCtrl.text.trim(),
        'latitude': lat,
        'longitude': lng,
        'date_creation': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() => _articles.clear());

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: kSurfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text('Commande envoyée !', style: TextStyle(color: Colors.white, fontSize: 17)),
          ]),
          content: Text(
            _mode == ModeCommande.livraison
                ? 'Commande confirmée pour $_zone.\nTotal : ${_total.toStringAsFixed(0)} MRU\nSuivez le statut dans "Mes commandes".'
                : 'Commande sur place confirmée.\nTotal : ${_total.toStringAsFixed(0)} MRU\nLe personnel vous sert bientôt.',
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () { Navigator.pop(context); Navigator.pop(context); },
              child: const Text('OK', style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) _snack('Erreur : $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _snack(String msg, Color color) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
  );

  void _modifierQte(int i, bool inc) {
    setState(() {
      int q = _articles[i]['quantite'] ?? 1;
      if (inc) { _articles[i]['quantite'] = q + 1; }
      else if (q > 1) { _articles[i]['quantite'] = q - 1; }
      else { _articles.removeAt(i); }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Text('Panier (${_articles.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(children: [
          // ── Articles ────────────────────────────────
          Expanded(
            flex: 4,
            child: _articles.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.shopping_cart_outlined, size: 70, color: Colors.grey.withOpacity(0.3)),
                    const SizedBox(height: 12),
                    const Text('Panier vide', style: TextStyle(color: Colors.grey)),
                  ]))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _articles.length,
                    itemBuilder: (_, i) {
                      final a = _articles[i];
                      final prix = (a['prix'] as num?)?.toDouble() ?? 0;
                      final qte = (a['quantite'] as num?)?.toInt() ?? 1;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(color: kSurfaceColor, borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [
                          const Icon(Icons.fastfood, color: kPrimaryColor, size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(a['nom'] ?? 'Plat', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text('${prix.toStringAsFixed(0)} MRU', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ])),
                          Row(children: [
                            GestureDetector(onTap: () => _modifierQte(i, false),
                              child: const Icon(Icons.remove_circle_outline, color: Colors.grey, size: 22)),
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text('$qte', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                            GestureDetector(onTap: () => _modifierQte(i, true),
                              child: const Icon(Icons.add_circle_outline, color: kPrimaryColor, size: 22)),
                          ]),
                        ]),
                      );
                    },
                  ),
          ),

          // ── Formulaire ──────────────────────────────
          Expanded(
            flex: 7,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              decoration: BoxDecoration(
                color: kSurfaceColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: SingleChildScrollView(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  // Mode commande
                  const _Label('Mode de commande'),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _Toggle(label: '🛵  Livraison', active: _mode == ModeCommande.livraison, onTap: () => setState(() => _mode = ModeCommande.livraison))),
                    const SizedBox(width: 10),
                    Expanded(child: _Toggle(label: '🪑  Sur place', active: _mode == ModeCommande.surPlace, onTap: () => setState(() => _mode = ModeCommande.surPlace))),
                  ]),
                  const SizedBox(height: 16),

                  // Infos client
                  const _Label('Vos informations'),
                  const SizedBox(height: 8),
                  _Champ(ctrl: _nomCtrl, label: 'Nom complet', icon: Icons.person),
                  const SizedBox(height: 10),
                  _Champ(ctrl: _telCtrl, label: 'Téléphone', icon: Icons.phone, type: TextInputType.phone),

                  // Zone + adresse (livraison uniquement)
                  if (_mode == ModeCommande.livraison) ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _zone,
                      dropdownColor: kBackgroundColor,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDeco('Zone de livraison', Icons.map_outlined),
                      items: _zonesLivraison.entries.map((e) =>
                        DropdownMenuItem(value: e.key, child: Text('${e.key}  —  ${e.value.toStringAsFixed(0)} MRU'))
                      ).toList(),
                      onChanged: (v) => setState(() => _zone = v!),
                    ),
                    const SizedBox(height: 10),
                    _Champ(ctrl: _adresseCtrl, label: 'Repères précis (près de…)', icon: Icons.home_work_outlined, maxLines: 2),
                  ],

                  const SizedBox(height: 16),

                  // Paiement
                  const _Label('Mode de paiement'),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _PaiBtn(label: 'Cash 💵', active: _paiement == ModePaiement.cash, color: Colors.grey, onTap: () => setState(() => _paiement = ModePaiement.cash))),
                    const SizedBox(width: 8),
                    Expanded(child: _PaiBtn(label: 'Bankily', active: _paiement == ModePaiement.bankily, color: const Color(0xFF2E7D32), onTap: () => setState(() => _paiement = ModePaiement.bankily))),
                    const SizedBox(width: 8),
                    Expanded(child: _PaiBtn(label: 'Masrivi', active: _paiement == ModePaiement.masrivi, color: const Color(0xFFB8860B), onTap: () => setState(() => _paiement = ModePaiement.masrivi))),
                  ]),

                  if (_paiement == ModePaiement.bankily)
                    _PaiInfo(color: const Color(0xFF2E7D32), titre: 'Paiement Bankily 💚', numero: kBankilyNumero),
                  if (_paiement == ModePaiement.masrivi)
                    _PaiInfo(color: const Color(0xFFB8860B), titre: 'Paiement Masrivi 💛', numero: kMasriviNumero),

                  const SizedBox(height: 16),
                  const Divider(color: Colors.white12),

                  // Récap prix
                  _PrixLigne('Sous-total', '${_sousTotal.toStringAsFixed(0)} MRU'),
                  if (_mode == ModeCommande.livraison)
                    _PrixLigne('Livraison ($_zone)', '${_fraisLivraison.toStringAsFixed(0)} MRU'),
                  const Divider(color: Colors.white12),
                  _PrixLigne('Total', '${_total.toStringAsFixed(0)} MRU', gras: true),
                  const SizedBox(height: 16),

                  // Bouton commander
                  _isSubmitting
                      ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                      : SizedBox(
                          width: double.infinity, height: 52,
                          child: ElevatedButton(
                            onPressed: _commander,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(
                              _mode == ModeCommande.surPlace ? 'Commander sur place' : 'Confirmer la commande',
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                  const SizedBox(height: 10),
                  const Center(child: DeveloperContactButton()),
                  const SizedBox(height: 8),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
    labelText: label, labelStyle: const TextStyle(color: Colors.grey),
    prefixIcon: Icon(icon, color: Colors.grey),
    filled: true, fillColor: kBackgroundColor,
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kPrimaryColor)),
  );
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) =>
    Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15));
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
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      labelText: label, labelStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: Colors.grey),
      filled: true, fillColor: kBackgroundColor,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kPrimaryColor)),
    ),
  );
}

class _Toggle extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Toggle({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: active ? kPrimaryColor : kBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: active ? kPrimaryColor : Colors.white12),
      ),
      child: Center(child: Text(label, style: TextStyle(color: active ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 13))),
    ),
  );
}

class _PaiBtn extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  const _PaiBtn({required this.label, required this.active, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: active ? color.withOpacity(0.15) : kBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: active ? color : Colors.white12, width: active ? 1.5 : 1),
      ),
      child: Center(child: Text(label, style: TextStyle(color: active ? color : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12))),
    ),
  );
}

class _PaiInfo extends StatelessWidget {
  final Color color;
  final String titre;
  final String numero;
  const _PaiInfo({required this.color, required this.titre, required this.numero});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.07),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(children: [
      Icon(Icons.account_balance_wallet_rounded, color: color, size: 24),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titre, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 3),
        Text('Envoyez le montant au : $numero\nMentionnez votre numéro de commande.',
          style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.5)),
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
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: gras ? Colors.white : Colors.grey, fontWeight: gras ? FontWeight.bold : FontWeight.normal, fontSize: gras ? 16 : 14)),
      Text(valeur, style: TextStyle(color: gras ? kPrimaryColor : Colors.white, fontWeight: FontWeight.bold, fontSize: gras ? 18 : 14)),
    ]),
  );
}
