import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/account_balance.dart';

class AccountCardCarousel extends StatefulWidget {
  const AccountCardCarousel({
    super.key,
    required this.balances,
    required this.currentIndex,
    required this.onPageChanged,
    required this.onAddAccount,
    required this.onToggleActive,
    this.showBalance = true,
  });

  final List<AccountBalance> balances;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onAddAccount;
  final ValueChanged<AccountBalance> onToggleActive;
  final bool showBalance;

  @override
  State<AccountCardCarousel> createState() => _AccountCardCarouselState();
}

class _AccountCardCarouselState extends State<AccountCardCarousel> {
  late final PageController _pageController;

  static const List<List<Color>> _cardGradients = [
    [Color(0xFFD8FF3F), Color(0xFFC4F51C), Color(0xFF9ECE00)], // Neon Lime Hero
    [Color(0xFF22242D), Color(0xFF16171D), Color(0xFF0F1015)], // Obsidian Carbon
    [Color(0xFF0D9488), Color(0xFF0F766E), Color(0xFF042F2E)], // Cyber Teal
    [Color(0xFF8B5CF6), Color(0xFF6D28D9), Color(0xFF3B0764)], // Deep Violet
    [Color(0xFFEA580C), Color(0xFFC2410C), Color(0xFF7C2D12)], // Sunset Flame
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: widget.currentIndex,
      viewportFraction: 0.90,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPrevious() {
    if (_pageController.hasClients && widget.currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _goToNext(int totalCards) {
    if (_pageController.hasClients && widget.currentIndex < totalCards - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCards = widget.balances.length + 1; // Accounts + 1 Add Card slide

    return Column(
      children: [
        SizedBox(
          height: 195,
          child: Stack(
            children: [
              ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.trackpad,
                    PointerDeviceKind.stylus,
                  },
                ),
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: totalCards,
                  onPageChanged: widget.onPageChanged,
                  itemBuilder: (context, index) {
                    if (index < widget.balances.length) {
                      final balance = widget.balances[index];
                      final gradient = _cardGradients[index % _cardGradients.length];
                      final isLimeTheme = index % _cardGradients.length == 0;
                      final isSelected = widget.currentIndex == index;

                      return AnimatedScale(
                        scale: isSelected ? 1.0 : 0.94,
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        child: _DigitalWalletCard(
                          balance: balance,
                          gradient: gradient,
                          isLimeTheme: isLimeTheme,
                          showBalance: widget.showBalance,
                          onToggleActive: () => widget.onToggleActive(balance),
                        ),
                      );
                    } else {
                      // Add Card Slide
                      return AnimatedScale(
                        scale: widget.currentIndex == index ? 1.0 : 0.94,
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        child: _AddAccountCard(onTap: widget.onAddAccount),
                      );
                    }
                  },
                ),
              ),

              // Desktop Left Navigation Arrow
              if (widget.currentIndex > 0)
                Positioned(
                  left: 2,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _goToPrevious,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.chevron_left_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ),
                ),

              // Desktop Right Navigation Arrow
              if (widget.currentIndex < totalCards - 1)
                Positioned(
                  right: 2,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _goToNext(totalCards),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.chevron_right_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Pagination Dots Indicator + Quick Nav
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalCards, (idx) {
            final isActive = widget.currentIndex == idx;
            return GestureDetector(
              onTap: () {
                if (_pageController.hasClients) {
                  _pageController.animateToPage(
                    idx,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                  );
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 22 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive ? (context.isDark ? AppColors.primary : const Color(0xFF15803D)) : context.cardBorder,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _DigitalWalletCard extends StatelessWidget {
  const _DigitalWalletCard({
    required this.balance,
    required this.gradient,
    required this.isLimeTheme,
    required this.showBalance,
    required this.onToggleActive,
  });

  final AccountBalance balance;
  final List<Color> gradient;
  final bool isLimeTheme;
  final bool showBalance;
  final VoidCallback onToggleActive;

  String _formatAmount(num val, String currency) {
    final s = val.abs().toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    final prefix = currency == 'MYR' ? 'RM' : 'Rp';
    final sign = val < 0 ? '-' : '';
    return '$sign$prefix ${buffer.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    final isInactive = !balance.isActive;

    // Inactive card colors vs active theme colors
    final cardGradient = isInactive
        ? const [Color(0xFF1E2027), Color(0xFF16171D), Color(0xFF101116)]
        : gradient;
    final textColor = isInactive
        ? const Color(0xFF94A3B8)
        : (isLimeTheme ? const Color(0xFF0E0E10) : Colors.white);
    final secondaryTextColor = isInactive
        ? const Color(0xFF64748B)
        : (isLimeTheme ? const Color(0xFF384205) : Colors.white70);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: cardGradient,
        ),
        boxShadow: [
          BoxShadow(
            color: isInactive
                ? Colors.black.withValues(alpha: 0.3)
                : cardGradient.first.withValues(alpha: isLimeTheme ? 0.35 : 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isInactive
              ? Colors.white.withValues(alpha: 0.1)
              : (isLimeTheme ? Colors.transparent : Colors.white.withValues(alpha: 0.12)),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Row: Badges & Direct Action Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isInactive
                          ? Colors.white.withValues(alpha: 0.06)
                          : (isLimeTheme ? Colors.black.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.15)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      balance.type.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isInactive
                          ? Colors.white.withValues(alpha: 0.06)
                          : (isLimeTheme ? Colors.black.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.15)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      balance.currency,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (isInactive) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.orange.withValues(alpha: 0.35)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_outline_rounded, size: 12, color: AppColors.orange),
                          SizedBox(width: 4),
                          Text(
                            'INACTIVE',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: AppColors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  if (!isInactive) ...[
                    // Metallic EMV Chip for Active Card
                    Container(
                      width: 30,
                      height: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFDF7A), Color(0xFFEAB308), Color(0xFFCA8A04)],
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 22,
                          height: 12,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black26, width: 0.7),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Direct Action Button (Lock / Unlock Card)
                  GestureDetector(
                    onTap: onToggleActive,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isInactive
                            ? AppColors.green.withValues(alpha: 0.15)
                            : (isLimeTheme
                                ? Colors.black.withValues(alpha: 0.12)
                                : Colors.white.withValues(alpha: 0.14)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isInactive
                            ? Icons.lock_open_rounded
                            : Icons.lock_outline_rounded,
                        size: 15,
                        color: isInactive
                            ? AppColors.green
                            : textColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Account Name
          Row(
            children: [
              Expanded(
                child: Text(
                  balance.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: textColor,
                  ),
                ),
              ),
              if (isInactive) ...[
                const SizedBox(width: 6),
                const Text(
                  '(Deactivated)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ],
          ),

          // Bottom Row: Current Balance
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isInactive ? 'DEACTIVATED BALANCE' : 'AVAILABLE BALANCE',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  showBalance ? _formatAmount(balance.balance, balance.currency) : '••••••••',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: isInactive ? const Color(0xFF94A3B8) : textColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddAccountCard extends StatelessWidget {
  const _AddAccountCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.15),
                border: Border.all(color: AppColors.primary),
              ),
              child: const Icon(Icons.add_rounded, size: 28, color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            Text(
              'Add New Account',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Bank, E-Wallet, or Cash',
              style: TextStyle(
                fontSize: 12,
                color: context.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
