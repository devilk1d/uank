import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'desktop_shell.dart';
import 'main_shell.dart';

class ResponsiveShell extends ConsumerWidget {
  const ResponsiveShell({super.key});

  static const double kDesktopBreakpoint = 800.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= kDesktopBreakpoint) {
          return const DesktopShell();
        } else {
          return const MainShell();
        }
      },
    );
  }
}
