import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../presentation/theme/app_spacing.dart';
import '../theme/app_theme.dart';

class TickerTape extends StatefulWidget {
  const TickerTape({super.key});

  @override
  State<TickerTape> createState() => _TickerTapeState();
}

class _TickerTapeState extends State<TickerTape>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  final String _message =
      'SYSTEM OPERATIONAL  •  FLIGHT OPS ACTIVE  •  AI COMPETITORS LIVE  •  GLOBAL RANKINGS ONLINE  •  CASH RUNWAY STABLE  •  SEASON CLOCK RUNNING';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 1.0, end: -1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
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
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surface,
      ),
      clipBehavior: Clip.hardEdge,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_animation.value * 800, 0),
            child: child,
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _message,
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: AppTheme.textMuted,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
