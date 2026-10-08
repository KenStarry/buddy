import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/data/hive_service.dart';
import 'core/data/ledger_bootstrap.dart';
import 'core/state/providers/core_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. System chrome. Transparent bars, because every Budgy page is
  //    edge-to-edge and paints its own ground.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 2. Preferences, preloaded so they can be injected synchronously.
  final prefs = await SharedPreferences.getInstance();

  // 3. Hive — boxes open before anything reads them. `SettingsController`
  //    builds synchronously off these, so this has to finish first.
  await HiveService.init();

  // 4. The container, with the preloaded singletons overridden in.
  final container = ProviderContainer(
    overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
  );

  // 5. Seed a fresh install and warm every ledger controller, so the first
  //    frame is the real home screen rather than a page of skeletons.
  await LedgerBootstrap.run(container);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const BudgyApp(),
    ),
  );
}
