import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final TextInputType? keyboardType;
  final bool isRequired;
  final int? maxLength;

  // 🌟 NEW: Properties for height and word counting
  final int? maxLines;
  final int? minLines;

  final Widget? prefixIcon;
  final ValueChanged<String>? onChanged;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.keyboardType,
    this.isRequired = true,
    this.maxLength,
    this.maxLines = 1, // Defaults to 1 for standard fields (Name, Email)
    this.minLines,
    this.prefixIcon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,

      // 🌟 1. Flutter natively handles the character limit and counter UI!
      maxLength: maxLength,
      maxLines: maxLines,
      minLines: minLines,
      onChanged: onChanged,
      textAlignVertical: TextAlignVertical.top,

      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        prefixIcon: prefixIcon,
        hintText: hintText,
        label: RichText(
          text: TextSpan(
            text: labelText,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
      ),
    );
  }
}
