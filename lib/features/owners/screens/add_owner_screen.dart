import 'package:flutter/material.dart';
import 'package:smart_farming/services/owner_service.dart';
import 'package:smart_farming/theme/app_colors.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';

class AddOwnerScreen extends StatefulWidget {
  const AddOwnerScreen({super.key});

  @override
  State<AddOwnerScreen> createState() => _AddOwnerScreenState();
}

class _AddOwnerScreenState extends State<AddOwnerScreen> {
  final _fullNameController = TextEditingController(text: 'rishan');
  final _totalAcresController = TextEditingController(text: '12.5');
  final _ratePerAcreController = TextEditingController(text: '10000');
  final _advanceAmountController = TextEditingController(text: '40000');

  final _ownerService = OwnerService();
  bool _isSaving = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _totalAcresController.dispose();
    _ratePerAcreController.dispose();
    _advanceAmountController.dispose();
    super.dispose();
  }

  // MOCK summary data for the top card — swap with Firestore values later.
  final double _pendingSettlementBalance = 85000;
  final double _totalBilling = 125000;
  final double _advancePaidSoFar = 40000;
  final int _settlementPercent = 32;
  DateTime _flowingDate = DateTime(2024, 10, 14);

  // Multi-select shifts
  final Set<String> _selectedShifts = {'Shift 1'};
  final List<String> _allShifts = ['Shift 1', 'Shift 2', 'Shift 3'];
  // ---------------- Automated Ledger Computation ----------------
  double get _totalCalculatedAmount {
    final acres = double.tryParse(_totalAcresController.text) ?? 0;
    final rate = double.tryParse(_ratePerAcreController.text) ?? 0;
    return acres * rate;
  }

  double get _calculatedBalanceDue {
    final advance = double.tryParse(_advanceAmountController.text) ?? 0;
    return _totalCalculatedAmount - advance;
  }

  // ---------------- Automated Ledger Computation ----------------
  Future<void> _pickDate() async {
    final results = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.single,
        // Selected day
        selectedDayHighlightColor: AppColors.accentPurple,
        selectedDayTextStyle: const TextStyle(
          color: Colors.white, // fixes the dark "14" text on purple
          fontWeight: FontWeight.w700,
        ),
        // Text colors
        dayTextStyle: const TextStyle(color: Colors.white),
        weekdayLabelTextStyle: const TextStyle(color: Colors.white70),
        controlsTextStyle: const TextStyle(color: Colors.white),
        yearTextStyle: const TextStyle(color: Colors.white),
        todayTextStyle: const TextStyle(color: AppColors.accentPurple),
        disabledDayTextStyle: const TextStyle(color: Colors.white24),

        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
      ),
      dialogSize: const Size(325, 400),
      value: [_flowingDate],
      borderRadius: BorderRadius.circular(20),
      dialogBackgroundColor: AppColors.surfaceElevated,
    );

    if (results != null && results.isNotEmpty && results[0] != null) {
      setState(() {
        _flowingDate = results[0]!;
      });
    }
  }

  // ---------------- Save to Firestore  ----------------

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final name = _fullNameController.text.trim();
    final acres = double.tryParse(_totalAcresController.text.trim());
    final rate = double.tryParse(_ratePerAcreController.text.trim());
    final advance = double.tryParse(_advanceAmountController.text.trim()) ?? 0;

    // Check the inputs before calling Firestore
    if (name.isEmpty) {
      _showMessage('Please enter the owner name.');
      return;
    }
    if (acres == null || acres <= 0) {
      _showMessage('Enter the total acres.');
      return;
    }
    if (rate == null || rate <= 0) {
      _showMessage('Enter the rate per acre.');
      return;
    }
    if (_selectedShifts.isEmpty) {
      _showMessage('Select at least one shift.');
      return;
    }
    if (advance > acres * rate) {
      _showMessage('Advance cannot be more than the total amount.');
      return;
    }

    //  Save
    setState(() => _isSaving = true);
    final error = await _ownerService.addOwner(
      fullName: name,
      totalAcres: acres,
      flowingDate: _flowingDate,
      shifts: _selectedShifts.toList()..sort(),
      ratePerAcre: rate,
      advanceAmount: advance,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error != null) {
      _showMessage(error);
      return;
    }

    //  Saved - close this screen
    Navigator.pop(context);
  }

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
              _buildSummaryCard(),
              const SizedBox(height: 24),
              _buildSectionHeader(),
              const SizedBox(height: 18),
              _buildLabel('OWNER FULL NAME', mandatory: true),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _fullNameController,
                hint: 'Enter owner name',
                icon: Icons.badge_outlined,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              _buildLabel('TOTAL ACRES', mandatory: true),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _totalAcresController,
                hint: 'Enter total acres',
                icon: Icons.landscape_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                suffix: 'acres',
              ),
              const SizedBox(height: 16),
              _buildLabel('FLOWING DATE'),
              const SizedBox(height: 8),
              _buildDateField(),
              const SizedBox(height: 16),
              _buildShiftChips(),
              const SizedBox(height: 18),
              _buildLabel('RATE PER ACRE', mandatory: true),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _ratePerAcreController,
                hint: 'Enter rate per acre',
                icon: Icons.payments_outlined,
                keyboardType: TextInputType.number,
                suffix: 'LKR',
              ),
              const SizedBox(height: 16),
              _buildLabel('ADVANCE AMOUNT'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _advanceAmountController,
                hint: 'Enter advance amount',
                icon: Icons.account_balance_wallet_outlined,
                keyboardType: TextInputType.number,
                suffix: 'LKR',
              ),
              const SizedBox(height: 20),
              _buildLedgerBox(),
              const SizedBox(height: 24),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  _fullNameController.text,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 32,
                height: 32,

                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.more_vert,
                  color: AppColors.textPrimary,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PENDING SETTLEMENT\nBALANCE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                          letterSpacing: 0.6,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'LKR ${_formatAmount(_pendingSettlementBalance)}',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(14),
                  ),

                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Payment\nDue',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.danger,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SummaryStat(
                  label: 'TOTAL BILLING',
                  value: 'LKR ${_formatAmount(_totalBilling)}',
                ),
              ),
              Expanded(
                child: _SummaryStat(
                  label: 'ADVANCE PAID',
                  value: 'LKR ${_formatAmount(_advancePaidSoFar)}',
                  valueColor: AppColors.success,
                ),
              ),
              Expanded(
                child: _SummaryStat(
                  label: 'SETTLEMENT',
                  value: '$_settlementPercent%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  // ---------------- Cancel / Save buttons ----------------

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

  // ---------------- Text Field ----------------
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? suffix,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 15, color: AppColors.textMuted),
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        suffixText: suffix,
        suffixStyle: const TextStyle(
          fontSize: 12,
          color: AppColors.textMuted,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ---------------- Date Field ----------------

  Widget _buildDateField() {
    final formatted = MaterialLocalizations.of(
      context,
    ).formatMediumDate(_flowingDate);

    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              color: AppColors.textMuted,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                formatted,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.event_outlined,
              color: AppColors.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Shift Chips ----------------

  Widget _buildShiftChips() {
    return Row(
      children: _allShifts.map((shift) {
        final isSelected = _selectedShifts.contains(shift);

        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedShifts.remove(shift);
                } else {
                  _selectedShifts.add(shift);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accentPurple
                    : AppColors.inputFill,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                shift,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ---------------- Automated Ledger Computation ----------------
  Widget _buildLedgerBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.sync_alt_rounded,
                color: AppColors.textSecondary,
                size: 14,
              ),
              const SizedBox(width: 6),
              const Text(
                'AUTOMATED LEDGER COMPUTATION',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.lock_outline,
                color: AppColors.textMuted,
                size: 14,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Calculated Amount',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Rate × Total Acreage',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'LKR ${_formatAmount(_totalCalculatedAmount)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calculated Balance Due',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Total - Advance Paid',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.dangerBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'LKR ${_formatAmount(_calculatedBalanceDue)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- Cancel / Save buttons ----------------

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _isSaving ? null : () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                // null disables the button while saving
                onTap: _isSaving ? null : _save,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.textPrimary,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.save_outlined,
                                color: AppColors.textPrimary,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Save Record',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _SummaryStat({
    required this.label,
    required this.value,
    this.valueColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

// ---------------- Section Header ----------------
Widget _buildSectionHeader() {
  return Row(
    children: [
      Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: AppColors.accentPink,
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 8),

      const Text(
        'Operational Record Details',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      const Spacer(),
      const Text(
        'EDIT MODE',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
          letterSpacing: 0.6,
        ),
      ),
    ],
  );
}

// ---------------- Shared Label ----------------
Widget _buildLabel(String text, {bool mandatory = false}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.6,
        ),
      ),
      if (mandatory)
        Text(
          '*MANDATORY',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.accentPink,
          ),
        ),
    ],
  );
}
