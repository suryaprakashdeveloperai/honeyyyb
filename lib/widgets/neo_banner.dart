import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/neo_brutalism_theme.dart';
import 'honeybee_logo.dart';
import 'neo_card.dart';

class NeoHeaderBanner extends StatelessWidget {
  final VoidCallback? onSmsTap;

  const NeoHeaderBanner({super.key, this.onSmsTap});

  @override
  Widget build(BuildContext context) {
    return NeoCard(
      backgroundColor: NeoColors.honeyYellow,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const HoneyBeeLogo(
                      size: 32,
                      backgroundColor: NeoColors.cardWhite,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Honeyyyb',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                              color: NeoColors.borderBlack,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'BY SURYA PRAKASH',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                              color: NeoColors.borderBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (onSmsTap != null)
                GestureDetector(
                  onTap: onSmsTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: NeoColors.neonTeal,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: NeoColors.borderBlack, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: NeoColors.borderBlack,
                          offset: Offset(2, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sms_rounded, size: 15, color: NeoColors.borderBlack),
                        const SizedBox(width: 4),
                        Text(
                          'SMS PARSER',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: NeoColors.borderBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          // Subtitle Quote Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: NeoColors.cardWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: NeoColors.borderBlack, width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: NeoColors.borderBlack,
                  offset: Offset(2.5, 2.5),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                const Text('🕷️', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '"No Matter the universe i Still choose her🕷️"',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      color: NeoColors.borderBlack,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
