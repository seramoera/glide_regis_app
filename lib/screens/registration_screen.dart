import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:org_registration_app/screens/user/user_shell.dart';
import 'package:org_registration_app/services/auth_service.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _barangayController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  String? _selectedDay;
  String? _selectedMonth;
  String? _selectedYear;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();

  /// Divider Color
  final Color dividerColor = Colors.white.withOpacity(0.5);

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDay == null ||
        _selectedMonth == null ||
        _selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete your Date of Birth")),
      );
      return;
    }

    final user = _auth.currentUser;
    if (user == null) return;

    final regData = {
      "firstName": _firstNameController.text,
      "lastName": _lastNameController.text,
      "dob":
          "${_selectedDay ?? ""}-${_selectedMonth ?? ""}-${_selectedYear ?? ""}",
      "email": _emailController.text,
      "contact": _contactController.text,
      "street": _streetController.text,
      "barangay": _barangayController.text,
      "city": _cityController.text,
      "hasRegistered": true,
      "updatedAt": DateTime.now().toIso8601String(),
    };

    try {
      await _authService.saveUserRegistration(user.uid, regData);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => UserShell(auth: _authService),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving registration: $e")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyRegistered();
  }

  Future<void> _checkIfAlreadyRegistered() async {
    final user = _auth.currentUser;
    if (user != null) {
      final alreadyRegistered =
          await _authService.hasUserRegistration(user.uid);
      if (alreadyRegistered) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => UserShell(auth: _authService),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              "lib/assets/images/background_1.png",
              fit: BoxFit.cover,
            ),
          ),

          // Dark overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.4),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Title
                  Column(
                    children: [
                      Image.asset(
                        "lib/assets/images/glide_logo.png",
                        height: 100,
                        width: 170,
                        fit: BoxFit.fill,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "REGISTRATION",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                          fontFamily: 'Afacad',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Glass Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Column(
                                    children: [
                                      Text(
                                        "USER INFORMATION",
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontFamily: 'Afacad',
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Divider(
                                        color: dividerColor,
                                        thickness: 2,
                                        indent: 40,
                                        endIndent: 40,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // First & Last Name
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        controller: _firstNameController,
                                        label: "First Name",
                                        validator: (value) {
                                          if (value == null || value.isEmpty)
                                            return "Please enter First Name";
                                          if (!RegExp(r'^[a-zA-Z\s]+$')
                                              .hasMatch(value)) {
                                            return "Only letters allowed";
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _buildTextField(
                                        controller: _lastNameController,
                                        label: "Last Name",
                                        validator: (value) {
                                          if (value == null || value.isEmpty)
                                            return "Please enter Last Name";
                                          if (!RegExp(r'^[a-zA-Z\s]+$')
                                              .hasMatch(value)) {
                                            return "Only letters allowed";
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // DOB
                                Text(
                                  "Date of Birth:",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontFamily: 'Afacad',
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildDropdown(
                                        value: _selectedDay,
                                        hint: "Day",
                                        items: List.generate(
                                            31, (index) => "${index + 1}"),
                                        onChanged: (val) =>
                                            setState(() => _selectedDay = val),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _buildDropdown(
                                        value: _selectedMonth,
                                        hint: "Month",
                                        items: const [
                                          "Jan",
                                          "Feb",
                                          "Mar",
                                          "Apr",
                                          "May",
                                          "Jun",
                                          "Jul",
                                          "Aug",
                                          "Sep",
                                          "Oct",
                                          "Nov",
                                          "Dec"
                                        ],
                                        onChanged: (val) => setState(
                                            () => _selectedMonth = val),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _buildDropdown(
                                        value: _selectedYear,
                                        hint: "Year",
                                        items: List.generate(
                                            100, (index) => "${2025 - index}"),
                                        onChanged: (val) =>
                                            setState(() => _selectedYear = val),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Email
                                _buildTextField(
                                  controller: _emailController,
                                  label: "Your Email Address",
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty)
                                      return "Please enter your email";
                                    if (!RegExp(
                                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                        .hasMatch(value)) {
                                      return "Enter a valid email (e.g. example@gmail.com)";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),

                                // Contact
                                _buildTextField(
                                  controller: _contactController,
                                  label: "Your Contact Number",
                                  keyboardType: TextInputType.phone,
                                  validator: (value) {
                                    if (value == null || value.isEmpty)
                                      return "Please enter contact number";
                                    if (!RegExp(r'^[0-9]{11}$')
                                        .hasMatch(value)) {
                                      return "Contact number must be 11 digits";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),

                                _buildTextField(
                                    controller: _streetController,
                                    label: "Street Address"),
                                const SizedBox(height: 12),
                                _buildTextField(
                                    controller: _barangayController,
                                    label: "Barangay"),
                                const SizedBox(height: 12),
                                _buildTextField(
                                    controller: _cityController, label: "City"),
                                const SizedBox(height: 16),

                                // Full-width Submit Button
                                Center(
                                  child: SizedBox(
                                    width: double.infinity, // full width
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFf1C1C1C)
                                            .withOpacity(0.1),
                                        foregroundColor: Colors.white,
                                        side: const BorderSide(
                                            color: Colors.white),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 13),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      onPressed: _submitForm,
                                      child: const Text(
                                        "SUBMIT",
                                        style: TextStyle(
                                          fontSize: 16,
                                          letterSpacing: 1.5,
                                          fontFamily: 'Afacad',
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // TextField with Afacad font and white 24% opacity
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(
        color: Colors.white,
        fontFamily: 'Afacad',
      ),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: label,
        hintStyle: const TextStyle(
          color: Colors.white54,
          fontFamily: 'Afacad',
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.24),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white30),
        ),
      ),
      validator: validator ??
          (value) =>
              (value == null || value.isEmpty) ? "Please enter $label" : null,
    );
  }

  // Dropdown with Afacad font and white 24% opacity
  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: Colors.black87,
      style: const TextStyle(
        color: Colors.white,
        fontFamily: 'Afacad',
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.24),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white30),
        ),
      ),
      hint: Text(hint,
          style: const TextStyle(color: Colors.white54, fontFamily: 'Afacad')),
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item,
                    style: const TextStyle(
                        color: Colors.white, fontFamily: 'Afacad')),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}
