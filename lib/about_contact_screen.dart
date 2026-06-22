import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'constants.dart';
 
class AboutContactScreen extends StatelessWidget {
  const AboutContactScreen({super.key});
 
  // ─── Helpers WhatsApp ───────────────────────────────────────────────────────
 
  Future<void> _ouvrirUrl(Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint("Impossible d'ouvrir : $uri");
    }
  }
 
  void _contacterWhatsApp(String message) {
    final clean = kDeveloperPhone.replaceAll(RegExp(r'[^\d+]'), '');
    final num   = clean.replaceAll('+', '');
    final uri   = Uri.parse('https://wa.me/$num?text=${Uri.encodeComponent(message)}');
    _ouvrirUrl(uri);
  }
 
  // ─── Build ──────────────────────────────────────────────────────────────────
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Nagato Business', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: kSurfaceColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
 
            // ── En-tête identité ────────────────────────────────────────────
            _HeroHeader(),
            const SizedBox(height: 32),
 
            // ── Accroche ────────────────────────────────────────────────────
            const Text(
              'Votre idée. Notre code. Votre succès.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Nous développons des applications mobiles et des sites web sur mesure '
              'pour les restaurants, commerces et entrepreneurs de Mauritanie '
              'et de toute l\'Afrique de l\'Ouest.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 32),
 
            // ── Nos 3 services ──────────────────────────────────────────────
            const _SectionTitle(title: 'Nos services'),
            const SizedBox(height: 14),
 
            _ServiceCard(
              icon: Icons.restaurant_menu_rounded,
              color: kPrimaryColor,
              tag: 'POPULAIRE',
              tagColor: kPrimaryColor,
              title: 'App Restaurant Clé en Main',
              description:
                  'La même application que vous utilisez en ce moment — '
                  'livrée en 48h avec votre nom, votre logo et vos couleurs. '
                  'Menu en ligne, commandes, livreurs, cuisine, caissier, IA intégrée.',
              features: const [
                'Menu + photos + catégories',
                'Suivi commande temps réel',
                'Dashboard directeur + IA',
                'Notifications push client',
                'Écran cuisine & livreur GPS',
              ],
              price: 'À partir de 15 000 MRU / an',
              onTap: () => _contacterWhatsApp(
                'Bonjour Nagato ! Je veux une application pour mon restaurant. '
                'Pouvez-vous me donner plus d\'informations et les tarifs ?',
              ),
              buttonLabel: 'Je veux cette app',
            ),
 
            const SizedBox(height: 14),
 
            _ServiceCard(
              icon: Icons.phone_android_rounded,
              color: const Color(0xFF9C27B0),
              tag: 'SUR MESURE',
              tagColor: const Color(0xFF9C27B0),
              title: 'Application Mobile Personnalisée',
              description:
                  'Vous avez une idée d\'application ? '
                  'E-commerce, livraison, coiffure, pharmacie, immobilier, école… '
                  'Nous la développons en Flutter pour Android et iOS.',
              features: const [
                'Analyse de votre besoin gratuite',
                'Design sur mesure',
                'Android + iOS',
                'Connexion Firebase / API',
                'Maintenance incluse 3 mois',
              ],
              price: 'Devis gratuit sous 24h',
              onTap: () => _contacterWhatsApp(
                'Bonjour Nagato ! J\'ai une idée d\'application mobile. '
                'Je voudrais un devis et discuter du projet.',
              ),
              buttonLabel: 'Discuter de mon projet',
            ),
 
            const SizedBox(height: 14),
 
            _ServiceCard(
              icon: Icons.language_rounded,
              color: const Color(0xFF009688),
              tag: 'SITE WEB',
              tagColor: const Color(0xFF009688),
              title: 'Site Web Professionnel',
              description:
                  'Un site vitrine ou e-commerce moderne et rapide — '
                  'pour être visible sur Google, présenter vos services '
                  'et attirer de nouveaux clients 24h/24.',
              features: const [
                'Design moderne et responsive',
                'Référencement Google (SEO)',
                'Formulaire de contact',
                'Galerie photos / menu en ligne',
                'Hébergement 1 an offert',
              ],
              price: 'À partir de 8 000 MRU',
              onTap: () => _contacterWhatsApp(
                'Bonjour Nagato ! Je suis intéressé par la création d\'un site web. '
                'Pouvez-vous me donner les détails et tarifs ?',
              ),
              buttonLabel: 'Commander mon site',
            ),
 
            const SizedBox(height: 32),
 
            // ── Chiffres clés ───────────────────────────────────────────────
            const _SectionTitle(title: 'Pourquoi nous choisir'),
            const SizedBox(height: 14),
            const _StatsRow(),
            const SizedBox(height: 32),
 
            // ── Comment ça marche ───────────────────────────────────────────
            const _SectionTitle(title: 'Comment ça marche'),
            const SizedBox(height: 14),
            const _ProcessSteps(),
            const SizedBox(height: 32),
 
            // ── CTA final ───────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kSurfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Prêt à lancer votre projet ?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Contactez Nagato maintenant sur WhatsApp — réponse garantie dans la journée.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () => _contacterWhatsApp(
                        'Bonjour Nagato ! Je veux créer une application ou un site web. '
                        'Pouvez-vous me contacter pour discuter de mon projet ?',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.chat_rounded, color: Colors.white),
                      label: const Text(
                        'WhatsApp — +222 32 65 23 00',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final uri = Uri(
                          scheme: 'tel',
                          path: kDeveloperPhone.replaceAll(' ', ''),
                        );
                        _ouvrirUrl(uri);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withOpacity(0.2)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.phone_rounded, color: Colors.white70),
                      label: const Text(
                        'Appel direct',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
 
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
 
// ══════════════════════════════════════════════════════════════════
//  WIDGETS INTERNES
// ══════════════════════════════════════════════════════════════════
 
class _HeroHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            color: kSurfaceColor,
            shape: BoxShape.circle,
            border: Border.all(color: kPrimaryColor, width: 2.5),
          ),
          child: const Icon(Icons.code_rounded, size: 42, color: kPrimaryColor),
        ),
        const SizedBox(height: 12),
        const Text(
          'Nagato Business',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: kAccentColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kAccentColor.withOpacity(0.3)),
          ),
          child: const Text(
            'Développeur App & Web — Nouakchott',
            style: TextStyle(
              color: kAccentColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
 
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
 
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 4, height: 20, color: kPrimaryColor,
            margin: const EdgeInsets.only(right: 10)),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
 
class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tag;
  final Color tagColor;
  final String title;
  final String description;
  final List<String> features;
  final String price;
  final VoidCallback onTap;
  final String buttonLabel;
 
  const _ServiceCard({
    required this.icon,
    required this.color,
    required this.tag,
    required this.tagColor,
    required this.title,
    required this.description,
    required this.features,
    required this.price,
    required this.onTap,
    required this.buttonLabel,
  });
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: tagColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: tagColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
 
          // Description
          Text(
            description,
            style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 12),
 
          // Features
          ...features.map((f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: color, size: 15),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(f,
                          style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ),
                  ],
                ),
              )),
 
          const SizedBox(height: 14),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),
 
          // Prix + Bouton
          Row(
            children: [
              Expanded(
                child: Text(
                  price,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Text(
                    buttonLabel,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
 
class _StatsRow extends StatelessWidget {
  const _StatsRow();
 
  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: _StatBox(value: '48h', label: 'Livraison')),
        SizedBox(width: 10),
        Expanded(child: _StatBox(value: '100%', label: 'Sur mesure')),
        SizedBox(width: 10),
        Expanded(child: _StatBox(value: '24/7', label: 'Support')),
      ],
    );
  }
}
 
class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  const _StatBox({required this.value, required this.label});
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: kPrimaryColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
 
class _ProcessSteps extends StatelessWidget {
  const _ProcessSteps();
 
  static const _steps = [
    ('1', 'Contact', 'Un message WhatsApp suffit'),
    ('2', 'Brief', 'On discute de votre projet en détail'),
    ('3', 'Dev', 'On développe votre app ou site'),
    ('4', 'Livraison', 'Vous recevez votre produit fini'),
  ];
 
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _steps.map((s) {
        final isLast = s == _steps.last;
        return Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: kPrimaryColor, width: 1.5),
                      ),
                      child: Center(
                        child: Text(s.$1,
                            style: const TextStyle(
                                color: kPrimaryColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 14)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(s.$2,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(s.$3,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey, fontSize: 11, height: 1.4)),
                  ],
                ),
              ),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    width: 16,
                    height: 1.5,
                    color: kPrimaryColor.withOpacity(0.3),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
 