import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  bool _initialized = false;
  String? _watchedUid;

  Future<void> init() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/launcher_icon');
    await _local.initialize(settings: const InitializationSettings(android: android));

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
        await FirebaseFirestore.instance.collection('utilisateurs').doc(uid).set(
          {'fcm_token': token, 'derniere_connexion': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        );
      }
    } catch (_) {}
  }

  void demarrerSuiviCommandes() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid == _watchedUid) return;
    _watchedUid = uid;

    FirebaseFirestore.instance
        .collection('commandes')
        .where('client_uid', isEqualTo: uid)
        .snapshots()
        .listen(_traiterChangements);
  }

  void arreterSuivi() {
    _watchedUid = null;
  }

  Future<void> _traiterChangements(QuerySnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();

    for (final doc in snapshot.docChanges) {
      if (doc.type == DocumentChangeType.added || doc.type == DocumentChangeType.modified) {
        final data = doc.doc.data() as Map<String, dynamic>? ?? {};
        final statut = data['statut'] ?? '';
        final cmdId = doc.doc.id.substring(0, 5).toUpperCase();
        final cle = 'statut_${doc.doc.id}';
        final ancien = prefs.getString(cle);

        if (ancien == statut) continue;
        await prefs.setString(cle, statut);

        if (doc.type == DocumentChangeType.added && statut == 'En attente de validation') {
          await _afficher(
            id: doc.doc.id.hashCode,
            titre: "Commande envoyée ✅",
            corps: "Commande #$cmdId reçue. En attente de validation.",
          );
          continue;
        }

        if (doc.type == DocumentChangeType.modified) {
          final message = _messagePourStatut(statut, cmdId);
          if (message != null) {
            await _afficher(id: doc.doc.id.hashCode, titre: message.titre, corps: message.corps);
          }
        }
      }
    }
  }

  ({String titre, String corps})? _messagePourStatut(String statut, String cmdId) {
    switch (statut) {
      case 'En cuisine':
        return (titre: "En cuisine 🍳", corps: "Commande #$cmdId est en préparation !");
      case 'En cours de livraison':
        return (titre: "En route 🛵", corps: "Commande #$cmdId est en cours de livraison !");
      case 'Livré':
        return (titre: "Livré 🎉", corps: "Commande #$cmdId a été livrée. Bon appétit !");
      case 'Rejeté / Fraude suspectée':
        return (titre: "Commande rejetée ❌", corps: "Commande #$cmdId : problème de paiement.");
      default:
        return null;
    }
  }

  Future<void> _afficher({required int id, required String titre, required String corps}) async {
    const details = AndroidNotificationDetails(
      'commandes_channel',
      'Suivi des commandes',
      channelDescription: 'Notifications de statut de commande',
      importance: Importance.high,
      priority: Priority.high,
    );
    await _local.show(
      id: id,
      title: titre,
      body: corps,
      notificationDetails: const NotificationDetails(android: details),
    );
  }
}
