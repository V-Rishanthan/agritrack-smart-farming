import 'package:flutter/material.dart';
import 'package:smart_farming/features/owners/screens/add_owner_screen.dart'
    show AddOwnerScreen;
import 'package:smart_farming/services/owner_service.dart';
import 'package:smart_farming/theme/app_colors.dart' show AppColors;

class OwnersScreen extends StatefulWidget {
  const OwnersScreen({super.key});

  @override
  State<OwnersScreen> createState() => _OwnersScreenState();
}

class _OwnersScreenState extends State<OwnersScreen> {
  int _currentNavIndex = 1; // Owners tab active
  int _selectedSeasonIndex = 0;
  int _selectedFilterIndex = 0;

  // ---------------------------------------------------------------------
  // MOCK / DUMMY DATA — swap with Firestore query results later.
  // Keep these same field names so the UI below needs no changes.
  // ---------------------------------------------------------------------

  final int _totalOwners = 28;
  final int _pendingDueCount = 12;
  final int _fullyClearedCount = 16;

  final List<String> _seasons = [
    '2024 Season',
    '2023 Season',
    '2022',
    'All Years',
  ];

  final List<_LandOwner> _owners = [
    _LandOwner(
      name: 'Balwinder Singh D',
      isVerified: false,
      acres: 12.5,
      plot: 'Plot #PL-409 • Zone B',
      date: '14 Oct 2024',
      shifts: const ['Shift 1', 'Shift 2'],
      advancePaid: '₹40,000',
      totalYieldFee: '₹1,25,000',
      settlementStatus: SettlementStatus.pending,
      settlementAmount: '₹85,000',
    ),
    _LandOwner(
      name: 'Gurmeet Kaur',
      isVerified: true,
      acres: 8.0,
      plot: 'Plot #PL-112 • Zone A',
      date: '18 Oct 2024',
      shifts: const ['Shift 3'],
      advancePaid: '₹80,000',
      totalYieldFee: '₹80,000',
      settlementStatus: SettlementStatus.cleared,
      settlementAmount: '₹0',
    ),
    _LandOwner(
      name: 'Rajinder Prasad',
      isVerified: false,
      acres: 15.2,
      plot: 'Plot #PL-884 • Sector 4',
      date: '22 Oct 2024',
      shifts: const ['Shift 1', 'Shift 3'],
      advancePaid: '₹60,000',
      totalYieldFee: '₹1,52,000',
      settlementStatus: SettlementStatus.pending,
      settlementAmount: '₹92,000',
    ),
    _LandOwner(
      name: 'Harpreet Verma',
      isVerified: true,
      acres: 6.0,
      plot: 'Plot #PL-305 • East Ridge',
      date: '25 Oct 2024',
      shifts: const ['Shift 2'],
      advancePaid: '₹60,000',
      totalYieldFee: '₹60,000',
      settlementStatus: SettlementStatus.cleared,
      settlementAmount: '₹0',
    ),
  ];

  final _ownerService = OwnerService();
  final _searchController = TextEditingController();

  // Created once, so typing in the search box does not re-subscribe to Firestore.

  // late final Stream<List <LandOwner>> _ownersStream = _ownerService.watchOwners();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildTitleRow(),
                      const SizedBox(height: 16),
                      _buildSearchBar(),
                      const SizedBox(height: 14),
                      _buildSeasonTabs(),
                      const SizedBox(height: 12),
                      _buildFilterChips(),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: _owners.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) =>
                        _OwnerCard(owner: _owners[index]),
                  ),
                ),
                _buildSyncFooter(),
              ],
            ),
          ),

          // ---------- Floating Add Owner Button ----------
          Positioned(
            right: 20,
            bottom: 90,
            child: _AddOwnerButton(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddOwnerScreen(),
                  ),
                );
              },
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

  // ---------------- Title Row ----------------
  Widget _buildTitleRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ASSET REGISTRY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentPink,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Land Owner\nRecords',
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$_totalOwners Total\nOwners',
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------- Search Bar ----------------
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.textMuted, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search by owner name, plot or phone...',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const Icon(
            Icons.qr_code_scanner_rounded,
            color: AppColors.textMuted,
            size: 20,
          ),
        ],
      ),
    );
  }

  // ---------------- Season Tabs ----------------
  Widget _buildSeasonTabs() {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _seasons.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = index == _selectedSeasonIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedSeasonIndex = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.primaryGradient : null,
                color: isSelected ? null : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                _seasons[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------- Filter Chips ----------------
  Widget _buildFilterChips() {
    final filters = [
      ('All Records', '$_totalOwners', null),
      ('Pending Due', '$_pendingDueCount', AppColors.danger),
      ('Fully Cleared', '$_fullyClearedCount', AppColors.success),
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final isSelected = index == _selectedFilterIndex;
          final (label, count, dotColor) = filters[index];

          return GestureDetector(
            onTap: () => setState(() => _selectedFilterIndex = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.surfaceElevated
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? AppColors.border : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (dotColor != null) ...[
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      count,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------- Sync Footer ----------------
  Widget _buildSyncFooter() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sync_rounded, color: AppColors.textMuted, size: 13),
          const SizedBox(width: 6),
          Text(
            'Synced with telemetry satellite mesh • 2 min ago',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

//------------- Owner Card-------------

class _OwnerCard extends StatelessWidget {
  final _LandOwner owner;

  const _OwnerCard({required this.owner});

  @override
  Widget build(BuildContext context) {
    final isPending = owner.settlementStatus == SettlementStatus.pending;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------- Avatar + Name + Acres ----------
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceElevated,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: AppColors.textPrimary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            owner.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (owner.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                            size: 15,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.textMuted,
                          size: 12,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            owner.plot,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.change_history_rounded,
                      color: AppColors.success,
                      size: 11,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${owner.acres} Acres',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ---------- Date + Shifts ----------
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                color: AppColors.textMuted,
                size: 12,
              ),
              const SizedBox(width: 6),
              Text(
                owner.date,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Wrap(
                spacing: 6,
                children: owner.shifts
                    .map(
                      (shift) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentPurple.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          shift,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ---------- Financial Row ----------
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _FinancialColumn(
                    label: 'ADVANCE PAID',
                    value: owner.advancePaid,
                  ),
                ),
                Expanded(
                  child: _FinancialColumn(
                    label: 'TOTAL YIELD FEE',
                    value: owner.totalYieldFee,
                  ),
                ),
                Expanded(
                  child: _FinancialColumn(
                    label: 'SETTLEMENT',
                    value: isPending
                        ? 'Pending ${owner.settlementAmount}'
                        : 'Cleared ${owner.settlementAmount}',
                    valueColor: isPending
                        ? AppColors.danger
                        : AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FinancialColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _FinancialColumn({
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
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ===========================================================================
// Add Owner Floating Button
// ===========================================================================

class _AddOwnerButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddOwnerButton({required this.onTap});

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
                      'Add Owner',
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

// ===========================================================================
// Data model
// ===========================================================================

enum SettlementStatus { pending, cleared }

class _LandOwner {
  final String name;
  final bool isVerified;
  final double acres;
  final String plot;
  final String date;
  final List<String> shifts;
  final String advancePaid;
  final String totalYieldFee;
  final SettlementStatus settlementStatus;
  final String settlementAmount;

  _LandOwner({
    required this.name,
    required this.isVerified,
    required this.acres,
    required this.plot,
    required this.date,
    required this.shifts,
    required this.advancePaid,
    required this.totalYieldFee,
    required this.settlementStatus,
    required this.settlementAmount,
  });
}
