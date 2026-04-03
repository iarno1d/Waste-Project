import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:garbage_classification/admin/ui/dashboard/dashboard.dart';
import 'package:garbage_classification/admin/ui/public/public.dart';
import 'package:garbage_classification/admin/ui/tickets/tickets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  int selectedIndex = 0;

  final List<Widget> pages = [
    const AdminDashboard(),
    const PublicDetails(),
    const TicketsRaised(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Admin Panel", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          )
        ],
      ),
      body: pages[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        backgroundColor: Colors.white,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: "Users",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number),
            label: "Tickets",
          ),
        ],
      ),
    );
  }
}