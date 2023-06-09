import 'package:flutter/material.dart';
import 'dart:math';

class SemiCircleSlider extends StatefulWidget {
  const SemiCircleSlider({
    Key? key,
    required this.initialValue,
    required this.divisions,
    required this.onChanged,
  }) : super(key: key);

  final double initialValue;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  State<SemiCircleSlider> createState() => _SemiCircleSliderState();
}

class _SemiCircleSliderState extends State<SemiCircleSlider> {
  late var value = widget.initialValue;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 350,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Apply some padding to the outside so the nub doesn't go past the
          // edge of the painter.
          const inset = 32.0;
          final arcWidth = constraints.maxWidth - inset * 2;
          final height = (arcWidth / 2) + inset * 2;
          final arcHeight = (height - inset * 2) * 2;
          final arcRect = Rect.fromLTRB(
            inset,
            height - (inset + arcHeight),
            arcWidth + inset,
            height - inset,
          );
          Widget child = TweenAnimationBuilder<double>(
            tween: Tween(begin: value.toDouble(), end: value.toDouble()),
            duration: const Duration(milliseconds: 50),
            curve: Curves.ease,
            builder: (context, value, child) {
              return CustomPaint(
                painter: SemiCircleSliderPainter(
                  divisions: widget.divisions,
                  arcRect: arcRect,
                  // Map the value to the angle at which to display the nub
                  nubAngle: (1 - (value / (widget.divisions - 1))) * pi,
                ),
                child: SizedBox(
                  height: height,
                ),
              );
            },
          );
          child = GestureDetector(
            // Use TweenAnimationBuilder to smoothly animate between divisions
            child: child,
            onPanUpdate: (e) {
              // Calculate the angle of the tap relative to the center of the
              // arc, then map that angle to a value
              final position = e.localPosition - arcRect.center;
              final angle = atan2(position.dy, position.dx);
              final newValue = ((1 - (angle / pi)) * (widget.divisions - 1))
                  .round()
                  .toDouble();
              if (value != newValue &&
                  newValue >= 0 &&
                  newValue < widget.divisions) {
                widget.onChanged(newValue);
                setState(() {
                  value = newValue;
                });
              }
            },
          );

          // Subtract by one to prevent the background from bleeding through
          // and creating a seam
          const imageInset = inset + SemiCircleSliderPainter.lineWidth - 1;
          const imageTopInset = inset - SemiCircleSliderPainter.lineWidth / 2;
          child = Stack(
            fit: StackFit.passthrough,
            children: [
              // Position the image so that it fits neatly inside the semicircle
              const Positioned(
                left: imageInset,
                top: imageTopInset,
                right: imageInset,
                bottom: imageInset,
                child: ClipRRect(
                  // A clever trick to round it into a semi-circle: round the
                  // bottom left and bottom right a large amount
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(1000.0),
                  ),
                ),
              ),
              child,
            ],
          );
          return child;
        },
      ),
    );
  }
}

class SemiCircleSliderPainter extends CustomPainter {
  SemiCircleSliderPainter({
    required this.divisions,
    required this.arcRect,
    required this.nubAngle,
  });

  final int divisions;
  final Rect arcRect;
  final double nubAngle;

  static const nubRadius = 16.0;
  static const lineWidth = 16.0;
  static const stepThickness = 3.0;
  static const stepLength = 2.0;
  late final lineArcRect = arcRect.deflate(lineWidth / 2);
  late final xradius = lineArcRect.width / 2;
  late final yradius = lineArcRect.height / 2;
  late final center = arcRect.center;
  late final nubPath = Path()
    ..addPath(
      Path()
        ..moveTo(0, 0)
        ..arcTo(
          const Offset(nubRadius / 2, -nubRadius) &
              const Size.fromRadius(nubRadius),
          5 * pi / 4,
          3 * pi / 2,
          false,
        ),
      Offset(
        center.dx + cos(nubAngle) * xradius,
        center.dy + sin(nubAngle) * yradius,
      ),
      matrix4: Matrix4.rotationZ(nubAngle).storage,
    );

  @override
  void paint(Canvas canvas, Size size) {
    // Paint large arc
    canvas.drawPath(
      Path()
        // Extend a line on the left and right so the markers aren't sitting
        // right on the border
        ..moveTo(lineArcRect.right, lineArcRect.center.dy - lineWidth / 2)
        ..arcTo(
          lineArcRect,
          0,
          pi,
          false,
        )
        ..lineTo(lineArcRect.left, lineArcRect.center.dy - lineWidth / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.black
        ..strokeWidth = lineWidth,
    );

    // Paint division markers
    for (var i = 0; i < divisions; i++) {
      final angle = pi * i / (divisions - 1);
      final xnorm = cos(angle);
      final ynorm = sin(angle);
      canvas.drawLine(
        center +
            Offset(
              xnorm * (xradius - stepLength),
              ynorm * (yradius - stepLength),
            ),
        center +
            Offset(
              xnorm * (xradius + stepLength),
              ynorm * (yradius + stepLength),
            ),
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.white
          ..strokeWidth = stepThickness
          ..strokeCap = StrokeCap.round,
      );
    }

    // Paint nub
    canvas.drawPath(
      nubPath,
      Paint()..color = Colors.pink.shade200,
    );
  }

  @override
  bool? hitTest(Offset position) {
    // Only respond to hit tests when tapping the nub
    return nubPath.contains(position);
  }

  @override
  bool shouldRepaint(SemiCircleSliderPainter oldDelegate) =>
      divisions != oldDelegate.divisions ||
      arcRect != oldDelegate.arcRect ||
      nubAngle != oldDelegate.nubAngle;
}
