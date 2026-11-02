import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:org_registration_app/services/auth_service.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false;

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      //  Replace with your AuthService sign up logic
      await AuthService().signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context); // go back to login after sign up
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sign up failed: ${e.toString()}")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
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
                    //  Logo
                    SvgPicture.asset(
                      "lib/assets/images/glide_logo.svg",
                      height: 200,
                      width: 620,
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

                    //  Frosted Glass Sign Up Box
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
                                  "CREATE AN ACCOUNT",
                                  style: TextStyle(
                                    fontFamily: 'Afacad',
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Email
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
                                  validator: (value) =>
                                      value == null || value.isEmpty ? "Enter email" : null,
                                ),
                                const SizedBox(height: 16),

                                // Password
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
                                const SizedBox(height: 16),

                                //  Confirm Password
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: true,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontFamily: 'Afacad',
                                  ),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    hintText: "Confirm Password",
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
                                  validator: (value) {
                                    if (value == null || value.isEmpty)
                                      return "Confirm password";
                                    if (value != _passwordController.text)
                                      return "Passwords don’t match";
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Sign Up Button
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
                                          onPressed: _signup,
                                          child: const Text(
                                            "SIGN UP",
                                            style: TextStyle(
                                              fontFamily: 'Afacad',
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                const SizedBox(height: 16),

                                //  Go back to login
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: const Text(
                                    "Already have an account? Login",
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
