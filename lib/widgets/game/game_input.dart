import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';

class GameInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;

  const GameInput({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      style: DSText.bodyMedium(context),
      cursorColor: DSColors.accent,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        hintStyle: DSText.bodyMedium(context).copyWith(color: DSColors.textDisabled),
        labelStyle: DSText.label(context).copyWith(color: DSColors.textSecondary),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: DSColors.surface2,
        contentPadding: const EdgeInsets.symmetric(horizontal: DSSpace.md, vertical: DSSpace.sm),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DSRadius.md),
          borderSide: const BorderSide(color: DSColors.borderSubtle, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DSRadius.md),
          borderSide: const BorderSide(color: DSColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DSRadius.md),
          borderSide: const BorderSide(color: DSColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DSRadius.md),
          borderSide: const BorderSide(color: DSColors.error, width: 1.5),
        ),
        errorStyle: DSText.bodySmall(context).copyWith(color: DSColors.error),
      ),
    );
  }
}
