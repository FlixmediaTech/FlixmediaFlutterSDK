import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

  Future<void> handleExternalLink(String url, BuildContext context) async {
    final uri = Uri.parse(url);

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