import 'dart:async';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../models/window_args.dart';
import 'settings_page.dart';

class SettingsWindowApp extends StatefulWidget {
  const SettingsWindowApp({super.key, required this.controller});

  final SettingsController controller;

  @override
  State<SettingsWindowApp> createState() => _SettingsWindowAppState();
}

class _SettingsWindowAppState extends State<SettingsWindowApp> {
  Timer? _notifyTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onSettingsChanged);
    _notifyTimer?.cancel();
    super.dispose();
  }

  void _onSettingsChanged() {
    _notifyTimer?.cancel();
    _notifyTimer = Timer(const Duration(milliseconds: 200), () async {
      try {
        final current = widget.controller.value;
        final payload = <String, dynamic>{
          'petScale': current.petScale,
          'desktopRoamSpeed': current.desktopRoamSpeed,
          'mobileRoamSpeed': current.mobileRoamSpeed,
          'androidOverlayScale': current.androidOverlayScale,
          'showOverlayDebug': current.showOverlayDebug,
          'launchAtStartup': current.launchAtStartup,
        };
        final controllers = await WindowController.getAll();
        for (final controller in controllers) {
          final args = WindowArgs.fromJsonString(controller.arguments);
          if (args.type == WindowArgs.typeMain) {
            await controller.invokeMethod('applySettings', payload);
            break;
          }
        }
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aemeath Settings',
      themeMode: ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F3EF),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F3EF),
          foregroundColor: Colors.black,
        ),
      ),
      home: SettingsPage(controller: widget.controller),
    );
  }
}
