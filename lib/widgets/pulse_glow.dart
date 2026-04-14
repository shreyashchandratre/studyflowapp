import 'package:flutter/material.dart';

class PulseGlow extends StatefulWidget {
  final Widget child;
  final Color color;
  final double endRadius;

  const PulseGlow({
    Key? key,
    required this.child,
    required this.color,
    this.endRadius = 60.0,
  }) : super(key: key);

  @override
  State<PulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<PulseGlow> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.3 * (1.2 - _animation.value)),
                blurRadius: widget.endRadius * _animation.value,
                spreadRadius: 10 * _animation.value,
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}
