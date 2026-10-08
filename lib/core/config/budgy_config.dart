/// Build-time configuration.
///
/// ⚠️ Deliberately **not** `envied`. Budgy is local-first and has no backend,
/// no API key and no secret to obfuscate yet; an `@Envied` class over an empty
/// `.env` adds a codegen step, a gitignored file every contributor has to be
/// told about, and an obfuscation pass over nothing. When a sync service
/// lands, this class becomes the envied one and [baseUrl] stops being a
/// placeholder — that is the moment to pay for it, not before.
class BudgyConfig {
  BudgyConfig._();

  static const appName = 'Budgy';
  static const tagline = 'Your budget buddy';

  /// Placeholder. Nothing calls it yet; `dioProvider` is wired so that the
  /// day something does, the interceptors and error parsing already exist.
  static const baseUrl = 'https://api.budgy.app/v1';

  static const connectTimeout = Duration(seconds: 12);
  static const receiveTimeout = Duration(seconds: 12);
}
