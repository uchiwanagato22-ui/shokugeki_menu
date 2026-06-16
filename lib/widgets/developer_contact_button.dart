import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DeveloperContactButton extends StatelessWidget {
  const DeveloperContactButton({Key? key}) : super(key: key);

  Future<void> _contacterUchiwaNagato() async {
    // Ton numéro mauritanien au format international sans le + pour l'URL
    final String numeroWhatsapp = "22232652300"; 
    final String message = Uri.encodeComponent(
      "Bonjour, j'ai vu votre application Shokugeki Menu et je souhaite commander une application similaire pour mon entreprise !"
    );
    final Uri url = Uri.parse("https://wa.me/$numeroWhatsapp?text=$message");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      print("Impossible d'ouvrir WhatsApp");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: _contacterUchiwaNagato,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.code, size: 16, color: Colors.deepOrange),
            SizedBox(width: 6),
            Text(
              "Propulsé par Shinra.ia - Obtenir votre App",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}