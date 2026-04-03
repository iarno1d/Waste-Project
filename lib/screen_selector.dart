import 'package:flutter/material.dart';
import 'admin/ui/admin_login.dart';
import 'public/ui/public_login.dart';

class ScreenSelector extends StatelessWidget {
  const ScreenSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade700, Colors.teal],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [

              // 🔵 ADMIN BOX
              _box(
                context,
                title: "Admin",
                icon: Icons.admin_panel_settings,
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminLoginPage(),
                    ),
                  );
                },
              ),

              // 🟠 PUBLIC BOX
              _box(
                context,
                title: "Public",
                icon: Icons.people,
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PublicLogin(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔥 REUSABLE BOX WIDGET
  Widget _box(BuildContext context,
      {required String title,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 150,
        width: 130,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 45, color: color),
            SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}