import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

/// Full-screen confetti overlay + dialog "Selamat".
///
/// Usage:
/// ```dart
/// await SuccessConfettiDialog.show(
///   context,
///   title: 'Selamat!',
///   message: 'Anda berhasil menukar Beras 5 kg.',
///   emoji: '🎉',
/// );
/// ```
class SuccessConfettiDialog extends StatefulWidget {
  final String title;
  final String message;
  final String emoji;
  final String? primaryActionLabel;

  const SuccessConfettiDialog({
    super.key,
    required this.title,
    required this.message,
    this.emoji = '🎉',
    this.primaryActionLabel,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String emoji = '🎉',
    String? primaryActionLabel,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierLabel: 'Selamat',
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => SuccessConfettiDialog(
        title: title,
        message: message,
        emoji: emoji,
        primaryActionLabel: primaryActionLabel,
      ),
      transitionBuilder: (_, animation, __, child) {
        final scale = Tween<double>(begin: 0.85, end: 1).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
    );
  }

  @override
  State<SuccessConfettiDialog> createState() => _SuccessConfettiDialogState();
}

class _SuccessConfettiDialogState extends State<SuccessConfettiDialog>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _topController;
  late final ConfettiController _sideLeft;
  late final ConfettiController _sideRight;

  @override
  void initState() {
    super.initState();
    _topController =
        ConfettiController(duration: const Duration(seconds: 2));
    _sideLeft = ConfettiController(duration: const Duration(seconds: 2));
    _sideRight = ConfettiController(duration: const Duration(seconds: 2));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _topController.play();
      _sideLeft.play();
      _sideRight.play();
    });
  }

  @override
  void dispose() {
    _topController.dispose();
    _sideLeft.dispose();
    _sideRight.dispose();
    super.dispose();
  }

  static const _colors = <Color>[
    AppColors.primary,
    AppColors.primaryDark,
    Color(0xFFFACC15), // yellow
    Color(0xFF3B82F6), // blue
    Color(0xFFEC4899), // pink
    Color(0xFFF97316), // orange
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Top center burst
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _topController,
              blastDirection: math.pi / 2, // downward
              maxBlastForce: 28,
              minBlastForce: 12,
              emissionFrequency: 0.04,
              numberOfParticles: 24,
              gravity: 0.25,
              shouldLoop: false,
              colors: _colors,
            ),
          ),
          // Left side burst
          Align(
            alignment: const Alignment(-1, -0.3),
            child: ConfettiWidget(
              confettiController: _sideLeft,
              blastDirection: 0, // right
              maxBlastForce: 22,
              minBlastForce: 10,
              emissionFrequency: 0.05,
              numberOfParticles: 18,
              gravity: 0.3,
              shouldLoop: false,
              colors: _colors,
            ),
          ),
          // Right side burst
          Align(
            alignment: const Alignment(1, -0.3),
            child: ConfettiWidget(
              confettiController: _sideRight,
              blastDirection: math.pi, // left
              maxBlastForce: 22,
              minBlastForce: 10,
              emissionFrequency: 0.05,
              numberOfParticles: 18,
              gravity: 0.3,
              shouldLoop: false,
              colors: _colors,
            ),
          ),
          // The dialog itself
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Dialog(
                  backgroundColor: scheme.surface,
                  insetPadding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.xl,
                      AppSizes.xxl,
                      AppSizes.xl,
                      AppSizes.lg,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.6, end: 1),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.elasticOut,
                          builder: (context, scale, child) =>
                              Transform.scale(scale: scale, child: child),
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              widget.emoji,
                              style: const TextStyle(fontSize: 44),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.lg),
                        Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSizes.sm),
                        Text(
                          widget.message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: scheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: AppSizes.xl),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusPill,
                                ),
                              ),
                            ),
                            child: Text(
                              widget.primaryActionLabel ?? 'Mantap!',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
