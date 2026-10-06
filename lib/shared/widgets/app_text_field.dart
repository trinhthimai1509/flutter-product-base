import 'package:flutter/material.dart';

/// Standard text input. Thin wrapper over [TextFormField] so all inputs share
/// behavior (labels, password visibility toggle, validation).
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.obscure = false,
    this.enabled = true,
    this.autofillHints,
    this.prefixIcon,
    this.maxLines = 1,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  /// Hides the text and shows a visibility toggle (passwords).
  final bool obscure;
  final bool enabled;
  final Iterable<String>? autofillHints;
  final IconData? prefixIcon;
  final int maxLines;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      obscureText: _hidden,
      enabled: widget.enabled,
      autofillHints: widget.autofillHints,
      maxLines: widget.obscure ? 1 : widget.maxLines,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon == null ? null : Icon(widget.prefixIcon),
        suffixIcon: widget.obscure
            ? IconButton(
                icon: Icon(_hidden ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _hidden = !_hidden),
              )
            : null,
      ),
    );
  }
}
