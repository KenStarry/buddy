import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../theme/budgy_shadows.dart';
import '../../../utils/budgy_constants.dart';
import '../../../utils/extensions/context_extensions.dart';
import '../../budgy_icons.dart';
import '../budgy_button.dart';
import '../press_scale.dart';

/// One step of a journey.
@immutable
class JourneyStep {
  const JourneyStep({
    required this.iconKey,
    required this.title,
    required this.subtitle,
    required this.content,
    this.canContinue = true,
    this.onContinue,
    this.continueLabel,
  });

  /// Key into [BudgyIcons].
  ///
  /// The house spec calls for an SVG path here. Budgy ships no SVG set yet,
  /// so this takes the same icon key every other Budgy surface uses and the
  /// swap to SVGs is a one-line change in [_StepHeader] rather than a change
  /// to every call site.
  final String iconKey;

  final String title;
  final String subtitle;
  final Widget content;

  /// Gates the Continue button. Recomputed on every rebuild of the host, so
  /// the button un-greys the moment the step's own form becomes valid.
  final bool canContinue;

  /// Async gate. Return false to stay on this step (after showing whatever
  /// message the step wants to show).
  final Future<bool> Function()? onContinue;

  final String? continueLabel;
}

/// What the finale says on success.
@immutable
class JourneyOutcome {
  const JourneyOutcome({
    required this.title,
    required this.subtitle,
    this.iconKey = 'party-popper',
    this.doneLabel = 'Nice one',
    this.confetti = true,
  });

  final String title;
  final String subtitle;
  final String iconKey;
  final String doneLabel;
  final bool confetti;
}

/// What the finale says on failure.
@immutable
class JourneyFailure {
  const JourneyFailure({
    this.title = 'That didn’t go through',
    this.subtitle = 'Something slipped up on our end. Give it another go?',
    this.iconKey = 'circle-dashed',
    this.retryLabel = 'Try again',
  });

  final String title;
  final String subtitle;
  final String iconKey;
  final String retryLabel;
}

enum _Phase { form, processing, success, failure }

/// **The** multi-step flow. Never hand-roll a stepper.
///
/// It owns all the chrome — the segmented progress bar, the glowing step
/// header, the directional transitions, the Back/Continue nav with per-step
/// gating, and the whole `form → processing → success | failure` finale. A
/// caller supplies step bodies and one async submit.
///
/// ## The processing dwell
///
/// ⚠️ `onComplete` against a local Hive box returns in about two
/// milliseconds, which renders as the Continue button flickering and the
/// screen jumping straight to a success state. Users read that as "nothing
/// happened" and tap again. A minimum dwell holds the processing state long
/// enough to be seen, so the success lands as a *result* of something. It is
/// a floor, not a delay: a submit that genuinely takes longer is simply
/// awaited.
class JourneyStepper extends StatefulWidget {
  const JourneyStepper({
    super.key,
    required this.kicker,
    required this.steps,
    required this.onComplete,
    required this.outcome,
    this.completeLabel = 'Finish',
    this.failure = const JourneyFailure(),
    this.onExit,
    this.onDone,
    this.minProcessingDwell = const Duration(milliseconds: 1400),
  });

  final String kicker;
  final List<JourneyStep> steps;

  /// The submit. `true` for success, `false` to show the failure finale.
  final Future<bool> Function() onComplete;

  final JourneyOutcome outcome;
  final String completeLabel;
  final JourneyFailure failure;

  final VoidCallback? onExit;

  /// Called when the user dismisses the success finale. Defaults to [onExit].
  final VoidCallback? onDone;

  final Duration minProcessingDwell;

  @override
  State<JourneyStepper> createState() => _JourneyStepperState();
}

class _JourneyStepperState extends State<JourneyStepper> {
  int _index = 0;
  _Phase _phase = _Phase.form;

  /// Which way the next transition should slide. Set before the index
  /// changes, so the outgoing and incoming steps agree about direction —
  /// deriving it from the index inside the builder gets it backwards on the
  /// frame the index changes.
  bool _forward = true;

  late final ConfettiController _confetti = ConfettiController(
    duration: const Duration(milliseconds: 900),
  );

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  JourneyStep get _step => widget.steps[_index];
  bool get _isLast => _index == widget.steps.length - 1;

  Future<void> _next() async {
    final gate = _step.onContinue;
    if (gate != null) {
      final allowed = await gate();
      if (!allowed || !mounted) return;
    }

    if (!_isLast) {
      HapticFeedback.lightImpact();
      setState(() {
        _forward = true;
        _index++;
      });
      return;
    }

    await _submit();
  }

  Future<void> _submit() async {
    HapticFeedback.mediumImpact();
    setState(() => _phase = _Phase.processing);

    final started = DateTime.now();
    bool ok;
    try {
      ok = await widget.onComplete();
    } catch (_) {
      ok = false;
    }

    final elapsed = DateTime.now().difference(started);
    final remaining = widget.minProcessingDwell - elapsed;
    if (remaining > Duration.zero) await Future.delayed(remaining);
    if (!mounted) return;

    setState(() => _phase = ok ? _Phase.success : _Phase.failure);
    if (ok) {
      HapticFeedback.mediumImpact();
      if (widget.outcome.confetti) _confetti.play();
    }
  }

  void _back() {
    if (_index == 0) {
      widget.onExit?.call();
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _forward = false;
      _index--;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;

    return Scaffold(
      backgroundColor: c.surface100,
      body: SafeArea(
        child: Stack(
          children: [
            switch (_phase) {
              _Phase.form => _buildForm(context),
              _Phase.processing => _Processing(kicker: widget.kicker),
              _Phase.success => _Finale(
                iconKey: widget.outcome.iconKey,
                title: widget.outcome.title,
                subtitle: widget.outcome.subtitle,
                buttonLabel: widget.outcome.doneLabel,
                tint: c.successMain,
                onButton: () =>
                    (widget.onDone ?? widget.onExit)?.call(),
              ),
              _Phase.failure => _Finale(
                iconKey: widget.failure.iconKey,
                title: widget.failure.title,
                subtitle: widget.failure.subtitle,
                buttonLabel: widget.failure.retryLabel,
                tint: c.errorMain,
                onButton: _submit,
                secondaryLabel: 'Back to the form',
                onSecondary: () => setState(() => _phase = _Phase.form),
              ),
            },

            // Confetti is anchored to the top centre and blasts downward, so
            // it falls across the success card rather than erupting from
            // behind the button the user is about to press.
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0,
                numberOfParticles: 26,
                maxBlastForce: 22,
                minBlastForce: 9,
                gravity: 0.28,
                shouldLoop: false,
                colors: [
                  c.accent,
                  c.accentPop,
                  c.categoryAt(3),
                  c.categoryAt(4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BudgyConstants.gutter,
            8,
            BudgyConstants.gutter,
            0,
          ),
          child: Row(
            children: [
              BudgyIconButton(
                icon: _index == 0 ? LucideIcons.x : LucideIcons.arrowLeft,
                onTap: _back,
              ),
              const Spacer(),
              Text(
                widget.kicker,
                style: context.textTheme.titleSmall?.copyWith(
                  color: context.budgyColors.text300,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 44),
            ],
          ),
        ),

        const SizedBox(height: 18),

        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BudgyConstants.gutter,
          ),
          child: _ProgressBar(
            count: widget.steps.length,
            index: _index,
          ),
        ),

        const SizedBox(height: 24),

        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BudgyConstants.gutter,
          ),
          child: _StepHeader(step: _step),
        ),

        const SizedBox(height: 24),

        Expanded(
          child: _StepTransition(
            forward: _forward,
            index: _index,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: BudgyConstants.gutter,
              ),
              child: _step.content,
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(
            BudgyConstants.gutter,
            10,
            BudgyConstants.gutter,
            12,
          ),
          child: Row(
            children: [
              if (_index > 0) ...[
                BudgyTonalButton(
                  label: 'Back',
                  icon: LucideIcons.arrowLeft,
                  onTap: _back,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: BudgyFilledButton(
                  label: _isLast
                      ? widget.completeLabel
                      : (_step.continueLabel ?? 'Continue'),
                  icon: _isLast ? LucideIcons.check : LucideIcons.arrowRight,
                  iconTrailing: !_isLast,
                  width: double.infinity,
                  disabled: !_step.canContinue,
                  onTap: _next,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Slides step bodies in from the direction of travel.
///
/// ⚠️ Not named `AnimatedSwitcher` — that is a framework widget, and
/// shadowing it here would silently hijack every `AnimatedSwitcher` in any
/// file that imports this one.
class _StepTransition extends StatelessWidget {
  const _StepTransition({
    required this.child,
    required this.index,
    required this.forward,
  });

  final Widget child;
  final int index;
  final bool forward;

  @override
  Widget build(BuildContext context) => KeyedSubtree(
    // Keyed by index, so changing step genuinely replaces the subtree and
    // the entry animation runs. Without the key, Flutter reuses the element
    // and the new step simply appears.
    key: ValueKey(index),
    child: child
        .animate()
        .fadeIn(duration: 280.ms, curve: Curves.easeOut)
        .slideX(
          begin: forward ? 0.07 : -0.07,
          end: 0,
          duration: 320.ms,
          curve: Curves.easeOutCubic,
        )
        .scaleXY(begin: 0.99, end: 1, duration: 320.ms),
  );
}

/// The segmented progress bar: done segments filled, the active one flowing.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: _Segment(
              active: i == index,
              child: AnimatedContainer(
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutCubic,
              height: 6,
              decoration: BoxDecoration(
                color: i < index
                    ? c.accent
                    : i == index
                    ? null
                    : c.surface300,
                gradient: i == index
                    ? LinearGradient(colors: [c.accent, c.accentPop])
                    : null,
                borderRadius: BorderRadius.circular(3),
                boxShadow: i == index
                    ? BudgyShadows.glow(context, c.accent, strength: 0.6)
                    : null,
              ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Shimmers only while it is the live segment.
///
/// The shimmer is a repeating effect, so it has to be mounted conditionally
/// rather than toggled with `target:` — a repeating controller driven to a
/// target of 0 keeps running, which leaves every completed segment quietly
/// animating for the rest of the journey.
class _Segment extends StatelessWidget {
  const _Segment({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!active) return child;
    return child
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: 1600.ms,
          color: Colors.white.withValues(alpha: 0.45),
        );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step});

  final JourneyStep step;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [c.accentSoft, c.accentMid.withValues(alpha: 0.6)],
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: BudgyShadows.glow(context, c.accent, strength: 0.4),
          ),
          child: Icon(
            BudgyIcons.resolve(step.iconKey),
            size: 21,
            color: c.accent,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(step.title, style: context.textTheme.headlineSmall),
              const SizedBox(height: 3),
              Text(
                step.subtitle,
                style: context.textTheme.bodySmall?.copyWith(
                  color: c.text300,
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate(key: ValueKey(step.title)).fadeIn(duration: 300.ms);
  }
}

class _Processing extends StatelessWidget {
  const _Processing({required this.kicker});

  final String kicker;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.accentSoft,
                  shape: BoxShape.circle,
                ),
                child: SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation(c.accent),
                  ),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scaleXY(
                begin: 1,
                end: 1.05,
                duration: 900.ms,
                curve: Curves.easeInOutSine,
              ),
          const SizedBox(height: 26),
          Text('Saving $kicker…', style: context.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Hang tight, this won’t take long.',
            style: context.textTheme.bodyMedium?.copyWith(color: c.text300),
          ),
        ],
      ),
    );
  }
}

class _Finale extends StatelessWidget {
  const _Finale({
    required this.iconKey,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.tint,
    required this.onButton,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String iconKey;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final Color tint;
  final FutureOr<void> Function() onButton;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    return Padding(
      padding: const EdgeInsets.all(BudgyConstants.gutter),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
                width: 116,
                height: 116,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  BudgyIcons.resolve(iconKey),
                  size: 46,
                  color: tint,
                ),
              )
              .animate()
              .scaleXY(
                begin: 0.6,
                end: 1,
                duration: 480.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 240.ms),
          const SizedBox(height: 28),
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.textTheme.displaySmall,
          ).animate(delay: 120.ms).fadeIn(duration: 280.ms),
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyLarge?.copyWith(color: c.text300),
          ).animate(delay: 180.ms).fadeIn(duration: 280.ms),
          const SizedBox(height: 34),
          BudgyFilledButton(
            label: buttonLabel,
            width: double.infinity,
            onTap: onButton,
          ).animate(delay: 240.ms).fadeIn(duration: 260.ms),
          if (secondaryLabel != null) ...[
            const SizedBox(height: 10),
            PressScale(
              onTap: onSecondary,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  secondaryLabel!,
                  style: context.textTheme.labelLarge?.copyWith(
                    color: c.text300,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
