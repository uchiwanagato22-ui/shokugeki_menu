import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'branding_service.dart';
import 'constants.dart';
import 'widgets/restaurant_logo.dart';
import 'widgets/developer_contact_button.dart';

class AboutContactScreen extends StatelessWidget {
  const AboutContactScreen({super.key});

  Future<void> _ouvrirUrl(Uri uri) async {
    // Correction url_launcher pour forcer l'ouverture externe sur mobile
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint("Impossible d'ouvrir l'url : $uri");
    }
  }

  String _whatsappUri(String numero) {
    // Supprime les espaces et caractères spéciaux sauf les chiffres
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
                _infoCard(Icons.access_time, "Horaires d'ouverture", brand.horaires),
                const SizedBox(height: 12),
                _infoCard(Icons.location_on_outlined, "Notre Adresse", brand.adresse),
                const SizedBox(height: 12),
                
                // --- APERÇU DE LA CARTE (Évite l'effet désert vide) ---
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: kSurfaceColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.3,
                            child: GridPaper(
                              color: kPrimaryColor,
                              divisions: 2,
                              subdivisions: 1,
                            ),
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.map_radial, color: kPrimaryColor, size: 40),
                              const SizedBox(height: 8),
                              Text(
                                "Nouakchott, Mauritanie",
                                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // --- BOUTONS D'ACTION RESTAURANT ---
                _actionButton(
                  icon: Icons.phone,
                  label: "Appeler le Restaurant",
                  subtitle: brand.telephone,
                  color: Colors.green,
                  onTap: () => _ouvrirUrl(Uri.parse("tel:${brand.telephone.replaceAll(' ', '')}")),
                ),
                const SizedBox(height: 12),
                _actionButton(
                  icon: Icons.chat,
                  label: "WhatsApp du Restaurant",
                  subtitle: "Passer commande en direct",
                  color: const Color(0xFF25D366),
                  onTap: () {
                    // Utilisation directe du numéro cible +22232652300 par défaut si brand est vide
                    final numWh = brand.whatsapp.isNotEmpty ? brand.whatsapp : "+22232652300";
                    _ouvrirUrl(Uri.parse(_whatsappUri(numWh)));
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kSurfaceColor, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Icon(icon, color: kPrimaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
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
                    Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                    Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
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