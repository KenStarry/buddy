import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../utils/extensions/context_extensions.dart';
import '../budgy_icons.dart';
import 'budgy_button.dart';

/// "Nothing here yet" — warm, specific, and with a way out.
///
/// The copy rules apply hardest here: an empty state is where an app either
/// sounds like a person or sounds like a database. [title] says what is
/// missing in the user's words, [message] says why that is fine, and the CTA
/// is the single next thing to do.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.iconKey = 'sparkles',
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final String title;
  final String message;
  final String iconKey;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Inline inside a card, rather than filling a page.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final circle = compact ? 72.0 : 116.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: compact ? 18 : 40,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
                width: circle,
                height: circle,
                decoration: BoxDecoration(
                  color: c.accentSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  BudgyIcons.resolve(iconKey),
                  size: circle * 0.4,
                  color: c.accent,
                ),
              )
              // Floats, so a screen with nothing on it still has something
              // alive on it.
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .moveY(
                begin: 0,
                end: -7,
                duration: 2600.ms,
                curve: Curves.easeInOutSine,
              ),
          SizedBox(height: compact ? 14 : 22),
          Text(
            title,
            textAlign: TextAlign.center,
            style: compact
                ? context.textTheme.titleMedium
                : context.textTheme.titleLarge,
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(color: c.text300),
          ),
          if (onAction != null) ...[
            SizedBox(height: compact ? 16 : 24),
            BudgyFilledButton(
              label: actionLabel ?? 'Get started',
              height: compact ? 46 : 54,
              onTap: () async => onAction!(),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shimmering placeholders, for the frame or two before Hive answers.
class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({
    super.key,
    this.width,
    this.height = 16,
    this.radius = 8,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: c.surface300,
            borderRadius: BorderRadius.circular(radius),
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: 1400.ms,
          color: c.surface200,
        );
  }
}

/// A placeholder shaped like a ledger row, so the list does not jump when the
/// real rows arrive.
class SkeletonRow extends StatelessWidget {
  const SkeletonRow({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      children: [
        const SkeletonBlock(width: 44, height: 44, radius: 15),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonBlock(width: 128, height: 13),
              const SizedBox(height: 7),
              const SkeletonBlock(width: 78, height: 11),
            ],
          ),
        ),
        const SkeletonBlock(width: 62, height: 15),
      ],
    ),
  );
}
