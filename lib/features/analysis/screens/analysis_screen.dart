import 'package:flutter/material.dart';
import 'package:smart_farming/theme/app_colors.dart' show AppColors;

/// One year of totals. Later you will fill this from the database.
class _YearData {
  final int year;
  final double income;
  final double expenses;

  const _YearData({
    required this.year,
    required this.income,
    required this.expenses,
  });
}

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  // ---------------------------------------------------------------------
  // MOCK DATA — oldest year first. Replace with database values later.
  // ---------------------------------------------------------------------
  static const _data = <_YearData>[
    _YearData(year: 2022, income: 920000, expenses: 52000),
    _YearData(year: 2023, income: 1180000, expenses: 61500),
    _YearData(year: 2024, income: 1485000, expenses: 68450),
    _YearData(year: 2025, income: 1640000, expenses: 74200),
    _YearData(year: 2026, income: 1265000, expenses: 58300),
  ];

  // Which year row is selected (starts on the latest year)
  int _selectedIndex = _data.length - 1;

  // ---------------- Calculated values ----------------
  double get _maxIncome =>
      _data.fold<double>(0, (max, d) => d.income > max ? d.income : max);

  double get _totalIncome => _data.fold<double>(0, (sum, d) => sum + d.income);

  _YearData get _bestYear =>
      _data.reduce((a, b) => a.income >= b.income ? a : b);

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

  // ---------------- Build ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitle(),
              const SizedBox(height: 20),
              _buildSummaryRow(),
              const SizedBox(height: 24),
              _buildSectionHeader(),
              const SizedBox(height: 12),
              _buildYearBarsCard(),
              const SizedBox(height: 16),
              _buildSelectedYearCard(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Title ----------------
  Widget _buildTitle() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FARM INTELLIGENCE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.accentPink,
            letterSpacing: 1.0,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Income Analysis',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ---------------- Two small summary cards ----------------
  Widget _buildSummaryRow() {
    final best = _bestYear;

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'TOTAL INCOME',
            value: 'LKR ${_formatAmount(_totalIncome)}',
            caption: 'Last ${_data.length} years',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: 'BEST YEAR',
            value: '${best.year}',
            caption: 'LKR ${_formatAmount(best.income)}',
          ),
        ),
      ],
    );
  }

  // ---------------- Section header ----------------
  Widget _buildSectionHeader() {
    return const Row(
      children: [
        Text(
          'Income by Year',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Spacer(),
        Text(
          'Tap a year',
          style: TextStyle(
            fontSize: 11,
            fontFamily: 'monospace',
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  // ---------------- Year-wise bars ----------------
  Widget _buildYearBarsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [for (var i = 0; i < _data.length; i++) _buildYearRow(i)],
      ),
    );
  }

  Widget _buildYearRow(int index) {
    final d = _data[index];
    final isSelected = index == _selectedIndex;
    final fraction = _maxIncome == 0 ? 0.0 : d.income / _maxIncome;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _selectedIndex = index),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            // Year label
            SizedBox(
              width: 44,
              child: Text(
                '${d.year}',
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'monospace',
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),

            // Bar: a dark track with a coloured fill on top
            Expanded(
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: fraction,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppColors.primaryGradient : null,
                      color: isSelected
                          ? null
                          : AppColors.accentPurple.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Amount
            SizedBox(
              width: 92,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  'LKR ${_formatAmount(d.income)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Details for the tapped year ----------------
  Widget _buildSelectedYearCard() {
    final selected = _data[_selectedIndex];
    final previous = _selectedIndex > 0 ? _data[_selectedIndex - 1] : null;

    final netProfit = selected.income - selected.expenses;
    final double? growth = previous == null
        ? null
        : (selected.income - previous.income) / previous.income * 100;

    final growthText = growth == null
        ? '—'
        : '${growth >= 0 ? '+' : ''}${growth.toStringAsFixed(1)}%';
    final growthColor = growth == null
        ? AppColors.textMuted
        : (growth >= 0 ? AppColors.success : AppColors.danger);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${selected.year} SUMMARY',
            style: const TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          _infoRow('Income', 'LKR ${_formatAmount(selected.income)}'),
          const SizedBox(height: 14),
          _infoRow(
            'Expenses',
            'LKR ${_formatAmount(selected.expenses)}',
            valueColor: AppColors.danger,
          ),
          const SizedBox(height: 14),
          _infoRow(
            'Net profit',
            'LKR ${_formatAmount(netProfit)}',
            valueColor: AppColors.success,
          ),
          const SizedBox(height: 14),
          _infoRow('Growth vs last year', growthText, valueColor: growthColor),
        ],
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value, {
    Color valueColor = AppColors.textPrimary,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

/// Small card: label on top, big value, caption underneath.
class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String caption;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontFamily: 'monospace',
              color: AppColors.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          // FittedBox shrinks long amounts instead of overflowing
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
