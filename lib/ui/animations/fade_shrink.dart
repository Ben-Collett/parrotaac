import 'package:flutter/material.dart';

class FadeAndShrink extends StatefulWidget {
  final bool visible;
  final Widget child;
  final Duration duration;
  final Curve curve;

  const FadeAndShrink({
    super.key,
    required this.visible,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  });

  @override
  State<FadeAndShrink> createState() => _FadeAndShrinkState();
}

class _FadeAndShrinkState extends State<FadeAndShrink>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: widget.visible ? 1.0 : 0.0,
    );

    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);
  }

  @override
  void didUpdateWidget(FadeAndShrink oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible != widget.visible) {
      if (widget.visible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
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
        final double value = _animation.value;

        return ExcludeSemantics(
          excluding: value < 0.01,
          child: IgnorePointer(
            ignoring: value < 0.01,
            child: Opacity(
              opacity: value,
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: value, // 👈 uses same value for shrinking
                child: child,
              ),
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
