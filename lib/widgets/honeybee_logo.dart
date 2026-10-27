import 'package:flutter/material.dart';
import '../theme/neo_brutalism_theme.dart';

/// A custom high-performance low-poly geometric Honeybee brandmark widget
/// rendered via crisp vector canvas paths matching the neo-brutalist aesthetic.
class HoneyBeeLogo extends StatelessWidget {
  final double size;
  final Color backgroundColor;
  final bool showBadgeContainer;

  const HoneyBeeLogo({
    super.key,
    this.size = 36.0,
    this.backgroundColor = NeoColors.honeyYellow,
    this.showBadgeContainer = true,
  });

  @override
  Widget build(BuildContext context) {
    final logoWidget = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: LowPolyHoneybeePainter(),
      ),
    );

    if (!showBadgeContainer) {
      return logoWidget;
    }

    return Container(
      width: size + 14,
      height: size + 14,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: NeoColors.borderBlack, width: NeoTheme.borderWidth),
        boxShadow: const [
          BoxShadow(
            color: NeoColors.borderBlack,
            offset: Offset(2.5, 2.5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Center(child: logoWidget),
    );
  }
}

class LowPolyHoneybeePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Scale canvas from a 100x100 reference coordinate system
    canvas.save();
    canvas.scale(w / 100.0, h / 100.0);

    final Paint borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final Paint fillPaint = Paint()..style = PaintingStyle.fill;

    void drawPoly(List<Offset> points, Color color) {
      final path = Path()..addPolygon(points, true);
      fillPaint.color = color;
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, borderPaint);
    }

    // --- 1. LEGS (Back & bottom legs in black) ---
    final legPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    // Front leg
    final frontLeg = Path()
      ..moveTo(24, 62)
      ..lineTo(18, 72)
      ..lineTo(22, 84);
    canvas.drawPath(frontLeg, legPaint);

    // Middle leg 1
    final midLeg1 = Path()
      ..moveTo(36, 68)
      ..lineTo(32, 80)
      ..lineTo(28, 88);
    canvas.drawPath(midLeg1, legPaint);

    // Middle leg 2
    final midLeg2 = Path()
      ..moveTo(48, 70)
      ..lineTo(44, 82)
      ..lineTo(48, 92);
    canvas.drawPath(midLeg2, legPaint);

    // Back leg
    final backLeg = Path()
      ..moveTo(64, 72)
      ..lineTo(60, 86)
      ..lineTo(68, 96);
    canvas.drawPath(backLeg, legPaint);

    // --- 2. ANTENNAE ---
    final antenna1 = Path()
      ..moveTo(14, 38)
      ..lineTo(6, 32)
      ..lineTo(8, 24);
    canvas.drawPath(antenna1, legPaint);

    final antenna2 = Path()
      ..moveTo(18, 36)
      ..lineTo(14, 28)
      ..lineTo(18, 20);
    canvas.drawPath(antenna2, legPaint);

    // --- 3. ABDOMEN (Stripes: Yellow and Black Facets) ---
    // Abdomen Tip (Black stinger zone)
    drawPoly([
      const Offset(70, 68),
      const Offset(78, 76),
      const Offset(74, 80),
      const Offset(65, 74),
    ], const Color(0xFF1E1E1E));

    // Abdomen Stripe 4 (Yellow)
    drawPoly([
      const Offset(64, 60),
      const Offset(72, 66),
      const Offset(68, 75),
      const Offset(60, 68),
    ], const Color(0xFFFFB703));

    // Abdomen Stripe 3 (Black)
    drawPoly([
      const Offset(56, 52),
      const Offset(64, 60),
      const Offset(60, 68),
      const Offset(52, 62),
    ], const Color(0xFF222222));

    // Abdomen Stripe 2 (Yellow)
    drawPoly([
      const Offset(48, 44),
      const Offset(56, 52),
      const Offset(52, 62),
      const Offset(44, 55),
    ], const Color(0xFFFFC300));

    // Abdomen Stripe 1 (Black facet)
    drawPoly([
      const Offset(42, 38),
      const Offset(48, 44),
      const Offset(44, 55),
      const Offset(38, 50),
    ], const Color(0xFF1A1A1A));

    // --- 4. THORAX (Golden Poly Facets) ---
    // Thorax top facet
    drawPoly([
      const Offset(28, 36),
      const Offset(42, 32),
      const Offset(46, 44),
      const Offset(32, 48),
    ], const Color(0xFFFFD000));

    // Thorax side facet
    drawPoly([
      const Offset(32, 48),
      const Offset(46, 44),
      const Offset(44, 62),
      const Offset(28, 60),
    ], const Color(0xFFE5A100));

    // Thorax front facet
    drawPoly([
      const Offset(24, 40),
      const Offset(28, 36),
      const Offset(32, 48),
      const Offset(24, 52),
    ], const Color(0xFFFFB703));

    // --- 5. HEAD ---
    // Face main facet
    drawPoly([
      const Offset(14, 40),
      const Offset(24, 36),
      const Offset(22, 54),
      const Offset(12, 50),
    ], const Color(0xFFFFC300));

    // Snout / Jaw (Dark low poly facet)
    drawPoly([
      const Offset(12, 50),
      const Offset(22, 54),
      const Offset(18, 64),
      const Offset(12, 58),
    ], const Color(0xFF2B2B2B));

    // Top of head
    drawPoly([
      const Offset(14, 40),
      const Offset(24, 36),
      const Offset(20, 32),
      const Offset(12, 36),
    ], const Color(0xFFFFE066));

    // --- 6. WINGS (Low-poly translucent white / pale blue polygonal facets) ---
    // Back Wing Facet 1
    drawPoly([
      const Offset(44, 30),
      const Offset(70, 8),
      const Offset(84, 18),
      const Offset(58, 38),
    ], const Color(0xFFEDF6F9));

    // Back Wing Facet 2 (Vein shading)
    drawPoly([
      const Offset(58, 38),
      const Offset(84, 18),
      const Offset(88, 28),
      const Offset(62, 44),
    ], const Color(0xFFD8E2DC));

    // Fore Wing Facet 1 (Top leading edge)
    drawPoly([
      const Offset(38, 26),
      const Offset(62, 4),
      const Offset(74, 12),
      const Offset(50, 32),
    ], const Color(0xFFFFFFFF));

    // Fore Wing Facet 2 (Middle)
    drawPoly([
      const Offset(50, 32),
      const Offset(74, 12),
      const Offset(82, 22),
      const Offset(56, 38),
    ], const Color(0xFFF1FAEE));

    // Fore Wing Facet 3 (Bottom edge)
    drawPoly([
      const Offset(56, 38),
      const Offset(82, 22),
      const Offset(76, 32),
      const Offset(52, 44),
    ], const Color(0xFFE2EAFC));

    // Wing interior facet lines for origami/low-poly look
    final veinPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    canvas.drawLine(const Offset(44, 28), const Offset(74, 12), veinPaint);
    canvas.drawLine(const Offset(50, 32), const Offset(82, 22), veinPaint);
    canvas.drawLine(const Offset(46, 30), const Offset(66, 16), veinPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
