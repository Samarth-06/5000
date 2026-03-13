import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

// ─── Farm Scene Widget ────────────────────────────────────────────────────────
// A layered parallax background with animated farm elements:
//   Layer 0 (sky + gradient)  – stationary
//   Layer 1 (clouds)          – slow leftward drift
//   Layer 2 (hills/trees)     – medium parallax
//   Layer 3 (foreground)      – crops, fence with scroll
//   Overlay  (rain)           – vertical drop animation

class FarmParallaxBackground extends StatefulWidget {
  final Widget child;
  final ScrollController? scrollController;
  const FarmParallaxBackground({
    Key? key,
    required this.child,
    this.scrollController,
  }) : super(key: key);

  @override
  State<FarmParallaxBackground> createState() => _FarmParallaxBackgroundState();
}

class _FarmParallaxBackgroundState extends State<FarmParallaxBackground>
    with TickerProviderStateMixin {
  late AnimationController _cloudController;
  late AnimationController _rainController;
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();

    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    _rainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cloudController.dispose();
    _rainController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Sky gradient ─────────────────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF020C02),
                Color(0xFF041A0A),
                Color(0xFF021020),
                Color(0xFF030A03),
              ],
              stops: [0.0, 0.35, 0.65, 1.0],
            ),
          ),
        ),

        // ── Neon grid lines ──────────────────────────────────────────────────
        CustomPaint(
          size: Size.infinite,
          painter: _GridPainter(),
        ),

        // ── Glowing orbs ─────────────────────────────────────────────────────
        AnimatedBuilder(
          animation: _floatController,
          builder: (_, __) {
            final t = _floatController.value;
            return Stack(children: [
              _blob(Alignment(-0.8 + t * 0.1, -0.6 + t * 0.05),
                  AppColors.primaryAccent.withOpacity(0.08), 200),
              _blob(Alignment(0.7 - t * 0.08, 0.3 - t * 0.1),
                  AppColors.secondaryAccent2.withOpacity(0.06), 160),
              _blob(Alignment(-0.1 + t * 0.04, 0.7 + t * 0.03),
                  AppColors.goldAccent.withOpacity(0.05), 140),
            ]);
          },
        ),

        // ── Cloud layer (slow drift) ──────────────────────────────────────────
        AnimatedBuilder(
          animation: _cloudController,
          builder: (context, _) {
            final offset = _cloudController.value;
            return Positioned(
              top: 40,
              left: -300 + offset * (MediaQuery.of(context).size.width + 300),
              right: null,
              child: _buildCloudsRow(),
            );
          },
        ),

        // ── Stars / sparkles ─────────────────────────────────────────────────
        CustomPaint(
          size: Size.infinite,
          painter: _StarsPainter(seed: 42),
        ),

        // ── Mountain silhouette ───────────────────────────────────────────────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: CustomPaint(
            painter: _MountainPainter(),
            child: const SizedBox(height: 240),
          ),
        ),

        // ── Farm scene row ────────────────────────────────────────────────────
        Positioned(
          bottom: 60,
          left: 0,
          right: 0,
          child: AnimatedBuilder(
            animation: _floatController,
            builder: (_, __) {
              final t = _floatController.value;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _farmEmoji('🌾', 38 - t * 3, 0.7),
                    _farmEmoji('🌲', 52, 0.8),
                    _farmEmoji('🐄', 36 + t * 2, 0.6),
                    _farmEmoji('🌽', 42, 0.75),
                    _farmEmoji('🧹', 44 - t * 2, 0.65, isFlip: true),
                    _farmEmoji('🌳', 56, 0.8),
                    _farmEmoji('🌾', 36 + t * 3, 0.7),
                    _farmEmoji('🐓', 30 - t, 0.6),
                    _farmEmoji('🌻', 40, 0.7),
                  ],
                ),
              );
            },
          ),
        ),

        // ── Rain overlay ──────────────────────────────────────────────────────
        AnimatedBuilder(
          animation: _rainController,
          builder: (context, _) {
            return CustomPaint(
              size: Size.infinite,
              painter: _RainPainter(_rainController.value),
            );
          },
        ),

        // ── Content on top ────────────────────────────────────────────────────
        widget.child,
      ],
    );
  }

  Widget _blob(Alignment align, Color color, double size) {
    return Align(
      alignment: align,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
          ),
        ),
      ),
    );
  }

  Widget _farmEmoji(String emoji, double size, double opacity,
      {bool isFlip = false}) {
    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scaleX: isFlip ? -1 : 1,
        child: Text(emoji, style: TextStyle(fontSize: size)),
      ),
    );
  }

  Widget _buildCloudsRow() {
    return Row(
      children: const [
        Text('☁️', style: TextStyle(fontSize: 64, color: Colors.white12)),
        SizedBox(width: 40),
        Text('☁️', style: TextStyle(fontSize: 48, color: Colors.white10)),
        SizedBox(width: 80),
        Text('☁️', style: TextStyle(fontSize: 56, color: Colors.white12)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Custom Painters
// ═══════════════════════════════════════════════════════════════════════════

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryAccent.withOpacity(0.04)
      ..strokeWidth = 0.5;
    const step = 50.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter o) => false;
}

class _MountainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final darkGreen = Paint()
      ..color = const Color(0xFF062006)
      ..style = PaintingStyle.fill;
    final midGreen = Paint()
      ..color = const Color(0xFF031203)
      ..style = PaintingStyle.fill;

    // Back layer of hills
    final back = Path()
      ..moveTo(0, size.height * 0.7)
      ..lineTo(size.width * 0.2, size.height * 0.3)
      ..lineTo(size.width * 0.45, size.height * 0.55)
      ..lineTo(size.width * 0.7, size.height * 0.25)
      ..lineTo(size.width * 0.9, size.height * 0.45)
      ..lineTo(size.width, size.height * 0.4)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(back, midGreen);

    // Front layer of hills (darker)
    final front = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.8)
      ..lineTo(size.width * 0.15, size.height * 0.55)
      ..lineTo(size.width * 0.35, size.height * 0.75)
      ..lineTo(size.width * 0.55, size.height * 0.48)
      ..lineTo(size.width * 0.75, size.height * 0.65)
      ..lineTo(size.width, size.height * 0.5)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(front, darkGreen);
  }

  @override
  bool shouldRepaint(_MountainPainter o) => false;
}

class _StarsPainter extends CustomPainter {
  final int seed;
  _StarsPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(seed);
    final paint = Paint()..color = Colors.white;
    for (int i = 0; i < 60; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height * 0.6;
      final r = rng.nextDouble() * 1.5 + 0.3;
      paint.color = Colors.white.withOpacity(rng.nextDouble() * 0.4 + 0.1);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(_StarsPainter o) => false;
}

class _RainPainter extends CustomPainter {
  final double progress;
  static final _rng = Random(99);
  static late List<Offset> _starts;
  static bool _initialized = false;

  _RainPainter(this.progress) {
    if (!_initialized) {
      _starts = List.generate(
        30,
        (_) => Offset(_rng.nextDouble(), _rng.nextDouble()),
      );
      _initialized = true;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryAccent.withOpacity(0.07)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    const dropLength = 18.0;
    for (final start in _starts) {
      final x = start.dx * size.width;
      final rawY = (start.dy + progress) % 1.0;
      final y = rawY * size.height;
      canvas.drawLine(
        Offset(x, y),
        Offset(x - 2, y + dropLength),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RainPainter o) => o.progress != progress;
}
