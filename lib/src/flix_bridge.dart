import 'package:flutter/services.dart';

class FlixBridge {
  static const MethodChannel _ch = MethodChannel('flix_media/methods');

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
