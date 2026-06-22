import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'constants.dart';

class AboutContactScreen extends StatelessWidget {
  const AboutContactScreen({super.key});

  Future<void> _ouvrirUrl(Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint("Impossible d'ouvrir l'url : $uri");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text("À Propos & Business 🚀", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: kSurfaceColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Logo Brillant Luminescent
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: kPrimaryColor,
              ),
              child: const CircleAvatar(
                radius: 45,
                backgroundColor: kSurfaceColor,
                child: Icon(Icons.restaurant_menu_rounded, size: 45, color: kPrimaryColor),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              kAppName,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.white),
            ),
            const Text(
              "L'Élite de la Gestion Digitale à Nouakchott",
              style: TextStyle(fontSize: 12, color: kAccentColor, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),
            
            // SECTION 1 : POUR LES CLIENTS DU RESTO
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kSurfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("📍 SERVICE CLIENT", style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  const Text(
                    "Commandez vos plats préférés, suivez vos livraisons en temps réel partout dans la capitale et profitez du support de notre Chef IA !",
                    style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  _buildActionRow(Icons.flash_on, "Livraison Éclair", "Tevragh Zeina, Ksar, Carrefour, etc."),
                  _buildActionRow(Icons.account_balance_wallet, "Paiements Locaux", "Bankily, Masrvi ou Cash"),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // SECTION 2 : TON ARGENT 💰 - POUR VENDRE TON APPLICATION AUX AUTRES RESTOS
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kSurfaceColor, kPrimaryColor.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.monetization_on, color: kAccentColor, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        "PROPRIÉTAIRE DE RESTAURANT ?",
                        style: TextStyle(color: kAccentColor, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Vous voulez la même application exclusive pour votre propre établissement ? Augmentez vos commandes de 40%, gérez vos livreurs et vos caisses comme un pro avec un abonnement mensuel ultra rentable.",
                    style: TextStyle(color: Colors.whiteB0, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "⚡ Inclus : Application Client + Panel Directeur + Cuisine + Système Livreur + Chef IA.",
                    style: TextStyle(color: kPrimaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // BOUTON DE CONTACT UNIQUE, PRO ET PROPRE (WHATSAPP SÉCURISÉ)
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(colors: [Color(0xFF25D366), Color(0xFF075E54)]),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF25D366).withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  final cleanPhone = kDeveloperPhone.replaceAll(RegExp(r'[^+\d]'), '');
                  final whatsappUrl = Uri.parse("https://wa.me/$cleanPhone?text=Salut%20Nagato,%20je%20veux%20commander%20ou%20avoir%20des%20infos%20sur%20l%27abonnement%20de%20l%27application%20!");
                  _ouvrirUrl(whatsappUrl);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.whatsapp, color: Colors.white, size: 24),
                label: const Text(
                  "CONTACTER LE SCRIPT / NAGATO",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white, letterSpacing: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: kPrimaryColor, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          )
        ],
      ),
    );
  }
}