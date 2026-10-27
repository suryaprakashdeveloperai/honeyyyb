import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/neo_brutalism_theme.dart';

class NeoTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType keyboardType;
  final int maxLines;
  final IconData? prefixIcon;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  const NeoTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.prefixIcon,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
            color: NeoColors.borderBlack,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: NeoTheme.neoBoxDecoration(
            backgroundColor: NeoColors.cardWhite,
            sOffset: const Offset(3, 3),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            onChanged: onChanged,
            validator: validator,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: NeoColors.borderBlack,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.plusJakartaSans(
                color: Colors.black38,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: NeoColors.borderBlack)
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
