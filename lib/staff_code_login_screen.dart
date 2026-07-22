import 'package:flutter/material.dart';

import 'constants.dart';
import 'restaurant_app_config.dart';
import 'staff_access_service.dart';

class StaffCodeLoginScreen extends StatefulWidget {
  const StaffCodeLoginScreen({
    super.key,
    required this.restaurantId,
    required this.onAccessGranted,
  });

  final String restaurantId;
  final void Function(StaffAccessResult result) onAccessGranted;

  @override
  State<StaffCodeLoginScreen> createState() => _StaffCodeLoginScreenState();
}

class _StaffCodeLoginScreenState extends State<StaffCodeLoginScreen> with SingleTickerProviderStateMixin {
  final _codeController = TextEditingController();
  final _focusNode = FocusNode();
  final _service = StaffAccessService();
  bool _loading = false;
  String? _error;

  late final AnimationController _shakeCtrl;

  // ── Protection anti brute-force ─────────────────────────
  // Un code à 4 chiffres = seulement 10 000 combinaisons.
  // Sans cette limite, quelqu'un pourrait tout essayer en quelques minutes.
  int _echecsConsecutifs = 0;
  DateTime? _bloqueJusqua;
  static const int _maxEssaisAvantBlocage = 5;
  static const Duration _dureeBlocageInitiale = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  }

  Duration _dureeBlocageActuelle() {
    // Blocage qui double à chaque nouvelle série d'échecs (30s, 60s, 120s...)
    final palier = (_echecsConsecutifs ~/ _maxEssaisAvantBlocage) - 1;
    final multiplicateur = 1 << palier.clamp(0, 5);
    return _dureeBlocageInitiale * multiplicateur;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_bloqueJusqua != null) {
      final restant = _bloqueJusqua!.difference(DateTime.now());
      if (restant.inSeconds > 0) {
        setState(() {
          _error = 'Trop de tentatives. Réessayez dans ${restant.inSeconds + 1}s.';
        });
        return;
      }
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await _service.verifyCode(
      restaurantId: widget.restaurantId,
      code: _codeController.text,
    );

    if (!mounted) return;

    if (result.allowed) {
      _echecsConsecutifs = 0;
      _bloqueJusqua = null;
      setState(() {
        _loading = false;
        _error = null;
      });
      widget.onAccessGranted(result);
      return;
    }

    _echecsConsecutifs++;
    String? messageErreur = result.errorMessage;
    if (_echecsConsecutifs % _maxEssaisAvantBlocage == 0) {
      final duree = _dureeBlocageActuelle();
      _bloqueJusqua = DateTime.now().add(duree);
      messageErreur = 'Trop de tentatives. Réessayez dans ${duree.inSeconds}s.';
    }

    setState(() {
      _loading = false;
      _error = messageErreur;
      _codeController.clear();
    });
    _shakeCtrl.forward(from: 0);
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    // Champ invisible qui capte réellement la saisie, par-dessus les 4 cases visuelles.
    return Scaffold(
      backgroundColor: kSurfaceColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 84,
                    width: 84,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.6)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: kPrimaryColor.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 10)),
                      ],
                    ),
                    child: const Icon(Icons.badge_rounded, color: Colors.white, size: 42),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Accès personnel',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Entrez le code à 4 chiffres donné par le directeur.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 32),

                  // Champ invisible : capte le clavier numérique, jamais affiché lui-même.
                  GestureDetector(
                    onTap: () => _focusNode.requestFocus(),
                    child: AnimatedBuilder(
                      animation: _shakeCtrl,
                      builder: (context, child) {
                        final t = _shakeCtrl.value;
                        final offset = (t == 0 || t == 1) ? 0.0 : 10 * (1 - t) * (t < 0.5 ? -1 : 1) * ((t * 40).round().isEven ? 1 : -1);
                        return Transform.translate(offset: Offset(offset, 0), child: child);
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Cases visuelles
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _codeController,
                            builder: (context, value, _) {
                              final saisi = value.text;
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(4, (i) {
                                  final rempli = i < saisi.length;
                                  final actif = i == saisi.length && _focusNode.hasFocus;
                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 7),
                                    width: 58,
                                    height: 64,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1B1E2B),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: _error != null
                                            ? Colors.redAccent
                                            : (actif ? kPrimaryColor : Colors.white24),
                                        width: actif || _error != null ? 2 : 1,
                                      ),
                                    ),
                                    child: rempli
                                        ? Container(
                                            height: 14,
                                            width: 14,
                                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                          )
                                        : null,
                                  );
                                }),
                              );
                            },
                          ),
                          // Champ réel, invisible, superposé, qui capte le vrai clavier
                          Opacity(
                            opacity: 0,
                            child: SizedBox(
                              width: 260,
                              child: TextField(
                                controller: _codeController,
                                focusNode: _focusNode,
                                autofocus: true,
                                keyboardType: TextInputType.number,
                                maxLength: 4,
                                showCursor: false,
                                decoration: const InputDecoration(counterText: '', border: InputBorder.none),
                                onChanged: (v) {
                                  setState(() => _error = null);
                                  if (v.length == 4 && !_loading) _submit();
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],

                  const SizedBox(height: 28),
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _loading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: _loading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.login_rounded),
                      label: Text(_loading ? 'Vérification...' : 'Entrer', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
