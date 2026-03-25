import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

bool shouldHandleAsExternalLink(String url) {
  final normalizedUrl = url.trim().replaceAll(
    RegExp(r'&amp;', caseSensitive: false),
    '&',
  );
  final uri = Uri.tryParse(normalizedUrl);
  if (uri == null) return false;

  final lowerUrl = normalizedUrl.toLowerCase();
  final sceneViewerRegex = RegExp(
    r'^https?:\/\/arvr\.google\.com\/scene-viewer(?:[\/?#]|$)',
    caseSensitive: false,
  );
  final externalFileRegex = RegExp(
    r'\.(pdf|docx?|usdz)(?:$|[?#&])',
    caseSensitive: false,
  );

  return lowerUrl.startsWith('intent:') ||
      sceneViewerRegex.hasMatch(normalizedUrl) ||
      externalFileRegex.hasMatch(normalizedUrl);
}

Future<void> handleExternalLink(String url, BuildContext context) async {
  if (!shouldHandleAsExternalLink(url)) return;

  final normalizedUrl = url.trim().replaceAll(
    RegExp(r'&amp;', caseSensitive: false),
    '&',
  );
  final uri = Uri.tryParse(normalizedUrl);
  if (uri == null) return;

  final shouldOpen = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Leave the app?"),
      content: Text("This link will open in the browser."),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text("Open"),
        ),
      ],
    ),
  );

  if (shouldOpen == true) {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
