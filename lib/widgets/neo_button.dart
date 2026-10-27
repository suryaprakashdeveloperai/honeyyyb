import 'package:flutter/material.dart';
import '../theme/neo_brutalism_theme.dart';

class NeoButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color color;
  final Color borderColor;
  final Color shadowColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool isFullWidth;

  const NeoButton({
    super.key,
    required this.child,
    this.onPressed,
    this.color = NeoColors.honeyYellow,
    this.borderColor = NeoColors.borderBlack,
    this.shadowColor = NeoColors.borderBlack,
    this.borderRadius = NeoTheme.borderRadius,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    this.isFullWidth = false,
  });

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    const double offset = 4.0;
    final bool isEnabled = widget.onPressed != null;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled
          ? (_) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        transform: Matrix4.translationValues(
          _isPressed ? offset : 0,
          _isPressed ? offset : 0,
          0,
        ),
        width: widget.isFullWidth ? double.infinity : null,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: isEnabled ? widget.color : NeoColors.softGrey,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(color: widget.borderColor, width: NeoTheme.borderWidth),
          boxShadow: [
            BoxShadow(
              color: (_isPressed || !isEnabled) ? Colors.transparent : widget.shadowColor,
              offset: (_isPressed || !isEnabled) ? Offset.zero : const Offset(offset, offset),
              blurRadius: 0,
            ),
          ],
        ),
        child: Center(
          widthFactor: widget.isFullWidth ? null : 1.0,
          child: widget.child,
        ),
      ),
    );
  }
}
