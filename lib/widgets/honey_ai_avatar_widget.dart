import 'package:flutter/material.dart';
import '../theme/neo_brutalism_theme.dart';

class HoneyAiAvatarWidget extends StatelessWidget {
  final double size;
  final bool showOnlineIndicator;
  final bool showBorder;
  final VoidCallback? onTap;

  const HoneyAiAvatarWidget({
    super.key,
    this.size = 48,
    this.showOnlineIndicator = true,
    this.showBorder = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: NeoColors.honeyYellow,
            border: showBorder
                ? Border.all(
                    color: NeoColors.borderBlack,
                    width: size > 40 ? 2.5 : 2.0,
                  )
                : null,
            boxShadow: showBorder
                ? [
                    BoxShadow(
                      color: NeoColors.borderBlack.withValues(alpha: 0.3),
                      offset: const Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/honey_ai_avatar.png',
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback stylized icon
                return Container(
                  color: NeoColors.pastelPink,
                  child: Center(
                    child: Text(
                      '🌸',
                      style: TextStyle(fontSize: size * 0.5),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (showOnlineIndicator)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00E676), // Glowing neon green
                border: Border.all(
                  color: NeoColors.borderBlack,
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    return avatar;
  }
}
