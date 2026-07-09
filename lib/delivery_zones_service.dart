import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_config.dart';

// ═══════════════════════════════════════════════════════
//  DELIVERY ZONES SERVICE
//  Avant : les quartiers de livraison (Tevragh Zeina, Ksar...)
//  étaient codés en dur dans l'app — exactement le même problème
//  que les catégories de menu. Un futur restaurant à Dakar ou
//  Abidjan aurait vu les quartiers de Nouakchott.
//
//  Maintenant : chaque restaurant a ses propres zones, stockées
//  dans restaurants/{id}/config/livraison, modifiables par le
//  Directeur depuis l'app (Paramètres du restaurant).
//
//  ⚠️ Setup Firebase requis : rien à créer à la main. Si le
//  document n'existe pas encore (restaurant existant comme
//  Shokugeki), l'app utilise automatiquement les 9 quartiers de
//  Nouakchott par défaut (ceux qui existaient déjà + Toujounine,
//  qui manquait) jusqu'à ce que le Directeur les personnalise.
// ═══════════════════════════════════════════════════════

class DeliveryZonesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Valeurs par défaut = les 9 quartiers (moughataas) de Nouakchott.
  // "Toujounine" manquait dans l'ancienne liste codée en dur.
  static const Map<String, double> zonesParDefaut = {
    'Tevragh Zeina': 60,
    'Ksar': 50,
    'Arafat': 80,
    'Dar Naim': 90,
    'Sebkha': 70,
    'El Mina': 70,
    'Riyadh': 80,
    'Teyarett': 60,
    'Toujounine': 90,
  };

  DocumentReference get _doc => _db.collection(AppConfig.config).doc('livraison');

  Stream<Map<String, double>> zonesStream() {
    return _doc.snapshots().map((snap) {
      if (!snap.exists) return zonesParDefaut;
      final data = (snap.data() as Map<String, dynamic>?)?['zones'] as Map<String, dynamic>?;
      if (data == null || data.isEmpty) return zonesParDefaut;
      return data.map((k, v) => MapEntry(k, (v as num).toDouble()));
    });
  }

  Future<Map<String, double>> obtenirZones() async {
    final snap = await _doc.get();
    if (!snap.exists) return zonesParDefaut;
    final data = (snap.data() as Map<String, dynamic>?)?['zones'] as Map<String, dynamic>?;
    if (data == null || data.isEmpty) return zonesParDefaut;
    return data.map((k, v) => MapEntry(k, (v as num).toDouble()));
  }

  Future<void> ajouterOuModifierZone(String nom, double prix) async {
    await _doc.set({'zones': {nom: prix}}, SetOptions(merge: true));
  }

  Future<void> supprimerZone(String nom) async {
    await _doc.set({'zones': {nom: FieldValue.delete()}}, SetOptions(merge: true));
  }
}
