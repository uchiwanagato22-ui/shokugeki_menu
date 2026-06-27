import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import 'constants.dart';

// ═══════════════════════════════════════════════════════
//  ABOUT CONTACT SCREEN — v2 Premium
//  ✅ Avatar Nagato avec effets anime
//  ✅ Services cards avec vraie photo
//  ✅ Animations particules
// ═══════════════════════════════════════════════════════

class AboutContactScreen extends StatefulWidget {
  const AboutContactScreen({super.key});

  @override
  State<AboutContactScreen> createState() => _AboutContactScreenState();
}

class _AboutContactScreenState extends State<AboutContactScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  Future<void> _ouvrirUrl(Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint("Impossible d'ouvrir : $uri");
    }
  }

  void _contacterWhatsApp(String message) {
    final num = kDeveloperPhone.replaceAll(RegExp(r'[^\d+]'), '').replaceAll('+', '');
    final uri = Uri.parse('https://wa.me/$num?text=${Uri.encodeComponent(message)}');
    _ouvrirUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030005),
      appBar: AppBar(
        title: const Text('Nagato Business', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF0A0012),
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.transparent, kPrimaryColor.withOpacity(0.5), Colors.transparent]),
          )),
        ),
      ),
      body: Stack(children: [
        // Fond particules
        const _ParticleBackground(),

        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // ── Hero Nagato ─────────────────────────────────
              _NagatoHero(glowAnim: _glowAnim),
              const SizedBox(height: 28),

              // ── Accroche ────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kPrimaryColor.withOpacity(0.2)),
                ),
                child: const Column(children: [
                  Text(
                    'Votre idée. Notre code. Votre succès.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.3, height: 1.3),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Applications mobiles et sites web sur mesure pour les restaurants, commerces et entrepreneurs de Mauritanie et d\'Afrique de l\'Ouest.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
                  ),
                ]),
              ),
              const SizedBox(height: 28),

              // ── Stats ────────────────────────────────────────
              Row(children: [
                _StatBadge(value: '48h', label: 'Livraison'),
                const SizedBox(width: 10),
                _StatBadge(value: '100%', label: 'Sur mesure'),
                const SizedBox(width: 10),
                _StatBadge(value: '24/7', label: 'Support'),
              ]),
              const SizedBox(height: 28),

              // ── Services ─────────────────────────────────────
              _SectionLabel(label: 'NOS SERVICES'),
              const SizedBox(height: 14),

              _ServiceCard(
                icon: Icons.restaurant_menu_rounded,
                color: kPrimaryColor,
                tag: '⭐ POPULAIRE',
                title: 'App Restaurant Clé en Main',
                description: 'La même application que vous utilisez — livrée en 48h avec votre nom, logo et couleurs. Menu, commandes, 5 rôles, IA intégrée.',
                features: const ['Menu + photos + catégories', 'Suivi commande temps réel', 'Dashboard directeur + IA', 'Caissier, cuisine, livreur', 'Notifications push client'],
                price: 'À partir de 15 000 MRU/an',
                buttonLabel: 'Je veux cette app',
                onTap: () => _contacterWhatsApp('Bonjour Nagato ! Je veux une application pour mon restaurant. Pouvez-vous me donner plus d\'informations ?'),
              ),
              const SizedBox(height: 14),

              _ServiceCard(
                icon: Icons.phone_android_rounded,
                color: const Color(0xFF9C27B0),
                tag: '🚀 SUR MESURE',
                title: 'Application Mobile Personnalisée',
                description: 'E-commerce, livraison, coiffure, pharmacie, immobilier... Nous développons votre idée en Flutter pour Android et iOS.',
                features: const ['Analyse de votre besoin gratuite', 'Design sur mesure', 'Android + iOS', 'Connexion Firebase / API', 'Maintenance 3 mois incluse'],
                price: 'Devis gratuit sous 24h',
                buttonLabel: 'Discuter de mon projet',
                onTap: () => _contacterWhatsApp('Bonjour Nagato ! J\'ai une idée d\'application mobile. Je voudrais un devis.'),
              ),
              const SizedBox(height: 14),

              _ServiceCard(
                icon: Icons.language_rounded,
                color: const Color(0xFF009688),
                tag: '🌐 SITE WEB',
                title: 'Site Web Professionnel',
                description: 'Site vitrine ou e-commerce moderne — visible sur Google, avec formulaire de contact, galerie photos et hébergement offert.',
                features: const ['Design responsive moderne', 'Référencement Google (SEO)', 'Formulaire de contact', 'Galerie photos / menu', 'Hébergement 1 an offert'],
                price: 'À partir de 8 000 MRU',
                buttonLabel: 'Commander mon site',
                onTap: () => _contacterWhatsApp('Bonjour Nagato ! Je suis intéressé par la création d\'un site web.'),
              ),
              const SizedBox(height: 32),

              // ── CTA Final ────────────────────────────────────
              AnimatedBuilder(
                animation: _glowAnim,
                builder: (_, __) => Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0012),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kPrimaryColor.withOpacity(0.2 + _glowAnim.value * 0.3)),
                    boxShadow: [
                      BoxShadow(color: kPrimaryColor.withOpacity(_glowAnim.value * 0.15), blurRadius: 20, spreadRadius: 2),
                    ],
                  ),
                  child: Column(children: [
                    const Text('Prêt à lancer votre projet ?', textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    const Text('Contactez Nagato maintenant — réponse garantie dans la journée.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5)),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity, height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () => _contacterWhatsApp('Bonjour Nagato ! Je veux créer une application ou un site web. Pouvez-vous me contacter ?'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.chat_rounded, color: Colors.white),
                        label: const Text('WhatsApp — +222 32 65 23 00',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity, height: 46,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final uri = Uri(scheme: 'tel', path: kDeveloperPhone.replaceAll(' ', ''));
                          _ouvrirUrl(uri);
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white.withOpacity(0.15)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.phone_rounded, color: Colors.white70),
                        label: const Text('Appel direct', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  HERO NAGATO AVEC VRAIE PHOTO
// ═══════════════════════════════════════════════════════
class _NagatoHero extends StatelessWidget {
  final Animation<double> glowAnim;
  const _NagatoHero({required this.glowAnim});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      AnimatedBuilder(
        animation: glowAnim,
        builder: (_, __) => Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: kPrimaryColor, width: 2.5),
            boxShadow: [
              BoxShadow(color: kPrimaryColor.withOpacity(glowAnim.value * 0.6), blurRadius: 24, spreadRadius: 4),
              BoxShadow(color: kPrimaryColor.withOpacity(glowAnim.value * 0.3), blurRadius: 40, spreadRadius: 8),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/nagato_avatar.jpg',
              width: 100, height: 100, fit: BoxFit.cover,
              // Fallback si l'image n'est pas encore dans les assets
              errorBuilder: (_, __, ___) => Container(
                color: kSurfaceColor,
                child: Image.asset('assets/images/nagato_avatar.png', width: 100, height: 100, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.code_rounded, size: 48, color: kPrimaryColor),
            ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 14),
      const Text('Uchiwa Nagato', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: kPrimaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
        ),
        child: const Text('⚡ Développeur App & Web — Nouakchott',
            style: TextStyle(color: kPrimaryColor, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    ]);
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 3, height: 16, color: kPrimaryColor, margin: const EdgeInsets.only(right: 10)),
    Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
  ]);
}

class _StatBadge extends StatelessWidget {
  final String value, label;
  const _StatBadge({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(children: [
        Text(value, style: const TextStyle(color: kPrimaryColor, fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ]),
    ),
  );
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tag, title, description, price, buttonLabel;
  final List<String> features;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.icon, required this.color, required this.tag,
    required this.title, required this.description, required this.price,
    required this.buttonLabel, required this.features, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0012),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(tag, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ])),
        ]),
        const SizedBox(height: 12),
        Text(description, style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.5)),
        const SizedBox(height: 12),
        ...features.map((f) => Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Row(children: [
            Icon(Icons.check_circle_rounded, color: color, size: 14),
            const SizedBox(width: 8),
            Expanded(child: Text(f, style: const TextStyle(color: Colors.white70, fontSize: 12))),
          ]),
        )),
        const SizedBox(height: 12),
        const Divider(color: Colors.white10, height: 1),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Text(price, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold))),
          SizedBox(
            height: 38,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              child: Text(buttonLabel, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _ParticleBackground extends StatefulWidget {
  const _ParticleBackground();

  @override
  State<_ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<_ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, __) => CustomPaint(
      painter: _ParticlePainter(_ctrl.value),
      size: Size.infinite,
    ),
  );
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  _ParticlePainter(this.progress);

  static final _pts = List.generate(15, (i) => [
    (i * 137.5) % 100.0,
    (i * 73.3) % 100.0,
    0.2 + (i % 5) * 0.08,
    (i * 0.7) % 1.0,
  ]);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _pts) {
      final x = p[0] / 100 * size.width;
      final baseY = p[1] / 100 * size.height;
      final y = (baseY - progress * size.height * 0.4 * p[2]) % size.height;
      final o = (math.sin((progress + p[3]) * math.pi * 2) * 0.5 + 0.5) * p[2];
      canvas.drawCircle(Offset(x, y < 0 ? y + size.height : y), 1.5,
          Paint()..color = kPrimaryColor.withOpacity(o * 0.5));
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
