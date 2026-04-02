import 'package:flutter/material.dart';
import 'package:garbage_classification/public/services/signin_services.dart';


class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final AuthService _authService = AuthService();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final locationController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  Future<void> handleSignUp() async {
    setState(() => isLoading = true);

    String? result = await _authService.signUpUser(
      name: nameController.text,
      phone: phoneController.text,
      location: locationController.text,
      email: emailController.text,
      password: passwordController.text,
      confirmPassword: confirmPasswordController.text,
    );

    setState(() => isLoading = false);

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Account Created Successfully")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ $result")),
      );
    }
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? toggleVisibility,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? !isVisible : false,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: toggleVisibility,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
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
            colors: [Color(0xFF00c6ff), Color(0xFF0072ff)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 420,
              padding: const EdgeInsets.all(25),

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

                  const Icon(Icons.person_add, size: 70, color: Colors.blue),

                  const SizedBox(height: 10),

                  const Text(
                    "Create Account",
                    style: TextStyle(
                        fontSize: 26, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    "Join Smart Waste Management",
                    style: TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 25),

                  buildTextField(
                    controller: nameController,
                    label: "Full Name",
                    icon: Icons.person,
                  ),

                  buildTextField(
                    controller: phoneController,
                    label: "Phone Number",
                    icon: Icons.phone,
                  ),

                  buildTextField(
                    controller: locationController,
                    label: "Location",
                    icon: Icons.location_on,
                  ),

                  buildTextField(
                    controller: emailController,
                    label: "Email",
                    icon: Icons.email,
                  ),

                  buildTextField(
                    controller: passwordController,
                    label: "Password",
                    icon: Icons.lock,
                    isPassword: true,
                    isVisible: isPasswordVisible,
                    toggleVisibility: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                  ),

                  buildTextField(
                    controller: confirmPasswordController,
                    label: "Confirm Password",
                    icon: Icons.lock_outline,
                    isPassword: true,
                    isVisible: isConfirmPasswordVisible,
                    toggleVisibility: () {
                      setState(() {
                        isConfirmPasswordVisible =
                            !isConfirmPasswordVisible;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  // 🔘 Button
                  isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: handleSignUp,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize:
                                const Size(double.infinity, 50),
                          ),
                          child: const Text(
                            "Create Account",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),

                  const SizedBox(height: 10),

                  // 🔙 Back to login
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Already have an account? Login"),
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