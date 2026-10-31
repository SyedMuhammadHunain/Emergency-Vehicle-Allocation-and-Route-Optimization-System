import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class EmergencyButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isCountingDown;
  final int countdownRemaining;
  final VoidCallback? onCancelCountdown;
  final bool isActivated;

  const EmergencyButton({
    super.key,
    required this.onPressed,
    this.isCountingDown = false,
    this.countdownRemaining = 3,
    this.onCancelCountdown,
    this.isActivated = false,
  });

  @override
  State<EmergencyButton> createState() => _EmergencyButtonState();
}

class _EmergencyButtonState extends State<EmergencyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = widget.isActivated || widget.isCountingDown
            ? _pulseAnimation.value
            : 1.0;

        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ripple pulse ring
              if (widget.isActivated || widget.isCountingDown)
                Container(
                  width: 220 * _pulseAnimation.value,
                  height: 220 * _pulseAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.18),
                  ),
                ),

              // Secondary glow ring
              Container(
                width: 190 * scale,
                height: 190 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (widget.isActivated ? AppColors.warning : AppColors.primary)
                      .withValues(alpha: 0.25),
                ),
              ),

              // Central SOS Button
              GestureDetector(
                onTap: widget.isCountingDown
                    ? widget.onCancelCountdown
                    : widget.onPressed,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: widget.isActivated
                          ? [const Color(0xFFE65100), const Color(0xFFFF9800)]
                          : [const Color(0xFFB71C1C), const Color(0xFFE53935)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (widget.isActivated
                                ? Colors.orange
                                : AppColors.primary)
                            .withValues(alpha: 0.45),
                        blurRadius: 24,
                        spreadRadius: 4,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.isCountingDown) ...[
                        Text(
                          '${widget.countdownRemaining}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'TAP TO CANCEL',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ] else if (widget.isActivated) ...[
                        const Icon(
                          Icons.broadcast_on_personal_rounded,
                          color: Colors.white,
                          size: 42,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'SOS ACTIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ] else ...[
                        const Icon(
                          Icons.touch_app_rounded,
                          color: Colors.white70,
                          size: 26,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'SOS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const Text(
                          'EMERGENCY',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
