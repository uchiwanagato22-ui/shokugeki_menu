import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_config.dart';
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
  final String bankilyNumero;
  final String masriviNumero;

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
    required this.bankilyNumero,
    required this.masriviNumero,
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
        bankilyNumero: RestaurantConfig.bankilyNumero,
        masriviNumero: RestaurantConfig.masriviNumero,
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
      bankilyNumero: data['bankily_numero'] ?? d.bankilyNumero,
      masriviNumero: data['masrivi_numero'] ?? d.masriviNumero,
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
        'bankily_numero': bankilyNumero,
        'masrivi_numero': masriviNumero,
      };
}

class BrandingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ⚠️ Scopé par restaurant — chaque resto a SA PROPRE config, isolée
  // des autres. Avant, ce chemin était global ('configuration/branding'),
  // ce qui aurait fait partager code promo, adresse, etc. entre TOUS
  // les restaurants dès le 2e client.
  DocumentReference<Map<String, dynamic>> get _doc => _db
      .collection('restaurants')
      .doc(AppConfig.restaurantId)
      .collection('config')
      .doc('branding');

  Stream<BrandingData> watchBranding() {
    return _doc.snapshots().map((doc) => BrandingData.fromFirestore(doc.data()));
  }

  Future<void> sauvegarderBranding(BrandingData data) async {
    await _doc.set(data.toFirestore(), SetOptions(merge: true));
  }
}
