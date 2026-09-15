import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

const _kMonthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];

/// Reusable Neo-Fintech Single Date Picker Sheet
class AppDatePickerSheet extends StatefulWidget {
  const AppDatePickerSheet({
    super.key,
    required this.initialDate,
    this.firstDate,
    this.lastDate,
    this.title = 'Select Date',
  });

  final DateTime initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String title;

  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    String title = 'Select Date',
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AppDatePickerSheet(
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        title: title,
      ),
    );
  }

  @override
  State<AppDatePickerSheet> createState() => _AppDatePickerSheetState();
}

class _AppDatePickerSheetState extends State<AppDatePickerSheet> {
  late DateTime _selectedDate;
  late DateTime _viewMonth;
  late int _pickerYear;

  bool _isPickerMode = false;
  bool _isYearListMode = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(widget.initialDate.year, widget.initialDate.month, widget.initialDate.day);
    _viewMonth = DateTime(_selectedDate.year, _selectedDate.month);
    _pickerYear = _viewMonth.year;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final now = DateTime.now();

    final firstDayOfMonth = DateTime(_viewMonth.year, _viewMonth.month, 1);
    final startOffset = firstDayOfMonth.weekday - 1; // Mon = 0
    final daysInMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;
    final totalCells = startOffset + daysInMonth;
    final totalRows = (totalCells / 7).ceil();

    final currentMonthName = _kMonthNames[_viewMonth.month - 1];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkCardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.darkCardBorder, width: 1.5),
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
                color: AppColors.darkTextMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header: Close Button & Month/Year Switcher
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
                    color: const Color(0xFF22242D),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.darkCardBorder),
                  ),
                  child: Icon(
                    _isPickerMode ? Icons.arrow_back_rounded : Icons.close_rounded,
                    size: 18,
                    color: AppColors.darkTextPrimary,
                  ),
                ),
              ),

              if (!_isPickerMode)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 22, color: AppColors.darkTextSecondary),
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
                          color: const Color(0xFF22242D),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.darkCardBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$currentMonthName ${_viewMonth.year}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.darkTextPrimary,
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
                      icon: const Icon(Icons.chevron_right_rounded, size: 22, color: AppColors.darkTextSecondary),
                      onPressed: _nextMonth,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 22, color: AppColors.darkTextSecondary),
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
                          color: const Color(0xFF22242D),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isYearListMode ? AppColors.primary : AppColors.darkCardBorder,
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
                                color: AppColors.darkTextPrimary,
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
                      icon: const Icon(Icons.chevron_right_rounded, size: 22, color: AppColors.darkTextSecondary),
                      onPressed: _nextYear,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),

              // Quick "Today" action
              GestureDetector(
                onTap: () {
                  final today = DateTime.now();
                  setState(() {
                    _selectedDate = DateTime(today.year, today.month, today.day);
                    _viewMonth = DateTime(today.year, today.month);
                    _pickerYear = today.year;
                    _isPickerMode = false;
                    _isYearListMode = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22242D),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.darkCardBorder),
                  ),
                  child: Text(
                    'Today',
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

          // Content: Year Grid vs Month Grid vs Day Grid
          if (_isYearListMode)
            _buildYearGrid()
          else if (_isPickerMode)
            _buildMonthGrid()
          else ...[
            // Weekday headers
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _CalendarWeekdayLabel('M'),
                _CalendarWeekdayLabel('T'),
                _CalendarWeekdayLabel('W'),
                _CalendarWeekdayLabel('T'),
                _CalendarWeekdayLabel('F'),
                _CalendarWeekdayLabel('S'),
                _CalendarWeekdayLabel('S'),
              ],
            ),
            const SizedBox(height: 12),

            // Days Table
            Table(
              children: List.generate(totalRows, (rowIdx) {
                return TableRow(
                  children: List.generate(7, (colIdx) {
                    final cellIdx = (rowIdx * 7) + colIdx;
                    final dayNumber = cellIdx - startOffset + 1;

                    if (dayNumber < 1 || dayNumber > daysInMonth) {
                      return const SizedBox(height: 46);
                    }

                    final currentDate = DateTime(_viewMonth.year, _viewMonth.month, dayNumber);
                    final isSelected = _isSameDay(currentDate, _selectedDate);
                    final isToday = _isSameDay(now, currentDate);

                    return SizedBox(
                      height: 46,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDate = currentDate;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? const Color(0xFF15161B) : const Color(0xFF22242D),
                              border: isSelected
                                  ? Border.all(color: AppColors.primary, width: 2.2)
                                  : isToday
                                      ? Border.all(color: AppColors.primary.withValues(alpha: 0.6), width: 1.2)
                                      : null,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.4),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                '$dayNumber',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : isToday
                                          ? AppColors.primaryLight
                                          : AppColors.darkTextSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              }),
            ),
            const SizedBox(height: 18),

            // Bottom Selected Date Card + Confirm Action
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2028),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.darkCardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.15),
                    ),
                    child: const Icon(Icons.event_available_rounded, size: 20, color: AppColors.primaryLight),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_selectedDate.day} ${_kMonthNames[_selectedDate.month - 1]} ${_selectedDate.year}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isSameDay(_selectedDate, now)
                              ? 'Today'
                              : '${_selectedDate.year == now.year ? '' : '${_selectedDate.year} \u00b7 '}${_selectedDate.weekday == 1 ? 'Monday' : _selectedDate.weekday == 2 ? 'Tuesday' : _selectedDate.weekday == 3 ? 'Wednesday' : _selectedDate.weekday == 4 ? 'Thursday' : _selectedDate.weekday == 5 ? 'Friday' : _selectedDate.weekday == 6 ? 'Saturday' : 'Sunday'}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.darkTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(context, _selectedDate);
                    },
                    child: Text(
                      'Select Date',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
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
                color: isCurrentSelectedMonth ? AppColors.primary : const Color(0xFF22242D),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isCurrentSelectedMonth ? AppColors.primary : AppColors.darkCardBorder,
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
                  _kMonthNames[index],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: isCurrentSelectedMonth ? FontWeight.w700 : FontWeight.w600,
                    color: isCurrentSelectedMonth ? Colors.black : AppColors.darkTextPrimary,
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
                color: AppColors.darkTextSecondary,
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
                    color: isSelectedYear ? AppColors.primary : const Color(0xFF22242D),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelectedYear ? AppColors.primary : AppColors.darkCardBorder,
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
                        color: isSelectedYear ? Colors.black : AppColors.darkTextPrimary,
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

/// Reusable Neo-Fintech Month & Year Picker Sheet (for Monthly Bills & Analytics)
class AppMonthPickerSheet extends StatefulWidget {
  const AppMonthPickerSheet({
    super.key,
    required this.initialMonth,
    this.firstDate,
    this.lastDate,
    this.title = 'Select Month',
  });

  final DateTime initialMonth;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String title;

  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime initialMonth,
    DateTime? firstDate,
    DateTime? lastDate,
    String title = 'Select Month',
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AppMonthPickerSheet(
        initialMonth: initialMonth,
        firstDate: firstDate,
        lastDate: lastDate,
        title: title,
      ),
    );
  }

  @override
  State<AppMonthPickerSheet> createState() => _AppMonthPickerSheetState();
}

class _AppMonthPickerSheetState extends State<AppMonthPickerSheet> {
  late int _selectedYear;
  late int _selectedMonth;
  bool _isYearListMode = false;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialMonth.year;
    _selectedMonth = widget.initialMonth.month;
  }

  void _prevYear() {
    setState(() {
      _selectedYear--;
    });
  }

  void _nextYear() {
    setState(() {
      _selectedYear++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final now = DateTime.now();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkCardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.darkCardBorder, width: 1.5),
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
                color: AppColors.darkTextMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header: Close Button & Year Navigator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  if (_isYearListMode) {
                    setState(() => _isYearListMode = false);
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22242D),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.darkCardBorder),
                  ),
                  child: Icon(
                    _isYearListMode ? Icons.arrow_back_rounded : Icons.close_rounded,
                    size: 18,
                    color: AppColors.darkTextPrimary,
                  ),
                ),
              ),

              // Year Selector
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 22, color: AppColors.darkTextSecondary),
                    onPressed: _prevYear,
                    visualDensity: VisualDensity.compact,
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() => _isYearListMode = !_isYearListMode);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22242D),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isYearListMode ? AppColors.primary : AppColors.darkCardBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$_selectedYear',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkTextPrimary,
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
                    icon: const Icon(Icons.chevron_right_rounded, size: 22, color: AppColors.darkTextSecondary),
                    onPressed: _nextYear,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),

              // This Month shortcut
              GestureDetector(
                onTap: () {
                  Navigator.pop(context, DateTime(now.year, now.month, 1));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22242D),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.darkCardBorder),
                  ),
                  child: Text(
                    'This Month',
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

          // Content: Year List vs 12-Month Grid
          if (_isYearListMode)
            _buildYearGrid()
          else
            _buildMonthGrid(now),
        ],
      ),
    );
  }

  Widget _buildMonthGrid(DateTime now) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.1,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          final monthNum = index + 1;
          final isSelected = _selectedYear == widget.initialMonth.year && _selectedMonth == monthNum;
          final isThisMonth = now.year == _selectedYear && now.month == monthNum;

          return GestureDetector(
            onTap: () {
              Navigator.pop(context, DateTime(_selectedYear, monthNum, 1));
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : const Color(0xFF22242D),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : isThisMonth
                          ? AppColors.primary.withValues(alpha: 0.5)
                          : AppColors.darkCardBorder,
                  width: isSelected || isThisMonth ? 1.5 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  _kMonthNames[index],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: isSelected || isThisMonth ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? Colors.black : AppColors.darkTextPrimary,
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
      padding: const EdgeInsets.symmetric(vertical: 6),
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
                color: AppColors.darkTextSecondary,
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
              final isSelectedYear = year == _selectedYear;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedYear = year;
                    _isYearListMode = false;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  decoration: BoxDecoration(
                    color: isSelectedYear ? AppColors.primary : const Color(0xFF22242D),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelectedYear ? AppColors.primary : AppColors.darkCardBorder,
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
                        color: isSelectedYear ? Colors.black : AppColors.darkTextPrimary,
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

class _CalendarWeekdayLabel extends StatelessWidget {
  const _CalendarWeekdayLabel(this.label);
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
            color: AppColors.darkTextSecondary,
          ),
        ),
      ),
    );
  }
}
