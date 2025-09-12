import 'package:flutter/services.dart';

class FlixBridge {
  static const MethodChannel _ch = MethodChannel('flix_media/methods');

  static Future<void> initialize({
    required String username,
    required String password,
  }) async {
    await _ch.invokeMethod('initialize', {
      'username': username,
      'password': password,
    });
  }

  static Future<String?> getInpageHtml({
    required Map<String, dynamic> productParams,
  }) async {
    final res = await _ch.invokeMethod<String>('getInpageHtml', {
      'productParams': productParams,
    });
    return res;
  }
}