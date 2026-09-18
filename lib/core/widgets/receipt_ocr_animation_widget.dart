import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class ReceiptOcrAnimationWidget extends StatefulWidget {
  const ReceiptOcrAnimationWidget({
    super.key,
    this.height = 200,
  });

  final double height;

  @override
  State<ReceiptOcrAnimationWidget> createState() => _ReceiptOcrAnimationWidgetState();
}

class _ReceiptOcrAnimationWidgetState extends State<ReceiptOcrAnimationWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _scanAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primaryAccent = isDark ? AppColors.primary : const Color(0xFF15803D);
    final cardBgColor = isDark ? const Color(0xFF12141A) : Colors.white;
    final receiptBgColor = isDark ? const Color(0xFF181B24) : const Color(0xFFF8FAFC);
    final textMutedColor = isDark ? Colors.white38 : Colors.black38;

    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? primaryAccent.withValues(alpha: 0.25)
              : primaryAccent.withValues(alpha: 0.18),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryAccent.withValues(alpha: isDark ? 0.08 : 0.05),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background grid pattern / subtle ambiance glow
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryAccent.withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              left: -40,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.teal.withValues(alpha: 0.06),
                ),
              ),
            ),

            // Stylized Digital Receipt Card
            Center(
              child: Container(
                width: 280,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: receiptBgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Receipt Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: primaryAccent.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.receipt_long_rounded,
                                  size: 13,
                                  color: primaryAccent,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'FamilyMart KLCC',
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: context.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '18/09/2026',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: textMutedColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Dashed Divider
                    Row(
                      children: List.generate(
                        22,
                        (i) => Expanded(
                          child: Container(
                            height: 1,
                            color: i.isEven
                                ? (isDark ? Colors.white12 : const Color(0xFFCBD5E1))
                                : Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Line Items
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '1x Matcha Latte',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: context.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'RM 9.90',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '1x Oden Set',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: context.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'RM 15.50',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Total Row with Highlighted Pill
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TOTAL',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: context.textPrimary,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: primaryAccent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: primaryAccent.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            'RM 25.40',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: primaryAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Corner Scanner Brackets
            Positioned(
              left: 20,
              top: 20,
              child: _ScannerBracket(color: primaryAccent, position: _BracketPos.topLeft),
            ),
            Positioned(
              right: 20,
              top: 20,
              child: _ScannerBracket(color: primaryAccent, position: _BracketPos.topRight),
            ),
            Positioned(
              left: 20,
              bottom: 20,
              child: _ScannerBracket(color: primaryAccent, position: _BracketPos.bottomLeft),
            ),
            Positioned(
              right: 20,
              bottom: 20,
              child: _ScannerBracket(color: primaryAccent, position: _BracketPos.bottomRight),
            ),

            // Moving Laser Scan Beam
            AnimatedBuilder(
              animation: _scanAnimation,
              builder: (context, child) {
                return Positioned(
                  top: 26 + (widget.height - 72) * _scanAnimation.value,
                  left: 30,
                  right: 30,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              primaryAccent.withValues(alpha: 0.4),
                              primaryAccent,
                              primaryAccent.withValues(alpha: 0.4),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryAccent.withValues(alpha: 0.7),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 14,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              primaryAccent.withValues(alpha: 0.2),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Floating Detected Badges (Animated pulse)
            Positioned(
              bottom: 12,
              right: 22,
              child: AnimatedBuilder(
                animation: _scanAnimation,
                builder: (context, child) {
                  final isDetected = _scanAnimation.value > 0.4;
                  return AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: isDetected ? 1.0 : 0.4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isDark ? const Color(0xFF0F172A) : Colors.white).withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primaryAccent.withValues(alpha: 0.4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 11, color: primaryAccent),
                          const SizedBox(width: 4),
                          Text(
                            'Auto-Fill Detected',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: primaryAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _BracketPos { topLeft, topRight, bottomLeft, bottomRight }

class _ScannerBracket extends StatelessWidget {
  const _ScannerBracket({
    required this.color,
    required this.position,
  });

  final Color color;
  final _BracketPos position;

  @override
  Widget build(BuildContext context) {
    const size = 16.0;
    const thickness = 2.5;

    Border border;
    switch (position) {
      case _BracketPos.topLeft:
        border = Border(
          top: BorderSide(color: color, width: thickness),
          left: BorderSide(color: color, width: thickness),
        );
        break;
      case _BracketPos.topRight:
        border = Border(
          top: BorderSide(color: color, width: thickness),
          right: BorderSide(color: color, width: thickness),
        );
        break;
      case _BracketPos.bottomLeft:
        border = Border(
          bottom: BorderSide(color: color, width: thickness),
          left: BorderSide(color: color, width: thickness),
        );
        break;
      case _BracketPos.bottomRight:
        border = Border(
          bottom: BorderSide(color: color, width: thickness),
          right: BorderSide(color: color, width: thickness),
        );
        break;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(border: border),
    );
  }
}
