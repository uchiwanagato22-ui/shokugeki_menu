import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'app_config.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  bool _initialized = false;
  String? _watchedUid;

  Future<void> init() async {
    if (_initialized) return;

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    // ✅ FIX: named parameter "settings:" comme dans la version originale
    await _local.initialize(
      settings: initializationSettings,
    );

    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
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
    if (uid == null || _watchedUid == uid) return;
    _watchedUid = uid;

    // ✅ Multi-tenant : écoute les commandes du bon restaurant
    FirebaseFirestore.instance
        .collection(AppConfig.commandes)
        .where('clientId', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
      for (final doc in snapshot.docChanges) {
        if (doc.type == DocumentChangeType.modified) {
          final data = doc.doc.data() as Map<String, dynamic>? ?? {};
          final statut = data['statut']?.toString() ?? '';
          final cmdId = doc.doc.id.length > 6
              ? doc.doc.id.substring(0, 6).toUpperCase()
              : doc.doc.id.toUpperCase();
          final message = _messagePourStatut(statut, cmdId);
          if (message != null) {
            _afficher(
              id: doc.doc.id.hashCode,
              titre: message.titre,
              corps: message.corps,
            );
          }
        }
      }
    });
  }

  void arreterSuivi() {
    _watchedUid = null;
  }

  // ✅ Statuts corrigés (minuscules + underscores)
  ({String titre, String corps})? _messagePourStatut(String statut, String cmdId) {
    switch (statut) {
      case 'en_attente':
        return (titre: 'Commande recue', corps: 'Commande #$cmdId confirmee, validation en cours.');
      case 'en_cuisine':
        return (titre: 'En preparation !', corps: 'Commande #$cmdId est en cours de preparation.');
      case 'pret':
      case 'pret_pour_livraison':
        return (titre: 'Prete !', corps: 'Commande #$cmdId prete, livraison imminente.');
      case 'en_livraison':
      case 'en_cours_de_livraison':
        return (titre: 'En route !', corps: 'Commande #$cmdId est en chemin vers vous !');
      case 'livree':
      case 'livre':
        return (titre: 'Livree !', corps: 'Commande #$cmdId livree. Bon appetit !');
      case 'rejete':
        return (titre: 'Commande rejetee', corps: 'Commande #$cmdId a ete rejetee. Contactez le restaurant.');
      default:
        return null;
    }
  }

  Future<void> _afficher({
    required int id,
    required String titre,
    required String corps,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'commandes_channel',
      'Suivi des commandes',
      channelDescription: 'Notifications de statut des commandes Shokugeki',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    // ✅ FIX: named parameters comme dans la version originale
    await _local.show(
      id: id,
      title: titre,
      body: corps,
      notificationDetails: notificationDetails,
    );
  }
}
