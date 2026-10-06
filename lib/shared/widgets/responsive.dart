import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

extension ResponsiveX on BuildContext {
  WindowSize get windowSize =>
      WindowSize.fromWidth(MediaQuery.sizeOf(this).width);

  bool get isCompact => windowSize == WindowSize.compact;
}

/// Centers [child] and caps its width so content stays readable on tablets
/// and desktop, while using the full width on phones.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = AppLayout.maxContentWidth,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
