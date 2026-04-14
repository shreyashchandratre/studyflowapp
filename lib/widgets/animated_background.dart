import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Formerly an animated gradient + particle background.
/// Now a clean, solid off-white wrapper — no distractions.
class AnimatedBackground extends StatelessWidget {
  final Widget child;
  const AnimatedBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.bgColor,
      child: child,
    );
  }
}
