import 'package:flutter/material.dart';

/// Custom text field for form inputs
class CustomFormField extends StatefulWidget {
  const CustomFormField({
    required this.label,
    required this.controller,
    super.key,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.minLines = 1,
    this.validator,
    this.obscureText = false,
    this.suffixIcon,
    this.errorText,
  });
  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final int maxLines;
  final int minLines;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? errorText;

  @override
  State<CustomFormField> createState() => _CustomFormFieldState();
}

class _CustomFormFieldState extends State<CustomFormField> {
  late FocusNode _focusNode;
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: widget.controller,
            keyboardType: widget.keyboardType,
            maxLines: widget.maxLines,
            minLines: widget.minLines,
            obscureText: widget.obscureText,
            focusNode: _focusNode,
            onChanged: (value) {
              // Auto-validate on change if error was shown
              if (_showError) {
                setState(() {
                  _showError = widget.validator?.call(value) != null;
                });
              }
            },
            validator: widget.validator,
            decoration: InputDecoration(
              hintText: widget.hint,
              suffixIcon: widget.suffixIcon,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Colors.green,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Colors.red,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              errorText: widget.errorText,
            ),
          ),
        ],
      );
}

/// Custom widget for currency input
class PriceField extends StatelessWidget {
  const PriceField({
    required this.label,
    required this.controller,
    super.key,
    this.validator,
    this.errorText,
  });
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String? errorText;

  @override
  Widget build(BuildContext context) => CustomFormField(
        label: label,
        controller: controller,
        hint: '0.00',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: validator,
        errorText: errorText,
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Center(
            child: Text(
              r'$',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ),
      );
}
