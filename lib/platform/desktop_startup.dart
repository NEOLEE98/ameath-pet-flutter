import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

import '../l10n/app_localizations.dart';
import '../l10n/locale_utils.dart';
import '../models/app_settings.dart';
import '../models/window_args.dart';

Future<void> initializeDesktopWindow({
  required WindowArgs windowArgs,
  required SettingsController settingsController,
}) async {
  final ready = await _ensureWindowManagerReady();
  if (ready) {
    if (windowArgs.type == WindowArgs.typeSettings) {
      await _configureSettingsWindow(settingsController);
    } else {
      await _configurePetWindow(settingsController);
    }
  }
  await _tryRegisterWindowHandlers(
    windowArgs: windowArgs,
    settingsController: settingsController,
  );
}

Future<bool> _ensureWindowManagerReady() async {
  const retries = 5;
  for (var attempt = 0; attempt < retries; attempt += 1) {
    try {
      await WindowManagerPlus.ensureInitialized(0);
      return true;
    } on MissingPluginException {
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
  }
  return false;
}

Future<void> _tryRegisterWindowHandlers({
  required WindowArgs windowArgs,
  required SettingsController settingsController,
}) async {
  const retries = 5;
  for (var attempt = 0; attempt < retries; attempt += 1) {
    try {
      final windowController = await WindowController.fromCurrentEngine();
      if (windowArgs.type == WindowArgs.typeSettings) {
        await _registerSettingsWindowHandlers(windowController);
      } else {
        await _registerMainWindowHandlers(
          windowController: windowController,
          settingsController: settingsController,
        );
      }
      return;
    } on MissingPluginException {
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
  }
}

Future<void> _configurePetWindow(SettingsController settingsController) async {
  final windowSize = settingsController.value.desktopWindowSize;
  final windowOptions = WindowOptions(
    size: Size(windowSize, windowSize),
    center: true,
    backgroundColor: Colors.transparent,
    titleBarStyle: TitleBarStyle.hidden,
    skipTaskbar: true,
  );

  WindowManagerPlus.current.waitUntilReadyToShow(windowOptions, () async {
    await WindowManagerPlus.current.setAsFrameless();
    await WindowManagerPlus.current.setResizable(false);
    await WindowManagerPlus.current
        .setMinimumSize(Size(windowSize, windowSize));
    await WindowManagerPlus.current
        .setMaximumSize(Size(windowSize, windowSize));
    await WindowManagerPlus.current.setHasShadow(false);
    await WindowManagerPlus.current.setOpacity(1);
    await WindowManagerPlus.current.setVisibleOnAllWorkspaces(true);
    await WindowManagerPlus.current.setAlwaysOnTop(true);
    await WindowManagerPlus.current.setBackgroundColor(Colors.transparent);
    await WindowManagerPlus.current.show();
    await WindowManagerPlus.current.focus();
  });
}

Future<void> _configureSettingsWindow(SettingsController settingsController) async {
  final locale = effectiveAppLocale(
    languageCode: settingsController.value.languageCode,
    systemLocale: WidgetsBinding.instance.platformDispatcher.locale,
  );
  final strings = lookupAppLocalizations(locale);
  const settingsSize = Size(720, 720);
  const minSize = Size(520, 640);
  const maxSize = Size(1400, 1200);
  final windowOptions = WindowOptions(
    size: settingsSize,
    center: true,
    backgroundColor: const Color(0xFFF5F3EF),
    title: strings.appTitleSettings,
    titleBarStyle: TitleBarStyle.normal,
    skipTaskbar: false,
  );

  WindowManagerPlus.current.waitUntilReadyToShow(windowOptions, () async {
    await WindowManagerPlus.current.setResizable(true);
    await WindowManagerPlus.current.setMinimumSize(minSize);
    await WindowManagerPlus.current.setMaximumSize(maxSize);
    await WindowManagerPlus.current.setHasShadow(true);
    await WindowManagerPlus.current.setAlwaysOnTop(false);
    await WindowManagerPlus.current.setVisibleOnAllWorkspaces(false);
    await WindowManagerPlus.current.setBackgroundColor(
      const Color(0xFFF5F3EF),
    );
    await WindowManagerPlus.current.show();
    await WindowManagerPlus.current.focus();
  });
}

Future<void> _registerMainWindowHandlers({
  required WindowController windowController,
  required SettingsController settingsController,
}) async {
  await windowController.setWindowMethodHandler((call) async {
    switch (call.method) {
      case 'reloadSettings':
        await settingsController.load();
        return true;
      case 'applySettings':
        final args = call.arguments;
        if (args is Map) {
          settingsController.value = AppSettings(
            petScale: (args['petScale'] as num?)?.toDouble() ??
                settingsController.value.petScale,
            desktopRoamSpeed:
                (args['desktopRoamSpeed'] as num?)?.toDouble() ??
                    settingsController.value.desktopRoamSpeed,
            mobileRoamSpeed:
                (args['mobileRoamSpeed'] as num?)?.toDouble() ??
                    settingsController.value.mobileRoamSpeed,
            androidOverlayScale:
                (args['androidOverlayScale'] as num?)?.toDouble() ??
                    settingsController.value.androidOverlayScale,
            showOverlayDebug: args['showOverlayDebug'] as bool? ??
                settingsController.value.showOverlayDebug,
            launchAtStartup: args['launchAtStartup'] as bool? ??
                settingsController.value.launchAtStartup,
            languageCode: args['languageCode'] as String? ??
                settingsController.value.languageCode,
          );
          return true;
        }
        return false;
      case 'focus':
        await WindowManagerPlus.current.show();
        await WindowManagerPlus.current.focus();
        return true;
    }
    return null;
  });
}

Future<void> _registerSettingsWindowHandlers(
  WindowController windowController,
) async {
  await windowController.setWindowMethodHandler((call) async {
    switch (call.method) {
      case 'focus':
        await WindowManagerPlus.current.show();
        await WindowManagerPlus.current.focus();
        return true;
    }
    return null;
  });
}
