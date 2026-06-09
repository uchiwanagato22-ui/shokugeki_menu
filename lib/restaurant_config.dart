import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  WHITE-LABEL : UN SEUL FICHIER À MODIFIER PAR RESTAURANT
// ═══════════════════════════════════════════════════════════════════════════
//
//  Quand tu vends l'app à un nouveau client :
//  1. Duplique tout le dossier du projet
//  2. Remplace assets/icon/logo.png par le logo du client
//  3. Modifie les valeurs ci-dessous (nom, couleurs, ville...)
//  4. Crée un nouveau projet Firebase pour ce client
//  5. Remplace firebase_options.dart + google-services.json
//  6. Change android:label dans android/app/src/main/AndroidManifest.xml
//  7. Lance : flutter pub run flutter_launcher_icons
//  8. Build l'APK → c'est l'app unique du restaurant !
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
