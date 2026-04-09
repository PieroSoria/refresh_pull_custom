import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:refresh_pull_custom/refresh_custom/loading_custom.dart';

class CircularProgress extends StatelessWidget {
  final double innerCircleRadius;
  final double progressPercent;
  final double progressCircleOpacity;
  final double progressCircleRadius;
  final double progressCircleBorderWidth;
  final Color backgroundColor;
  final double startAngle;

  const CircularProgress({
    super.key,
    required this.innerCircleRadius,
    required this.progressPercent,
    required this.progressCircleRadius,
    required this.progressCircleBorderWidth,
    required this.backgroundColor,
    required this.progressCircleOpacity,
    required this.startAngle,
  });

  @override
  Widget build(BuildContext context) {
    // double containerLength =
    //     2 * math.max(progressCircleRadius, innerCircleRadius);
    return Opacity(
      opacity: progressCircleOpacity,
      child: const LoadingIndicator(),
    );
  }
}
