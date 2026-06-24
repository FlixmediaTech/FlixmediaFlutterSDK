import 'package:flutter/services.dart';

typedef FlixTokenProvider = Future<FlixTokenResult> Function();

class FlixTokenResult {
  const FlixTokenResult({required this.idToken, this.expiresAt});

  final String idToken;
  final Object? expiresAt;
}

class FlixBridge {
  static const MethodChannel _ch = MethodChannel('flix_media/methods');
  static FlixTokenProvider? _flixTokenProvider;
  static bool _tokenProviderHandlerConfigured = false;

  static Future<void> initialize({
    required String username,
    required String password,
    bool useSandbox = false,
  }) async {
    await _ch.invokeMethod('initialize', {
      'username': username,
      'password': password,
      'useSandbox': useSandbox,
    });
  }

  static Future<void> initializeWithTokenProvider({
    required FlixTokenProvider tokenProvider,
    bool useSandbox = false,
  }) async {
    _flixTokenProvider = tokenProvider;
    _configureTokenProviderHandler();

    final tokenResult = await _flixTokenProvider!();
    await _ch.invokeMethod('initializeWithToken', {
      'useSandbox': useSandbox,
      'idToken': tokenResult.idToken,
      if (tokenResult.expiresAt != null) 'expiresAt': tokenResult.expiresAt,
    });
  }

  static void _configureTokenProviderHandler() {
    if (_tokenProviderHandlerConfigured) {
      return;
    }

    _tokenProviderHandlerConfigured = true;
    _ch.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'requestTokenUpdate':
        case 'updateToken':
          await requestTokenUpdate();
          return null;
        default:
          throw MissingPluginException();
      }
    });
  }

  static Future<void> requestTokenUpdate() async {
    final tokenProvider = _flixTokenProvider;
    if (tokenProvider == null) {
      throw StateError('Missing tokenProvider');
    }

    final tokenResult = await tokenProvider();
    await _ch.invokeMethod('updateToken', {
      'idToken': tokenResult.idToken,
      if (tokenResult.expiresAt != null) 'expiresAt': tokenResult.expiresAt,
    });
  }

  static Future<String?> getInpageHtml({
    required Map<String, dynamic> productParams,
    String? baseURL,
  }) async {
    final res = await _ch.invokeMethod<String>('getInpageHtml', {
      'productParams': productParams,
      if (baseURL != null) 'baseURL': baseURL,
    });
    return res;
  }
}
