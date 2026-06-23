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
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
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
            .set(
          {
            'fcm_token': token,
          },
          SetOptions(merge: true),
        );
      }

    } catch (e) {
      debugPrint("Erreur token FCM : $e");
    }
  }


  void demarrerSuiviCommandes() {

    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null || _watchedUid == uid) return;

    _watchedUid = uid;


    FirebaseFirestore.instance
        .collection('commandes')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {


      for (var doc in snapshot.docChanges) {


        if (doc.type == DocumentChangeType.modified) {


          final data = doc.doc.data() as Map<String, dynamic>;

          final statut = data['statut'] ?? '';


          final cmdId =
              doc.doc.id.length > 5
                  ? doc.doc.id.substring(0, 5)
                  : doc.doc.id;


          final message =
              _messagePourStatut(statut, cmdId);


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
      String statut,
      String cmdId,
      ) {

    // ✅ FIX CRITIQUE : statuts corrigés pour correspondre à ce que Firestore contient
    // Caissier envoie 'en_cuisine', livreur envoie 'livree', etc.
    switch (statut) {
      case 'en_attente':
        return (
          titre: "Commande reçue 📋",
          corps: "Commande #\$cmdId confirmée, en attente de validation."
        );
      case 'en_cuisine':
        return (
          titre: "En cuisine 🍳",
          corps: "Commande #\$cmdId est en préparation !"
        );
      case 'pret':
      case 'pret_pour_livraison':
        return (
          titre: "Prête ! 🛵",
          corps: "Commande #\$cmdId est prête, le livreur arrive bientôt."
        );
      case 'en_livraison':
      case 'en_cours_de_livraison':
        return (
          titre: "En route 🛵",
          corps: "Commande #\$cmdId est en cours de livraison !"
        );
      case 'livree':
      case 'livre':
        return (
          titre: "Livrée 🎉",
          corps: "Commande #\$cmdId a été livrée. Bon appétit !"
        );
      case 'rejete':
        return (
          titre: "Commande rejetée ❌",
          corps: "Commande #\$cmdId a été rejetée. Contactez le restaurant."
        );
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

      channelDescription:
      'Notifications de statut des commandes Shokugeki',

      importance: Importance.max,

      priority: Priority.high,

      ticker: 'ticker',

    );


    const notificationDetails =
        NotificationDetails(android: androidDetails);



    await _local.show(

      id: id,

      title: titre,

      body: corps,

      notificationDetails: notificationDetails,

    );

  }

}