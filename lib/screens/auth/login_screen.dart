import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:org_registration_app/screens/user/user_shell.dart';
import 'package:org_registration_app/services/auth_service.dart';
import 'package:org_registration_app/screens/registration_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:org_registration_app/screens/auth/signup_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginScreen extends StatefulWidget {
  final AuthService auth;
  const LoginScreen({super.key, required this.auth});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final user = await widget.auth.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      setState(() => _loading = false);

      if (user != null && mounted) {
        final doc = await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data()?['hasRegistered'] == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => UserShell(auth: widget.auth)),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => RegistrationScreen()),
          );
        }
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            "lib/assets/images/background_1.png",
            fit: BoxFit.cover,
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo + tagline
                    SvgPicture.asset(
                      "lib/assets/images/glide_logo.svg",
                      height: 220,
                      width: 600,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Glide: Find Your Crew, Faster.',
                      style: TextStyle(
                        fontFamily: 'LeagueSpartan-Regular',
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Frosted Glass Login Box
                    ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                const Text(
                                  "LOGIN",
                                  style: TextStyle(
                                    fontFamily: 'Afacad',
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Email Box
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontFamily: 'Afacad',
                                  ),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    hintText: "Email",
                                    hintStyle: const TextStyle(
                                      color: Colors.black54,
                                      fontFamily: 'Afacad',
                                    ),
                                    suffixIcon: const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: Icon(
                                        Icons.person_outline,
                                        size: 24,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(color: Colors.white),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(color: Colors.blueAccent),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please enter your email";
                                    }
                                    if (!RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$")
                                        .hasMatch(value)) {
                                      return "Enter a valid email";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Password Box
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontFamily: 'Afacad',
                                  ),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    hintText: "Password",
                                    hintStyle: const TextStyle(
                                      color: Colors.black54,
                                      fontFamily: 'Afacad',
                                    ),
                                    suffixIcon: const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: Icon(
                                        Icons.lock_outline,
                                        size: 24,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(color: Colors.white),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(color: Colors.blueAccent),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  validator: (value) =>
                                      value == null || value.isEmpty ? "Enter password" : null,
                                ),
                                const SizedBox(height: 20),

                                _loading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white.withOpacity(0.25),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(30),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                          ),
                                          onPressed: _login,
                                          child: const Text(
                                            "LOGIN",
                                            style: TextStyle(
                                              fontFamily: 'Afacad',
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                const SizedBox(height: 16),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const SignUpScreen()),
                                    );
                                  },
                                  child: const Text(
                                    "Don’t have an account? Sign up",
                                    style: TextStyle(
                                      fontFamily: 'Afacad',
                                      color: Colors.white,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
