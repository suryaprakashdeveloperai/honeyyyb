import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/neo_brutalism_theme.dart';
import 'honey_ai_avatar_widget.dart';
import 'snapchat_ai_chat_modal.dart';

/// Free-Floating Draggable Honey AI Bubble that can be dragged to any part of the screen
class FloatingHoneyAiBubble extends StatefulWidget {
  final String currentScreenName;
  final VoidCallback? onTap;

  const FloatingHoneyAiBubble({
    super.key,
    this.currentScreenName = 'Dashboard',
    this.onTap,
  });

  @override
  State<FloatingHoneyAiBubble> createState() => _FloatingHoneyAiBubbleState();
}

class _FloatingHoneyAiBubbleState extends State<FloatingHoneyAiBubble> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  // Draggable position coordinates
  Offset? _position;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 0.97, end: 1.04).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _snapToScreenEdge(Size screenSize) {
    if (_position == null) return;
    const double margin = 16.0;
    const double bubbleWidth = 140.0;
    final double midX = screenSize.width / 2;

    double targetX = _position!.dx < midX ? margin : screenSize.width - bubbleWidth - margin;
    double targetY = _position!.dy.clamp(60.0, screenSize.height - 150.0);

    setState(() {
      _position = Offset(targetX, targetY);
      _isDragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // Default initial position near bottom-left above bottom navigation bar
    _position ??= Offset(16.0, screenSize.height - 165.0);

    return Positioned(
      left: _position!.dx,
      top: _position!.dy,
      child: GestureDetector(
        onPanStart: (_) => setState(() => _isDragging = true),
        onPanUpdate: (details) {
          setState(() {
            final double newX = (_position!.dx + details.delta.dx).clamp(8.0, screenSize.width - 145.0);
            final double newY = (_position!.dy + details.delta.dy).clamp(40.0, screenSize.height - 120.0);
            _position = Offset(newX, newY);
          });
        },
        onPanEnd: (_) => _snapToScreenEdge(screenSize),
        child: ScaleTransition(
          scale: _isDragging ? const AlwaysStoppedAnimation(1.08) : _scaleAnim,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (widget.onTap != null) {
                  widget.onTap!();
                } else {
                  SnapchatAiChatModal.show(
                    context,
                    currentScreenName: widget.currentScreenName,
                  );
                }
              },
              borderRadius: BorderRadius.circular(30),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: NeoColors.honeyYellow,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: _isDragging ? NeoColors.primaryPink : NeoColors.borderBlack,
                    width: _isDragging ? 3.5 : 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: NeoColors.borderBlack.withValues(alpha: _isDragging ? 0.45 : 0.25),
                      offset: _isDragging ? const Offset(4, 6) : const Offset(2, 3),
                      blurRadius: _isDragging ? 6 : 0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const HoneyAiAvatarWidget(
                      size: 34,
                      showOnlineIndicator: true,
                      showBorder: false,
                    ),
                    const SizedBox(width: 6),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'HONEY AI',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: NeoColors.borderBlack,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Text('🌸', style: TextStyle(fontSize: 9)),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Ask Co-Pilot',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: NeoColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Icon(Icons.drag_indicator_rounded, size: 10, color: Colors.black45),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
