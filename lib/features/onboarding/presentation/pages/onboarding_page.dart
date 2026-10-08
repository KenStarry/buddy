import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../core/data/hive_service.dart';
import '../../../../core/presentation/budgy_icons.dart';
import '../../../../core/presentation/components/budgy_button.dart';
import '../../../../core/presentation/components/budgy_card.dart';
import '../../../../core/presentation/components/press_scale.dart';
import '../../../../core/theme/budgy_shadows.dart';
import '../../../../core/utils/budgy_constants.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../settings/presentation/state/controllers/settings_controller.dart';

/// First launch. Three screens, then a name, then in.
///
/// Deliberately short. An onboarding carousel is a tax on getting to the
/// thing, and a budget app's actual onboarding is the furnished demo month
/// waiting on the other side — you learn more from a home screen with real
/// numbers on it than from four slides promising there will be some.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  int _page = 0;

  static const _slides = [
    (
      iconKey: 'target',
      title: 'Know what’s\nactually safe',
      body:
          'Not your balance. What’s left after the bills you haven’t paid '
          'yet — and what that is per day.',
    ),
    (
      iconKey: 'piggy-bank',
      title: 'Budgets that\nkeep pace',
      body:
          'Every budget shows how far through the period you are, so 60% '
          'spent means something.',
    ),
    (
      iconKey: 'rocket',
      title: 'Goals worth\nlooking at',
      body:
          'Name what you’re saving for. Budgy does the maths and tells you '
          'if you’re on track.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  bool get _onLastSlide => _page >= _slides.length;

  Future<void> _finish() async {
    await ref
        .read(settingsControllerProvider.notifier)
        .setUserName(_nameController.text);
    await HiveService.markOnboarded();
    if (mounted) context.goNamed('home');
  }

  void _next() {
    if (_page < _slides.length) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;

    return Scaffold(
      backgroundColor: c.surface100,
      body: SafeArea(
        child: Column(
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
                  Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [c.accentPop, c.accent],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: BudgyShadows.glow(context, c.accent, strength: 0.6),
                        ),
                        child: Icon(
                          LucideIcons.wallet,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Text('Budgy', style: context.textTheme.titleLarge),
                    ],
                  ),
                  const Spacer(),
                  if (!_onLastSlide)
                    PressScale(
                      onTap: () => _pageController.animateToPage(
                        _slides.length,
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.easeOutCubic,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        child: Text(
                          'Skip',
                          style: context.textTheme.labelLarge?.copyWith(
                            color: c.text300,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _page = page),
                children: [
                  for (final slide in _slides) _Slide(slide: slide),
                  _NameSlide(controller: _nameController),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                BudgyConstants.gutter,
                0,
                BudgyConstants.gutter,
                14,
              ),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _slides.length + 1,
                    effect: ExpandingDotsEffect(
                      dotHeight: 7,
                      dotWidth: 7,
                      expansionFactor: 3.4,
                      spacing: 6,
                      activeDotColor: c.accent,
                      dotColor: c.surface300,
                    ),
                  ),
                  const SizedBox(height: 20),
                  BudgyFilledButton(
                    label: _onLastSlide ? 'Let’s go' : 'Next',
                    icon: LucideIcons.arrowRight,
                    iconTrailing: true,
                    width: double.infinity,
                    onTap: () async => _next(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.slide});

  final ({String iconKey, String title, String body}) slide;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BudgyConstants.gutter),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
                width: 104,
                height: 104,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [c.accentSoft, c.accentMid.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(34),
                  boxShadow: BudgyShadows.glow(context, c.accent, strength: 0.5),
                ),
                child: Icon(
                  BudgyIcons.resolve(slide.iconKey),
                  size: 42,
                  color: c.accent,
                ),
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .moveY(
                begin: 0,
                end: -9,
                duration: 2800.ms,
                curve: Curves.easeInOutSine,
              ),
          const SizedBox(height: 34),
          Text(slide.title, style: context.textTheme.displayLarge),
          const SizedBox(height: 14),
          Text(
            slide.body,
            style: context.textTheme.bodyLarge?.copyWith(color: c.text300),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 380.ms);
  }
}

class _NameSlide extends StatelessWidget {
  const _NameSlide({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BudgyConstants.gutter),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'One last thing',
            style: context.textTheme.labelSmall?.copyWith(color: c.text300),
          ),
          const SizedBox(height: 10),
          Text('What should\nwe call you?', style: context.textTheme.displayLarge),
          const SizedBox(height: 18),
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            style: context.textTheme.titleLarge,
            decoration: const InputDecoration(hintText: 'Your name'),
          ),
          const SizedBox(height: 16),
          BudgyCard(
            tone: BudgyCardTone.wash,
            elevated: false,
            child: Row(
              children: [
                Icon(LucideIcons.sparkles, size: 16, color: c.accent),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'We’ve filled Budgy with a demo month so there’s '
                    'something to look at. Clear it any time from Settings.',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: c.text200,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 380.ms);
  }
}
