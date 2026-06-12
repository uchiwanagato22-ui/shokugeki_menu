import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  bool _initialized = false;
  String? _watchedUid;

  Future<void> init() async {
    if (_initialized) return;

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/launcher_icon'),
    );

    await _local.initialize(
      settings: initializationSettings,
    );

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
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
            .collection('utilisateurs')
            .doc(uid)
            .update({'fcm_token': token});
      }
    } catch (e) {
      print("Erreur token FCM : $e");
    }
  }

  void demarrerSuiviCommandes() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _watchedUid == uid) return;

    _watchedUid = uid;
    FirebaseFirestore.instance
        .collection('commandes')
        .where('phone',
            isNotEqualTo: '') // Juste pour filtrer un champ existant
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docChanges) {
        if (doc.type == DocumentChangeType.modified) {
          final data = doc.doc.data() as Map<String, dynamic>;
          final statut = data['statut'] ?? '';
          final cmdId = doc.doc.id.substring(0, 5);

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

  ({String titre, String corps})? _messagePourStatut(
      String statut, String cmdId) {
    switch (statut) {
      case 'En cuisine':
        return (
          titre: "En cuisine 🍳",
          corps: "Commande #$cmdId est en préparation !"
        );
      case 'En cours de livraison':
        return (
          titre: "En route 🛵",
          corps: "Commande #$cmdId est en cours de livraison !"
        );
      case 'Livré':
        return (
          titre: "Livré 🎉",
          corps: "Commande #$cmdId a été livrée. Bon appétit !"
        );
      case 'Rejeté / Fraude suspectée':
        return (
          titre: "Commande rejetée ❌",
          corps: "Commande #$cmdId : problème de paiement."
        );
      default:
        return null;
    }
  }

  Future<void> _afficher(
      {required int id, required String titre, required String corps}) async {
    const androidDetails = AndroidNotificationDetails(
      'commandes_channel',
      'Suivi des commandes',
      importance: Importance.max,
      priority: Priority.high,
    );

    // CORRECTION : Utilisation complète des arguments nommés exigés par le package
    await _local.show(
      id: id,
      title: titre,
      body: corps,
      notificationDetails: const NotificationDetails(android: androidDetails),
    );
  }
}
