import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_user_contributions.dart';

class PublicDetails extends StatefulWidget {
  const PublicDetails({super.key});

  @override
  State<PublicDetails> createState() => _PublicDetailsState();
}

class _PublicDetailsState extends State<PublicDetails> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Registered Users',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('public').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.indigo),
            );
          }

          final users = snapshot.data?.docs ?? [];

          if (users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No users found in Firestore.",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userData = users[index].data() as Map<String, dynamic>;
              final email = userData['email'] ?? 'No Email Provided';
              final role = userData['role'] ?? 'public';
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 1,
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminUserContributions(userEmail: email),
                      ),
                    );
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo.shade100,
                    child: Icon(Icons.person, color: Colors.indigo.shade700),
                  ),
                  title: Text(
                    email,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "UID: ${users[index].id}",
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Chip(
                    backgroundColor: role == 'admin' ? Colors.red.shade100 : Colors.green.shade100,
                    label: Text(
                      role.toString().toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: role == 'admin' ? Colors.red.shade800 : Colors.green.shade800,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}