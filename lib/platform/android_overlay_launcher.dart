import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import '../models/app_settings.dart';
import '../widgets/settings_page.dart';

class AndroidOverlayLauncher extends StatefulWidget {
  const AndroidOverlayLauncher({super.key, required this.controller});

  final SettingsController controller;

  @override
  State<AndroidOverlayLauncher> createState() => _AndroidOverlayLauncherState();
}

class _AndroidOverlayLauncherState extends State<AndroidOverlayLauncher>
    with WidgetsBindingObserver {
  String status = 'Overlay permission not granted.';
  bool overlayActive = false;
  bool hasPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_onSettingsChanged);
    _refreshOverlayState();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onSettingsChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // no-op: user starts overlay manually
      _refreshOverlayState();
      _shareOverlayApplyData();
    }
  }

  @override
  void didChangeMetrics() {
    _shareOverlayApplyData();
  }

  void _onSettingsChanged() {
    _shareOverlayApplyData();
  }

  Future<void> _startOverlay() async {
    if (!Platform.isAndroid) return;
    final granted = await FlutterOverlayWindow.isPermissionGranted();
    if (!granted) {
      await FlutterOverlayWindow.requestPermission();
    }
    final allowed = await FlutterOverlayWindow.isPermissionGranted();
    if (!allowed) {
      setState(() {
        hasPermission = false;
        status = 'Overlay permission not granted.';
      });
      return;
    }
    hasPermission = true;

    final mq = MediaQuery.of(context);
    await FlutterOverlayWindow.showOverlay(
      alignment: OverlayAlignment.topLeft,
      height: widget.controller.value.androidOverlaySize.toInt(),
      width: widget.controller.value.androidOverlaySize.toInt(),
      enableDrag: true,
      flag: OverlayFlag.defaultFlag,
      overlayTitle: 'Aemeath Pet',
      overlayContent: 'Aemeath Pet is running',
      startPosition: OverlayPosition(mq.padding.left, mq.padding.top),
    );
    overlayActive = true;
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await _shareOverlayApplyData();

    setState(() {
      status = 'Overlay running. You can leave the app.';
    });
  }

  Future<void> _stopOverlay() async {
    await FlutterOverlayWindow.closeOverlay();
    overlayActive = false;
    if (mounted) {
      setState(() {
        status = 'Overlay stopped.';
      });
    }
  }

  Future<void> _refreshOverlayState() async {
    if (!Platform.isAndroid) return;
    final allowed = await FlutterOverlayWindow.isPermissionGranted();
    final active = await FlutterOverlayWindow.isActive();
    if (!mounted) return;
    setState(() {
      hasPermission = allowed;
      overlayActive = active;
      status = !allowed
          ? 'Overlay permission not granted.'
          : active
              ? 'Overlay running. You can leave the app.'
              : 'Overlay stopped.';
    });
  }

  Future<void> _shareOverlayApplyData() async {
    if (!Platform.isAndroid) return;
    final active = overlayActive || await FlutterOverlayWindow.isActive();
    if (!active || !mounted) return;
    final view = View.of(context);
    final size = view.physicalSize / view.devicePixelRatio;
    final padding = EdgeInsets.fromViewPadding(
      view.padding,
      view.devicePixelRatio,
    );
    final fullWidth = size.width + padding.left + padding.right;
    final fullHeight = size.height + padding.top + padding.bottom;
    final current = widget.controller.value;
    await FlutterOverlayWindow.shareData({
      'type': 'apply',
      'mobileRoamSpeed': current.mobileRoamSpeed,
      'androidOverlayScale': current.androidOverlayScale,
      'showOverlayDebug': current.showOverlayDebug,
      'screenWidth': fullWidth,
      'screenHeight': fullHeight,
      'padLeft': padding.left,
      'padTop': padding.top,
      'padRight': padding.right,
      'padBottom': padding.bottom,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      appBar: AppBar(
        title: const Text('Aemeath Pet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SettingsPage(
                    controller: widget.controller,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                status,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: hasPermission
                      ? (overlayActive ? _stopOverlay : _startOverlay)
                      : _startOverlay,
                  child: Text(
                    hasPermission
                        ? (overlayActive ? 'Stop Overlay' : 'Start Overlay')
                        : 'Request Permission',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
