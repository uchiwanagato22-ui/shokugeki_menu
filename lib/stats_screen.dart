import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_config.dart';
import 'constants.dart';

// ═══════════════════════════════════════════════════════
//  STATS AVANCÉES DIRECTEUR
//  ✅ CA par jour (7 derniers jours)
//  ✅ Top 5 plats vendus
//  ✅ Répartition horaire des commandes
//  ✅ Taux de livraison vs sur place
// ═══════════════════════════════════════════════════════

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _db = FirebaseFirestore.instance;
  bool _loading = true;

  // Données calculées
  double _caTotal = 0;
  int _totalCommandes = 0;
  int _livrees = 0;
  int _surPlace = 0;
  Map<String, double> _caParJour = {};
  Map<String, int> _topPlats = {};
  Map<String, int> _heures = {};
  Map<String, int> _paiements = {'cash':0,'bankily':0,'masrivi':0};

  @override
  void initState() {
    super.initState();
    _chargerStats();
  }

  Future<void> _chargerStats() async {
    try {
      final snap = await _db.collection(AppConfig.commandes).get();
      double ca = 0; int total = 0; int livrees = 0; int surPlace = 0;
      final caJour = <String, double>{};
      final plats = <String, int>{};
      final heures = <String, int>{};
      final paie = <String, int>{'cash':0,'bankily':0,'masrivi':0};

      final now = DateTime.now();
      for (int i = 6; i >= 0; i--) {
        final d = now.subtract(Duration(days: i));
        caJour['${d.day}/${d.month}'] = 0;
      }

      for (final doc in snap.docs) {
        final d = doc.data();
        final statut = d['statut']?.toString() ?? '';
        if (statut == 'rejete') continue;

        total++;
        final montant = (d['total'] as num?)?.toDouble() ?? 0;
        ca += montant;

        if (statut == 'livree' || statut == 'livre') livrees++;
        if (d['mode_commande']?.toString() == 'sur_place') surPlace++;

        final p = d['mode_paiement']?.toString() ?? 'cash';
        if (paie.containsKey(p)) paie[p] = (paie[p] ?? 0) + 1;

        // CA par jour
        final ts = d['date_creation'];
        if (ts != null) {
          DateTime? dt;
          if (ts is Map) {
            dt = DateTime.fromMillisecondsSinceEpoch((ts['_seconds'] as int) * 1000);
          }
          if (dt != null && now.difference(dt).inDays <= 6) {
            final key = '${dt.day}/${dt.month}';
            caJour[key] = (caJour[key] ?? 0) + montant;
            final h = '${dt.hour}h';
            heures[h] = (heures[h] ?? 0) + 1;
          }
        }

        // Plats
        final articles = d['articles'] as List? ?? [];
        for (final a in articles) {
          if (a is Map && a['nom'] != null) {
            final nom = a['nom'].toString();
            plats[nom] = (plats[nom] ?? 0) + ((a['quantite'] as num?)?.toInt() ?? 1);
          }
        }
      }

      // Top 5 plats
      final sortedPlats = plats.entries.toList()..sort((a,b) => b.value.compareTo(a.value));
      final top5 = Map.fromEntries(sortedPlats.take(5));

      setState(() {
        _caTotal = ca; _totalCommandes = total;
        _livrees = livrees; _surPlace = surPlace;
        _caParJour = caJour; _topPlats = top5;
        _heures = heures; _paiements = paie;
        _loading = false;
      });
    } catch(e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Statistiques', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kSurfaceColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () { setState(()=>_loading=true); _chargerStats(); }),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // KPIs principaux
                Row(children: [
                  _KPI(label: 'CA Total', value: '${_caTotal.toStringAsFixed(0)} MRU', color: kAccentColor, icon: Icons.trending_up),
                  const SizedBox(width: 10),
                  _KPI(label: 'Commandes', value: '$_totalCommandes', color: kPrimaryColor, icon: Icons.receipt_long),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  _KPI(label: 'Livrées', value: '$_livrees', color: Colors.green, icon: Icons.delivery_dining),
                  const SizedBox(width: 10),
                  _KPI(label: 'Sur place', value: '$_surPlace', color: Colors.purple, icon: Icons.table_restaurant),
                ]),
                const SizedBox(height: 24),

                // CA des 7 derniers jours
                _SectionTitle('CA — 7 derniers jours'),
                const SizedBox(height: 12),
                _BarChart(data: _caParJour, color: kPrimaryColor),
                const SizedBox(height: 24),

                // Top 5 plats
                _SectionTitle('Top 5 plats vendus'),
                const SizedBox(height: 12),
                ..._topPlats.entries.toList().asMap().entries.map((entry) {
                  final rank = entry.key + 1;
                  final nom = entry.value.key;
                  final qte = entry.value.value;
                  final max = _topPlats.values.first;
                  return _TopPlatRow(rank: rank, nom: nom, qte: qte, max: max);
                }),
                const SizedBox(height: 24),

                // Paiements
                _SectionTitle('Répartition paiements'),
                const SizedBox(height: 12),
                _PaiementChart(paiements: _paiements, total: _totalCommandes),
                const SizedBox(height: 24),

                // Panier moyen
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kSurfaceColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.shopping_basket, color: kAccentColor),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Panier moyen', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      Text(
                        _totalCommandes > 0 ? '${(_caTotal/_totalCommandes).toStringAsFixed(0)} MRU' : '0 MRU',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                      ),
                    ]),
                    const Spacer(),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      const Text('Taux livraison', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      Text(
                        _totalCommandes > 0 ? '${((_livrees/_totalCommandes)*100).toStringAsFixed(0)}%' : '0%',
                        style: const TextStyle(color: Colors.green, fontSize: 22, fontWeight: FontWeight.w900),
                      ),
                    ]),
                  ]),
                ),
                const SizedBox(height: 20),
              ]),
            ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 3, height: 16, color: kPrimaryColor, margin: const EdgeInsets.only(right: 10)),
    Text(title.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
  ]);
}

class _KPI extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _KPI({required this.label, required this.value, required this.color, required this.icon});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ]),
    ),
  );
}

class _BarChart extends StatelessWidget {
  final Map<String, double> data;
  final Color color;
  const _BarChart({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.values.isEmpty ? 1.0 : (data.values.reduce((a,b) => a>b?a:b).clamp(1.0, double.infinity));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kSurfaceColor, borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.entries.map((e) {
              final pct = e.value / maxVal;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    if (e.value > 0)
                      Text('${e.value.toStringAsFixed(0)}', style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      height: (pct * 90).clamp(4.0, 90.0),
                      decoration: BoxDecoration(
                        color: e.value > 0 ? color : Colors.white10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ]),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: data.keys.map((k) => Expanded(
            child: Text(k, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 9)),
          )).toList(),
        ),
      ]),
    );
  }
}

class _TopPlatRow extends StatelessWidget {
  final int rank, qte, max;
  final String nom;
  const _TopPlatRow({required this.rank, required this.nom, required this.qte, required this.max});

  @override
  Widget build(BuildContext context) {
    const rankColors = [kAccentColor, Colors.white60, Color(0xFFCD7F32), Colors.white38, Colors.white24];
    final color = rankColors[rank - 1];
    final pct = max > 0 ? qte / max : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: kSurfaceColor, borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
          child: Center(child: Text('#$rank', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(nom, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct, minHeight: 4,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ])),
        const SizedBox(width: 12),
        Text('×$qte', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 15)),
      ]),
    );
  }
}

class _PaiementChart extends StatelessWidget {
  final Map<String, int> paiements;
  final int total;
  const _PaiementChart({required this.paiements, required this.total});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Cash 💵', paiements['cash'] ?? 0, Colors.grey),
      ('Bankily', paiements['bankily'] ?? 0, const Color(0xFF2E7D32)),
      ('Masrivi', paiements['masrivi'] ?? 0, const Color(0xFFB8860B)),
    ];
    return Row(children: items.map((item) {
      final pct = total > 0 ? (item.$2 / total * 100).toStringAsFixed(0) : '0';
      return Expanded(child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: item.$3.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: item.$3.withOpacity(0.2)),
        ),
        child: Column(children: [
          Text('${item.$2}', style: TextStyle(color: item.$3, fontSize: 22, fontWeight: FontWeight.w900)),
          Text(item.$1, style: const TextStyle(color: Colors.grey, fontSize: 10)),
          Text('$pct%', style: TextStyle(color: item.$3.withOpacity(0.7), fontSize: 10)),
        ]),
      ));
    }).toList());
  }
}
