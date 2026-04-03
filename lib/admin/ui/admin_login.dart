import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:garbage_classification/admin/ui/home_page/home_page.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = false;
  bool isPasswordVisible = false;

  Future<void> loginAdmin() async {
    setState(() => isLoading = true);

    // ✅ Validation
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please fill all fields")),
      );
      setState(() => isLoading = false);
      return;
    }

    try {
      await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("✅ Login Successful")));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      String message = "Login Failed";

      if (e.code == 'user-not-found') {
        message = "❌ No admin found with this email";
      } else if (e.code == 'wrong-password') {
        message = "❌ Incorrect password";
      } else if (e.code == 'invalid-email') {
        message = "❌ Invalid email format";
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error: $e")));
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        // 🌈 Gradient Background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: Center(
          child: SingleChildScrollView(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,

              width: 420,
              padding: const EdgeInsets.all(30),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),

              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔥 Icon
                  const Icon(
                    Icons.admin_panel_settings,
                    size: 70,
                    color: Colors.green,
                  ),

                  const SizedBox(height: 10),

                  // 🧾 Title
                  const Text(
                    "Admin Login",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 5),

                  // ✨ Subtitle
                  const Text(
                    "Manage waste system efficiently",
                    style: TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 25),

                  // 📧 Email Field
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: "Email",
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // 🔒 Password Field with toggle
                  TextField(
                    controller: passwordController,
                    obscureText: !isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            isPasswordVisible = !isPasswordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // 🔘 Button with hover effect
                  isLoading
                      ? const CircularProgressIndicator()
                      : MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: ElevatedButton(
                            onPressed: loginAdmin,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              backgroundColor: Colors.green,
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: const Text(
                              "Login",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
