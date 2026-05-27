import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import 'game_button.dart';

class GameSheet extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailingHeader;
  final List<GameButton>? actions;

  const GameSheet({
    super.key,
    required this.title,
    required this.child,
    this.trailingHeader,
    this.actions,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget child,
    Widget? trailingHeader,
    List<GameButton>? actions,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => GameSheet(
        title: title,
        trailingHeader: trailingHeader,
        actions: actions,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 64),
      decoration: const BoxDecoration(
        color: DSColors.surface1,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(DSRadius.xl),
          topRight: Radius.circular(DSRadius.xl),
        ),
        border: Border(
          top: BorderSide(color: DSColors.borderDefault, width: 2),
        ),
      ),
      padding: EdgeInsets.only(
        left: DSSpace.md,
        right: DSSpace.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + DSSpace.xl,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: DSSpace.sm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: DSColors.textDisabled.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(DSRadius.pill),
                ),
              ),
            ),
            // Header Row
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: DSText.headingMedium(context),
                  ),
                ),
                if (trailingHeader != null) trailingHeader!,
                IconButton(
                  icon: const Icon(Icons.close, color: DSColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: DSColors.borderSubtle),
            const SizedBox(height: DSSpace.sm),
            // Main Content
            Flexible(
              child: SingleChildScrollView(
                child: child,
              ),
            ),
            // Actions
            if (actions != null && actions!.isNotEmpty) ...[
              const SizedBox(height: DSSpace.md),
              const Divider(color: DSColors.borderSubtle),
              const SizedBox(height: DSSpace.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions!
                    .map((action) => Padding(
                          padding: const EdgeInsets.only(left: DSSpace.sm),
                          child: action,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
