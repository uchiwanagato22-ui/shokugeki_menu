import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  WHITE-LABEL : UN SEUL FICHIER À MODIFIER PAR RESTAURANT
// ═══════════════════════════════════════════════════════════════════════════
//
//  ⚠️ Un seul Firebase pour TOUS les restaurants (multi-tenant).
//  Ne JAMAIS créer de nouveau projet Firebase par client — chaque resto
//  vit isolé dans restaurants/{restaurantId}/... au sein du même Firebase.
//
//  Quand tu vends l'app à un nouveau client :
//  1. Crée le restaurant sur le panel admin (bouton "Créer ce restaurant")
//     → ça crée restaurants/{id} + les PINs staff automatiquement
//  2. Duplique le dossier du projet Flutter
//  3. Clique "Copier config Flutter" sur le panel → colle dans
//     app_config.dart (restaurantId) et constants.dart (kAppName, kPrimaryColor)
//  4. Remplace assets/icon/logo.png par le logo du client
//  5. Change android:label dans android/app/src/main/AndroidManifest.xml
//  6. ⚠️ Change bankilyNumero et masriviNumero ci-dessous avec les VRAIS
//     numéros du restaurant client — jamais les tiens, sinon l'argent des
//     clients t'arrive à toi au lieu du restaurant
//  7. Lance : flutter pub run flutter_launcher_icons
//  8. Build l'APK → c'est l'app unique du restaurant !
//
//  firebase_options.dart et google-services.json restent IDENTIQUES
//  pour tous les clients : ne pas y toucher.
//
// ═══════════════════════════════════════════════════════════════════════════

class RestaurantConfig {
  static const String name = "Shokugeki Menu";
  static const String slogan = "La livraison qui enflamme vos papilles";
  static const String logoAsset = "assets/icon/logo.png";

  static const Color primaryColor = Color(0xFFFF4500);
  static const Color secondaryColor = Color(0xFF1E1E24);
  static const Color accentColor = Color(0xFFFFD700);

  static const String city = "Nouakchott";
  static const String zone = "Tevragh Zeina";
  static const String adresse = "Tevragh Zeina, Rue principale";
  static const int deliveryFee = 50;

  static const String phone = "+222 00 00 00 00";
  static const String whatsapp = "+22200000000";
  static const String horaires = "Lun-Dim : 10h00 - 23h00";

  // ⚠️ Numéros du RESTAURANT CLIENT — jamais les tiens ! L'argent des
  // commandes Bankily/Masrivi doit arriver chez le restaurant, pas chez
  // toi. À changer obligatoirement à chaque nouveau client.
  static const String bankilyNumero = "00000000";
  static const String masriviNumero = "00000000";

  static const String codeDirecteur = "3265";
  static const String codeCaissier = "2300";
  static const String codeLivreur = "3223";

  static const String defaultPromoMessage = "🎉 Livraison offerte sur votre 1ère commande !";
  static const bool defaultPromoActive = true;
  static const String codePromo = "BIENVENUE";
  static const int reductionPromoMru = 50;

  static String get deliveryLocation => "$city, $zone";
  static String get mapsCitySuffix => city;
}
