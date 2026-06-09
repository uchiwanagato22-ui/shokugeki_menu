import 'package:flutter/material.dart';
import 'restaurant_config.dart';

const String kAppName = RestaurantConfig.name;

// --- CODES PIN (définis dans restaurant_config.dart) ---
const String kCodeDirecteur = RestaurantConfig.codeDirecteur;
const String kCodeCaissier = RestaurantConfig.codeCaissier;
const String kCodeLivreur = RestaurantConfig.codeLivreur;

// --- CHARTE COULEURS (définies dans restaurant_config.dart) ---
const Color kPrimaryColor = RestaurantConfig.primaryColor;
const Color kSecondaryColor = RestaurantConfig.secondaryColor;
const Color kAccentColor = RestaurantConfig.accentColor;
const Color kBackgroundColor = Color(0xFFF8F9FA);

// --- CATÉGORIES PAR DÉFAUT DU MENU ---
const List<String> kDefaultCategories = [
  "Burgers",
  "Pizzas",
  "Poulet",
  "Boissons",
  "Desserts",
  "Divers",
];
