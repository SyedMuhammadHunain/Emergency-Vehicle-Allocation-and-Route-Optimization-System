import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class GradientHeader extends StatelessWidget {
  final Widget child;
  final double height;
  final EdgeInsetsGeometry padding;

  const GradientHeader({
    super.key,
    required this.child,
    this.height = 220,
    this.padding = const EdgeInsets.fromLTRB(20, 48, 20, 24),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          // Translucent concentric background circles as specified in design
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),

          // Header Content
          Padding(
            padding: padding,
            child: child,
          ),
        ],
      ),
    );
  }
}
