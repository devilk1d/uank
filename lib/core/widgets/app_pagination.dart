import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

class AppPagination extends StatelessWidget {
  const AppPagination({
    super.key,
    required this.currentPage,
    required this.totalItems,
    required this.itemsPerPage,
    required this.onPageChanged,
    this.onItemsPerPageChanged,
    this.availablePageSizes = const [10, 25, 50, 100],
    this.itemLabel = 'entries',
    this.compact = false,
  });

  final int currentPage;
  final int totalItems;
  final int itemsPerPage;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int>? onItemsPerPageChanged;
  final List<int> availablePageSizes;
  final String itemLabel;
  final bool compact;

  int get totalPages => (totalItems / itemsPerPage).ceil().clamp(1, 999999);
  int get startItemIndex => totalItems == 0 ? 0 : ((currentPage - 1) * itemsPerPage) + 1;
  int get endItemIndex => (currentPage * itemsPerPage).clamp(0, totalItems);

  List<dynamic> _buildPageNumbers() {
    final pages = <dynamic>[];
    final total = totalPages;

    if (total <= 7) {
      for (int i = 1; i <= total; i++) {
        pages.add(i);
      }
    } else {
      pages.add(1);
      if (currentPage > 3) {
        pages.add('...');
      }

      final start = (currentPage - 1).clamp(2, total - 1);
      final end = (currentPage + 1).clamp(2, total - 1);

      for (int i = start; i <= end; i++) {
        if (!pages.contains(i)) {
          pages.add(i);
        }
      }

      if (currentPage < total - 2) {
        pages.add('...');
      }
      if (!pages.contains(total)) {
        pages.add(total);
      }
    }
    return pages;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primaryColor = isDark ? AppColors.primary : const Color(0xFF15803D);
    final borderColor = context.cardBorder;
    final textMuted = context.textSecondary;
    final hasPrev = currentPage > 1;
    final hasNext = currentPage < totalPages;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 620 || compact;

        final infoWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Showing ',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: textMuted,
              ),
            ),
            Text(
              '$startItemIndex-$endItemIndex',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            Text(
              ' of ',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: textMuted,
              ),
            ),
            Text(
              '$totalItems',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            Text(
              ' $itemLabel',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: textMuted,
              ),
            ),
            if (onItemsPerPageChanged != null) ...[
              const SizedBox(width: 14),
              Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF14161C) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor, width: 1.0),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: availablePageSizes.contains(itemsPerPage)
                        ? itemsPerPage
                        : availablePageSizes.first,
                    dropdownColor: isDark ? const Color(0xFF181B24) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    isDense: true,
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: textMuted,
                    ),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                    items: availablePageSizes.map((size) {
                      return DropdownMenuItem<int>(
                        value: size,
                        child: Text('$size / page'),
                      );
                    }).toList(),
                    onChanged: (newSize) {
                      if (newSize != null && newSize != itemsPerPage) {
                        HapticFeedback.selectionClick();
                        onItemsPerPageChanged!(newSize);
                      }
                    },
                  ),
                ),
              ),
            ],
          ],
        );

        final pageControls = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Previous Button
            _NavigationButton(
              icon: Icons.chevron_left_rounded,
              label: isNarrow ? null : 'Prev',
              isEnabled: hasPrev,
              onTap: () {
                if (hasPrev) {
                  HapticFeedback.selectionClick();
                  onPageChanged(currentPage - 1);
                }
              },
            ),
            const SizedBox(width: 6),

            // Number Pills
            ..._buildPageNumbers().map((page) {
              if (page == '...') {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '...',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                    ),
                  ),
                );
              }

              final pageNum = page as int;
              final isActive = pageNum == currentPage;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                child: InkWell(
                  onTap: () {
                    if (!isActive) {
                      HapticFeedback.selectionClick();
                      onPageChanged(pageNum);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isActive
                          ? primaryColor
                          : (isDark ? const Color(0xFF14161C) : Colors.white),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isActive ? primaryColor : borderColor,
                        width: 1.0,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: isDark ? 0.35 : 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$pageNum',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                          color: isActive
                              ? (isDark ? Colors.black : Colors.white)
                              : context.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(width: 6),
            // Next Button
            _NavigationButton(
              icon: Icons.chevron_right_rounded,
              label: isNarrow ? null : 'Next',
              isEnabled: hasNext,
              onTap: () {
                if (hasNext) {
                  HapticFeedback.selectionClick();
                  onPageChanged(currentPage + 1);
                }
              },
            ),
          ],
        );

        return Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: [
            infoWidget,
            pageControls,
          ],
        );
      },
    );
  }
}

class _NavigationButton extends StatelessWidget {
  const _NavigationButton({
    required this.icon,
    this.label,
    required this.isEnabled,
    required this.onTap,
  });

  final IconData icon;
  final String? label;
  final bool isEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final borderColor = context.cardBorder;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          height: 32,
          padding: EdgeInsets.symmetric(
            horizontal: label != null ? 8 : 6,
          ),
          decoration: BoxDecoration(
            color: isEnabled
                ? (isDark ? const Color(0xFF14161C) : Colors.white)
                : (isDark ? const Color(0xFF0F1015) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isEnabled ? borderColor : borderColor.withValues(alpha: 0.4),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (label != null && icon == Icons.chevron_left_rounded) ...[
                Icon(
                  icon,
                  size: 16,
                  color: isEnabled ? context.textPrimary : context.textMuted,
                ),
                const SizedBox(width: 2),
                Text(
                  label!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isEnabled ? context.textPrimary : context.textMuted,
                  ),
                ),
              ] else if (label != null) ...[
                Text(
                  label!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isEnabled ? context.textPrimary : context.textMuted,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  icon,
                  size: 16,
                  color: isEnabled ? context.textPrimary : context.textMuted,
                ),
              ] else ...[
                Icon(
                  icon,
                  size: 16,
                  color: isEnabled ? context.textPrimary : context.textMuted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
