import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'restaurant_app_config.dart';

class SubscriptionGuard extends StatelessWidget {
  const SubscriptionGuard({
    super.key,
    required this.restaurantId,
    required this.child,
  });

  final String restaurantId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data?.data();
        final config = data == null
            ? RestaurantAppConfig.demo()
            : RestaurantAppConfig.fromFirestore(data, restaurantId: restaurantId);

        if (!config.subscriptionActive) {
          return SubscriptionBlockedScreen(config: config);
        }

        return child;
      },
    );
  }
}

class SubscriptionBlockedScreen extends StatelessWidget {
  const SubscriptionBlockedScreen({
    super.key,
    required this.config,
  });

  final RestaurantAppConfig config;

  @override
  Widget build(BuildContext context) {
    final message = config.subscriptionMessage ??
        'Abonnement inactif. Contactez le support pour reactiver le restaurant.';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_clock,
                    color: config.primaryColor,
                    size: 56,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    config.name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF4B5563),
                        ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.support_agent),
                    label: const Text('Contacter le support'),
                    style: FilledButton.styleFrom(
                      backgroundColor: config.primaryColor,
                      minimumSize: const Size.fromHeight(48),
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
