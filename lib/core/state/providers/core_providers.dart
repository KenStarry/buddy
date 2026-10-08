import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../config/budgy_config.dart';

part 'core_providers.g.dart';

/// Overridden in `main()` with the instance awaited before the widget tree,
/// so preferences can be read synchronously anywhere.
@Riverpod(keepAlive: true)
SharedPreferences sharedPrefs(Ref ref) => throw UnimplementedError(
  'sharedPrefsProvider must be overridden in main() with the preloaded '
  'instance. See main.dart.',
);

@Riverpod(keepAlive: true)
Logger logger(Ref ref) => Logger(
  printer: PrettyPrinter(methodCount: 0, lineLength: 80, printEmojis: false),
  // Release builds stay quiet: a ledger's titles and amounts are the user's
  // private finances and have no business in a device log.
  level: kReleaseMode ? Level.warning : Level.debug,
);

@Riverpod(keepAlive: true)
Uuid uuid(Ref ref) => const Uuid();

/// HTTP client. Configured, unused — see [BudgyConfig.baseUrl].
@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final client = Dio(
    BaseOptions(
      baseUrl: BudgyConfig.baseUrl,
      connectTimeout: BudgyConfig.connectTimeout,
      receiveTimeout: BudgyConfig.receiveTimeout,
    ),
  );
  if (!kReleaseMode) {
    client.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true),
    );
  }
  return client;
}

/// Terse access to cross-cutting singletons from a widget.
extension BudgyRefX on WidgetRef {
  Logger get log => read(loggerProvider);
  Uuid get ids => read(uuidProvider);
}
