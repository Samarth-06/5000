import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Background: slowly drifting isometric 3D grid that also tilts
/// with touch. Much lower intensity than before.
class FarmParallaxBackground extends StatefulWidget {
  final Widget child;
  final ScrollController? scrollController;
  const FarmParallaxBackground({Key? key, required this.child, this.scrollController}) : super(key: key);

  @override
  State<FarmParallaxBackground> createState() => _FarmParallaxBgState();
}

class _FarmParallaxBgState extends State<FarmParallaxBackground>
    with TickerProviderStateMixin {
  // Slow continual drift offset
  late AnimationController _driftCtrl;
  // Touch tilt
  double _tiltX = 0.0, _tiltY = 0.0;
  // Pulse for corner dot
  late AnimationController _pulseCtrl;
  Size _size = Size.zero;

  @override
  void initState() {
    super.initState();
    _driftCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _driftCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (!mounted || _size == Size.zero) return;
    setState(() {
      _tiltX = ((d.localPosition.dx / _size.width) - 0.5).clamp(-0.5, 0.5);
      _tiltY = ((d.localPosition.dy / _size.height) - 0.5).clamp(-0.5, 0.5);
    });
  }

  void _onPanEnd(DragEndDetails _) {
    setState(() {
      _tiltX = 0;
      _tiltY = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      _size = Size(constraints.maxWidth, constraints.maxHeight);

      return GestureDetector(
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            // ── Animated 3D grid ──────────────────────────────────────────
            AnimatedBuilder(
              animation: Listenable.merge([_driftCtrl, _pulseCtrl]),
              builder: (_, __) {
                const maxTilt = 0.14;
                final matrix = Matrix4.identity()
                  ..setEntry(3, 2, 0.0008)
                  ..rotateX(_tiltY * maxTilt - 0.22)   // base 3D tilt (isometric)
                  ..rotateY(_tiltX * maxTilt);

                return Transform(
                  transform: matrix,
                  alignment: Alignment.center,
                  child: CustomPaint(
                    painter: _GridPainter(
                      drift: _driftCtrl.value,
                      pulse: _pulseCtrl.value,
                      tiltX: _tiltX,
                      tiltY: _tiltY,
                    ),
                    child: const SizedBox.expand(),
                  ),
                );
              },
            ),

            // ── Corner pulse dot ──────────────────────────────────────────
            Positioned(
              bottom: 18,
              right: 18,
              child: AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) {
                  final p = _pulseCtrl.value;
                  return Stack(alignment: Alignment.center, children: [
                    Container(
                      width: 22 + p * 12,
                      height: 22 + p * 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryAccent.withOpacity(0.06 * (1 - p)),
                        border: Border.all(
                          color: AppColors.primaryAccent.withOpacity(0.18 * (1 - p)),
                        ),
                      ),
                    ),
                    Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryAccent.withOpacity(0.15),
                        border: Border.all(color: AppColors.primaryAccent.withOpacity(0.4)),
                      ),
                    ),
                    Container(
                      width: 5, height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryAccent.withOpacity(0.7),
                        boxShadow: [BoxShadow(color: AppColors.primaryAccent.withOpacity(0.5), blurRadius: 6)],
                      ),
                    ),
                  ]);
                },
              ),
            ),

            // ── Content ───────────────────────────────────────────────────
            widget.child,
          ],
        ),
      );
    });
  }
}

class _GridPainter extends CustomPainter {
  final double drift;  // 0.0 – 1.0 (looping)
  final double pulse;
  final double tiltX;
  final double tiltY;
  const _GridPainter({required this.drift, required this.pulse, required this.tiltX, required this.tiltY});

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF040904),
    );

    const cellSize = 52.0;
    // Drift offset: lines move diagonally bottom-right ↘ slowly
    final offsetX = (drift * cellSize) % cellSize;
    final offsetY = (drift * cellSize * 0.6) % cellSize;

    // Touch-highlight centre
    final touchX = (tiltX + 0.5) * size.width;
    final touchY = (tiltY + 0.5) * size.height;
    final isTouching = tiltX.abs() > 0.02 || tiltY.abs() > 0.02;

    final minorColor = AppColors.gridLine.withOpacity(0.22); // very dim
    final majorColor = AppColors.gridLine.withOpacity(0.40); // slightly brighter

    // Draw lines from -cellSize to allow drift wraparound
    // Horizontal
    for (double y = -cellSize + offsetY; y <= size.height + cellSize; y += cellSize) {
      final isMajor = ((y - offsetY) ~/ cellSize).abs() % 4 == 0;
      final dist = isTouching ? (y - touchY).abs() : double.infinity;
      final hl = isTouching ? math.max(0.0, 1.0 - dist / 90.0) : 0.0;
      canvas.drawLine(
        Offset(-cellSize, y), Offset(size.width + cellSize, y),
        Paint()
          ..strokeWidth = isMajor ? 0.8 : 0.5
          ..color = hl > 0.05
              ? Color.lerp(isMajor ? majorColor : minorColor,
                  AppColors.primaryAccent.withOpacity(0.45), hl)!
              : (isMajor ? majorColor : minorColor),
      );
    }
    // Vertical
    for (double x = -cellSize + offsetX; x <= size.width + cellSize; x += cellSize) {
      final isMajor = ((x - offsetX) ~/ cellSize).abs() % 4 == 0;
      final dist = isTouching ? (x - touchX).abs() : double.infinity;
      final hl = isTouching ? math.max(0.0, 1.0 - dist / 90.0) : 0.0;
      canvas.drawLine(
        Offset(x, -cellSize), Offset(x, size.height + cellSize),
        Paint()
          ..strokeWidth = isMajor ? 0.8 : 0.5
          ..color = hl > 0.05
              ? Color.lerp(isMajor ? majorColor : minorColor,
                  AppColors.primaryAccent.withOpacity(0.45), hl)!
              : (isMajor ? majorColor : minorColor),
      );
    }

    // Subtle glow at touch point
    if (isTouching) {
      canvas.drawCircle(
        Offset(touchX, touchY), 16 + pulse * 6,
        Paint()
          ..color = AppColors.primaryAccent.withOpacity(0.06 + pulse * 0.03)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
      );
    }
  }

  @override
  bool shouldRepaint(_GridPainter o) =>
      o.drift != drift || o.tiltX != tiltX || o.tiltY != tiltY || o.pulse != pulse;
}
