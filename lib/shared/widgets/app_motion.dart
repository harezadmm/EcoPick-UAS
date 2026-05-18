import 'package:flutter/material.dart';

class AppMotion {
  AppMotion._();

  static const Curve curve = Cubic(0.22, 1, 0.36, 1);
  static const Curve fastCurve = Cubic(0.25, 1, 0.5, 1);
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration medium = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 420);

  static bool reduce(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    if (media == null) return false;
    return media.disableAnimations || media.accessibleNavigation;
  }
}

class MotionFadeSlide extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final Offset offset;
  final Duration duration;

  const MotionFadeSlide({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.offset = const Offset(0, 18),
    this.duration = AppMotion.slow,
  });

  @override
  State<MotionFadeSlide> createState() => _MotionFadeSlideState();
}

class _MotionFadeSlideState extends State<MotionFadeSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final curved = CurvedAnimation(parent: _controller, curve: AppMotion.curve);
    _opacity = Tween<double>(begin: 0, end: 1).animate(curved);
    _slide =
        Tween<Offset>(begin: widget.offset, end: Offset.zero).animate(curved);
    _start();
  }

  Future<void> _start() async {
    if (widget.delayMs > 0) {
      await Future.delayed(Duration(milliseconds: widget.delayMs));
    }
    if (mounted) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduce(context)) return widget.child;
    return FadeTransition(
      opacity: _opacity,
      child: AnimatedBuilder(
        animation: _slide,
        builder: (context, child) => Transform.translate(
          offset: _slide.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

class MotionPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadiusGeometry? borderRadius;
  final bool enabled;

  const MotionPressable({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.enabled = true,
  });

  @override
  State<MotionPressable> createState() => _MotionPressableState();
}

class _MotionPressableState extends State<MotionPressable> {
  bool _pressed = false;

  void _setPressed(bool pressed) {
    if (_pressed == pressed || !widget.enabled) return;
    setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduce(context);
    final child = AnimatedScale(
      scale: !reduce && _pressed ? 0.975 : 1,
      duration: AppMotion.fast,
      curve: AppMotion.fastCurve,
      child: widget.child,
    );

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.enabled ? widget.onTap : null,
      onTapDown: widget.enabled ? (_) => _setPressed(true) : null,
      onTapUp: widget.enabled ? (_) => _setPressed(false) : null,
      onTapCancel: widget.enabled ? () => _setPressed(false) : null,
      child: child,
    );
  }
}

class MotionSwitcher extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const MotionSwitcher({
    super.key,
    required this.child,
    this.duration = AppMotion.medium,
  });

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduce(context)) return child;
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: AppMotion.curve,
      switchOutCurve: AppMotion.fastCurve,
      transitionBuilder: (child, animation) {
        final offset = Tween<Offset>(
          begin: const Offset(0.02, 0.04),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offset, child: child),
        );
      },
      child: child,
    );
  }
}
