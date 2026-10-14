import 'package:flutter/material.dart';
import 'package:smart_farming/features/expenses/screens/add_expenses_screen.dart'
    show AddExpensesScreen;
import 'package:smart_farming/services/expense_service.dart'; // NEW
import 'package:smart_farming/theme/app_colors.dart' show AppColors;
import 'package:calendar_date_picker2/calendar_date_picker2.dart';

enum ExpenseCategory { all, fuel, maintenance, other }

class _Expense {
  final String title;
  final String date;
  final String ref;
  final double amount;
  final ExpenseCategory category;
  final IconData icon;
  final int year; // NEW - used for the year filter

  const _Expense({
    required this.title,
    required this.date,
    required this.ref,
    required this.amount,
    required this.category,
    required this.icon,
    required this.year,
  });
}

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  static const String _currency = 'LKR';
  int _selectedYear = DateTime.now().year;
  ExpenseCategory _selectedCategory = ExpenseCategory.all;

  // NEW - the service + a live stream of the saved expenses.
  // The stream is created ONCE here (not inside build), otherwise every
  // rebuild would open a new connection to Firestore.
  final _expenseService = ExpenseService();
  late final Stream<List<Map<String, dynamic>>> _expensesStream =
      _expenseService.watchExpenses();

  String _formatAmount(double amount) {
    final wholePart = amount.toInt().toString();
    if (wholePart.length <= 3) return wholePart;
    final lastThree = wholePart.substring(wholePart.length - 3);
    final rest = wholePart.substring(0, wholePart.length - 3);
    final restWithCommas = rest.replaceAllMapped(
      RegExp(r'\B(?=(\d{2})+(?!\d))'),
      (match) => ',',
    );
    return '$restWithCommas,$lastThree';
  }

  // e.g. "Nov 15, 2026"
  String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  // NEW - turns one saved expense (a Map from the service) into an _Expense.
  _Expense _expenseFromMap(Map<String, dynamic> m) {
    final type = m['type'] as String; // 'fuel' | 'service' | 'spares' | 'other'
    final date = m['date'] as DateTime;
    final notes = m['notes'] as String;

    // Service and Spares both count as "Maintenance" in the ledger
    final ExpenseCategory category;
    final IconData icon;
    switch (type) {
      case 'fuel':
        category = ExpenseCategory.fuel;
        icon = Icons.local_gas_station_outlined;
      case 'service':
        category = ExpenseCategory.maintenance;
        icon = Icons.build_outlined;
      case 'spares':
        category = ExpenseCategory.maintenance;
        icon = Icons.settings_suggest_outlined;
      default:
        category = ExpenseCategory.other;
        icon = Icons.settings_input_component_outlined;
    }

    return _Expense(
      title: m['name'] as String,
      date: _formatDate(date),
      ref: notes.isEmpty ? '—' : notes,
      amount: m['amount'] as double,
      category: category,
      icon: icon,
      year: date.year,
    );
  }

  // pick Year
  Future<void> _pickYear() async {
    final results = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.single,
        calendarViewMode: CalendarDatePicker2Mode.year,
        disableModePicker: true, // hides the month/year toggle
        firstDate: DateTime(2026), // years from 2026
        lastDate: DateTime(2050),

        // Colors (same style as your other picker)
        selectedYearTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),

        selectedDayHighlightColor: AppColors.accentPurple,

        yearTextStyle: const TextStyle(color: Colors.white),
        controlsTextStyle: const TextStyle(color: Colors.white),
        disabledYearTextStyle: const TextStyle(color: Colors.white24),
        okButtonTextStyle: const TextStyle(
          color: AppColors.accentPurple,
          fontWeight: FontWeight.w700,
        ),
        cancelButtonTextStyle: const TextStyle(color: Colors.white70),
      ),
      dialogSize: const Size(325, 400),
      value: [DateTime(_selectedYear)],
      borderRadius: BorderRadius.circular(20),
      dialogBackgroundColor: AppColors.surfaceElevated,
    );

    if (results != null && results.isNotEmpty && results[0] != null) {
      setState(() => _selectedYear = results[0]!.year);
    }
  }

  void _logNewExpense() {
    // navigate to the add-expense screen.
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddExpensesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            // NEW - StreamBuilder rebuilds this part every time Firestore sends
            // a new list, so a saved expense appears without any refresh.
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _expensesStream,
              builder: (context, snapshot) {
                final all = (snapshot.data ?? const <Map<String, dynamic>>[])
                    .map(_expenseFromMap)
                    .toList();

                //  Only the selected year
                final inYear = all
                    .where((e) => e.year == _selectedYear)
                    .toList();

                // The summary card totals the whole year (all categories)
                final total = inYear.fold<double>(
                  0,
                  (sum, e) => sum + e.amount,
                );

                //  Then the selected category chip
                final items = _selectedCategory == ExpenseCategory.all
                    ? inYear
                    : inYear
                          .where((e) => e.category == _selectedCategory)
                          .toList();

                return Column(
                  children: [
                    // ---------- Fixed part (does not scroll) ----------
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 24),
                          _buildTitleRow(),
                          const SizedBox(height: 24),
                          _buildSummaryCard(total),
                          const SizedBox(height: 24),
                          _buildLedgerHeader(items.length),
                          const SizedBox(height: 14),
                          _buildFilterChips(),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),

                    // ---------- Scrollable part (only the tiles) ----------
                    Expanded(
                      child: _buildExpenseList(
                        snapshot: snapshot,
                        items: items,
                        noExpensesThisYear: inYear.isEmpty,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // ---------- Floating Add Expense Button ----------
          Positioned(
            right: 20,
            bottom: 24,
            child: _AddExpenseButton(onTap: _logNewExpense),
          ),
        ],
      ),
    );
  }

  // ---------------- Expense list (loading / error / empty / data) ----------------
  Widget _buildExpenseList({
    required AsyncSnapshot<List<Map<String, dynamic>>> snapshot,
    required List<_Expense> items,
    required bool noExpensesThisYear,
  }) {
    if (snapshot.hasError) {
      return _buildMessage('Could not load expenses.\n${snapshot.error}');
    }

    // Still waiting for the first answer from Firestore
    if (!snapshot.hasData) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentPink),
      );
    }

    if (items.isEmpty) {
      return _buildMessage(
        noExpensesThisYear
            ? 'No expenses recorded for $_selectedYear.\nTap "Add Expense" to log one.'
            : 'No expenses in this category',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildExpenseTile(items[index]),
    );
  }

  Widget _buildMessage(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textMuted,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  // ---------------- Header ----------------
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.change_history_rounded,
            color: AppColors.accentPink,
            size: 18,
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'AgriTrack',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: AppColors.surfaceElevated,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.accentPink,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: AppColors.accentPurple,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person,
            color: AppColors.textPrimary,
            size: 20,
          ),
        ),
      ],
    );
  }

  // ---------------- Title Row ----------------
  Widget _buildTitleRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ASSET TELEMETRY & LEDGER',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentPink,
                  letterSpacing: 1.0,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Tractor & Operational\nExpenses',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: _pickYear,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  color: AppColors.textMuted,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  '$_selectedYear',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- Summary Card ----------------
  Widget _buildSummaryCard(double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOTAL TRACTOR EXPENSES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'LKR ${_formatAmount(total)}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary, // was textOnGradient
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Ledger Header ----------------
  Widget _buildLedgerHeader(int count) {
    return Row(
      children: [
        const Text(
          'Expense Ledger',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        Text(
          '$count Records',
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ---------------- Filter Chips ----------------

  Widget _buildFilterChips() {
    final filters = <ExpenseCategory, ({String label, IconData icon})>{
      ExpenseCategory.all: (label: 'All', icon: Icons.list_alt_rounded),
      ExpenseCategory.fuel: (
        label: 'Fuel (Diesel)',
        icon: Icons.local_gas_station_outlined,
      ),
      ExpenseCategory.maintenance: (
        label: 'Maintenance',
        icon: Icons.build_outlined,
      ),
      ExpenseCategory.other: (
        label: 'Other Ops',
        icon: Icons.inventory_2_outlined,
      ),
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.entries.map((entry) {
          final isSelected = _selectedCategory == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = entry.key),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accentPurple
                      : AppColors.navBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accentPurple
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      entry.value.icon,
                      size: 16,
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      entry.value.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------------- Expense Tile ----------------
  Widget _buildExpenseTile(_Expense e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(e.icon, color: AppColors.accentPink, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),

                Row(
                  children: [
                    Text(
                      e.date,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        e.ref,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$_currency ${_formatAmount(e.amount)}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddExpenseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddExpenseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentPink.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: onTap,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Add Expense',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: -3,
          right: -3,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.danger,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.background, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
