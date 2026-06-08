import 'package:cloud_firestore/cloud_firestore.dart';

class DirectorIaService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- L'IA ANALYSE LES DONNÉES DE LA BOUTIQUE POUR LE DIRECTEUR ---
  Future<String> repondreAuDirecteur(String question) async {
    String q = question.toLowerCase();

    try {
      // 1. Récupération de toutes les commandes pour les calculs
      QuerySnapshot cmdSnapshot = await _db.collection('commandes').get();
      List<DocumentSnapshot> docs = cmdSnapshot.docs;

      int chiffreAffaires = 0;
      int commandesAttente = 0;
      int commandesLivrees = 0;

      for (var doc in docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        int total = data['total'] ?? 0;
        String statut = data['statut'] ?? '';

        // Cumul du chiffre d'affaires (uniquement les commandes validées/livrées)
        if (statut != "Rejeté / Fraude suspectée" && statut != "En attente de validation") {
          chiffreAffaires += total;
        }

        if (statut == "En attente de validation") {
          commandesAttente++;
        } else if (statut == "Livré") {
          commandesLivrees++;
        }
      }

      // 2. Logique de réponse de l'IA selon ta question
      if (q.contains("gagné") || q.contains("chiffre d'affaires") || q.contains("argent") || q.contains("ca")) {
        return "Chef, d'après les calculs en temps réel de Firestore, le chiffre d'affaires actuel (commandes validées et en cours) est de **$chiffreAffaires MRU**. 💰";
      } 
      
      else if (q.contains("attente") || q.contains("valider") || q.contains("caisse")) {
        if (commandesAttente > 0) {
          return "Oui Directeur, il y a actuellement **$commandesAttente commande(s) en attente** de validation à la caisse. On devrait presser le caissier ! ⏳";
        } else {
          return "Tout est calme Directeur, aucune commande n'est en attente à la caisse pour le moment. 👌";
        }
      } 
      
      else if (q.contains("statut") || q.contains("résumé") || q.contains("rapport")) {
        return "Voici le rapport flash de l'empire Shokugeki, Chef :\n\n"
               "• Chiffre d'affaires : **$chiffreAffaires MRU**\n"
               "• Commandes en attente : **$commandesAttente**\n"
               "• Total commandes enregistrées : **${docs.length}**\n\n"
               "Tout tourne correctement à Nouakchott ! 🚀";
      }

      // Réponse par défaut si la question est générale
      return "Je suis à vos ordres, Directeur. Je peux vous donner le chiffre d'affaires, le statut des caisses ou le résumé global des commandes. Que voulez-vous savoir ? 🍳";

    } catch (e) {
      return "Désolé Chef, j'ai eu un problème pour lire la base de données : ${e.toString()}";
    }
  }
}