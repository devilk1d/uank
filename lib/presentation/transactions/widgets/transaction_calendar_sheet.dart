import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

class TransactionCalendarSheet extends StatefulWidget {
  const TransactionCalendarSheet({
    super.key,
    this.startDate,
    this.endDate,
    required this.activeDates,
    required this.onDateRangeSelected,
    required this.onMonthSelected,
    required this.onClearFilter,
    this.dailySummaryMap,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final Set<DateTime> activeDates;
  final void Function(DateTime start, DateTime? end) onDateRangeSelected;
  final ValueChanged<DateTime> onMonthSelected;
  final VoidCallback onClearFilter;
  final Map<DateTime, String>? dailySummaryMap;

  static Future<void> show(
    BuildContext context, {
    required DateTime? startDate,
    DateTime? endDate,
    required Set<DateTime> activeDates,
    required void Function(DateTime start, DateTime? end) onDateRangeSelected,
    required ValueChanged<DateTime> onMonthSelected,
    required VoidCallback onClearFilter,
    Map<DateTime, String>? dailySummaryMap,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionCalendarSheet(
        startDate: startDate,
        endDate: endDate,
        activeDates: activeDates,
        onDateRangeSelected: onDateRangeSelected,
        onMonthSelected: onMonthSelected,
        onClearFilter: onClearFilter,
        dailySummaryMap: dailySummaryMap,
      ),
    );
  }

  @override
  State<TransactionCalendarSheet> createState() => _TransactionCalendarSheetState();
}

class _TransactionCalendarSheetState extends State<TransactionCalendarSheet> {
  late DateTime _viewMonth;
  DateTime? _tempStartDate;
  DateTime? _tempEndDate;
  DateTime? _dragAnchorDate;
  DateTime? _tapDownDate;
  bool _hasMovedDuringPan = false;

  bool _isPickerMode = false;
  bool _isYearListMode = false;
  late int _pickerYear;

  final _monthNames = const [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _tempStartDate = widget.startDate;
    _tempEndDate = widget.endDate;
    final base = widget.startDate ?? DateTime.now();
    _viewMonth = DateTime(base.year, base.month);
    _pickerYear = _viewMonth.year;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _hasActivity(DateTime date) {
    return widget.activeDates.any((d) => _isSameDay(d, date));
  }

  void _prevMonth() {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1);
      _pickerYear = _viewMonth.year;
    });
  }

  void _nextMonth() {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1);
      _pickerYear = _viewMonth.year;
    });
  }

  void _prevYear() {
    setState(() {
      _pickerYear--;
    });
  }

  void _nextYear() {
    setState(() {
      _pickerYear++;
    });
  }

  void _handleDateTapped(DateTime date) {
    setState(() {
      if (_tempStartDate != null &&
          _isSameDay(_tempStartDate!, date) &&
          (_tempEndDate == null || _isSameDay(_tempEndDate!, date))) {
        // Deselect if tapping the already selected single date
        _tempStartDate = null;
        _tempEndDate = null;
      } else {
        // Select this individual date
        _tempStartDate = date;
        _tempEndDate = null;
      }
    });
  }

  DateTime? _getDateFromPosition(
    Offset localPos,
    double gridWidth,
    int totalRows,
    int startOffset,
    int daysInMonth,
  ) {
    final cellWidth = gridWidth / 7;
    const cellHeight = 46.0;

    if (localPos.dx < 0 || localPos.dx >= gridWidth || localPos.dy < 0) return null;
    final col = (localPos.dx / cellWidth).floor().clamp(0, 6);
    final row = (localPos.dy / cellHeight).floor().clamp(0, totalRows - 1);
    final cellIdx = (row * 7) + col;
    final dayNumber = cellIdx - startOffset + 1;
    if (dayNumber < 1 || dayNumber > daysInMonth) return null;
    return DateTime(_viewMonth.year, _viewMonth.month, dayNumber);
  }

  int _countTransactionsInRange(DateTime start, DateTime end) {
    int total = 0;
    var curr = DateTime(start.year, start.month, start.day);
    final endLimit = DateTime(end.year, end.month, end.day);

    while (!curr.isAfter(endLimit)) {
      if (widget.dailySummaryMap != null && widget.dailySummaryMap!.containsKey(curr)) {
        final text = widget.dailySummaryMap![curr]!;
        final match = RegExp(r'(\d+)').firstMatch(text);
        if (match != null) {
          total += int.tryParse(match.group(1)!) ?? 1;
        } else {
          total += 1;
        }
      } else if (_hasActivity(curr)) {
        total += 1;
      }
      curr = curr.add(const Duration(days: 1));
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final now = DateTime.now();

    // Days calculation for current viewMonth
    final firstDayOfMonth = DateTime(_viewMonth.year, _viewMonth.month, 1);
    final startOffset = firstDayOfMonth.weekday - 1; // Mon = 0
    final daysInMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;
    final totalCells = startOffset + daysInMonth;
    final totalRows = (totalCells / 7).ceil();

    final hasActiveFilter = widget.startDate != null;
    final currentMonthName = _monthNames[_viewMonth.month - 1];

    final isRangeSelected = _tempStartDate != null &&
        _tempEndDate != null &&
        !_isSameDay(_tempStartDate!, _tempEndDate!);
    final isSingleSelected = _tempStartDate != null &&
        (_tempEndDate == null || _isSameDay(_tempStartDate!, _tempEndDate!));

    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: context.cardBorder, width: 1.5),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomInset),
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
                color: context.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header: Close / Back Button & Month/Year Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Close or Back button
              GestureDetector(
                onTap: () {
                  if (_isYearListMode) {
                    setState(() => _isYearListMode = false);
                  } else if (_isPickerMode) {
                    setState(() => _isPickerMode = false);
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: context.isDark ? const Color(0xFF22242D) : AppColors.lightBackground,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.cardBorder),
                  ),
                  child: Icon(
                    _isPickerMode ? Icons.arrow_back_rounded : Icons.close_rounded,
                    size: 18,
                    color: context.textPrimary,
                  ),
                ),
              ),

              // Interactive Month & Year Navigator / Switcher
              if (!_isPickerMode)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left_rounded, size: 22, color: context.textSecondary),
                      onPressed: _prevMonth,
                      visualDensity: VisualDensity.compact,
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _pickerYear = _viewMonth.year;
                          _isPickerMode = true;
                          _isYearListMode = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: context.isDark ? const Color(0xFF22242D) : AppColors.lightBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.cardBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$currentMonthName ${_viewMonth.year}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: context.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.chevron_right_rounded, size: 22, color: context.textSecondary),
                      onPressed: _nextMonth,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                )
              else
                // Year Header in Picker Mode
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left_rounded, size: 22, color: context.textSecondary),
                      onPressed: _prevYear,
                      visualDensity: VisualDensity.compact,
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() => _isYearListMode = !_isYearListMode);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: context.isDark ? const Color(0xFF22242D) : AppColors.lightBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isYearListMode ? AppColors.primary : context.cardBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$_pickerYear',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: context.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _isYearListMode
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.chevron_right_rounded, size: 22, color: context.textSecondary),
                      onPressed: _nextYear,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),

              // Filter Month Button or Done Button
              if (!_isPickerMode)
                GestureDetector(
                  onTap: () {
                    widget.onMonthSelected(_viewMonth);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: context.isDark ? const Color(0xFF22242D) : AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.cardBorder),
                    ),
                    child: Text(
                      'All Month',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                )
              else
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isPickerMode = false;
                      _isYearListMode = false;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: context.isDark ? const Color(0xFF22242D) : AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.cardBorder),
                    ),
                    child: Text(
                      'Done',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),

          // Content Switcher: Days Grid vs Month Selector vs Year List
          if (_isYearListMode)
            _buildYearGrid()
          else if (_isPickerMode)
            _buildMonthGrid()
          else ...[
            // Day of Week Headers (M T W T F S S)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                _WeekdayLabel('M'),
                _WeekdayLabel('T'),
                _WeekdayLabel('W'),
                _WeekdayLabel('T'),
                _WeekdayLabel('F'),
                _WeekdayLabel('S'),
                _WeekdayLabel('S'),
              ],
            ),
            const SizedBox(height: 12),

            // Calendar Grid with Slide / Drag gesture support
            LayoutBuilder(
              builder: (context, constraints) {
                final gridWidth = constraints.maxWidth;
                final cellWidth = gridWidth / 7;

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) {
                    final date = _getDateFromPosition(
                      details.localPosition,
                      gridWidth,
                      totalRows,
                      startOffset,
                      daysInMonth,
                    );
                    _tapDownDate = date;
                  },
                  onTapUp: (details) {
                    final date = _getDateFromPosition(
                      details.localPosition,
                      gridWidth,
                      totalRows,
                      startOffset,
                      daysInMonth,
                    );
                    final targetDate = date ?? _tapDownDate;
                    if (targetDate != null) {
                      _handleDateTapped(targetDate);
                    }
                    _tapDownDate = null;
                  },
                  onTapCancel: () {
                    _tapDownDate = null;
                  },
                  onPanStart: (details) {
                    final date = _getDateFromPosition(
                      details.localPosition,
                      gridWidth,
                      totalRows,
                      startOffset,
                      daysInMonth,
                    );
                    if (date != null) {
                      _dragAnchorDate = date;
                      _hasMovedDuringPan = false;
                    }
                  },
                  onPanUpdate: (details) {
                    final date = _getDateFromPosition(
                      details.localPosition,
                      gridWidth,
                      totalRows,
                      startOffset,
                      daysInMonth,
                    );
                    if (date != null && _dragAnchorDate != null) {
                      if (!_isSameDay(date, _dragAnchorDate!)) {
                        _hasMovedDuringPan = true;
                        setState(() {
                          if (date.isBefore(_dragAnchorDate!)) {
                            _tempStartDate = date;
                            _tempEndDate = _dragAnchorDate;
                          } else {
                            _tempStartDate = _dragAnchorDate;
                            _tempEndDate = date;
                          }
                        });
                      } else if (_hasMovedDuringPan) {
                        setState(() {
                          _tempStartDate = _dragAnchorDate;
                          _tempEndDate = null;
                        });
                      }
                    }
                  },
                  onPanEnd: (_) {
                    _dragAnchorDate = null;
                    _hasMovedDuringPan = false;
                  },
                  onPanCancel: () {
                    _dragAnchorDate = null;
                    _hasMovedDuringPan = false;
                  },
                  child: Table(
                    children: List.generate(totalRows, (rowIdx) {
                      return TableRow(
                        children: List.generate(7, (colIdx) {
                          final cellIdx = (rowIdx * 7) + colIdx;
                          final dayNumber = cellIdx - startOffset + 1;

                          if (dayNumber < 1 || dayNumber > daysInMonth) {
                            return const SizedBox(height: 46);
                          }

                          final currentDate = DateTime(_viewMonth.year, _viewMonth.month, dayNumber);
                          final isRange = _tempStartDate != null &&
                              _tempEndDate != null &&
                              !_isSameDay(_tempStartDate!, _tempEndDate!);
                          final isStart = _tempStartDate != null && _isSameDay(currentDate, _tempStartDate!);
                          final isEnd = _tempEndDate != null && _isSameDay(currentDate, _tempEndDate!);
                          final isInBetween = isRange &&
                              currentDate.isAfter(_tempStartDate!) &&
                              currentDate.isBefore(_tempEndDate!);
                          final isSingle = _tempStartDate != null &&
                              _tempEndDate == null &&
                              _isSameDay(currentDate, _tempStartDate!);
                          final hasActivity = _hasActivity(currentDate);
                          final isToday = _isSameDay(now, currentDate);

                          return SizedBox(
                            height: 46,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // 1. Connecting Ribbon Background
                                if (isInBetween)
                                  Container(
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.22),
                                      borderRadius: BorderRadius.horizontal(
                                        left: colIdx == 0 || dayNumber == 1
                                            ? const Radius.circular(19)
                                            : Radius.zero,
                                        right: colIdx == 6 || dayNumber == daysInMonth
                                            ? const Radius.circular(19)
                                            : Radius.zero,
                                      ),
                                    ),
                                  )
                                else if (isStart && isRange)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Container(
                                      width: cellWidth / 2 + 1,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.22),
                                        borderRadius: colIdx == 6 || dayNumber == daysInMonth
                                            ? const BorderRadius.horizontal(right: Radius.circular(19))
                                            : BorderRadius.zero,
                                      ),
                                    ),
                                  )
                                else if (isEnd && isRange)
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      width: cellWidth / 2 + 1,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.22),
                                        borderRadius: colIdx == 0 || dayNumber == 1
                                            ? const BorderRadius.horizontal(left: Radius.circular(19))
                                            : BorderRadius.zero,
                                      ),
                                    ),
                                  ),

                                // 2. Foreground Circular Badge / Node
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: (isStart || isEnd || isSingle)
                                        ? AppColors.primary
                                        : isInBetween
                                            ? Colors.transparent
                                            : (context.isDark ? const Color(0xFF22242D) : AppColors.lightBackground),
                                    border: (isToday && !isStart && !isEnd && !isSingle && !isInBetween)
                                        ? Border.all(color: AppColors.primary.withValues(alpha: 0.6), width: 1.2)
                                        : null,
                                    boxShadow: (isStart || isEnd || isSingle)
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primary.withValues(alpha: 0.4),
                                              blurRadius: 10,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '$dayNumber',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: (isStart || isEnd || isSingle)
                                              ? FontWeight.w800
                                              : (isToday || hasActivity)
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                          color: (isStart || isEnd || isSingle)
                                              ? Colors.black
                                              : isToday
                                                  ? (context.isDark ? AppColors.primaryLight : const Color(0xFF15803D))
                                                  : isInBetween
                                                      ? Colors.white
                                                      : hasActivity
                                                          ? context.textPrimary
                                                          : context.textSecondary,
                                        ),
                                      ),
                                      if (hasActivity && !isStart && !isEnd && !isSingle) ...[
                                        const SizedBox(height: 1),
                                        Container(
                                          width: 4,
                                          height: 4,
                                          decoration: const BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      );
                    }),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),

            // Selected Day or Date Range Detail & Action Card
            if (isRangeSelected) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.isDark ? const Color(0xFF1E2028) : AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.cardBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _tempStartDate!.month == _tempEndDate!.month && _tempStartDate!.year == _tempEndDate!.year
                                ? '${_tempStartDate!.day} - ${_tempEndDate!.day} ${_monthNames[_tempStartDate!.month - 1]} ${_tempStartDate!.year}'
                                : '${_tempStartDate!.day} ${_monthNames[_tempStartDate!.month - 1]} - ${_tempEndDate!.day} ${_monthNames[_tempEndDate!.month - 1]} ${_tempEndDate!.year}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Builder(
                            builder: (context) {
                              final count = _countTransactionsInRange(_tempStartDate!, _tempEndDate!);
                              return Text(
                                count > 0
                                    ? '$count transaction${count > 1 ? 's' : ''} in selected range'
                                    : 'No recorded activity in this range',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: count > 0 ? AppColors.primary : context.textMuted,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        widget.onDateRangeSelected(_tempStartDate!, _tempEndDate!);
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Filter Range',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ] else if (isSingleSelected) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.isDark ? const Color(0xFF1E2028) : AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.cardBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_tempStartDate!.day} ${_monthNames[_tempStartDate!.month - 1]} ${_tempStartDate!.year}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _hasActivity(_tempStartDate!)
                                ? (widget.dailySummaryMap?[DateTime(
                                        _tempStartDate!.year, _tempStartDate!.month, _tempStartDate!.day)] ??
                                    'Transactions recorded on this day')
                                : 'No recorded activity on this day',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: _hasActivity(_tempStartDate!) ? AppColors.primary : context.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        widget.onDateRangeSelected(_tempStartDate!, null);
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Filter Date',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ] else if (hasActiveFilter) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.isDark ? const Color(0xFF1E2028) : AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.cardBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Filter Deselected',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap to show all transactions without date filter',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: context.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        widget.onClearFilter();
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Show All',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Clear Filter / Reset Button
            if (hasActiveFilter && _tempStartDate != null)
              TextButton.icon(
                onPressed: () {
                  widget.onClearFilter();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.red),
                label: Text(
                  'Reset Date Filter (Show All)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.red,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.2,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          final isCurrentSelectedMonth =
              _viewMonth.year == _pickerYear && _viewMonth.month == index + 1;

          return GestureDetector(
            onTap: () {
              setState(() {
                _viewMonth = DateTime(_pickerYear, index + 1);
                _isPickerMode = false;
                _isYearListMode = false;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              decoration: BoxDecoration(
                color: isCurrentSelectedMonth ? AppColors.primary : (context.isDark ? const Color(0xFF22242D) : AppColors.lightBackground),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isCurrentSelectedMonth ? AppColors.primary : context.cardBorder,
                ),
                boxShadow: isCurrentSelectedMonth
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  _monthNames[index],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: isCurrentSelectedMonth ? FontWeight.w700 : FontWeight.w600,
                    color: isCurrentSelectedMonth ? Colors.black : context.textPrimary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildYearGrid() {
    final currentYear = DateTime.now().year;
    final startYear = currentYear - 5;
    final years = List.generate(12, (i) => startYear + i);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Select Year',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.textSecondary,
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.2,
            ),
            itemCount: years.length,
            itemBuilder: (context, index) {
              final year = years[index];
              final isSelectedYear = year == _pickerYear;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _pickerYear = year;
                    _isYearListMode = false;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  decoration: BoxDecoration(
                    color: isSelectedYear ? AppColors.primary : (context.isDark ? const Color(0xFF22242D) : AppColors.lightBackground),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelectedYear ? AppColors.primary : context.cardBorder,
                    ),
                    boxShadow: isSelectedYear
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$year',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: isSelectedYear ? FontWeight.w700 : FontWeight.w600,
                        color: isSelectedYear ? Colors.black : context.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.textSecondary,
          ),
        ),
      ),
    );
  }
}
