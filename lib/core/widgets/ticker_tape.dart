import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../presentation/theme/app_typography.dart';

class TickerTape extends StatefulWidget {
  const TickerTape({super.key});

  @override
  State<TickerTape> createState() => _TickerTapeState();
}

class _TickerTapeState extends State<TickerTape>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      color: AppTheme.primary,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return FractionalTranslation(
            translation: Offset(1.0 - _controller.value * 2.0, 0.0),
            child: child,
          );
        },
        child: Center(
          child: Text(
            '▲ SYSTEM STATUS: OPERATIONAL  ◆  FLIGHT OPERATIONS: ACTIVE  ◆  AI COMPETITORS: ENGAGED  ◆  GLOBAL RANKINGS: LIVE  ◆  CASH RUNWAY: STABLE',
            maxLines: 1,
            style: AppTypography.badgeText.copyWith(
              color: Colors.black,
              fontSize: 10,
              letterSpacing: 2.0,
            ),
          ),
        ),
      ),
    );
  }
}
