import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/budgy_config.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/presentation/state/controllers/settings_controller.dart';

class BudgyApp extends ConsumerWidget {
  const BudgyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);

    return MaterialApp.router(
      title: BudgyConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(settings.scheme),
      darkTheme: AppTheme.dark(settings.scheme),
      themeMode: settings.themeMode,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => MediaQuery(
        // ⚠️ Clamped, not disabled. `TextScaler.noScaling` makes the layout
        // predictable and makes Budgy unusable for anyone who has turned text
        // size up — which, for an app whose entire job is reading numbers, is
        // the wrong trade. 1.3 is as far as the money hero and the nav labels
        // hold their composition.
        data: MediaQuery.of(context).copyWith(
          textScaler: MediaQuery.textScalerOf(
            context,
          ).clamp(minScaleFactor: 0.9, maxScaleFactor: 1.3),
        ),
        child: child!,
      ),
    );
  }
}
