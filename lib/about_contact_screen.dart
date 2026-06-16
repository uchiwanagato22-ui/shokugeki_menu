import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'branding_service.dart';
import 'constants.dart';
import 'widgets/restaurant_logo.dart';

class AboutContactScreen extends StatelessWidget {
  const AboutContactScreen({super.key});

  Future<void> _ouvrirUrl(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _whatsappUri(String numero) {
    final clean = numero.replaceAll(RegExp(r'[^\d]'), '');
    return "https://wa.me/$clean";
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BrandingData>(
      stream: BrandingService().watchBranding(),
      builder: (context, snap) {
        final brand = snap.data ?? BrandingData.defaults();

        return Scaffold(
          backgroundColor: kBackgroundColor,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const RestaurantLogo(size: 100),
                const SizedBox(height: 16),
                Text(
                  brand.nom,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                Text(
                  brand.slogan,
                  style: TextStyle(
                      fontSize: 14,
                      color: kPrimaryColor.withOpacity(0.8),
                      fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // --- INFOS DU RESTAURANT ---
                _infoCard(
                    Icons.access_time, "Horaires d'ouverture", brand.horaires),
                const SizedBox(height: 12),
                _infoCard(
                    Icons.location_on_outlined, "Notre Adresse", brand.adresse),
                const SizedBox(height: 24),

                // --- BOUTONS D'ACTION RESTAURANT ---
                _actionButton(
                  icon: Icons.phone,
                  label: "Appeler le Restaurant",
                  subtitle: brand.telephone,
                  color: Colors.green,
                  onTap: () => _ouvrirUrl(Uri.parse("tel:${brand.telephone}")),
                ),
                const SizedBox(height: 12),
                _actionButton(
                  icon: Icons.chat,
                  label: "WhatsApp du Restaurant",
                  subtitle: "Passer commande en direct",
                  color: const Color(0xFF25D366),
                  onTap: () =>
                      _ouvrirUrl(Uri.parse(_whatsappUri(brand.whatsapp))),
                ),

                const SizedBox(height: 40),
                const Divider(color: Colors.white10),
                const SizedBox(height: 20),

                // ══════════════════════════════════════════════════════════
                // 🔥 NOUVELLE FONCTIONNALITÉ : TON APPORT FREELANCE / COMMERCIAL
                // ══════════════════════════════════════════════════════════
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kPrimaryColor.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.code, color: kPrimaryColor, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "Propulsé par Uchiwa Nagato",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Vous voulez une application iOS/Android sur-mesure ou un site web connecté pour votre propre business ?",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          final devUrl = _whatsappUri(kDeveloperPhone);
                          _ouvrirUrl(Uri.parse(devUrl));
                        },
                        icon: const Icon(Icons.bolt, color: Colors.black),
                        label: const Text(
                          "Commander mon Application",
                          style: TextStyle(
                              color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          minimumSize: const Size(double.infinity, 45),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoCard(IconData icon, String titre, String valeur) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: kSurfaceColor, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Icon(icon, color: kPrimaryColor, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre,
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(valeur,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: kSurfaceColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                  backgroundColor: color.withOpacity(0.15),
                  child: Icon(icon, color: color)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.white)),
                    Text(subtitle,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
