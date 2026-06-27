import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'login_screen.dart';
import 'constants.dart';

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

  late AnimationController _charCtrl;
  late AnimationController _glowCtrl;
  late AnimationController _particleCtrl;
  late Animation<double> _floatAnim;
  late Animation<double> _glowAnim;

  int _msgIdx = 0;
  String _text = '';
  bool _typing = false;
  bool _showBtn = false;

  final List<String> _msgs = [
    "Irasshaimase ! 🌀
Uchiwa Nagato te souhaite la bienvenue !",
    "Cette app a été forgée
dans la solitude et le code. ⚡",
    "Commande tes plats préférés
en quelques secondes. 🍜",
    "Livraison, sur place...
Ton choix. Notre mission. 🛵",
  ];

  @override
  void initState() {
    super.initState();
    _charCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _floatAnim = Tween<double>(begin: -10, end: 10).animate(CurvedAnimation(parent: _charCtrl, curve: Curves.easeInOut));
    _glowAnim = Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    Future.delayed(const Duration(milliseconds: 600), () => _type(_msgs[0]));
  }

  @override
  void dispose() {
    _charCtrl.dispose(); _glowCtrl.dispose(); _particleCtrl.dispose();
    super.dispose();
  }

  Future<void> _type(String msg) async {
    if (!mounted) return;
    setState(() { _typing = true; _text = ''; _showBtn = false; });
    for (int i = 0; i <= msg.length; i++) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 30));
      if (!mounted) return;
      setState(() => _text = msg.substring(0, i));
    }
    if (!mounted) return;
    setState(() => _typing = false);
    if (_msgIdx < _msgs.length - 1) {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      _msgIdx++;
      _type(_msgs[_msgIdx]);
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() => _showBtn = true);
    }
  }

  Future<void> _commencer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('welcome_done', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04000A),
      body: Stack(children: [
        AnimatedBuilder(
          animation: _particleCtrl,
          builder: (_, __) => CustomPaint(painter: _ParticlePainter(_particleCtrl.value), size: Size.infinite),
        ),
        SafeArea(
          child: Column(children: [
            const Spacer(flex: 1),

            AnimatedBuilder(
              animation: _glowAnim,
              builder: (_, __) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFCC0000).withOpacity(_glowAnim.value * 0.6)),
                  borderRadius: BorderRadius.circular(30),
                  color: const Color(0xFFCC0000).withOpacity(0.05),
                ),
                child: const Text('🌀  SHOKUGEKI MENU', style: TextStyle(color: Color(0xFFCC0000), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 3)),
              ),
            ),

            const Spacer(flex: 1),

            AnimatedBuilder(
              animation: _floatAnim,
              builder: (_, __) => Transform.translate(
                offset: Offset(0, _floatAnim.value),
                child: AnimatedBuilder(
                  animation: _glowAnim,
                  builder: (_, __) => Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: const Color(0xFFCC0000).withOpacity(_glowAnim.value * 0.5), blurRadius: 40, spreadRadius: 10),
                        BoxShadow(color: const Color(0xFFFF0000).withOpacity(_glowAnim.value * 0.2), blurRadius: 70, spreadRadius: 5),
                      ],
                    ),
                    child: Stack(alignment: Alignment.center, children: [
                      _OrbitRing(size: 180, color: const Color(0xFFCC0000), duration: 5),
                      _OrbitRing(size: 155, color: const Color(0xFFFF6666), duration: 7, reverse: true),
                      ClipOval(
                        child: Image.asset(
                          'assets/images/nagato_avatar.png',
                          width: 130, height: 130, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 130, height: 130,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF110015), border: Border.all(color: const Color(0xFFCC0000), width: 2)),
                            child: const Center(child: Text('🌀', style: TextStyle(fontSize: 50))),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFCC0000).withOpacity(0.3)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: _typing ? const Color(0xFFCC0000) : Colors.green,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: (_typing ? const Color(0xFFCC0000) : Colors.green).withOpacity(0.6), blurRadius: 6)],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(_typing ? 'Uchiwa Nagato écrit...' : '🌀 Uchiwa Nagato',
                      style: TextStyle(color: _typing ? const Color(0xFFCC0000) : Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 10),
                  Text(_text, style: const TextStyle(color: Colors.white, fontSize: 17, height: 1.5, fontWeight: FontWeight.w500)),
                  if (_typing) ...[const SizedBox(height: 8), const _TypingDots()],
                ]),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_msgs.length, (i) {
                final isActive = i == _msgIdx;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 20 : 6, height: 6,
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFFCC0000) : Colors.white24,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),

            const Spacer(flex: 2),

            if (_showBtn)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (_, val, child) => Transform.scale(scale: val, child: child),
                  child: AnimatedBuilder(
                    animation: _glowAnim,
                    builder: (_, __) => GestureDetector(
                      onTap: _commencer,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFCC0000), Color(0xFF8B0000)]),
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [BoxShadow(color: const Color(0xFFCC0000).withOpacity(_glowAnim.value * 0.6), blurRadius: 30, offset: const Offset(0, 8))],
                        ),
                        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text('⚡  ENTRER DANS L'APP', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),

            if (!_showBtn)
              GestureDetector(
                onTap: _commencer,
                child: const Padding(padding: EdgeInsets.all(16), child: Text('Passer', style: TextStyle(color: Colors.white30, fontSize: 14))),
              ),

            const SizedBox(height: 32),
          ]),
        ),
      ]),
    );
  }
}

class _OrbitRing extends StatefulWidget {
  final double size; final Color color; final int duration; final bool reverse;
  const _OrbitRing({required this.size, required this.color, required this.duration, this.reverse = false});
  @override
  State<_OrbitRing> createState() => _OrbitRingState();
}
class _OrbitRingState extends State<_OrbitRing> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: Duration(seconds: widget.duration))..repeat(); }
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
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: widget.color.withOpacity(0.25), width: 1.5)),
          child: Align(alignment: Alignment.topCenter,
            child: Container(width: 8, height: 8,
              decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: widget.color, blurRadius: 8)]))),
        ),
      ),
    );
  }
}

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
          final v = math.sin((_ctrl.value - i / 3) * math.pi * 2).clamp(0.0, 1.0);
          return Container(margin: const EdgeInsets.only(right: 4), width: 6, height: 6,
            decoration: BoxDecoration(color: const Color(0xFFCC0000).withOpacity(0.3 + v * 0.7), shape: BoxShape.circle));
        }),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  _ParticlePainter(this.progress);
  static final _pts = List.generate(18, (i) => [(i * 137.5) % 100.0, (i * 73.3) % 100.0, 0.2 + (i % 5) * 0.08, (i * 0.7) % 1.0]);
  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _pts) {
      final x = p[0] / 100 * size.width;
      final baseY = p[1] / 100 * size.height;
      final y = (baseY - progress * size.height * 0.4 * p[2]) % size.height;
      final o = (math.sin((progress + p[3]) * math.pi * 2) * 0.5 + 0.5) * p[2];
      canvas.drawCircle(Offset(x, y < 0 ? y + size.height : y), 1.5, Paint()..color = const Color(0xFFCC0000).withOpacity(o * 0.5));
    }
  }
  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
