import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_config.dart';
import 'constants.dart';

// ═══════════════════════════════════════════════════════
//  MES COMMANDES — v2 (CORRIGÉ MULTI-TENANT)
//  ✅ Suivi temps réel avec stepper visuel
//  ✅ Statuts complets : en_attente → en_cuisine → pret → livree
//  ✅ Gère sur_place et livraison
//  ✅ Notation après livraison
//  ✅ Détail articles + mode paiement
// ═══════════════════════════════════════════════════════

class ClientOrdersScreen extends StatefulWidget {
  const ClientOrdersScreen({super.key});

  @override
  State<ClientOrdersScreen> createState() => _ClientOrdersScreenState();
}

class _ClientOrdersScreenState extends State<ClientOrdersScreen> {
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  final Set<String> _notationsDemandees = {};

  Future<void> _noterCommande(String docId, int note) async {
    // CORRECTION : Chemin mis à jour vers la sous-collection du restaurant
    await FirebaseFirestore.instance
        .collection('restaurants')
        .doc(AppConfig.restaurantId)
        .collection('commandes')
        .doc(docId)
        .update({'note': note, 'updated_at': FieldValue.serverTimestamp()});

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Merci pour votre note ! ⭐'), backgroundColor: Colors.green),
    );
  }

  void _afficherNotation(String docId) {
    int note = 5;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          backgroundColor: kSurfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Noter la commande', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Comment était votre expérience ?', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) =>
              GestureDetector(
                onTap: () => setDialog(() => note = i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(i < note ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: kAccentColor, size: 36),
                ),
              ),
            )),
            const SizedBox(height: 8),
            Text(['😞 Mauvais', '😕 Moyen', '🙂 Bien', '😊 Très bien', '🤩 Excellent !'][note - 1],
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Plus tard', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
              onPressed: () { _noterCommande(docId, note); Navigator.pop(ctx); },
              child: const Text('Envoyer', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return const Scaffold(
        backgroundColor: kBackgroundColor,
        body: Center(child: Text('Connectez-vous pour voir vos commandes.', style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Mes Commandes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // CORRECTION : Écoute de la sous-collection du restaurant au lieu de la racine
        stream: FirebaseFirestore.instance
            .collection('restaurants')
            .doc(AppConfig.restaurantId)
            .collection('commandes')
            .where('clientId', isEqualTo: _uid)
            .orderBy('date_creation', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.wifi_off, color: Colors.grey, size: 48),
              const SizedBox(height: 12),
              Text('Erreur : ${snapshot.error}', style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
            ]),
          );
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: kPrimaryColor));

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.receipt_long_outlined, size: 72, color: Colors.grey.withOpacity(0.3)),
              const SizedBox(height: 16),
              const Text('Aucune commande pour le moment.', style: TextStyle(color: Colors.grey, fontSize: 15)),
              const SizedBox(height: 8),
              const Text('Explorez notre menu et passez votre première commande !',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
            ]),
          );

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              final statut = data['statut']?.toString() ?? 'en_attente';
              final note = data['note'];
              final total = (data['total'] as num?)?.toDouble() ?? 0.0;
              final surPlace = data['mode_commande']?.toString() == 'sur_place';
              final paiement = data['mode_paiement']?.toString() ?? 'cash';
              final articles = data['articles'] as List? ?? [];
              final zone = data['zone']?.toString() ?? '';
              final ref = doc.id.length > 6 ? doc.id.substring(0, 6).toUpperCase() : doc.id.toUpperCase();

              // Notation auto après livraison
              if (statut == 'livree' && note == null && !_notationsDemandees.contains(doc.id)) {
                _notationsDemandees.add(doc.id);
                WidgetsBinding.instance.addPostFrameCallback((_) => _afficherNotation(doc.id));
              }

              return _CommandeCard(
                ref: ref,
                statut: statut,
                total: total,
                surPlace: surPlace,
                zone: zone,
                paiement: paiement,
                articles: articles,
                note: note,
                onNoter: () => _afficherNotation(doc.id),
              );
            },
          );
        },
      ),
    );
  }
}

class _CommandeCard extends StatefulWidget {
  final String ref, statut, zone, paiement;
  final double total;
  final bool surPlace;
  final List articles;
  final dynamic note;
  final VoidCallback onNoter;

  const _CommandeCard({
    required this.ref, required this.statut, required this.total,
    required this.surPlace, required this.zone, required this.paiement,
    required this.articles, required this.note, required this.onNoter,
  });

  @override
  State<_CommandeCard> createState() => _CommandeCardState();
}

class _CommandeCardState extends State<_CommandeCard> {
  bool _expanded = false;

  int get _etape {
    switch (widget.statut) {
      case 'en_attente': return 0;
      case 'en_cuisine': return 1;
      case 'pret':
      case 'pret_pour_livraison': return 2;
      case 'en_livraison':
      case 'en_cours_de_livraison': return 3;
      case 'livree':
      case 'livre': return 4;
      case 'rejete': return -1;
      default: return 0;
    }
  }

  Color get _couleurStatut {
    switch (_etape) {
      case -1: return Colors.red;
      case 0: return Colors.blue;
      case 1: return Colors.orange;
      case 2: return Colors.purple;
      case 3: return Colors.teal;
      case 4: return Colors.green;
      default: return Colors.grey;
    }
  }

  String get _labelStatut {
    switch (widget.statut) {
      case 'en_attente': return '⏳ En attente de validation';
      case 'en_cuisine': return '🍳 En préparation';
      case 'pret':
      case 'pret_pour_livraison': return '✅ Prête — livraison imminente';
      case 'en_livraison':
      case 'en_cours_de_livraison': return '🛵 En route vers vous !';
      case 'livree':
      case 'livre': return '🎉 Livrée — Bon appétit !';
      case 'rejete': return '❌ Rejetée';
      default: return widget.statut;
    }
  }

  @override
  Widget build(BuildContext context) {
    final etape = _etape;
    final estRejete = etape == -1;

    final steps = widget.surPlace
        ? ['Reçue', 'Cuisine', 'Prête', 'Servie']
        : ['Reçue', 'Cuisine', 'Prête', 'Livrée'];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: estRejete ? Colors.red.withOpacity(0.3) : Colors.white.withOpacity(0.05)),
      ),
      child: Column(children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: _couleurStatut.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(_etapeIcon(etape), color: _couleurStatut, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Commande #${widget.ref}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 3),
                Text(_labelStatut, style: TextStyle(color: _couleurStatut, fontSize: 12, fontWeight: FontWeight.w600)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${widget.total.toStringAsFixed(0)} MRU',
                    style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 15)),
                Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey, size: 20),
              ]),
            ]),
          ),
        ),

        if (!estRejete) Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(children: List.generate(steps.length * 2 - 1, (i) {
            if (i.isOdd) {
              final active = etape > i ~/ 2;
              return Expanded(child: Container(height: 2, color: active ? kPrimaryColor : Colors.white12));
            }
            final stepIdx = i ~/ 2;
            final active = etape > stepIdx || (etape == stepIdx && stepIdx == 0);
            final current = etape == stepIdx + 1 || (stepIdx == 0 && etape == 0);
            return Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: active ? kPrimaryColor : (current ? kPrimaryColor.withOpacity(0.3) : Colors.white10),
                  shape: BoxShape.circle,
                  border: current ? Border.all(color: kPrimaryColor, width: 2) : null,
                ),
                child: Icon(active ? Icons.check : Icons.circle, color: Colors.white, size: 14),
              ),
              const SizedBox(height: 4),
              Text(steps[stepIdx], style: TextStyle(fontSize: 9, color: active ? Colors.white : Colors.grey,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal)),
            ]);
          })),
        ),

        if (_expanded) Container(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Divider(color: Colors.white12),
            const SizedBox(height: 8),

            Row(children: [
              _InfoPill(label: widget.surPlace ? '🪑 Sur place' : '🛵 ${widget.zone}', color: Colors.blue),
              const SizedBox(width: 8),
              _InfoPill(label: _labelPaiement(widget.paiement), color: Colors.grey),
            ]),
            const SizedBox(height: 12),

            const Text('Articles commandés :', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 6),
            ...widget.articles.map((a) {
              final item = a is Map ? a : {};
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(children: [
                  const Icon(Icons.circle, size: 6, color: kPrimaryColor),
                  const SizedBox(width: 8),
                  Text('${item['quantite'] ?? 1}x ${item['nom'] ?? 'Plat'}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  const Spacer(),
                  Text('${(item['prix'] as num? ?? 0).toStringAsFixed(0)} MRU',
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ]),
              );
            }),

            if (etape == 4 && widget.note == null) ...[
              const SizedBox(height: 14),
              GestureDetector(
                onTap: widget.onNoter,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: kAccentColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kAccentColor.withOpacity(0.3)),
                  ),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.star_rounded, color: kAccentColor, size: 20),
                    SizedBox(width: 8),
                    Text('Donnez votre avis', style: TextStyle(color: kAccentColor, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
            ],
            if (widget.note != null) ...[
              const SizedBox(height: 10),
              Row(children: [
                const Text('Votre note : ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ...List.generate(5, (i) => Icon(
                  i < (widget.note as int) ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: kAccentColor, size: 16,
                )),
              ]),
            ],
          ]),
        ),

        if (estRejete) Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.07),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.2)),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline, color: Colors.redAccent, size: 16),
              SizedBox(width: 8),
              Expanded(child: Text('Commande rejetée. Contactez le restaurant pour plus d\'infos.',
                  style: TextStyle(color: Colors.redAccent, fontSize: 12))),
            ]),
          ),
        ),
      ]),
    );
  }

  IconData _etapeIcon(int etape) {
    switch (etape) {
      case -1: return Icons.cancel;
      case 0: return Icons.access_time;
      case 1: return Icons.soup_kitchen;
      case 2: return Icons.check_circle;
      case 3: return Icons.delivery_dining;
      case 4: return Icons.celebration;
      default: return Icons.receipt_long;
    }
  }

  String _labelPaiement(String p) {
    switch (p) {
      case 'bankily': return 'Bankily 💚';
      case 'masrivi': return 'Masrivi 💛';
      default: return 'Cash 💵';
    }
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final Color color;
  const _InfoPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
  );
}