import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NeoColors {
  static const Color honeyYellow = Color(0xFFFFE600);
  static const Color spiderRed = Color(0xFFFF3366);
  static const Color neonTeal = Color(0xFF00F0FF);
  static const Color electricPurple = Color(0xFFA855F7);
  static const Color pastelPink = Color(0xFFFFB7B2);
  static const Color mintGreen = Color(0xFF2ECC71);
  static const Color creamBg = Color(0xFFFFFBEB);
  static const Color borderBlack = Color(0xFF000000);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color softGrey = Color(0xFFE5E7EB);
  static const Color primaryPink = Color(0xFFFF3366);
  static const Color neonGreen = Color(0xFF2ECC71);
  static const Color bgOffWhite = Color(0xFFFFFBEB);
  static const Color textSecondary = Color(0xFF6B7280);
}

class NeoTheme {
  static const double borderWidth = 3.0;
  static const double borderRadius = 12.0;
  static const Offset shadowOffset = Offset(4, 4);

  static BoxDecoration neoBoxDecoration({
    Color backgroundColor = NeoColors.cardWhite,
    Color borderColor = NeoColors.borderBlack,
    Color shadowColor = NeoColors.borderBlack,
    double radius = borderRadius,
    double bWidth = borderWidth,
    Offset sOffset = shadowOffset,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor, width: bWidth),
      boxShadow: [
        BoxShadow(
          color: shadowColor,
          offset: sOffset,
          blurRadius: 0,
          spreadRadius: 0,
        ),
      ],
    );
  }

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: NeoColors.creamBg,
      primaryColor: NeoColors.honeyYellow,
      colorScheme: ColorScheme.light(
        primary: NeoColors.honeyYellow,
        secondary: NeoColors.spiderRed,
        surface: NeoColors.creamBg,
        error: NeoColors.spiderRed,
      ),
      textTheme: GoogleFonts.spaceGroteskTextTheme().copyWith(
        displayLarge: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w900,
          color: NeoColors.borderBlack,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w800,
          color: NeoColors.borderBlack,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          color: NeoColors.borderBlack,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w500,
          color: NeoColors.borderBlack,
        ),
      ),
    );
  }
}
