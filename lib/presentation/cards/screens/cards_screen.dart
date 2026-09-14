import 'package:flutter/material.dart';
import '../../../core/theme/app_background.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_card.dart';
import '../../../core/widgets/circular_progress_badge.dart';
import '../../../core/widgets/digital_card_widget.dart';
import '../../../core/widgets/segmented_progress_bar.dart';

class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  int _selectedCardType = 1; // 0: Physical, 1: Virtual
  bool _isFrozen = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CircleIconButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: () {},
                  ),
                  const Text(
                    'Cards',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkTextPrimary,
                    ),
                  ),
                  _CircleIconButton(
                    icon: Icons.more_horiz_rounded,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Physical / Virtual Segmented Switcher
              Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.darkCardBg,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.darkCardBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SegmentTab(
                        label: 'Physical',
                        isActive: _selectedCardType == 0,
                        onTap: () => setState(() => _selectedCardType = 0),
                      ),
                      _SegmentTab(
                        label: 'Virtual',
                        isActive: _selectedCardType == 1,
                        onTap: () => setState(() => _selectedCardType = 1),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // Digital Card
              DigitalCardWidget(
                cardName: _selectedCardType == 0 ? 'UANK PHYSICAL' : 'LUMEN',
                balance: _selectedCardType == 0 ? 8450.50 : 12245.08,
                gradientColors: _selectedCardType == 0
                    ? const [Color(0xFF3B82F6), Color(0xFF1D4ED8), Color(0xFF1E3A8A)]
                    : const [Color(0xFF8B5CF6), Color(0xFF6D28D9), Color(0xFF3B0764)],
              ),
              const SizedBox(height: 24),

              // 4 Quick Card Action Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CardActionItem(
                    icon: Icons.visibility_outlined,
                    label: 'Details',
                    onTap: () {},
                  ),
                  _CardActionItem(
                    icon: Icons.ac_unit_rounded,
                    label: _isFrozen ? 'Unfreeze' : 'Freeze',
                    isActive: _isFrozen,
                    onTap: () => setState(() => _isFrozen = !_isFrozen),
                  ),
                  _CardActionItem(
                    icon: Icons.tune_rounded,
                    label: 'Limits',
                    onTap: () {},
                  ),
                  _CardActionItem(
                    icon: Icons.lock_outline_rounded,
                    label: 'PIN',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 26),

              // Spent in August Section
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkTextPrimary,
                            ),
                            children: [
                              TextSpan(text: 'Spent in '),
                              TextSpan(
                                text: 'August',
                                style: TextStyle(
                                  color: AppColors.orange,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          '\$1,567.00',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const SegmentedProgressBar(
                      height: 7,
                      legendSpacing: 14,
                      items: [
                        SegmentItem(
                          label: 'Food',
                          subtitle: '\$476',
                          value: 476,
                          color: Color(0xFF8B5CF6),
                        ),
                        SegmentItem(
                          label: 'Transport',
                          subtitle: '\$107',
                          value: 107,
                          color: Color(0xFF2DD4BF),
                        ),
                        SegmentItem(
                          label: 'Health',
                          subtitle: '\$215',
                          value: 215,
                          color: Color(0xFFFB923C),
                        ),
                        SegmentItem(
                          label: 'Shopping',
                          subtitle: '\$300',
                          value: 300,
                          color: Color(0xFF38BDF8),
                        ),
                        SegmentItem(
                          label: 'Utilities',
                          subtitle: '\$160',
                          value: 160,
                          color: Color(0xFFF472B6),
                        ),
                        SegmentItem(
                          label: 'Other',
                          subtitle: '\$309',
                          value: 309,
                          color: Color(0xFFA78BFA),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Monthly Card Limit Card
              GlassCard(
                child: Row(
                  children: [
                    const CircularProgressBadge(
                      percentage: 0.56,
                      size: 52,
                      strokeWidth: 4.5,
                      progressColor: AppColors.orange,
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monthly card limit',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkTextPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '\$1,567 of \$3,000 spent',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.darkTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: const Text(
                        'Adjust',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.darkCardBg,
          border: Border.all(color: AppColors.darkCardBorder),
        ),
        child: Icon(icon, size: 18, color: AppColors.darkTextPrimary),
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  const _SegmentTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.black : AppColors.darkTextSecondary,
          ),
        ),
      ),
    );
  }
}

class _CardActionItem extends StatelessWidget {
  const _CardActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? AppColors.primary : AppColors.darkCardBg,
              border: Border.all(
                color: isActive ? AppColors.primaryLight : AppColors.darkCardBorder,
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isActive ? Colors.white : AppColors.darkTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.darkTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
