import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart'; // Ensure to import your home page file

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isLoginMode = true;
  bool isLoading = false;

  void toggleMode() {
    setState(() {
      isLoginMode = !isLoginMode;
    });
  }

  Future<void> registerUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (password != confirmPassword) {
      _showError("Passwords do not match");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      _showMessage("Registration successful!");
      toggleMode(); // Toggle to login mode after successful registration
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> loginUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    setState(() {
      isLoading = true;
    });

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      _showMessage("Login successful!");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                HomePage()), // Navigate to HomePage on success
      );
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error, style: const TextStyle(color: Colors.red))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue.shade50,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Text(
                  isLoginMode
                      ? "Welcome back! Glad to see you, Again!"
                      : "Hello! Register to get started",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                _buildTextField(emailController, "Enter your email", false),
                const SizedBox(height: 16),
                _buildTextField(
                    passwordController, "Enter your password", true),
                if (!isLoginMode) ...[
                  const SizedBox(height: 16),
                  _buildTextField(
                      confirmPasswordController, "Confirm password", true),
                ],
                const SizedBox(height: 24),
                isLoading
                    ? CircularProgressIndicator() // Show loading indicator during registration/login
                    : _buildAuthButton(),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: toggleMode,
                  child: Text(
                    isLoginMode
                        ? "Don't have an account? Register Now"
                        : "Already have an account? Log in Now",
                    style: const TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String hint, bool obscureText) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            offset: const Offset(0, 2),
            blurRadius: 5.0,
          ),
        ],
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(12),
        ),
        obscureText: obscureText,
      ),
    );
  }

  Widget _buildAuthButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200,
            offset: const Offset(0, 3),
            blurRadius: 6.0,
          ),
        ],
        borderRadius: BorderRadius.circular(8),
      ),
      child: ElevatedButton(
        onPressed: () {
          if (isLoginMode) {
            loginUser();
          } else {
            registerUser();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          isLoginMode ? "Login" : "Register",
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
