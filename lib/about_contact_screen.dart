import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'branding_service.dart';
import 'constants.dart';
import 'widgets/restaurant_logo.dart';

class AboutContactScreen extends StatelessWidget {
  const AboutContactScreen({super.key});

  Future<void> _ouvrir(Uri uri) async {
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
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kSecondaryColor),
                ),
                const SizedBox(height: 6),
                Text(brand.slogan, textAlign: TextAlign.center, style: TextStyle(color: kPrimaryColor, fontSize: 14)),
                const SizedBox(height: 28),
                _infoCard(Icons.location_on, "Adresse", "${brand.adresse}\n${brand.deliveryLocation}"),
                const SizedBox(height: 12),
                _infoCard(Icons.access_time, "Horaires", brand.horaires),
                const SizedBox(height: 24),
                _actionButton(
                  icon: Icons.chat,
                  label: "WhatsApp",
                  subtitle: "Commander ou poser une question",
                  color: const Color(0xFF25D366),
                  onTap: () => _ouvrir(Uri.parse(_whatsappUri(brand.whatsapp))),
                ),
                const SizedBox(height: 12),
                _actionButton(
                  icon: Icons.phone,
                  label: "Appeler",
                  subtitle: brand.telephone,
                  color: kPrimaryColor,
                  onTap: () => _ouvrir(Uri.parse("tel:${brand.telephone.replaceAll(' ', '')}")),
                ),
                const SizedBox(height: 12),
                _actionButton(
                  icon: Icons.delivery_dining,
                  label: "Zone de livraison",
                  subtitle: "${brand.zone}, ${brand.ville} — ${brand.fraisLivraison} MRU",
                  color: kSecondaryColor,
                  onTap: () {},
                ),
                const SizedBox(height: 32),
                Text(
                  "Propulsé par votre application de livraison",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoCard(IconData icon, String titre, String contenu) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: kPrimaryColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre, style: const TextStyle(fontWeight: FontWeight.bold, color: kSecondaryColor)),
                const SizedBox(height: 4),
                Text(contenu, style: const TextStyle(color: Colors.grey, height: 1.4)),
              ],
            ),
          ),
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
          ),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: color.withValues(alpha: 0.15), child: Icon(icon, color: color)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
