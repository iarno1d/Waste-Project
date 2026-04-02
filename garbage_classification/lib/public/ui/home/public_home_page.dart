import 'package:flutter/material.dart';
import 'package:garbage_classification/public/ui/myContributions/myContributions.dart';
import 'package:garbage_classification/public/ui/myProfile/myProfile.dart';
import 'package:garbage_classification/public/ui/raiseTickets/raiseTicket.dart';


class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    Myprofile(),
    Report(),
    Mycontributions(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },

        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: "Report Waste", // better name 🔥
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: "My Contribution",
          ),
        ],
      ),
    );
  }
}