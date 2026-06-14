import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'constants.dart';

// ==========================================
// 1. ÉCRAN CUISINE (TABLETTE DE PREPARATION)
// ==========================================
class KitchenDashboard extends StatelessWidget {
  const KitchenDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A0F),
      appBar: AppBar(
        title: const Text("ÉCRAN CUISINE - PRÉPARATION", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF14161D),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
            child: const Row(
              children: [
                Icon(Icons.flash_on, color: Colors.amber, size: 16),
                SizedBox(width: 4),
                Text("LIVE", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('commandes')
            .where('statut', isEqualTo: 'en_preparation')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text("Aucun plat à préparer pour le moment. Calme plat !", style: TextStyle(color: Colors.white38, fontSize: 16)),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.3,
            ),
            itemCount: docs.count,
            itemBuilder: (context, index) {
              var commande = docs[index];
              var data = commande.data() as Map<String, dynamic>;
              List plats = data['plats'] ?? [];

              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF14161D),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kPrimaryColor.withOpacity(0.3), width: 1.5),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("COMMANDE #${commande.id.substring(0, 4).toUpperCase()}", style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
                        const Icon(Icons.timer, color: Colors.white54, size: 18),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 20),
                    Expanded(
                      child: ListView.builder(
                        itemCount: plats.length,
                        itemBuilder: (context, pIndex) => Text(
                          "- ${plats[pIndex]}",
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('commandes')
                              .doc(commande.id)
                              .update({'statut': 'pret_pour_livraison'});
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text("Plat Terminé 👍", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ==========================================
// 2. ÉCRAN LIVREUR (SUIVI ET GOOGLE MAPS)
// ==========================================
class LivreurDashboard extends StatelessWidget {
  const LivreurDashboard({super.key});

  Future<void> _ouvrirOutilsMaps(String quartier, String indications) async {
    // Création d'une requête de recherche propre pour Google Maps sur Nouakchott
    final query = Uri.encodeComponent("$quartier, Nouakchott, Mauritanie");
    final googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");
    
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A0F),
      appBar: AppBar(
        title: const Text("ZONE LIVREUR", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF14161D),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('commandes')
            .where('statut', isEqualTo: 'pret_pour_livraison')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text("Aucune course disponible. Attends que la cuisine termine !", style: TextStyle(color: Colors.white38)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var commande = docs[index];
              var data = commande.data() as Map<String, dynamic>;
              String quartier = data['quartier'] ?? "Non spécifié";
              String indications = data['indications_adresse'] ?? "Pas de repères fournis";

              return Container(
                margin: const EdgeInsets.bottom(16),
                decoration: BoxDecoration(color: const Color(0xFF14161D), borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Client: ${data['client_nom'] ?? 'Anonyme'}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text("${data['total'] ?? 0} MRU", style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.redAccent, size: 18),
                        const SizedBox(width: 8),
                        Text("Quartier : $quartier", style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(8)),
                      child: Text("📍 Repères : $indications", style: const TextStyle(color: Colors.amber, fontSize: 13, fontStyle: FontStyle.italic)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _ouvrirOutilsMaps(quartier, indications),
                            icon: const Icon(Icons.map_outlined, color: Colors.cyan),
                            label: const Text("Google Maps", style: TextStyle(color: Colors.cyan)),
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.cyan)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('commandes')
                                  .doc(commande.id)
                                  .update({'statut': 'livre'});
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
                            child: const Text("Livré ✓", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ==========================================
// 3. ÉCRAN CAISSIER (VALIDATION & FINANCES)
// ==========================================
class CaissierDashboard extends StatelessWidget {
  const CaissierDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A0F),
      appBar: AppBar(
        title: const Text("CONSOLE CAISSE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF14161D),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('commandes')
            .where('statut', isEqualTo: 'en_attente')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
          final docs = snapshot.data!.docs;

          return Column(
            children: [
              // Zone résumé des finances simplifiée
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                color: const Color(0xFF14161D),
                child: const Column(
                  children: [
                    Text("FLUX DE TRÉSORERIE DU JOUR", style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1)),
                    SizedBox(height: 8),
                    Text("Système Actif 100 MRU / Livraison", style: TextStyle(color: Colors.green, fontSize: 15, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: docs.isEmpty
                    ? const Center(child: Text("Aucune nouvelle commande en attente.", style: TextStyle(color: Colors.white38)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          var commande = docs[index];
                          var data = commande.data() as Map<String, dynamic>;

                          return Container(
                            margin: const EdgeInsets.bottom(12),
                            decoration: BoxDecoration(color: const Color(0xFF14161D), borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              title: Text("${data['client_nom'] ?? 'Client'} (${data['total'] ?? 0} MRU)", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              subtitle: Text("Quartier : ${data['quartier'] ?? 'ND'}", style: const TextStyle(color: Colors.white54)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check_circle, color: Colors.green),
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection('commandes')
                                          .doc(commande.id)
                                          .update({'statut': 'en_preparation'});
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.cancel, color: Colors.redAccent),
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection('commandes')
                                          .doc(commande.id)
                                          .update({'statut': 'rejete'});
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}