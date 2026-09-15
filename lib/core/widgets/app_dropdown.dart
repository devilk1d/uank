import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// Item definition for custom dropdowns and popup menus across the app.
class AppDropdownItem<T> {
  final T value;
  final String label;
  final String? subtitle;
  final Widget? icon;
  final Widget? trailing;
  final bool isDestructive;

  const AppDropdownItem({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
    this.trailing,
    this.isDestructive = false,
  });
}

/// A compact, sleek pill/button dropdown for filters, timeframe pickers, and view options.
/// Adapts dynamically to light and dark modes.
class AppFilterDropdown<T> extends StatelessWidget {
  const AppFilterDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.icon,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    this.textStyle,
    this.chevronColor,
  });

  final T value;
  final List<AppDropdownItem<T>> items;
  final ValueChanged<T> onChanged;
  final Widget? icon;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final EdgeInsets padding;
  final TextStyle? textStyle;
  final Color? chevronColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedItem = items.firstWhere(
      (item) => item.value == value,
      orElse: () => items.isNotEmpty ? items.first : AppDropdownItem<T>(value: value, label: '$value'),
    );

    final bg = backgroundColor ?? (isDark ? Colors.black45 : Colors.white);
    final border = borderColor ?? (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder);
    final txtColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: () => _showMenu(context),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: border),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: 5),
              ] else if (selectedItem.icon != null) ...[
                selectedItem.icon!,
                const SizedBox(width: 5),
              ],
              Text(
                selectedItem.label,
                style: textStyle ??
                    GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: txtColor,
                    ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: chevronColor ?? txtColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        renderBox.localToGlobal(Offset.zero, ancestor: overlay),
        renderBox.localToGlobal(renderBox.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final selected = await showMenu<T>(
      context: context,
      position: position,
      color: isDark ? AppColors.darkCardBg : Colors.white,
      elevation: 16,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.8 : 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
          width: 1.2,
        ),
      ),
      items: items.map((item) {
        final isSelected = item.value == value;
        return PopupMenuItem<T>(
          value: item.value,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark ? AppColors.primary.withValues(alpha: 0.12) : const Color(0xFF15803D).withValues(alpha: 0.08))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(
                      color: isDark ? AppColors.primary.withValues(alpha: 0.3) : const Color(0xFF15803D).withValues(alpha: 0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.icon != null) ...[
                  item.icon!,
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    item.label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? (isDark ? AppColors.primary : const Color(0xFF15803D))
                          : (isDark ? Colors.white : AppColors.lightTextPrimary),
                    ),
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: isDark ? AppColors.primary : const Color(0xFF15803D),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );

    if (selected != null) {
      onChanged(selected);
    }
  }
}

/// A form field dropdown that matches the input styling and opens
/// an interactive, searchable bottom sheet selector with custom items.
class AppDropdownFormField<T> extends FormField<T> {
  final T? value;

  AppDropdownFormField({
    super.key,
    this.value,
    T? initialValue,
    required List<AppDropdownItem<T>> items,
    required ValueChanged<T?>? onChanged,
    String? labelText,
    String? hintText,
    Widget? prefixIcon,
    super.validator,
    bool enableSearch = false,
    String? sheetTitle,
  }) : super(
          initialValue: value ?? initialValue,
          builder: (FormFieldState<T> state) {
            return _AppDropdownFieldContent<T>(
              state: state,
              items: items,
              onChanged: onChanged,
              labelText: labelText,
              hintText: hintText,
              prefixIcon: prefixIcon,
              enableSearch: enableSearch || items.length > 6,
              sheetTitle: sheetTitle,
            );
          },
        );

  @override
  FormFieldState<T> createState() => _AppDropdownFormFieldState<T>();
}

class _AppDropdownFormFieldState<T> extends FormFieldState<T> {
  @override
  AppDropdownFormField<T> get widget => super.widget as AppDropdownFormField<T>;

  @override
  void didUpdateWidget(AppDropdownFormField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != value) {
      setValue(widget.value);
    } else if (widget.initialValue != oldWidget.initialValue && widget.initialValue != value) {
      setValue(widget.initialValue);
    }
  }
}

class _AppDropdownFieldContent<T> extends StatelessWidget {
  const _AppDropdownFieldContent({
    required this.state,
    required this.items,
    required this.onChanged,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.enableSearch = false,
    this.sheetTitle,
  });

  final FormFieldState<T> state;
  final List<AppDropdownItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final bool enableSearch;
  final String? sheetTitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedItem = items.where((item) => item.value == state.value).firstOrNull;
    final hasError = state.hasError;

    final cardBg = isDark ? AppColors.darkCardBg : Colors.white;
    final cardBorder = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (labelText != null) ...[
          Text(
            labelText!,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: hasError ? AppColors.red : textSecondary,
            ),
          ),
          const SizedBox(height: 6),
        ],
        GestureDetector(
          onTap: onChanged == null ? null : () => _openSheet(context),
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasError ? AppColors.red : cardBorder,
                width: hasError ? 1.5 : 1.0,
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              children: [
                if (prefixIcon != null) ...[
                  prefixIcon!,
                  const SizedBox(width: 10),
                ] else if (selectedItem?.icon != null) ...[
                  selectedItem!.icon!,
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: selectedItem != null
                      ? Text(
                          selectedItem.label,
                          style: GoogleFonts.plusJakartaSans(
                            color: textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : Text(
                          hintText ?? 'Select option',
                          style: GoogleFonts.plusJakartaSans(
                            color: textMuted,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: isDark ? AppColors.primary : textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              state.errorText ?? '',
              style: const TextStyle(color: AppColors.red, fontSize: 11),
            ),
          ),
        ],
      ],
    );
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AppDropdownSheet<T>(
        title: sheetTitle ?? labelText ?? 'Select Option',
        items: items,
        selectedValue: state.value,
        enableSearch: enableSearch,
        onSelected: (val) {
          state.didChange(val);
          onChanged?.call(val);
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

class _AppDropdownSheet<T> extends StatefulWidget {
  const _AppDropdownSheet({
    required this.title,
    required this.items,
    required this.selectedValue,
    required this.onSelected,
    this.enableSearch = false,
  });

  final String title;
  final List<AppDropdownItem<T>> items;
  final T? selectedValue;
  final ValueChanged<T> onSelected;
  final bool enableSearch;

  @override
  State<_AppDropdownSheet<T>> createState() => _AppDropdownSheetState<T>();
}

class _AppDropdownSheetState<T> extends State<_AppDropdownSheet<T>> {
  final _searchController = TextEditingController();
  late List<AppDropdownItem<T>> _filteredItems;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _filteredItems = widget.items);
    } else {
      setState(() {
        _filteredItems = widget.items.where((it) {
          final matchLabel = it.label.toLowerCase().contains(q);
          final matchSub = it.subtitle?.toLowerCase().contains(q) ?? false;
          return matchLabel || matchSub;
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.75;

    final cardBg = isDark ? AppColors.darkCardBg : Colors.white;
    final cardBorder = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final itemUnselectedBg = isDark ? const Color(0xFF202128) : const Color(0xFFF8FAFC);

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: cardBorder, width: 1.5),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textMuted.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close_rounded, size: 18, color: textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Optional Search Bar
          if (widget.enableSearch) ...[
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? Colors.black45 : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cardBorder),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, size: 18, color: textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: textMuted),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () => _searchController.clear(),
                      child: Icon(Icons.clear_rounded, size: 16, color: textSecondary),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Item List
          Flexible(
            child: _filteredItems.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'No matching options',
                        style: GoogleFonts.plusJakartaSans(
                          color: textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: _filteredItems.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final item = _filteredItems[idx];
                      final isSelected = item.value == widget.selectedValue;

                      return GestureDetector(
                        onTap: () => widget.onSelected(item.value),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? AppColors.primary.withValues(alpha: 0.12) : const Color(0xFF15803D).withValues(alpha: 0.08))
                                : itemUnselectedBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? (isDark ? AppColors.primary : const Color(0xFF15803D))
                                  : cardBorder.withValues(alpha: 0.6),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              if (item.icon != null) ...[
                                item.icon!,
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      item.label,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                        color: isSelected
                                            ? (isDark ? AppColors.primary : const Color(0xFF15803D))
                                            : textPrimary,
                                      ),
                                    ),
                                    if (item.subtitle != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        item.subtitle!,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (item.trailing != null) ...[
                                const SizedBox(width: 8),
                                item.trailing!,
                              ],
                              if (isSelected) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: isDark ? AppColors.primary : const Color(0xFF15803D),
                                  size: 20,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// A reusable 3-dots action popup menu matching the light and dark theme.
class AppPopupMenu<T> extends StatelessWidget {
  const AppPopupMenu({
    super.key,
    required this.items,
    required this.onSelected,
    this.icon,
    this.tooltip,
  });

  final List<AppDropdownItem<T>> items;
  final ValueChanged<T> onSelected;
  final Widget? icon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCardBg : Colors.white;
    final cardBorder = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return PopupMenuButton<T>(
      tooltip: tooltip,
      color: cardBg,
      elevation: 16,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.8 : 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cardBorder, width: 1.2),
      ),
      icon: icon ?? Icon(Icons.more_vert_rounded, size: 18, color: textSecondary),
      onSelected: onSelected,
      itemBuilder: (_) => items.map((item) {
        return PopupMenuItem<T>(
          value: item.value,
          height: 38,
          child: Row(
            children: [
              if (item.icon != null) ...[
                item.icon!,
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  item.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: item.isDestructive ? AppColors.red : textPrimary,
                  ),
                ),
              ),
              if (item.trailing != null) ...[
                const SizedBox(width: 6),
                item.trailing!,
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}
