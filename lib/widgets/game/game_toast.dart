import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';

class GameToast {
  GameToast._();

  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    IconData? icon,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.clearSnackBars();
    
    scaffoldMessenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.all(DSSpace.md),
        padding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: DSSpace.md, vertical: DSSpace.sm),
          decoration: BoxDecoration(
            color: isError 
                ? const Color(0xEB2C1B1B) // Dark red-translucent
                : const Color(0xEB10171E), // Dark surface-translucent
            borderRadius: BorderRadius.circular(DSRadius.md),
            border: Border.all(
              color: isError ? DSColors.error : DSColors.borderEmphasis,
              width: 1.5,
            ),
            boxShadow: DSShadow.lg,
          ),
          child: Row(
            children: [
              Icon(
                icon ?? (isError ? Icons.error_outline : Icons.info_outline),
                color: isError ? DSColors.error : DSColors.accent,
                size: 20,
              ),
              const SizedBox(width: DSSpace.sm),
              Expanded(
                child: Text(
                  message,
                  style: DSText.bodyMedium(context).copyWith(
                    color: DSColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
