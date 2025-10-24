import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter/material.dart';

class FlixInpageHtmlViewController {
  InAppWebViewController? _webViewController;

  void attach(InAppWebViewController controller) {
    _webViewController = controller;
  }

  void detach() {
    _webViewController = null;
  }

  Future<void> callLogFromApp(String message) async {
    if (_webViewController == null) return;
    debugPrint("nacisnieto");
    final escapedMessage = _escapeJsString(message);
    final js = '''
      window.flixtracking.onLogFromApp("$escapedMessage");
    ''';

    try {
      await _webViewController!.evaluateJavascript(source: js);
    } catch (_) {
      // error
    }
  }

  String _escapeJsString(String s) {
    return s
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAll("'", r"\'")
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\r');
  }
}
