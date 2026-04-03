import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'certificate_viewer.dart';

class Myprofile extends StatefulWidget {
  const Myprofile({super.key});

  @override
  State<Myprofile> createState() => _MyprofileState();
}

class _MyprofileState extends State<Myprofile> {
  final user = FirebaseAuth.instance.currentUser;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final locationController = TextEditingController();
  final emailController = TextEditingController();

  bool isLoading = true;
  bool isEditing = false;
  int userPoints = 0;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final doc = await FirebaseFirestore.instance
        .collection("public")
        .doc(user!.uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      nameController.text = data['name'] ?? "";
      phoneController.text = data['phone'] ?? "";
      locationController.text = data['location'] ?? "";
      emailController.text = data['email'] ?? "";
      userPoints = data['points'] ?? 0;
    }

    setState(() => isLoading = false);
  }

  String getCertificateLevel() {
    if (userPoints >= 3000) return "Platinum";
    if (userPoints >= 2000) return "Gold";
    if (userPoints >= 1000) return "Silver";
    return "Bronze (Novice)";
  }

  Color getCertificateColor() {
    if (userPoints >= 3000) return Colors.cyan; // Platinum
    if (userPoints >= 2000) return Colors.amber; // Gold
    if (userPoints >= 1000) return Colors.blueGrey; // Silver
    return Colors.brown.shade400; // Bronze
  }

  Future<void> updateUserData() async {
    await FirebaseFirestore.instance
        .collection("public")
        .doc(user!.uid)
        .update({
      "name": nameController.text.trim(),
      "phone": phoneController.text.trim(),
      "location": locationController.text.trim(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Profile Updated")),
    );

    setState(() => isEditing = false);
  }

  Widget buildField(String label, IconData icon,
      TextEditingController controller, bool enabled) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      body: Stack(
        children: [

          // 🌈 TOP HEADER
          Container(
            height: 220,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 👤 PROFILE CONTENT
          SingleChildScrollView(
            child: Column(
              children: [

                const SizedBox(height: 100),

                // Profile Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),

                  child: Column(
                    children: [

                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.green,
                        child: Icon(Icons.person,
                            size: 50, color: Colors.white),
                      ),

                      const SizedBox(height: 15),

                      Text(
                        nameController.text,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        emailController.text,
                        style: const TextStyle(color: Colors.grey),
                      ),

                      const SizedBox(height: 20),

                      // 🏆 Gamification Banner
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: getCertificateColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: getCertificateColor().withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.workspace_premium, size: 36, color: getCertificateColor()),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${getCertificateLevel()} Certificate",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: getCertificateColor(),
                                    ),
                                  ),
                                  Text(
                                    "Total Points: $userPoints",
                                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            if (userPoints >= 1000)
                              IconButton(
                                icon: const Icon(Icons.download, color: Colors.blue),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CertificateViewer(
                                        userName: nameController.text,
                                        tier: getCertificateLevel(),
                                        points: userPoints,
                                      ),
                                    ),
                                  );
                                },
                              )
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      buildField("Name", Icons.person, nameController, isEditing),
                      buildField("Phone", Icons.phone, phoneController, isEditing),
                      buildField("Location", Icons.location_on, locationController, isEditing),

                      buildField("Email", Icons.email, emailController, false),

                      const SizedBox(height: 10),
                    ],
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),

          // ✏️ EDIT BUTTON
          Positioned(
            top: 50,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: () {
                setState(() {
                  isEditing = !isEditing;
                });
              },
              child: Icon(
                isEditing ? Icons.close : Icons.edit,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),

      // 💾 SAVE BUTTON
      floatingActionButton: isEditing
          ? FloatingActionButton.extended(
              onPressed: updateUserData,
              backgroundColor: Colors.green,
              icon: const Icon(Icons.save),
              label: const Text("Save"),
            )
          : null,

      // 🔴 LOGOUT BUTTON
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(15),
        child: ElevatedButton(
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: const Text("Logout"),
        ),
      ),
    );
  }
}