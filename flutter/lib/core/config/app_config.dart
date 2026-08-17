import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Central place for environment-ish config. The backend
/// (`../api`) listens on port 3000; `10.0.2.2` is the Android emulator's
/// alias for the host machine's `localhost` — a physical device needs the
/// host's real LAN IP instead, which is why this is overridable.
class AppConfig {
  AppConfig._();

  static const String _overrideBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_overrideBaseUrl.isNotEmpty) return _overrideBaseUrl;

    if (kIsWeb) return 'http://localhost:3000';

    if (Platform.isAndroid) return 'http://10.0.2.2:3000';

    return 'http://localhost:3000';
  }
}
