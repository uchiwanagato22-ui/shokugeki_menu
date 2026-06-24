import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'login_screen.dart';
import 'constants.dart';

// ═══════════════════════════════════════════════════════
//  WELCOME CHARACTER SCREEN — Anime Style
//  ✅ Personnage animé qui parle
//  ✅ Texte qui s'écrit lettre par lettre
//  ✅ Particules flottantes
//  ✅ S'affiche une seule fois au premier lancement
// ═══════════════════════════════════════════════════════

class WelcomeCharacterScreen extends StatefulWidget {
  const WelcomeCharacterScreen({super.key});

  static Future<bool> doitAfficher() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('welcome_done') ?? false);
  }

  @override
  State<WelcomeCharacterScreen> createState() => _WelcomeCharacterScreenState();
}

class _WelcomeCharacterScreenState extends State<WelcomeCharacterScreen>
    with TickerProviderStateMixin {

  late AnimationController _characterController;
  late AnimationController _particleController;
  late AnimationController _glowController;
  late AnimationController _textController;
  late Animation<double> _floatAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _scaleAnim;

  int _messageIndex = 0;
  String _displayedText = '';
  bool _isTyping = false;
  bool _showButton = false;

  final List<String> _messages = [
    "Irasshaimase ! 🎌\nBienvenue chez Shokugeki Menu !",
    "Je suis votre Chef IA... \nPrête à vous régaler ! 🍜",
    "Commandez vos plats préférés\nen quelques secondes. ⚡",
    "Livraison, sur place...\nVous choisissez, on s'occupe du reste ! 🛵",
  ];

  @override
  void initState() {
    super.initState();

    _characterController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _floatAnim = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _characterController, curve: Curves.easeInOut),
    );

    _glowAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.elasticOut),
    );

    Future.delayed(const Duration(milliseconds: 500), () => _typeMessage(_messages[0]));
  }

  @override
  void dispose() {
    _characterController.dispose();
    _particleController.dispose();
    _glowController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _typeMessage(String message) async {
    if (!mounted) return;
    setState(() { _isTyping = true; _displayedText = ''; _showButton = false; });
    _textController.reset();
    _textController.forward();

    for (int i = 0; i <= message.length; i++) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 35));
      if (!mounted) return;
      setState(() => _displayedText = message.substring(0, i));
    }

    if (!mounted) return;
    setState(() { _isTyping = false; });

    if (_messageIndex < _messages.length - 1) {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      _messageIndex++;
      _typeMessage(_messages[_messageIndex]);
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() => _showButton = true);
    }
  }

  Future<void> _commencer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('welcome_done', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050008),
      body: Stack(children: [

        // ── Fond animé ───────────────────────────────────
        AnimatedBuilder(
          animation: _particleController,
          builder: (_, __) => CustomPaint(
            painter: _ParticlePainter(_particleController.value),
            size: Size.infinite,
          ),
        ),

        // ── Contenu principal ────────────────────────────
        SafeArea(
          child: Column(children: [
            const Spacer(flex: 1),

            // Logo / titre
            AnimatedBuilder(
              animation: _glowAnim,
              builder: (_, __) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.purple.withOpacity(_glowAnim.value * 0.6), width: 1),
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.purple.withOpacity(0.05),
                ),
                child: const Text(
                  'SHOKUGEKI MENU',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ),

            const Spacer(flex: 1),

            // ── Personnage animé ─────────────────────────
            AnimatedBuilder(
              animation: _floatAnim,
              builder: (_, __) => Transform.translate(
                offset: Offset(0, _floatAnim.value),
                child: AnimatedBuilder(
                  animation: _glowAnim,
                  builder: (_, __) => Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(_glowAnim.value * 0.5),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                        BoxShadow(
                          color: Colors.blue.withOpacity(_glowAnim.value * 0.3),
                          blurRadius: 60,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Stack(alignment: Alignment.center, children: [
                      // Cercles orbitaux
                      _OrbitRing(size: 170, color: Colors.purple, duration: 4),
                      _OrbitRing(size: 150, color: Colors.blue, duration: 6, reverse: true),

                      // Personnage principal
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.purple.shade300,
                              Colors.purple.shade800,
                              const Color(0xFF1a0028),
                            ],
                          ),
                          border: Border.all(color: Colors.purple.shade300, width: 2),
                        ),
                        child: const Center(
                          child: Text('👩‍🍳', style: TextStyle(fontSize: 60)),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── Bulle de dialogue ────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.purple.withOpacity(0.4)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.1),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: _isTyping ? Colors.purple : Colors.green,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: (_isTyping ? Colors.purple : Colors.green).withOpacity(0.6), blurRadius: 6)],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isTyping ? 'Chef IA écrit...' : 'Chef IA',
                        style: TextStyle(
                          color: _isTyping ? Colors.purple.shade200 : Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    Text(
                      _displayedText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_isTyping) ...[
                      const SizedBox(height: 8),
                      const _TypingDots(),
                    ],
                  ]),
                ),
              ),
            ),

            // Indicateur de message
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_messages.length, (i) {
                final active = i == _messageIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? Colors.purple : Colors.white24,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),

            const Spacer(flex: 2),

            // ── Bouton commencer ─────────────────────────
            if (_showButton)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (_, val, child) => Transform.scale(scale: val, child: child),
                  child: GestureDetector(
                    onTap: _commencer,
                    child: AnimatedBuilder(
                      animation: _glowAnim,
                      builder: (_, __) => Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7B2FBE), Color(0xFF4A00E0)],
                          ),
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(_glowAnim.value * 0.6),
                              blurRadius: 30,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('✨  COMMENCER L\'AVENTURE', style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            if (!_showButton)
              GestureDetector(
                onTap: _commencer,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Passer', style: TextStyle(color: Colors.white30, fontSize: 14)),
                ),
              ),

            const SizedBox(height: 32),
          ]),
        ),
      ]),
    );
  }
}

// ── Anneau orbital ────────────────────────────────────────────────────────────
class _OrbitRing extends StatefulWidget {
  final double size;
  final Color color;
  final int duration;
  final bool reverse;
  const _OrbitRing({required this.size, required this.color, required this.duration, this.reverse = false});

  @override
  State<_OrbitRing> createState() => _OrbitRingState();
}

class _OrbitRingState extends State<_OrbitRing> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: Duration(seconds: widget.duration))..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.rotate(
        angle: (widget.reverse ? -1 : 1) * _ctrl.value * 2 * math.pi,
        child: Container(
          width: widget.size, height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: widget.color.withOpacity(0.3), width: 1.5),
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: widget.color, blurRadius: 8)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Points de frappe ──────────────────────────────────────────────────────────
class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Row(
        children: List.generate(3, (i) {
          final delay = i / 3;
          final val = math.sin((_ctrl.value - delay) * math.pi * 2).clamp(0.0, 1.0);
          return Container(
            margin: const EdgeInsets.only(right: 4),
            width: 6, height: 6,
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.3 + val * 0.7),
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }
}

// ── Particules background ─────────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final double progress;
  _ParticlePainter(this.progress);

  static final List<List<double>> _particles = List.generate(
    20, (i) => [
      (i * 137.5) % 100,
      (i * 73.3) % 100,
      0.3 + (i % 5) * 0.1,
      (i * 0.7) % 1.0,
    ],
  );

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final x = p[0] / 100 * size.width;
      final baseY = p[1] / 100 * size.height;
      final y = (baseY - progress * size.height * 0.3 * p[2]) % size.height;
      final opacity = (math.sin((progress + p[3]) * math.pi * 2) * 0.5 + 0.5) * p[2];

      canvas.drawCircle(
        Offset(x, y),
        1.5 + p[2] * 2,
        Paint()..color = Colors.purple.withOpacity(opacity * 0.6),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
