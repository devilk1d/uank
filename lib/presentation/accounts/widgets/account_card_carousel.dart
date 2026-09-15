import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../domain/entities/account_balance.dart';

class AccountCardCarousel extends StatefulWidget {
  const AccountCardCarousel({
    super.key,
    required this.balances,
    required this.currentIndex,
    required this.onPageChanged,
    required this.onAddAccount,
    required this.onDeactivate,
    this.showBalance = true,
  });

  final List<AccountBalance> balances;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onAddAccount;
  final ValueChanged<AccountBalance> onDeactivate;
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

  @override
  Widget build(BuildContext context) {
    final totalCards = widget.balances.length + 1; // Accounts + 1 Add Card slide

    return Column(
      children: [
        SizedBox(
          height: 195,
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
                    onDeactivate: () => widget.onDeactivate(balance),
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
        const SizedBox(height: 12),

        // Pagination Dots Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalCards, (idx) {
            final isActive = widget.currentIndex == idx;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 22 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.darkCardBorder,
                borderRadius: BorderRadius.circular(3),
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
    required this.onDeactivate,
  });

  final AccountBalance balance;
  final List<Color> gradient;
  final bool isLimeTheme;
  final bool showBalance;
  final VoidCallback onDeactivate;

  String _formatAmount(num val, String currency) {
    if (currency == 'MYR') {
      return 'RM ${val % 1 == 0 ? val.toStringAsFixed(0) : val.toStringAsFixed(2)}';
    }
    final s = val.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return 'Rp ${buffer.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    final textColor = isLimeTheme ? const Color(0xFF0E0E10) : Colors.white;
    final secondaryTextColor = isLimeTheme ? const Color(0xFF384205) : Colors.white70;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: isLimeTheme ? 0.35 : 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isLimeTheme ? Colors.transparent : AppColors.darkCardBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Row: Brand & Type Badge & Metallic Chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLimeTheme ? Colors.black.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.15),
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
                      color: isLimeTheme ? Colors.black.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.15),
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
                ],
              ),
              Row(
                children: [
                  // Metallic EMV Chip
                  Container(
                    width: 32,
                    height: 22,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFDF7A), Color(0xFFEAB308), Color(0xFFCA8A04)],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 24,
                        height: 14,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black26, width: 0.7),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  AppPopupMenu<String>(
                    icon: Icon(Icons.more_vert_rounded, size: 18, color: textColor),
                    onSelected: (val) {
                      if (val == 'deactivate') onDeactivate();
                    },
                    items: const [
                      AppDropdownItem(
                        value: 'deactivate',
                        label: 'Deactivate Account',
                        isDestructive: true,
                        icon: Icon(Icons.archive_outlined, size: 16, color: AppColors.red),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // Account Name
          Text(
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

          // Bottom Row: Current Balance
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AVAILABLE BALANCE',
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
                    color: textColor,
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
          color: AppColors.darkCardBg,
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
            const Text(
              'Add New Account',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.darkTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Bank, E-Wallet, or Cash',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.darkTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
