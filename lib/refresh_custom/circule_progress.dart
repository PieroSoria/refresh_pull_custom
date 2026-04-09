import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:refresh_pull_custom/refresh_custom/loading_custom.dart';

class CircularProgress extends StatelessWidget {
  final double innerCircleRadius;
  final double progressPercent;
  final double progressCircleOpacity;
  final double progressCircleRadius;
  final double progressCircleBorderWidth;
  final Color? backgroundColor;
  final Color? color;
  final double startAngle;

  const CircularProgress({
    super.key,
    required this.innerCircleRadius,
    required this.progressPercent,
    required this.progressCircleRadius,
    required this.progressCircleBorderWidth,
    this.backgroundColor,
    required this.progressCircleOpacity,
    required this.startAngle,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // double containerLength =
    //     2 * math.max(progressCircleRadius, innerCircleRadius);
    return Opacity(
      opacity: progressCircleOpacity,
      child: Container(
        padding: .all(5),
        decoration: BoxDecoration(color: backgroundColor, shape: .circle),
        child: LoadingIndicator(color: color),
      ),
    );
  }
}
