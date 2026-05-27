import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '_animated_pressable.dart';

class GameTab {
  final String label;
  final String? badge;
  final IconData? icon;

  const GameTab({
    required this.label,
    this.badge,
    this.icon,
  });
}

class GameTabs extends StatelessWidget {
  final List<GameTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool isScrollable;

  const GameTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
    this.isScrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    final list = List.generate(tabs.length, (index) {
      final tab = tabs[index];
      final isSelected = index == selectedIndex;

      final tabContent = Padding(
        padding: const EdgeInsets.symmetric(vertical: DSSpace.sm, horizontal: DSSpace.md),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (tab.icon != null) ...[
              Icon(
                tab.icon,
                size: 16,
                color: isSelected ? DSColors.accent : DSColors.textSecondary,
              ),
              const SizedBox(width: DSSpace.xs),
            ],
            Text(
              tab.label,
              style: DSText.button(context).copyWith(
                color: isSelected ? DSColors.accent : DSColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (tab.badge != null) ...[
              const SizedBox(width: DSSpace.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? DSColors.accent : DSColors.surface4,
                  borderRadius: BorderRadius.circular(DSRadius.pill),
                ),
                child: Text(
                  tab.badge!,
                  style: DSText.numeric(context).copyWith(
                    fontSize: 10,
                    color: isSelected ? DSColors.textOnAccent : DSColors.textPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      );

      return AnimatedPressable(
        onTap: () => onChanged(index),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? DSColors.accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: tabContent,
        ),
      );
    });

    final container = Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: DSColors.borderSubtle,
            width: 1,
          ),
        ),
      ),
      child: isScrollable
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: list),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: list.map((w) => Expanded(child: Center(child: w))).toList(),
            ),
    );

    return container;
  }
}
