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
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Row(
        children: [

          // 🔥 SIDEBAR
          Container(
            width: 250,
            color: const Color(0xFF1E1E2C),
            child: Column(
              children: [

                // 👤 Admin Info
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.green,
                        child: Icon(Icons.admin_panel_settings,
                            color: Colors.white, size: 30),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        user?.email ?? "Admin",
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const Divider(color: Colors.white24),

                // 📌 Menu Items
                sidebarItem(Icons.dashboard, "Dashboard", 0),
                sidebarItem(Icons.people, "Users", 1),
                sidebarItem(Icons.confirmation_number, "Tickets", 2),

                const Spacer(),

                // 🚪 Logout
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text("Logout",
                      style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushReplacementNamed(context, '/');
                  },
                ),

                const SizedBox(height: 20)
              ],
            ),
          ),

          // 🔥 MAIN CONTENT
          Expanded(
            child: Container(
              color: Colors.grey.shade100,
              child: pages[selectedIndex],
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Sidebar Item Widget
  Widget sidebarItem(IconData icon, String title, int index) {
    final isSelected = selectedIndex == index;

    return ListTile(
      leading: Icon(icon,
          color: isSelected ? Colors.green : Colors.white70),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.green : Colors.white70,
        ),
      ),
      selected: isSelected,
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
    );
  }
}