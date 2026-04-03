import 'package:flutter/material.dart';

class CertificateViewer extends StatelessWidget {
  final String userName;
  final String tier;
  final int points;

  const CertificateViewer({
    super.key,
    required this.userName,
    required this.tier,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    final Color tierColor = tier == "Platinum"
        ? Colors.cyan
        : tier == "Gold"
            ? Colors.amber
            : Colors.blueGrey;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Certificate", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: AspectRatio(
            aspectRatio: 0.75, // Fancy portrait certificate ratio
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: tierColor, width: 10),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 20, offset: const Offset(0, 10))
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.workspace_premium, size: 80, color: tierColor),
                  const SizedBox(height: 20),
                  Text(
                    "CERTIFICATE OF APPRECIATION",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Colors.indigo.shade900,
                    ),
                  ),
                  const Divider(height: 40, thickness: 1, indent: 40, endIndent: 40),
                  const Text("THIS IS PROUDLY PRESENTED TO"),
                  const SizedBox(height: 15),
                  Text(
                    userName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      decoration: TextDecoration.underline,
                      color: Colors.indigo.shade800,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "For contributing effectively towards waste management and environmental sustainability through our Garbage Classification System.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade800, height: 1.5),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: tierColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      "$tier Level Achieved",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: tierColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text("Total Contribution Points: $points",
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          Text("GCS Admin", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text("Verified Digital Signature", style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                      Icon(Icons.qr_code, size: 40, color: Colors.black54),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Certificate image saved to gallery (Simulated)")),
          );
        },
        label: const Text("Download"),
        icon: const Icon(Icons.download),
        backgroundColor: tierColor,
      ),
    );
  }
}
