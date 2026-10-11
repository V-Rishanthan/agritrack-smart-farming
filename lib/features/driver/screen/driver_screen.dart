import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_farming/theme/app_colors.dart' show AppColors;

/// One row in the "Last 5 years" payout history.
class _Payout {
  final String name;
  final String date;
  final double amount;
  final String status;

  const _Payout({
    required this.name,
    required this.date,
    required this.amount,
    required this.status,
  });
}

class DriverScreen extends StatefulWidget {
  const DriverScreen({super.key});

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  // Colors used only on this screen
  static const _lilac = Color(0xFFB39DFF);
  static const _payoutRed = Color(0xFF8E0E12);
  static const _payoutAmount = Color(0xFFF5A3A0);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rateController = TextEditingController();

  int? _selectedYear;

  final Set<String> _selectedSessions = {'Session 1', 'Session 2'};
  final List<String> _allSessions = ['Session 1', 'Session 2'];
  bool _sessionError = false;

  // MOCK DATA — replace with database values later.
  final double _totalPlowingAcres = 142.5;
  final double _totalIncome = 1485000;
  final double _mockCommissionRate = 15.0; // used until the user types a rate
  final double _advanceAmount = 1000;
  final double _pendingAmount = 8500;
  final String _historySummary = '1 year 2 Sessions';

  final List<_Payout> _payout = const [
    _Payout(
      name: 'Venthan',
      date: '04-08-2026',
      amount: 25000,
      status: 'SETTLED',
    ),
    _Payout(
      name: 'Venthan',
      date: '04-08-2026',
      amount: 65000,
      status: 'SETTLED',
    ),
    _Payout(
      name: 'Venthan',
      date: '04-08-2026',
      amount: 45000,
      status: 'SETTLED',
    ),
  ];

  // ---------------- Calculated values ----------------

  double get _commissionRate =>
      double.tryParse(_rateController.text.trim()) ?? _mockCommissionRate;

  double get _commissionAmount => _totalIncome * _commissionRate / 100;

  int get _statementYear => _selectedYear ?? DateTime.now().year;

  @override
  void dispose() {
    _nameController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  // ---------------- Helpers ----------------
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

  Future<void> _pickYear() async {
    final results = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.single,
        calendarViewMode: CalendarDatePicker2Mode.year,
        disableModePicker: true, // hides the month/year toggle
        firstDate: DateTime(2020),
        lastDate: DateTime(2050),
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
      value: [DateTime(_statementYear)],
      borderRadius: BorderRadius.circular(20),
      dialogBackgroundColor: AppColors.surfaceElevated,
    );

    if (results != null && results.isNotEmpty && results[0] != null) {
      setState(() => _selectedYear = results[0]!.year);
    }
  }

  void _toggleSession(String session) {
    setState(() {
      if (_selectedSessions.contains(session)) {
        _selectedSessions.remove(session);
      } else {
        _selectedSessions.add(session);
      }
      _sessionError = _selectedSessions.isEmpty;
    });
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter the driver name';
    }
    return null;
  }

  String? _validateRate(String? value) {
    final rate = double.tryParse((value ?? '').trim());
    if (rate == null || rate <= 0 || rate > 100) {
      return 'Enter a rate between 0 and 100';
    }
    return null;
  }

  void _save() {
    final isFormValid = _formKey.currentState?.validate() ?? false;
    setState(() => _sessionError = _selectedSessions.isEmpty);
    if (!isFormValid || _selectedSessions.isEmpty) return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildHeaderInfoTitle(),
                  const SizedBox(height: 20),
                  _buildDetailsCard(),
                  const SizedBox(height: 16),
                  _buildSettlementCard(),
                  const SizedBox(height: 24),
                  _buildHistoryHeader(),
                  const SizedBox(height: 12),
                  for (final payout in _payout) _buildPayoutTile(payout),
                ],
              ),
            ),
          ),
          // ---------- Floating Save button ----------
          Positioned.fill(
            child: SafeArea(
              child: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: _buildSaveButton(),
                ),
              ),
            ),
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

  // ---------------- Header Ttile ----------------
  Widget _buildHeaderInfoTitle() {
    return Column(
      children: [
        Row(
          children: [
            Text(
              "PAYROLL EXECUTION",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),

        Row(
          children: [
            Text(
              'Driver Salary & Payouts',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
      ),

      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,

        // child: Column(
        //   crossAxisAlignment: CrossAxisAlignment.start,
        //   children: [
        //     Row(
        //       children: [
        //         Icon(Icons.percent_outlined, color: _lilac, size: 20),
        //         const SizedBox(width: 8),
        //         const Text(
        //           'Driver Share Rate',
        //           style: TextStyle(
        //             fontSize: 18,
        //             fontWeight: FontWeight.w500,
        //             color: AppColors.textPrimary,
        //           ),
        //         ),
        //         const SizedBox(height: 16),

        //         //  Driver Name
        //         TextFormField(
        //           controller: _nameController,
        //           validator: _validateName,
        //           cursorColor: AppColors.accentPink,
        //           style: const TextStyle(
        //             fontSize: 13,
        //             color: AppColors.textPrimary,
        //           ),
        //           decoration: _fieldDecoration('Enter the Driver Name'),
        //         ),
        //       ],
        //     ),
        //   ],
        // ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.percent_outlined, color: _lilac, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Driver Share Rate',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Driver name
            TextFormField(
              controller: _nameController,
              validator: _validateName,
              cursorColor: AppColors.accentPink,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
              decoration: _fieldDecoration('Enter the Driver Name'),
            ),
            const SizedBox(height: 12),
            // Commission rate (%)
            TextFormField(
              controller: _rateController,
              validator: _validateRate,
              cursorColor: AppColors.accentPink,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              onChanged: (_) => setState(() {}), // live-updates the statement
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
              decoration: _fieldDecoration('Enter Driver Commission Rate'),
            ),
            // Year (opens the calendar_date_picker2 year dialog)
            // _buildYearField(),
            const SizedBox(height: 20),

            const Text(
              'SELECT THE SESSION',
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: AppColors.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            _buildSessionChips(),
          ],
        ),
      ),
    );
  }

  OutlineInputBorder _border([Color? color, double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: color == null
          ? BorderSide.none
          : BorderSide(color: color, width: width),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      border: _border(),
      enabledBorder: _border(AppColors.border, 1.5),
      errorBorder: _border(AppColors.danger),
      focusedErrorBorder: _border(AppColors.danger, 1.5),
    );
  }

  Widget _buildSessionChips() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: _allSessions.map((session) {
        final isSelected = _selectedSessions.contains(session);
        return GestureDetector(
          onTap: () => _toggleSession(session),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accentPurple : AppColors.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              session.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ---------------- Card 2: Settlement statement ----------------
  // Widget _buildSettlementCard({
  //   required Widget label,
  //   required String value,
  //   Color valueColor = AppColors.textPrimary,
  // }) {
  //   return Container(
  //     width: double.infinity,
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: AppColors.surfaceElevated,
  //       borderRadius: BorderRadius.circular(20),
  //     ),

  //     child: Column(
  //       children: [
  //         // Header strip
  //         Container(
  //           padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  //           decoration: BoxDecoration(
  //             color: AppColors.surface,
  //             borderRadius: BorderRadius.circular(12),
  //           ),

  //           child: Row(
  //             children: [
  //               const Icon(
  //                 Icons.receipt_long_outlined,
  //                 color: AppColors.navInactive,
  //                 size: 18,
  //               ),
  //               const SizedBox(width: 10),
  //               const Expanded(
  //                 child: Text(
  //                   'SETTLEMENT\nSTATEMENT',
  //                   style: TextStyle(
  //                     fontSize: 11,
  //                     fontFamily: 'monospace',
  //                     fontWeight: FontWeight.w700,
  //                     letterSpacing: 1.4,
  //                     height: 1.3,
  //                     color: AppColors.textPrimary,
  //                   ),
  //                 ),
  //               ),
  //               Text(
  //                 'SELECTED-$_statementYear',
  //                 style: const TextStyle(
  //                   fontSize: 10,
  //                   fontFamily: 'monospace',
  //                   color: AppColors.success,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //         const SizedBox(height: 18),
  //         _buildStatementRow(
  //           label: const Text(
  //             'Advance Amount',
  //             style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
  //           ),
  //           value: 'LKR ${_formatAmount(_advanceAmount)}',
  //         ),
  //         const SizedBox(height: 16),
  //         _buildStatementRow(
  //           label: label,
  //           value: value,
  //           valueColor: valueColor,
  //         ),
  //         const SizedBox(height: 16),
  //         _buildStatementRow(
  //           label: Text(
  //             'Pending Amount',
  //             style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
  //           ),
  //           value: 'LKR ${_formatAmount(_pendingAmount)}',
  //           valueColor: AppColors.success,
  //         ),

  //         const SizedBox(height: 14),
  //         Container(
  //           height: 2,
  //           decoration: BoxDecoration(
  //             color: AppColors.border,
  //             borderRadius: BorderRadius.circular(1),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildSettlementCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Header strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  color: AppColors.accentPink,
                  size: 18,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'SETTLEMENT\nSTATEMENT',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      height: 1.3,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  'SELECTED-$_statementYear',
                  style: const TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          _buildStatementRow(
            label: const Text(
              'Advance Amount',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            value: 'LKR ${_formatAmount(_advanceAmount)}',
          ),
          const SizedBox(height: 16),

          _buildStatementRow(
            label: Row(
              children: [
                const Flexible(
                  child: Text(
                    'Execution Commission',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${_commissionRate.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            value: 'LKR ${_formatAmount(_commissionAmount)}',
          ),
          const SizedBox(height: 16),

          _buildStatementRow(
            label: const Row(
              children: [
                Text(
                  'Pending Amount',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(width: 6),
                Icon(
                  Icons.check_circle_outline,
                  color: AppColors.danger,
                  size: 14,
                ),
              ],
            ),
            value: 'LKR ${_formatAmount(_pendingAmount)}',
            valueColor: AppColors.danger,
          ),
          const SizedBox(height: 14),

          Container(
            height: 2,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatementRow({
    required Widget label,
    required String value,
    Color valueColor = AppColors.textPrimary,
  }) {
    return Row(
      children: [
        Expanded(child: label),
        const SizedBox(width: 8),
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

  // ---------------- History ----------------
  Widget _buildHistoryHeader() {
    return Row(
      children: [
        const Icon(
          Icons.history_rounded,
          color: AppColors.accentPink,
          size: 20,
        ),
        const SizedBox(width: 8),
        const Text(
          'Last 5 years',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        Text(
          _historySummary,
          style: const TextStyle(
            fontSize: 11,
            fontFamily: 'monospace',
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildPayoutTile(_Payout payout) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.accentGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.north_east_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payout.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  payout.date,
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'LKR ${_formatAmount(payout.amount)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                payout.status,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- Save button ----------------
  Widget _buildSaveButton() {
    return SizedBox(
      width: 232,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentPink.withValues(alpha: 0.4),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _save,
            child: const Row(
              children: [
                SizedBox(width: 18),
                Icon(Icons.lock_clock_outlined, color: Colors.white, size: 20),
                Expanded(
                  child: Center(
                    child: Text(
                      'Save record',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 38,
                ), // balances the icon so the text is centered
              ],
            ),
          ),
        ),
      ),
    );
  }
}
