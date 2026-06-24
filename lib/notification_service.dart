import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'app_config.dart';

// ═══════════════════════════════════════════════════════
//  NOTIFICATION SERVICE — Multi-tenant v2
//  ✅ Écoute les commandes du bon restaurant
//  ✅ Statuts corrigés (minuscules + underscores)
//  ✅ FCM token sauvegardé dans utilisateurs/ (global)
// ═══════════════════════════════════════════════════════

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  bool _initialized = false;
  String? _watchedUid;
  Stream<QuerySnapshot>? _commandeStream;

  Future<void> init() async {
    if (_initialized) return;

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _local.initialize(settings: initSettings);
    await _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _fcm.requestPermission();
    _initialized = true;
  }

  Future<void> sauvegarderTokenUtilisateur() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        // Token global — pas par restaurant
        await FirebaseFirestore.instance
            .collection(AppConfig.utilisateurs)
            .doc(uid)
            .set({'fcm_token': token, 'updated_at': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Erreur token FCM : $e');
    }
  }

  void demarrerSuiviCommandes() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _watchedUid = uid;

    // ✅ Multi-tenant : écoute les commandes du bon restaurant
    _commandeStream = FirebaseFirestore.instance
        .collection(AppConfig.commandes)
        .where('clientId', isEqualTo: uid)
        .snapshots();

    _commandeStream?.listen((snap) {
      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final data = change.doc.data() as Map<String, dynamic>? ?? {};
          final statut = data['statut']?.toString() ?? '';
          final cmdId = change.doc.id.substring(0, 6).toUpperCase();
          final notif = _buildNotif(statut, cmdId);
          if (notif != null) _afficherNotifLocale(notif.titre, notif.corps);
        }
      }
    });
  }

  void arreterSuivi() {
    _watchedUid = null;
    _commandeStream = null;
  }

  // ✅ Statuts corrigés — correspondent exactement à Firestore
  ({String titre, String corps})? _buildNotif(String statut, String cmdId) {
    switch (statut) {
      case 'en_attente':
        return (titre: '📋 Commande reçue', corps: 'Commande #$cmdId confirmée, validation en cours.');
      case 'en_cuisine':
        return (titre: '🍳 En préparation !', corps: 'Commande #$cmdId est en cours de préparation.');
      case 'pret':
      case 'pret_pour_livraison':
        return (titre: '✅ Prête !', corps: 'Commande #$cmdId est prête, livraison imminente.');
      case 'en_livraison':
      case 'en_cours_de_livraison':
        return (titre: '🛵 En route !', corps: 'Commande #$cmdId est en chemin vers vous !');
      case 'livree':
      case 'livre':
        return (titre: '🎉 Livrée !', corps: 'Commande #$cmdId livrée. Bon appétit !');
      case 'rejete':
        return (titre: '❌ Commande rejetée', corps: 'Commande #$cmdId a été rejetée. Contactez le restaurant.');
      default:
        return null;
    }
  }

  Future<void> _afficherNotifLocale(String titre, String corps) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'commandes_channel',
        'Suivi commandes',
        channelDescription: 'Notifications de suivi de vos commandes',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );
    await _local.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: titre,
      body: corps,
      notificationDetails: details,
    );
  }
}
