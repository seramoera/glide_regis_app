import 'package:flutter/material.dart';

class LabeledField extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final bool obscure;
  const LabeledField({
    super.key,
    required this.icon,
    required this.label,
    required this.controller,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(prefixIcon: Icon(icon), labelText: label),
    );
  }
}
