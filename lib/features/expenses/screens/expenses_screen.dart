import 'package:flutter/material.dart';
import 'package:smart_farming/features/expenses/screens/add_expenses_screen.dart'
    show AddExpensesScreen;
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

  const _Expense({
    required this.title,
    required this.date,
    required this.ref,
    required this.amount,
    required this.category,
    required this.icon,
  });
}

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final double expenses = 68450;
  static const String _currency = 'LKR';
  int _selectedYear = DateTime.now().year;
  ExpenseCategory _selectedCategory = ExpenseCategory.all;

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

  // MOCK data — swap with Firestore values later.

  final List<_Expense> _allExpenses = const [
    _Expense(
      title: '50L Diesel Refill - Pump #4',
      date: 'Today, 08:30 AM',
      ref: 'JD 5310',
      amount: 4650,
      category: ExpenseCategory.fuel,
      icon: Icons.local_gas_station_outlined,
    ),
    _Expense(
      title: 'Engine Oil & Filter Replacement',
      date: 'Oct 22, 2024',
      ref: 'Inv #902',
      amount: 8200,
      category: ExpenseCategory.maintenance,
      icon: Icons.build_outlined,
    ),
    _Expense(
      title: '120L Bulk Tanker Fill',
      date: 'Oct 18, 2024',
      ref: 'Field Tank A',
      amount: 11160,
      category: ExpenseCategory.fuel,
      icon: Icons.local_gas_station_outlined,
    ),
    _Expense(
      title: 'Hydraulic Pipe Fitting',
      date: 'Oct 15, 2024',
      ref: 'Sharma Agro',
      amount: 2400,
      category: ExpenseCategory.other,
      icon: Icons.settings_input_component_outlined,
    ),
  ];

  List<_Expense> get _filteredExpenses {
    if (_selectedCategory == ExpenseCategory.all) return _allExpenses;
    return _allExpenses.where((e) => e.category == _selectedCategory).toList();
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
    final items = _filteredExpenses;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
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
                      _buildSummaryCard(),
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
                  child: items.isEmpty
                      ? Center(child: _buildEmptyState())
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          itemCount: items.length,
                          itemBuilder: (context, index) =>
                              _buildExpenseTile(items[index]),
                        ),
                ),
              ],
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
  Widget _buildSummaryCard() {
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
            'LKR ${_formatAmount(expenses)}',
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

  // ---------------- Empty State ----------------
  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Text(
        'No expenses in this category',
        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
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

  // ---------------- Add Expense Floating Button ----------------
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
