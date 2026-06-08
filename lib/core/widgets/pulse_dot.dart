import 'package:flutter/material.dart';

class PulseDot extends StatelessWidget {
  final Color color;

  const PulseDot({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
