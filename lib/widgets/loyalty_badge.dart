import 'package:flutter/material.dart';
import '../constants.dart';
import '../loyalty_service.dart';

/// Badge animé affichant le solde de points fidélité du client,
/// avec une petite pop-animation à chaque changement de valeur.
class LoyaltyBadge extends StatefulWidget {
  final String uid;
  final VoidCallback? onTap;

  const LoyaltyBadge({super.key, required this.uid, this.onTap});

  @override
  State<LoyaltyBadge> createState() => _LoyaltyBadgeState();
}

class _LoyaltyBadgeState extends State<LoyaltyBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _popCtrl;
  late final Animation<double> _pop;
  int _dernierSolde = -1;

  @override
  void initState() {
    super.initState();
    _popCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _pop = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _popCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _popCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.uid.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<int>(
      stream: LoyaltyService.instance.pointsStream(widget.uid),
      builder: (context, snapshot) {
        final solde = snapshot.data ?? 0;
        if (_dernierSolde != -1 && solde != _dernierSolde) {
          _popCtrl.forward(from: 0);
        }
        _dernierSolde = solde;

        return GestureDetector(
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: _pop,
            builder: (context, child) => Transform.scale(scale: _pop.value, child: child),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kAccentColor.withOpacity(0.25), kAccentColor.withOpacity(0.08)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kAccentColor.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events_rounded, color: kAccentColor, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '$solde pts',
                    style: const TextStyle(
                      color: kAccentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
