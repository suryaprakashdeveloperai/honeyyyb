import 'package:flutter/material.dart';
import '../theme/neo_brutalism_theme.dart';

class NeoCard extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final Color shadowColor;
  final double borderRadius;
  final double borderWidth;
  final Offset shadowOffset;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const NeoCard({
    super.key,
    required this.child,
    this.backgroundColor = NeoColors.cardWhite,
    this.borderColor = NeoColors.borderBlack,
    this.shadowColor = NeoColors.borderBlack,
    this.borderRadius = NeoTheme.borderRadius,
    this.borderWidth = NeoTheme.borderWidth,
    this.shadowOffset = NeoTheme.shadowOffset,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: padding ?? const EdgeInsets.all(16.0),
      decoration: NeoTheme.neoBoxDecoration(
        backgroundColor: backgroundColor,
        borderColor: borderColor,
        shadowColor: shadowColor,
        radius: borderRadius,
        bWidth: borderWidth,
        sOffset: shadowOffset,
      ),
      child: child,
    );

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}
