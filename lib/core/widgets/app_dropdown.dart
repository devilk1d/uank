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
/// Matches the neo-fintech dark obsidian and electric lime theme.
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
    final selectedItem = items.firstWhere(
      (item) => item.value == value,
      orElse: () => items.isNotEmpty ? items.first : AppDropdownItem<T>(value: value, label: '$value'),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: () => _showMenu(context),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.black45,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: borderColor ?? AppColors.darkCardBorder),
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
                      color: AppColors.darkTextSecondary,
                    ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: chevronColor ?? AppColors.darkTextSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) async {
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
      color: AppColors.darkCardBg,
      elevation: 16,
      shadowColor: Colors.black.withValues(alpha: 0.8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.darkCardBorder, width: 1.2),
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
              color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1)
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
                      color: isSelected ? AppColors.primary : Colors.white,
                    ),
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: AppColors.primary,
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

/// A form field dropdown that matches the neo-fintech input styling and opens
/// an interactive, searchable dark bottom sheet selector with custom items.
class AppDropdownFormField<T> extends FormField<T> {
  AppDropdownFormField({
    super.key,
    super.initialValue,
    required List<AppDropdownItem<T>> items,
    required ValueChanged<T?>? onChanged,
    String? labelText,
    String? hintText,
    Widget? prefixIcon,
    super.validator,
    bool enableSearch = false,
    String? sheetTitle,
  }) : super(
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
    final selectedItem = items.where((item) => item.value == state.value).firstOrNull;
    final hasError = state.hasError;

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
              color: hasError ? AppColors.red : AppColors.darkTextSecondary,
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
              color: AppColors.darkCardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasError ? AppColors.red : AppColors.darkCardBorder,
                width: hasError ? 1.5 : 1.0,
              ),
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
                            color: AppColors.darkTextPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : Text(
                          hintText ?? 'Select option',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.darkTextMuted,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primary,
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.75;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: AppColors.darkCardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.darkCardBorder, width: 1.5),
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
                color: AppColors.darkTextMuted,
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
                    color: AppColors.darkTextPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, size: 18, color: AppColors.darkTextSecondary),
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
                color: Colors.black45,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.darkCardBorder),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, size: 18, color: AppColors.darkTextSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.darkTextPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.darkTextMuted),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () => _searchController.clear(),
                      child: const Icon(Icons.clear_rounded, size: 16, color: AppColors.darkTextSecondary),
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
                          color: AppColors.darkTextMuted,
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
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : const Color(0xFF202128),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.darkCardBorder.withValues(alpha: 0.6),
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
                                        color: isSelected ? AppColors.primary : AppColors.darkTextPrimary,
                                      ),
                                    ),
                                    if (item.subtitle != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        item.subtitle!,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: AppColors.darkTextSecondary,
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
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primary,
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

/// A reusable 3-dots action popup menu matching the obsidian & neon theme.
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
    return PopupMenuButton<T>(
      tooltip: tooltip,
      color: AppColors.darkCardBg,
      elevation: 16,
      shadowColor: Colors.black.withValues(alpha: 0.8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.darkCardBorder, width: 1.2),
      ),
      icon: icon ?? const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.darkTextSecondary),
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
                    color: item.isDestructive ? AppColors.red : Colors.white,
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
