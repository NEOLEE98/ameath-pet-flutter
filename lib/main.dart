import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const AmeathPetApp());
}

class AmeathPetApp extends StatelessWidget {
  const AmeathPetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ameath Pet',
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6B8E23)),
      ),
      home: const PetStage(),
    );
  }
}

class PetStage extends StatefulWidget {
  const PetStage({super.key});

  @override
  State<PetStage> createState() => _PetStageState();
}

class _PetStageState extends State<PetStage> {
  static const double petSize = 160;

  final List<String> idleGifs = const [
    'gifs/idle1.gif',
    'gifs/idle2.gif',
    'gifs/idle3.gif',
    'gifs/idle4.gif',
  ];

  String currentGif = 'gifs/idle1.gif';
  Offset position = const Offset(120, 220);
  Timer? idleTimer;
  bool isDragging = false;
  bool isMoving = false;

  @override
  void initState() {
    super.initState();
    _startIdleLoop();
  }

  @override
  void dispose() {
    idleTimer?.cancel();
    super.dispose();
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
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      position += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    isDragging = false;
    _setGif('gifs/idle1.gif');
  }

  void _onMoveTap() {
    if (isMoving || isDragging) return;
    isMoving = true;
    _setGif('gifs/move.gif');
    final size = MediaQuery.sizeOf(context);
    final next = Offset(
      Random().nextDouble() * (size.width - petSize),
      Random().nextDouble() * (size.height - petSize),
    );

    final start = position;
    const steps = 30;
    var tick = 0;
    Timer.periodic(const Duration(milliseconds: 16), (timer) {
      tick += 1;
      final t = tick / steps;
      if (t >= 1) {
        timer.cancel();
        setState(() {
          position = next;
          isMoving = false;
          currentGif = 'gifs/idle1.gif';
        });
        return;
      }
      final lerp = Offset(
        start.dx + (next.dx - start.dx) * t,
        start.dy + (next.dy - start.dy) * t,
      );
      setState(() {
        position = lerp;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final clamped = Offset(
      position.dx.clamp(0.0, max(0.0, size.width - petSize)),
      position.dy.clamp(0.0, max(0.0, size.height - petSize)),
    );

    if (clamped != position) {
      position = clamped;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      body: Stack(
        children: [
          Positioned(
            left: position.dx,
            top: position.dy,
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              onDoubleTap: _onMoveTap,
              child: SizedBox(
                width: petSize,
                height: petSize,
                child: Image.asset(
                  currentGif,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 16,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 16,
                    color: Color(0x22000000),
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Text(
                  'Drag Ameath around. Double-tap to make it roam.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
