import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'constants.dart';

// ═══════════════════════════════════════════════════════
//  ONBOARDING SCREEN — 3 slides animés
//  ✅ S'affiche uniquement au premier lancement
//  ✅ Sauvegardé dans SharedPreferences
//  ✅ Design premium avec animations
// ═══════════════════════════════════════════════════════

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static Future<bool> doitAfficher() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('onboarding_done') ?? false);
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  int _currentPage = 0;

  final List<_OnboardingData> _pages = const [
    _OnboardingData(
      emoji: '🍔',
      title: 'Commandez en quelques secondes',
      subtitle: 'Parcourez le menu, ajoutez vos plats au panier et passez commande depuis votre téléphone.',
      color: Color(0xFF2196F3),
      bg: Color(0xFF0D1B2E),
    ),
    _OnboardingData(
      emoji: '🛵',
      title: 'Suivi en temps réel',
      subtitle: 'Suivez votre commande étape par étape — de la cuisine jusqu\'à votre porte.',
      color: Color(0xFF00E676),
      bg: Color(0xFF0A1F0F),
    ),
    _OnboardingData(
      emoji: '💳',
      title: 'Payez comme vous voulez',
      subtitle: 'Cash, Bankily ou Masrivi — choisissez votre mode de paiement préféré.',
      color: Color(0xFFFFD700),
      bg: Color(0xFF1F1A00),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      _terminer();
    }
  }

  Future<void> _terminer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Stack(children: [
        // Pages
        PageView.builder(
          controller: _pageController,
          itemCount: _pages.length,
          onPageChanged: (i) {
            setState(() => _currentPage = i);
            _animController.reset();
            _animController.forward();
          },
          itemBuilder: (context, i) {
            final page = _pages[i];
            return AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              color: page.bg,
              child: SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(flex: 2),
                          // Emoji animé
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.5, end: 1.0),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.elasticOut,
                            builder: (_, val, child) =>
                                Transform.scale(scale: val, child: child),
                            child: Container(
                              width: 140, height: 140,
                              decoration: BoxDecoration(
                                color: page.color.withOpacity(0.12),
                                shape: BoxShape.circle,
                                border: Border.all(color: page.color.withOpacity(0.3), width: 2),
                              ),
                              child: Center(child: Text(page.emoji, style: const TextStyle(fontSize: 64))),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            page.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white, fontSize: 26,
                              fontWeight: FontWeight.w900, height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            page.subtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white60, fontSize: 16, height: 1.6),
                          ),
                          const Spacer(flex: 2),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // Bottom controls
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, kBackgroundColor.withOpacity(0.95)],
              ),
            ),
            child: Column(children: [
              // Indicateurs
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) {
                  final active = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active ? _pages[_currentPage].color : Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              Row(children: [
                // Passer
                if (_currentPage < _pages.length - 1)
                  TextButton(
                    onPressed: _terminer,
                    child: const Text('Passer', style: TextStyle(color: Colors.white38, fontSize: 15)),
                  )
                else
                  const SizedBox(width: 80),
                const Spacer(),
                // Bouton suivant
                GestureDetector(
                  onTap: _nextPage,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: EdgeInsets.symmetric(
                      horizontal: _currentPage == _pages.length - 1 ? 32 : 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: _pages[_currentPage].color,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(color: _pages[_currentPage].color.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(
                        _currentPage == _pages.length - 1 ? 'Commencer' : 'Suivant',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        _currentPage == _pages.length - 1 ? Icons.check : Icons.arrow_forward_rounded,
                        color: Colors.white, size: 18,
                      ),
                    ]),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _OnboardingData {
  final String emoji, title, subtitle;
  final Color color, bg;
  const _OnboardingData({
    required this.emoji, required this.title,
    required this.subtitle, required this.color, required this.bg,
  });
}
