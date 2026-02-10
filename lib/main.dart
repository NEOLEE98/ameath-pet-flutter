import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:window_manager_plus/window_manager_plus.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

const Color windowsChromaKey = Color(0xFFFF00FF);

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isMacOS) {
    final windowId = args.isEmpty ? 0 : int.tryParse(args.first) ?? 0;
    await WindowManagerPlus.ensureInitialized(windowId);

    final windowOptions = WindowOptions(
      size: Size(180, 180),
      center: true,
      backgroundColor: Platform.isWindows ? windowsChromaKey : Colors.transparent,
      titleBarStyle: TitleBarStyle.hidden,
      skipTaskbar: true,
    );

    WindowManagerPlus.current.waitUntilReadyToShow(windowOptions, () async {
      await WindowManagerPlus.current.setAsFrameless();
      await WindowManagerPlus.current.setResizable(false);
      await WindowManagerPlus.current.setHasShadow(false);
      await WindowManagerPlus.current.setOpacity(1);
      await WindowManagerPlus.current.setVisibleOnAllWorkspaces(true);
      await WindowManagerPlus.current.setAlwaysOnTop(true);
      await WindowManagerPlus.current.setBackgroundColor(
        Platform.isWindows ? windowsChromaKey : Colors.transparent,
      );
      await WindowManagerPlus.current.show();
      await WindowManagerPlus.current.focus();
    });
  }

  runApp(const AmeathPetApp());
}

bool isOverlayApp = false;

@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  isOverlayApp = true;
  runApp(const AmeathOverlayApp());
}

class AmeathPetApp extends StatelessWidget {
  const AmeathPetApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isWindows = Platform.isWindows;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ameath Pet',
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6B8E23)),
        scaffoldBackgroundColor:
            isWindows ? windowsChromaKey : Colors.transparent,
        canvasColor: isWindows ? windowsChromaKey : Colors.transparent,
      ),
      home: Platform.isAndroid
          ? const AndroidOverlayLauncher()
          : const PetStage(),
    );
  }
}

class AmeathOverlayApp extends StatelessWidget {
  const AmeathOverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ameath Pet Overlay',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.transparent,
        canvasColor: Colors.transparent,
      ),
      home: const PetStage(),
    );
  }
}

class AndroidOverlayLauncher extends StatefulWidget {
  const AndroidOverlayLauncher({super.key});

  @override
  State<AndroidOverlayLauncher> createState() => _AndroidOverlayLauncherState();
}

class _AndroidOverlayLauncherState extends State<AndroidOverlayLauncher>
    with WidgetsBindingObserver {
  String status = 'Requesting overlay permission...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startOverlay();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startOverlay();
    }
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
        status = 'Overlay permission not granted.';
      });
      return;
    }

    await FlutterOverlayWindow.showOverlay(
      alignment: OverlayAlignment.center,
      height: _PetStageState.androidOverlaySize.toInt(),
      width: _PetStageState.androidOverlaySize.toInt(),
      enableDrag: true,
      flag: OverlayFlag.defaultFlag,
      overlayTitle: 'Ameath Pet',
      overlayContent: 'Ameath Pet is running',
    );

    setState(() {
      status = 'Overlay running. You can leave the app.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            status,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}

class PetStage extends StatefulWidget {
  const PetStage({super.key});

  @override
  State<PetStage> createState() => _PetStageState();
}

class _PetStageState extends State<PetStage> {
  static const double petSize = 100;
  static const double desktopWindowSize = 180;
  static const double desktopRoamSpeed = 100.0; // px/sec
  static const double mobileRoamSpeed = 180.0; // px/sec
  static const double androidOverlaySize = 200.0;

  final List<String> idleGifs = const [
    'gifs/idle1.gif',
    'gifs/idle2.gif',
    'gifs/idle3.gif',
    'gifs/idle4.gif',
  ];

  String currentGif = 'gifs/idle1.gif';
  Offset position = const Offset(120, 220);
  Timer? idleTimer;
  Timer? roamTimer;
  bool isDragging = false;
  bool isMoving = false;
  bool faceLeft = false;
  Size? stageSize;
  EdgeInsets? stagePadding;

  @override
  void initState() {
    super.initState();
    _startIdleLoop();
    _initRoamLoop();
  }

  @override
  void dispose() {
    idleTimer?.cancel();
    roamTimer?.cancel();
    super.dispose();
  }

  Future<void> _initRoamLoop() async {
    roamTimer?.cancel();
    roamTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (isDragging || isMoving) return;
      if (Platform.isWindows || Platform.isMacOS) {
        _roamDesktop();
      } else {
        _roamMobile();
      }
    });
  }

  void _startIdleLoop() {
    idleTimer?.cancel();
    idleTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (isDragging || isMoving) return;
      final next = idleGifs[Random().nextInt(idleGifs.length)];
      setState(() {
        currentGif = next;
      });
    });
  }

  void _setGif(String gif) {
    if (currentGif == gif) return;
    setState(() {
      currentGif = gif;
    });
  }

  void _onPanStart(DragStartDetails details) {
    isDragging = true;
    _setGif('gifs/drag.gif');
    if (Platform.isWindows || Platform.isMacOS) {
      WindowManagerPlus.current.startDragging();
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (Platform.isWindows || Platform.isMacOS) return;
    if (Platform.isAndroid && isOverlayApp) return;
    setState(() {
      if (details.delta.dx.abs() > 0.1) {
        faceLeft = details.delta.dx < 0;
      }
      position += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    isDragging = false;
    _setGif('gifs/idle1.gif');
  }

  void _onMoveTap() {
    if (isMoving || isDragging) return;
    if (Platform.isWindows || Platform.isMacOS) {
      _roamDesktop();
      return;
    }
    _roamMobile();
  }

  Future<void> _roamDesktop() async {
    final size = stageSize ?? const Size(1280, 720);
    final next = Offset(
      Random().nextDouble() * (size.width - desktopWindowSize),
      Random().nextDouble() * (size.height - desktopWindowSize),
    );
    final start = await WindowManagerPlus.current.getPosition();

    setState(() {
      isMoving = true;
      currentGif = 'gifs/move.gif';
      faceLeft = next.dx < start.dx;
    });
    await _animateWindowTo(next, speedPxPerSec: desktopRoamSpeed);
    setState(() {
      isMoving = false;
      currentGif = 'gifs/idle1.gif';
    });
  }

  Future<void> _animateWindowTo(
    Offset target, {
    required double speedPxPerSec,
  }) async {
    final start = await WindowManagerPlus.current.getPosition();
    final distance = (target - start).distance;
    final durationMs = max(200, (distance / speedPxPerSec * 1000).round());
    final duration = Duration(milliseconds: durationMs);
    const frame = Duration(milliseconds: 16);
    final steps = max(1, duration.inMilliseconds ~/ frame.inMilliseconds);
    var tick = 0;

    final completer = Completer<void>();
    Timer.periodic(frame, (timer) async {
      tick += 1;
      final t = tick / steps;
      if (t >= 1) {
        timer.cancel();
        await WindowManagerPlus.current.setPosition(target);
        completer.complete();
        return;
      }
      final eased = Curves.easeInOut.transform(t);
      final lerp = Offset(
        start.dx + (target.dx - start.dx) * eased,
        start.dy + (target.dy - start.dy) * eased,
      );
      await WindowManagerPlus.current.setPosition(lerp);
    });

    return completer.future;
  }

  void _roamMobile() {
    if (Platform.isAndroid && isOverlayApp) {
      _roamAndroidOverlay();
      return;
    }
    isMoving = true;
    _setGif('gifs/move.gif');
    final padding = isOverlayApp ? EdgeInsets.zero : (stagePadding ?? EdgeInsets.zero);
    final size = stageSize ?? MediaQuery.sizeOf(context);
    final usableHeight = max(0.0, size.height - padding.vertical);
    final next = Offset(
      Random().nextDouble() * (size.width - petSize),
      padding.top + Random().nextDouble() * (usableHeight - petSize),
    );

    final start = position;
    faceLeft = next.dx < start.dx;
    _animateMobileTo(start, next, speedPxPerSec: mobileRoamSpeed);
  }

  Future<void> _roamAndroidOverlay() async {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final screenSize = view.physicalSize / view.devicePixelRatio;
    final next = Offset(
      Random().nextDouble() * (screenSize.width - androidOverlaySize),
      Random().nextDouble() * (screenSize.height - androidOverlaySize),
    );

    final current = await FlutterOverlayWindow.getOverlayPosition();
    final start = Offset(current.x, current.y);
    setState(() {
      isMoving = true;
      currentGif = 'gifs/move.gif';
      faceLeft = next.dx < start.dx;
    });

    await _animateOverlayTo(start, next, speedPxPerSec: mobileRoamSpeed);
    setState(() {
      isMoving = false;
      currentGif = 'gifs/idle1.gif';
    });
  }

  Future<void> _animateOverlayTo(
    Offset start,
    Offset target, {
    required double speedPxPerSec,
  }) async {
    final distance = (target - start).distance;
    final durationMs = max(200, (distance / speedPxPerSec * 1000).round());
    final duration = Duration(milliseconds: durationMs);
    const frame = Duration(milliseconds: 16);
    final steps = max(1, duration.inMilliseconds ~/ frame.inMilliseconds);
    var tick = 0;

    final completer = Completer<void>();
    Timer.periodic(frame, (timer) async {
      tick += 1;
      final t = tick / steps;
      if (t >= 1) {
        timer.cancel();
        await FlutterOverlayWindow.moveOverlay(
          OverlayPosition(target.dx, target.dy),
        );
        completer.complete();
        return;
      }
      final eased = Curves.easeInOut.transform(t);
      final lerp = Offset(
        start.dx + (target.dx - start.dx) * eased,
        start.dy + (target.dy - start.dy) * eased,
      );
      await FlutterOverlayWindow.moveOverlay(
        OverlayPosition(lerp.dx, lerp.dy),
      );
    });

    return completer.future;
  }

  void _animateMobileTo(
    Offset start,
    Offset target, {
    required double speedPxPerSec,
  }) {
    final distance = (target - start).distance;
    final durationMs = max(200, (distance / speedPxPerSec * 1000).round());
    final duration = Duration(milliseconds: durationMs);
    const frame = Duration(milliseconds: 16);
    final steps = max(1, duration.inMilliseconds ~/ frame.inMilliseconds);
    var tick = 0;

    Timer.periodic(frame, (timer) {
      tick += 1;
      final t = tick / steps;
      if (t >= 1) {
        timer.cancel();
        setState(() {
          position = target;
          isMoving = false;
          currentGif = 'gifs/idle1.gif';
        });
        return;
      }
      final eased = Curves.easeInOut.transform(t);
      final lerp = Offset(
        start.dx + (target.dx - start.dx) * eased,
        start.dy + (target.dy - start.dy) * eased,
      );
      setState(() {
        position = lerp;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final view = View.of(context);
    final size = view.physicalSize / view.devicePixelRatio;
    final rawPadding = EdgeInsets.fromViewPadding(
      view.padding,
      view.devicePixelRatio,
    );
    final padding = isOverlayApp ? EdgeInsets.zero : rawPadding;
    stageSize = size;
    stagePadding = padding;
    final usableHeight = max(0.0, size.height - padding.vertical);
    final clamped = Offset(
      position.dx.clamp(0.0, max(0.0, size.width - petSize)),
      position.dy.clamp(
        padding.top,
        max(padding.top, padding.top + usableHeight - petSize),
      ),
    );

    if (clamped != position) {
      position = clamped;
    }

    final isDesktop = Platform.isWindows || Platform.isMacOS;
    final isAndroidOverlay = Platform.isAndroid && isOverlayApp;
    final pet = GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onDoubleTap: _onMoveTap,
      child: SizedBox(
        width: petSize,
        height: petSize,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(faceLeft ? -1 : 1, 1, 1),
          child: Image.asset(
            currentGif,
            fit: BoxFit.contain,
            gaplessPlayback: true,
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Platform.isWindows ? windowsChromaKey : Colors.transparent,
      body: (isDesktop || isAndroidOverlay)
          ? Center(child: pet)
          : Stack(
              children: [
                Positioned(
                  left: position.dx,
                  top: position.dy,
                  child: pet,
                ),
              ],
            ),
    );
  }
}
