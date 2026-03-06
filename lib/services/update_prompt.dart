import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'update_checker.dart';

Future<void> showUpdateAvailableDialog(
  BuildContext context,
  UpdateCheckResult result,
) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Update available'),
      content: Text(
        'Current version: ${result.currentVersion}\n'
        'Latest version: ${result.latestVersion}',
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Later'),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.of(context).pop();
            await openReleasePage(result.releaseUrl);
          },
          child: const Text('Open releases'),
        ),
      ],
    ),
  );
}

Future<void> showNoUpdateDialog(
  BuildContext context,
  UpdateCheckResult result,
) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('You are up to date'),
      content: Text(
        'Current version: ${result.currentVersion}\n'
        'Latest version: ${result.latestVersion}',
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

Future<void> openReleasePage(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    return;
  }
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
