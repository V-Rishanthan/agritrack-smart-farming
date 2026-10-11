import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:smart_farming/theme/app_colors.dart' show AppColors;

/// The four tiles under "Expense classification".
enum ExpenseType { fuel, service, spares, other }

/// What this screen hands back to the previous screen when the user taps
/// "Save Expense" (via Navigator.pop). Cancel / back returns null.
class NewExpense {
  final String name;
  final double amount;
  final DateTime date;
  final String notes;
  final ExpenseType type;

  const NewExpense({
    required this.name,
    required this.amount,
    required this.date,
    required this.notes,
    required this.type,
  });

  /// e.g. "Nov 15, 2026" — same style as the ledger tiles.
  String get dateLabel {
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class AddExpensesScreen extends StatefulWidget {
  const AddExpensesScreen({super.key});

  @override
  State<AddExpensesScreen> createState() => _AddExpensesScreenState();
}

class _AddExpensesScreenState extends State<AddExpensesScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController(text: 'Fuel');
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  ExpenseType _type = ExpenseType.fuel;
  DateTime _date = DateTime.now();

  // One row per classification tile. Adding a new type = add one line here
  // (and one value in the ExpenseType enum above).
  static const _types =
      <
        ({
          ExpenseType type,
          String label,
          IconData icon,
          String cardTitle,
          String defaultName,
        })
      >[
        (
          type: ExpenseType.fuel,
          label: 'Fuel',
          icon: Icons.local_gas_station_outlined,
          cardTitle: 'FUEL BREAKDOWN & METRICS',
          defaultName: 'Fuel',
        ),
        (
          type: ExpenseType.service,
          label: 'Service',
          icon: Icons.build_outlined,
          cardTitle: 'SERVICE DETAILS & METRICS',
          defaultName: 'Service',
        ),
        (
          type: ExpenseType.spares,
          label: 'Spares',
          icon: Icons.settings_suggest_outlined,
          cardTitle: 'SPARE PARTS & METRICS',
          defaultName: 'Spares',
        ),
        (
          type: ExpenseType.other,
          label: 'Other',
          icon: Icons.list_alt_rounded,
          cardTitle: 'EXPENSE DETAILS & METRICS',
          defaultName: '',
        ),
      ];

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ---------------- Logic ----------------
  String _defaultNameFor(ExpenseType type) =>
      _types.firstWhere((t) => t.type == type).defaultName;

  void _selectType(ExpenseType type) {
    if (type == _type) return;
    final previousDefault = _defaultNameFor(_type);
    setState(() {
      // Only replace the name if the user hasn't typed their own.
      final current = _nameController.text.trim();
      if (current.isEmpty || current == previousDefault) {
        _nameController.text = _defaultNameFor(type);
      }
      _type = type;
    });
  }

  String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ---------------- Date picker (calendar_date_picker2) ----------------
  Future<void> _pickDate() async {
    final results = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.single, // one date only
        calendarViewMode: CalendarDatePicker2Mode.day, // opens on the day grid
        firstDate: DateTime(2020),
        lastDate: DateTime(2050),

        // Colors (same style as your year picker)
        selectedDayHighlightColor: AppColors.accentPurple,
        selectedDayTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        dayTextStyle: const TextStyle(color: Colors.white),
        disabledDayTextStyle: const TextStyle(color: Colors.white24),
        todayTextStyle: const TextStyle(
          color: AppColors.accentPink,
          fontWeight: FontWeight.w700,
        ),
        weekdayLabelTextStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
        controlsTextStyle: const TextStyle(color: Colors.white),
        yearTextStyle: const TextStyle(color: Colors.white),
        selectedYearTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        okButtonTextStyle: const TextStyle(
          color: AppColors.accentPurple,
          fontWeight: FontWeight.w700,
        ),
        cancelButtonTextStyle: const TextStyle(color: Colors.white70),
      ),
      dialogSize: const Size(325, 400),
      value: [_date],
      borderRadius: BorderRadius.circular(20),
      dialogBackgroundColor: AppColors.surfaceElevated,
    );

    // results is null when the user taps Cancel / outside the dialog
    if (results != null && results.isNotEmpty && results[0] != null) {
      setState(() => _date = results[0]!);
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter an expense name';
    }
    return null;
  }

  String? _validatePrice(String? value) {
    final amount = double.tryParse((value ?? '').trim());
    if (amount == null || amount <= 0) {
      return 'Enter a valid amount';
    }
    return null;
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.pop(
      context,
      NewExpense(
        name: _nameController.text.trim(),
        amount: double.parse(_priceController.text.trim()),
        date: _date,
        notes: _notesController.text.trim(),
        type: _type,
      ),
    );
  }

  // ---------------- Build ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildScreenInfo(),
              const SizedBox(height: 24),
              _sectionLabel('EXPENSE CLASSIFICATION'),
              const SizedBox(height: 10),
              _buildTypeTiles(),
              const SizedBox(height: 16),
              _buildDetailsCard(),
              const SizedBox(height: 28),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Screen info card ----------------
  Widget _buildScreenInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'FLEET LEDGER ENTRY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Log Tractor Expense',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Record fuel refills, scheduled maintenance, parts, or repairs against active field assets.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Classification tiles ----------------
  Widget _buildTypeTiles() {
    return Row(
      children: [
        for (var i = 0; i < _types.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: _buildTypeTile(_types[i])),
        ],
      ],
    );
  }

  Widget _buildTypeTile(
    ({
      ExpenseType type,
      String label,
      IconData icon,
      String cardTitle,
      String defaultName,
    })
    t,
  ) {
    final isSelected = t.type == _type;

    return GestureDetector(
      onTap: () => _selectType(t.type),
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.accentPink.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(t.icon, color: AppColors.textPrimary, size: 18),
            const SizedBox(height: 4),
            Text(
              t.label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Details card ----------------
  Widget _buildDetailsCard() {
    final cardTitle = _types.firstWhere((t) => t.type == _type).cardTitle;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    cardTitle,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.accentPurple,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            _fieldLabel('Name of Expense'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _nameController,
              hint: 'Expense name',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              validator: _validateName,
            ),
            const SizedBox(height: 16),

            _fieldLabel('Expense price (LKR)'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _priceController,
              hint: '0.0',
              fontSize: 20,
              fontWeight: FontWeight.w500,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              validator: _validatePrice,
            ),
            const SizedBox(height: 16),

            _fieldLabel('Pick the Date'),
            const SizedBox(height: 8),
            _buildDateField(),
            const SizedBox(height: 16),

            _fieldLabel('Notes\nOptional'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _notesController,
              hint: 'Write something',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Shared field widgets ----------------
  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontFamily: 'monospace',
        color: AppColors.textSecondary,
        height: 1.3,
      ),
    );
  }

  OutlineInputBorder _border([Color? color, double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: color == null
          ? BorderSide.none
          : BorderSide(color: color, width: width),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required double fontSize,
    required FontWeight fontWeight,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      cursorColor: AppColors.accentPink,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: AppColors.textMuted,
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: _border(),
        enabledBorder: _border(),
        focusedBorder: _border(AppColors.accentPurple, 1.5),
        errorBorder: _border(AppColors.danger),
        focusedErrorBorder: _border(AppColors.danger, 1.5),
      ),
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _isoDate(_date),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  // ---------------- Cancel / Save ----------------
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Navigator.pop(context),
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
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentPink.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: _save,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Save Expense',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
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
