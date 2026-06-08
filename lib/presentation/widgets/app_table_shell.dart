import 'package:flutter/material.dart';

import 'app_card.dart';

class AppTableShell extends StatelessWidget {
  final Widget child;

  const AppTableShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: child,
        ),
      ),
    );
  }
}
