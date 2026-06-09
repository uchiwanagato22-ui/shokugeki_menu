import 'package:cloud_firestore/cloud_firestore.dart';
import 'restaurant_config.dart';

class BrandingData {
  final String nom;
  final String slogan;
  final String ville;
  final String zone;
  final String adresse;
  final String horaires;
  final int fraisLivraison;
  final String telephone;
  final String whatsapp;
  final String promoMessage;
  final bool promoActive;
  final String codePromo;
  final int reductionPromoMru;

  const BrandingData({
    required this.nom,
    required this.slogan,
    required this.ville,
    required this.zone,
    required this.adresse,
    required this.horaires,
    required this.fraisLivraison,
    required this.telephone,
    required this.whatsapp,
    required this.promoMessage,
    required this.promoActive,
    required this.codePromo,
    required this.reductionPromoMru,
  });

  String get deliveryLocation => "$ville, $zone";

  factory BrandingData.defaults() => BrandingData(
        nom: RestaurantConfig.name,
        slogan: RestaurantConfig.slogan,
        ville: RestaurantConfig.city,
        zone: RestaurantConfig.zone,
        adresse: RestaurantConfig.adresse,
        horaires: RestaurantConfig.horaires,
        fraisLivraison: RestaurantConfig.deliveryFee,
        telephone: RestaurantConfig.phone,
        whatsapp: RestaurantConfig.whatsapp,
        promoMessage: RestaurantConfig.defaultPromoMessage,
        promoActive: RestaurantConfig.defaultPromoActive,
        codePromo: RestaurantConfig.codePromo,
        reductionPromoMru: RestaurantConfig.reductionPromoMru,
      );

  factory BrandingData.fromFirestore(Map<String, dynamic>? data) {
    final d = BrandingData.defaults();
    if (data == null) return d;
    return BrandingData(
      nom: data['nom'] ?? d.nom,
      slogan: data['slogan'] ?? d.slogan,
      ville: data['ville'] ?? d.ville,
      zone: data['zone'] ?? d.zone,
      adresse: data['adresse'] ?? d.adresse,
      horaires: data['horaires'] ?? d.horaires,
      fraisLivraison: data['frais_livraison'] ?? d.fraisLivraison,
      telephone: data['telephone'] ?? d.telephone,
      whatsapp: data['whatsapp'] ?? d.whatsapp,
      promoMessage: data['promo_message'] ?? d.promoMessage,
      promoActive: data['promo_active'] ?? d.promoActive,
      codePromo: data['code_promo'] ?? d.codePromo,
      reductionPromoMru: data['reduction_promo_mru'] ?? d.reductionPromoMru,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'nom': nom,
        'slogan': slogan,
        'ville': ville,
        'zone': zone,
        'adresse': adresse,
        'horaires': horaires,
        'frais_livraison': fraisLivraison,
        'telephone': telephone,
        'whatsapp': whatsapp,
        'promo_message': promoMessage,
        'promo_active': promoActive,
        'code_promo': codePromo,
        'reduction_promo_mru': reductionPromoMru,
      };
}

class BrandingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<BrandingData> watchBranding() {
    return _db.collection('configuration').doc('branding').snapshots().map((doc) {
      return BrandingData.fromFirestore(doc.data());
    });
  }

  Future<void> sauvegarderBranding(BrandingData data) async {
    await _db.collection('configuration').doc('branding').set(data.toFirestore(), SetOptions(merge: true));
  }
}
