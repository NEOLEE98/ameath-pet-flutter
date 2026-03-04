import 'package:flutter/widgets.dart';

Locale effectiveAppLocale({
  required String languageCode,
  required Locale systemLocale,
}) {
  switch (languageCode) {
    case 'en':
      return const Locale('en');
    case 'zh':
      return const Locale('zh');
    default:
      if (systemLocale.languageCode == 'zh') return const Locale('zh');
      return const Locale('en');
  }
}
