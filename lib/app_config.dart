// ═══════════════════════════════════════════════════════
//  APP CONFIG — Multi-tenant SaaS Nagato Business
//  ✅ Change restaurantId pour déployer chez un nouveau client
//  ✅ Un seul Firebase pour tous les restaurants
//  ✅ Données 100% isolées par restaurant
// ═══════════════════════════════════════════════════════

class AppConfig {
  // ── ID du restaurant ─────────────────────────────────
  // Pour un nouveau client : change juste cette valeur
  // ex: 'pizza_palace', 'burger_house', 'resto_samba'
  static const String restaurantId = 'shokugeki';

  // ── Helpers Firestore ─────────────────────────────────
  static String get basePath => 'restaurants/$restaurantId';

  // Collections principales
  static String get menu => '$basePath/menu';
  static String get commandes => '$basePath/commandes';
  static String get personnel => '$basePath/personnel';
  static String get staffCodes => '$basePath/staffCodes';
  static String get config => '$basePath/config';
  static String get promotions => '$basePath/promotions';
  static String get clients => '$basePath/clients';
  static String get utilisateurs => 'utilisateurs'; // global (partagé)
  static String get statut => 'statut'; // global (kill switch)
}
