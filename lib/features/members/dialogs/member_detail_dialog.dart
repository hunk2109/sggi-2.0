import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/receipt_printing_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../memberships/models/group_model.dart';
import '../../memberships/providers/group_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/member_model.dart';
import '../providers/members_provider.dart';
import 'assign_membership_dialog.dart';
import 'new_member_dialog.dart';
import 'pay_fee_dialog.dart';

class MemberDetailDialog extends ConsumerStatefulWidget {
  final MemberModel member;

  const MemberDetailDialog({super.key, required this.member});

  @override
  ConsumerState<MemberDetailDialog> createState() => _MemberDetailDialogState();
}

class _MemberDetailDialogState extends ConsumerState<MemberDetailDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late MemberModel _currentMember;

  bool _isLoadingData = true;
  List<Map<String, dynamic>> _membershipsHistory = [];
  Map<String, dynamic> _paymentHistory = {};
  List<Map<String, dynamic>> _attendancesHistory = [];
  List<GroupModel> _memberGroups = [];

  final _currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: 'RD\$ ', decimalDigits: 2);
  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _dateTimeFormat = DateFormat('dd/MM/yyyy hh:mm a');

  @override
  void initState() {
    super.initState();
    _currentMember = widget.member;
    _tabController = TabController(length: 5, vsync: this);
    _loadAllHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllHistory() async {
    setState(() => _isLoadingData = true);
    final service = ref.read(memberServiceProvider);
    final groupService = ref.read(groupServiceProvider);

    try {
      final futures = await Future.wait([
        service.getMembershipsHistory(_currentMember.id),
        service.getPaymentHistory(_currentMember.id),
        service.getAttendancesHistory(_currentMember.id),
        service.getMemberById(_currentMember.id),
        groupService.getMemberGroups(_currentMember.id),
      ]);

      if (mounted) {
        setState(() {
          _membershipsHistory = futures[0] as List<Map<String, dynamic>>;
          _paymentHistory = futures[1] as Map<String, dynamic>;
          _attendancesHistory = futures[2] as List<Map<String, dynamic>>;
          _currentMember = futures[3] as MemberModel;
          _memberGroups = futures[4] as List<GroupModel>;
          _isLoadingData = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _openAssignMembership() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AssignMembershipDialog(member: _currentMember),
    );
    if (result == true) {
      await _loadAllHistory();
      ref.read(membersProvider.notifier).loadMembers();
    }
  }

  Future<void> _openEditMember() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => NewMemberDialog(memberToEdit: _currentMember),
    );
    if (result == true) {
      _loadAllHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF16191E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 880,
        height: 680,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Avatar, Names, Badges, Action Buttons
            _buildHeader(),

            const SizedBox(height: 16),

            // 3 Quick Stat Summary Cards
            _buildStatCards(),

            const SizedBox(height: 16),

            // Tab Bar
            Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF272D37), width: 1.5)),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: AppTheme.primary,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: [
                  Tab(
                    iconMargin: EdgeInsets.zero,
                    child: Row(
                      children: [
                        const Icon(Icons.credit_card_outlined, size: 16),
                        const SizedBox(width: 8),
                        Text('Membresías (${_membershipsHistory.length})'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 16),
                        const SizedBox(width: 8),
                        Text('Pagos (${(_paymentHistory['payments'] as List?)?.length ?? 0})'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_outlined, size: 16),
                        const SizedBox(width: 8),
                        Text('Asistencias (${_attendancesHistory.length})'),
                      ],
                    ),
                  ),
                  const Tab(
                    child: Row(
                      children: [
                        Icon(Icons.badge_outlined, size: 16),
                        SizedBox(width: 8),
                        Text('Datos Personales'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      children: [
                        const Icon(Icons.groups_outlined, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          _memberGroups.isNotEmpty
                              ? 'Grupo Familiar (${_memberGroups.first.companions.length})'
                              : 'Grupo Familiar',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: _isLoadingData
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildMembershipsTab(),
                        _buildPaymentsTab(),
                        _buildAttendancesTab(),
                        _buildPersonalDataTab(),
                        _buildFamilyGroupTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        CircleAvatar(
          radius: 28,
          backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
          child: Text(
            _currentMember.firstName.isNotEmpty ? _currentMember.firstName[0].toUpperCase() : 'S',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primary),
          ),
        ),
        const SizedBox(width: 16),

        // Name, Code, Badges
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _currentMember.fullName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(
                      'Código: ${_currentMember.displayCode}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(_currentMember),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (_currentMember.phone != null) ...[
                    const Icon(Icons.phone_outlined, size: 13, color: Colors.white54),
                    const SizedBox(width: 4),
                    Text(_currentMember.phone!, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                    const SizedBox(width: 14),
                  ],
                  if (_currentMember.documentId != null) ...[
                    const Icon(Icons.credit_card_outlined, size: 13, color: Colors.white54),
                    const SizedBox(width: 4),
                    Text('Cédula: ${_currentMember.documentId}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                    const SizedBox(width: 14),
                  ],
                  const Icon(Icons.calendar_today_outlined, size: 13, color: Colors.white54),
                  const SizedBox(width: 4),
                  Text('Ingreso: ${_dateFormat.format(_currentMember.joinDate)}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ],
          ),
        ),

        // Action Buttons
        ElevatedButton.icon(
          icon: const Icon(Icons.credit_card, size: 16),
          label: const Text('Renovar Plan'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          onPressed: _openAssignMembership,
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.edit_outlined, size: 16),
          label: const Text('Editar'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          onPressed: _openEditMember,
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.close, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildStatCards() {
    final totalPaid = double.tryParse(_paymentHistory['totalPaid']?.toString() ?? '') ?? 0.0;
    final totalAttendances = _attendancesHistory.length;

    return Row(
      children: [
        // Card 1: Membresía Actual
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E232B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.fitness_center, color: AppTheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Plan Activo', style: TextStyle(fontSize: 11, color: Colors.white54)),
                      const SizedBox(height: 2),
                      Text(
                        _currentMember.activePlanName ?? 'Sin Plan Activo',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        (_currentMember.membershipEndDate != null && _currentMember.membershipEndDate!.year > 2020)
                            ? 'Vence: ${_dateFormat.format(_currentMember.membershipEndDate!)}'
                            : 'No asignado',
                        style: TextStyle(
                          fontSize: 11,
                          color: _currentMember.isExpired ? Colors.redAccent : Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Card 2: Total Pagos
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E232B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.attach_money, color: Colors.greenAccent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Pagado', style: TextStyle(fontSize: 11, color: Colors.white54)),
                      const SizedBox(height: 2),
                      Text(
                        _currencyFormat.format(totalPaid),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                      ),
                      Text(
                        '${_paymentHistory['completedPayments'] ?? 0} pagos registrados',
                        style: const TextStyle(fontSize: 11, color: Colors.white60),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Card 3: Asistencias
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E232B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.login, color: Colors.blueAccent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Visitas', style: TextStyle(fontSize: 11, color: Colors.white54)),
                      const SizedBox(height: 2),
                      Text(
                        '$totalAttendances Asistencias',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        _attendancesHistory.isNotEmpty
                            ? 'Última: ${_dateFormat.format((DateTime.tryParse(_attendancesHistory.first['visitDate']?.toString() ?? '') ?? DateTime.now()).toLocal())}'
                            : 'Sin registros',
                        style: const TextStyle(fontSize: 11, color: Colors.white60),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // TAB 1: Membresías
  Widget _buildMembershipsTab() {
    if (_membershipsHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.card_membership_outlined, size: 48, color: Colors.white24),
            const SizedBox(height: 12),
            const Text('No hay historial de membresías para este socio.', style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Asignar Primera Membresía'),
              onPressed: _openAssignMembership,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 18,
            horizontalMargin: 12,
            headingRowHeight: 40,
            dataRowMinHeight: 46,
            dataRowMaxHeight: 46,
            columns: const [
              DataColumn(label: Text('Plan', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Inicio', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Vencimiento', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Precio', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Pagado', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Estado Pago', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Acción', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: _membershipsHistory.map((m) {
              final planMap = m['membership'] as Map?;
              final planName = planMap?['name']?.toString() ?? 'Plan';
              final startRaw = m['startDate']?.toString();
              final endRaw = m['endDate']?.toString() ?? m['acc_enddate']?.toString();
              final startDt = startRaw != null ? DateTime.tryParse(startRaw)?.toLocal() : null;
              final endDt = endRaw != null ? DateTime.tryParse(endRaw)?.toLocal() : null;
              final price = double.tryParse(planMap?['price']?.toString() ?? m['price']?.toString() ?? '') ?? 0.0;
              final paid = double.tryParse(m['amountPaid']?.toString() ?? '') ?? 0.0;
              final pStatus = m['paymentStatus']?.toString() ?? (m['isPaid'] == true ? 'PAID' : 'PENDING');
              final isEndValid = endDt != null && endDt.year > 2020;
              final isActive = m['isActive'] == true || (isEndValid && endDt.isAfter(DateTime.now()));

              return DataRow(
                cells: [
                  DataCell(Text(planName, style: const TextStyle(fontWeight: FontWeight.w600))),
                  DataCell(Text((startDt != null && startDt.year > 2020) ? _dateFormat.format(startDt) : '-')),
                  DataCell(Text(isEndValid ? _dateFormat.format(endDt) : 'Expirada')),
                  DataCell(Text(_currencyFormat.format(price))),
                  DataCell(Text(_currencyFormat.format(paid), style: const TextStyle(color: Colors.greenAccent))),
                  DataCell(_buildPaymentStatusBadge(pStatus)),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green.withValues(alpha: 0.15) : Colors.white10,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isActive ? 'ACTIVA' : 'FINALIZADA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.greenAccent : Colors.white38,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    isActive
                        ? ElevatedButton.icon(
                            icon: const Icon(Icons.cancel_outlined, size: 14),
                            label: const Text('Cancelar', style: TextStyle(fontSize: 11)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: const Size(0, 28),
                            ),
                            onPressed: () => _openCancelMembershipDialog(m),
                          )
                        : const Text('-', style: TextStyle(color: Colors.white38)),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // TAB 2: Pagos
  Widget _buildPaymentsTab() {
    final paymentsList = (_paymentHistory['payments'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    if (paymentsList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: Colors.white24),
            SizedBox(height: 12),
            Text('No hay pagos registrados para este socio.', style: TextStyle(color: Colors.white54)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: DataTable(
            headingRowHeight: 40,
            dataRowMinHeight: 46,
            dataRowMaxHeight: 46,
            columns: const [
              DataColumn(label: Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Monto', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Método', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Referencia / Recibo', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Acción', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: paymentsList.map((p) {
              final rawDate = p['paymentDate']?.toString() ?? p['createdAt']?.toString();
              final dt = rawDate != null ? DateTime.tryParse(rawDate) : null;
              final amount = double.tryParse(p['amount']?.toString() ?? '') ?? 0.0;
              final method = p['paymentMethod']?.toString() ?? 'Efectivo';
              final refCode = p['receiptNumber']?.toString() ?? p['reference']?.toString() ?? p['id']?.toString().substring(0, 8) ?? '-';
              final status = p['status']?.toString() ?? 'COMPLETED';
              final isPending = status.toLowerCase() == 'pending';
              final paymentId = p['id']?.toString() ?? '';

              return DataRow(
                cells: [
                  DataCell(Text(dt != null ? _dateTimeFormat.format(dt.isUtc ? dt.toLocal() : dt) : '-')),
                  DataCell(Text(_currencyFormat.format(amount), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent))),
                  DataCell(Text(_translateMethod(method))),
                  DataCell(Text(refCode, style: const TextStyle(color: Colors.white70, fontSize: 12))),
                  DataCell(_buildPaymentStatusBadge(status)),
                  DataCell(
                    isPending && paymentId.isNotEmpty
                        ? ElevatedButton.icon(
                            icon: const Icon(Icons.point_of_sale, size: 14),
                            label: const Text('Cobrar', style: TextStyle(fontSize: 11)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.success,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: const Size(0, 28),
                            ),
                            onPressed: () => _openPayDialog(paymentId, amount),
                          )
                        : OutlinedButton.icon(
                            icon: const Icon(Icons.print_outlined, size: 14),
                            label: const Text('Recibo', style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: const Size(0, 28),
                            ),
                            onPressed: () => _printPaymentReceipt(p),
                          ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _printPaymentReceipt(Map<String, dynamic> payment) async {
    final paymentId = payment['id']?.toString() ?? '';
    final amount = double.tryParse(payment['amount']?.toString() ?? '') ?? 0.0;
    final method = payment['paymentMethod']?.toString() ?? 'Efectivo';
    final refCode = payment['receiptNumber']?.toString() ??
        payment['reference']?.toString() ??
        (paymentId.length > 8 ? paymentId.substring(0, 8) : paymentId);

    // Buscar membresía vinculada en el historial
    Map<String, dynamic>? matchedMm;
    for (final mm in _membershipsHistory) {
      if (mm['paymentId'] == paymentId || mm['payment']?['id'] == paymentId) {
        matchedMm = mm;
        break;
      }
    }
    matchedMm ??= _membershipsHistory.isNotEmpty ? _membershipsHistory.first : null;

    final planName = matchedMm?['membership']?['name']?.toString() ?? _currentMember.activePlanName ?? 'Membresía General';
    final rawStart = matchedMm?['startDate']?.toString();
    final rawEnd = matchedMm?['endDate']?.toString();
    final startDate = rawStart != null ? DateTime.tryParse(rawStart)?.toLocal() : null;
    final endDate = rawEnd != null ? DateTime.tryParse(rawEnd)?.toLocal() : _currentMember.membershipEndDate;

    final promoCode = matchedMm?['appliedPromotionCode']?.toString();
    final discountPercent = matchedMm?['discountPercentage'] != null
        ? num.tryParse(matchedMm!['discountPercentage'].toString())
        : null;
    final rawPrice = matchedMm?['membership']?['price'];
    final originalPrice = rawPrice != null ? double.tryParse(rawPrice.toString()) : null;

    final gymSettings = ref.read(gymSettingsProvider).settings;

    try {
      await ReceiptPrintingService.printMembershipReceipt(
        memberName: _currentMember.fullName,
        displayCode: _currentMember.displayCode,
        planName: planName,
        amountPaid: amount,
        paymentMethod: method,
        startDate: startDate,
        endDate: endDate,
        receiptNumber: refCode,
        promotionCode: promoCode,
        discountPercentage: discountPercent,
        originalPlanPrice: originalPrice,
        gymSettings: gymSettings,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al abrir diálogo de impresión de Windows: $e')),
        );
      }
    }
  }

  Future<void> _openPayDialog(String paymentId, double amount) async {
    final paid = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PayFeeDialog(
        member: _currentMember,
        paymentId: paymentId,
        initialAmount: amount,
        concept: 'Cuota de Membresía',
        onPaymentSuccess: () {
          _loadAllHistory();
          ref.read(membersProvider.notifier).loadMembers();
        },
      ),
    );

    if (paid == true) {
      _loadAllHistory();
      ref.read(membersProvider.notifier).loadMembers();
    }
  }

  Future<void> _openCancelMembershipDialog(Map<String, dynamic> m) async {
    final planMap = m['membership'] as Map?;
    final planName = planMap?['name']?.toString() ?? 'Plan';
    final price = double.tryParse(planMap?['price']?.toString() ?? m['price']?.toString() ?? '') ?? 0.0;
    final paid = double.tryParse(m['amountPaid']?.toString() ?? '') ?? 0.0;
    final pStatus = m['paymentStatus']?.toString() ?? (m['isPaid'] == true ? 'PAID' : 'PENDING');
    final isPending = pStatus.toUpperCase().contains('PEND');
    final effectivePaid = paid > 0 ? paid : price;

    String selectedAction = 'credit_balance'; // 'credit_balance', 'refund', 'revoke_only'

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E232B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(
                isPending ? Icons.warning_amber_rounded : Icons.remove_circle_outline,
                color: isPending ? Colors.orangeAccent : Colors.redAccent,
              ),
              const SizedBox(width: 10),
              Text(
                isPending ? 'Cancelar Plan Pendiente' : 'Cancelar Plan Pagado',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plan: $planName - ${_currencyFormat.format(price)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                ),
                const SizedBox(height: 12),
                if (isPending) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Esta membresía tiene un cobro pendiente en el sistema.',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.orangeAccent),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '• La factura pendiente se marcará como CANCELADA (se anula la deuda).\n• El acceso biométrico y la membresía serán removidos de inmediato.',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      'Esta membresía ya fue pagada (${_currencyFormat.format(effectivePaid)}). Selecciona cómo deseas gestionar el pago:',
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                  _buildRefundOption(
                    title: 'Saldo a Favor del Socio (Recomendado)',
                    subtitle: 'Acredita ${_currencyFormat.format(effectivePaid)} al monedero del socio para futuras mensualidades o productos.',
                    value: 'credit_balance',
                    groupValue: selectedAction,
                    onChanged: (val) => setDialogState(() => selectedAction = val!),
                  ),
                  const SizedBox(height: 8),
                  _buildRefundOption(
                    title: 'Reembolso / Devolución',
                    subtitle: 'Marca el pago como REEMBOLSADO para registrar la devolución del dinero al cliente.',
                    value: 'refund',
                    groupValue: selectedAction,
                    onChanged: (val) => setDialogState(() => selectedAction = val!),
                  ),
                  const SizedBox(height: 8),
                  _buildRefundOption(
                    title: 'Solo revocar acceso (Sin reembolso)',
                    subtitle: 'Cancela la membresía y bloquea el acceso sin devolver ni acreditar el importe pagado.',
                    value: 'revoke_only',
                    groupValue: selectedAction,
                    onChanged: (val) => setDialogState(() => selectedAction = val!),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Volver'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(isPending ? 'Anular Deuda y Cancelar' : 'Confirmar Cancelación'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      final s = ref.read(memberServiceProvider);
      try {
        final res = await s.removeMembership(
          _currentMember.id,
          action: isPending ? null : selectedAction,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message']?.toString() ?? 'Membresía cancelada exitosamente'),
            backgroundColor: AppTheme.success,
          ),
        );
        _loadAllHistory();
        ref.read(membersProvider.notifier).loadMembers();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Widget _buildRefundOption({
    required String title,
    required String subtitle,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.12) : const Color(0xFF252A34),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.white12,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 20,
              color: isSelected ? AppTheme.primary : Colors.white38,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Colors.white54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TAB 3: Asistencias
  Widget _buildAttendancesTab() {
    if (_attendancesHistory.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time_outlined, size: 48, color: Colors.white24),
            SizedBox(height: 12),
            Text('No hay registros de asistencia para este socio.', style: TextStyle(color: Colors.white54)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: DataTable(
            headingRowHeight: 40,
            dataRowMinHeight: 46,
            dataRowMaxHeight: 46,
            columns: const [
              DataColumn(label: Text('Fecha y Hora', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Dispositivo / Punto', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Detalle / Motivo', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: _attendancesHistory.map((a) {
              final rawDate = a['visitDate']?.toString() ?? a['checkInTime']?.toString();
              final dt = rawDate != null ? DateTime.tryParse(rawDate) : null;
              final device = a['device']?.toString() ?? a['accessPoint']?.toString() ?? 'Molinete Principal';
              final status = a['status']?.toString() ?? 'AUTHORIZED';
              final isAllowed = status == 'AUTHORIZED' || status == 'PERMITTED';
              final reason = a['rejectionReason']?.toString() ?? a['notes']?.toString() ?? (isAllowed ? 'Acceso correcto' : 'Denegado');

              return DataRow(
                cells: [
                  DataCell(Text(dt != null ? _dateTimeFormat.format(dt.isUtc ? dt.toLocal() : dt) : '-')),
                  DataCell(Text(device, style: const TextStyle(fontSize: 12))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isAllowed ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isAllowed ? 'AUTORIZADO' : 'RECHAZADO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isAllowed ? Colors.greenAccent : Colors.redAccent,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      reason,
                      style: TextStyle(
                        fontSize: 12,
                        color: isAllowed ? Colors.white70 : Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // TAB 4: Datos Personales
  Widget _buildPersonalDataTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Información Detallada de Contacto y Emergencia', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoTile('Cédula / Documento', _currentMember.documentId ?? 'No registrada', Icons.badge_outlined),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoTile('Teléfono Móvil', _currentMember.phone ?? 'No registrado', Icons.phone_outlined),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoTile('Correo Electrónico', _currentMember.email ?? 'No registrado', Icons.email_outlined),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoTile('Género', _currentMember.gender == 'F' ? 'Femenino' : 'Masculino', Icons.people_outline),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoTile('Dirección Residencial', _currentMember.address ?? 'No registrada', Icons.home_outlined),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoTile('Contacto de Emergencia', _currentMember.emergencyContact ?? 'No especificado', Icons.contact_emergency_outlined),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoTile('Teléfono de Emergencia', _currentMember.emergencyPhone ?? 'No especificado', Icons.phone_in_talk_outlined),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E232B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(MemberModel member) {
    Color bg;
    Color fg;
    String label = member.statusLabel;

    switch (label) {
      case 'Al Día':
        bg = AppTheme.success.withValues(alpha: 0.15);
        fg = Colors.greenAccent;
        break;
      case 'Vencido':
        bg = AppTheme.error.withValues(alpha: 0.15);
        fg = Colors.redAccent;
        break;
      case 'Pago Pendiente':
        bg = AppTheme.warning.withValues(alpha: 0.15);
        fg = Colors.orangeAccent;
        break;
      default:
        bg = Colors.white.withValues(alpha: 0.08);
        fg = Colors.white60;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  Widget _buildPaymentStatusBadge(String status) {
    final s = status.toUpperCase();
    Color bg;
    Color fg;
    String label = s;

    if (s.contains('PAID') || s.contains('COMPLET')) {
      bg = Colors.green.withValues(alpha: 0.15);
      fg = Colors.greenAccent;
      label = 'PAGADO';
    } else if (s.contains('PEND')) {
      bg = Colors.orange.withValues(alpha: 0.15);
      fg = Colors.orangeAccent;
      label = 'PENDIENTE';
    } else {
      bg = Colors.red.withValues(alpha: 0.15);
      fg = Colors.redAccent;
      label = 'FALLIDO';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  String _translateMethod(String m) {
    final low = m.toLowerCase();
    if (low.contains('cash')) return 'Efectivo';
    if (low.contains('card')) return 'Tarjeta';
    if (low.contains('transfer')) return 'Transferencia';
    return m;
  }

  // =========================================================================
  // TAB DE GRUPO FAMILIAR / ACOMPAÑANTES
  // =========================================================================

  Widget _buildFamilyGroupTab() {
    if (_memberGroups.isEmpty) {
      return Center(
        child: Container(
          width: 520,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF1B2028),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.family_restroom_outlined, size: 48, color: Colors.purpleAccent),
              ),
              const SizedBox(height: 18),
              const Text(
                'Sin Grupo Familiar Vinculado',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'Este socio no cuenta actualmente con una membresía grupal activa ni figura como acompañante de otro titular familiar.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.white60, height: 1.4),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add_card, size: 18),
                label: const Text('Asignar Plan Familiar / Grupal'),
                onPressed: _openAssignMembership,
              ),
            ],
          ),
        ),
      );
    }

    final group = _memberGroups.first;
    final isTitular = group.responsibleUserId == _currentMember.userId || group.responsibleUserId == _currentMember.id;
    final maxComp = group.maxGroupCompanions ?? 0;
    final currentCount = group.companions.length;
    final progress = maxComp > 0 ? (currentCount / maxComp).clamp(0.0, 1.0) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Principal del Grupo
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2E1A47).withValues(alpha: 0.8),
                  const Color(0xFF1B2028),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.4)),
                      ),
                      child: const Icon(Icons.groups_outlined, color: Colors.purpleAccent, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  group.name,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isTitular
                                      ? Colors.tealAccent.withValues(alpha: 0.15)
                                      : Colors.orangeAccent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isTitular ? Colors.tealAccent : Colors.orangeAccent,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  isTitular ? '★ Titular Responsable' : 'Acompañante Familiar',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isTitular ? Colors.tealAccent : Colors.orangeAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Plan: ${group.membershipName ?? "Membresía Familiar"} • Vigencia: ${group.startDate != null ? _dateFormat.format(group.startDate!) : "-"} al ${group.endDate != null ? _dateFormat.format(group.endDate!) : "-"}',
                            style: const TextStyle(fontSize: 13, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 16),

                // Métricas y Cupo
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                maxComp > 0
                                    ? 'Cupos de familiares: $currentCount de $maxComp ocupados'
                                    : 'Acompañantes registrados: $currentCount',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
                              ),
                              if (group.pricePerCompanion != null && group.pricePerCompanion! > 0)
                                Text(
                                  'Costo adicional: RD\$ ${group.pricePerCompanion!.toStringAsFixed(2)} / familiar',
                                  style: const TextStyle(fontSize: 12, color: Colors.purpleAccent, fontWeight: FontWeight.w600),
                                ),
                            ],
                          ),
                          if (maxComp > 0) ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 8,
                                backgroundColor: Colors.white10,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  progress >= 1.0 ? Colors.redAccent : Colors.purpleAccent,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: group.canAddCompanions ? Colors.purpleAccent.shade400 : Colors.grey.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.person_add_alt_1, size: 16),
                      label: Text(
                        group.canAddCompanions ? '+ Agregar Familiar' : 'Cupo Lleno',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      onPressed: group.canAddCompanions ? () => _openAddCompanionDialog(group) : null,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Título de Acompañantes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Miembros Familiares / Acompañantes (${group.companions.length})',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              if (group.companions.isNotEmpty)
                Text(
                  '${group.availableSlots} cupo(s) disponible(s)',
                  style: const TextStyle(fontSize: 12, color: Colors.white54),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Lista de Acompañantes
          if (group.companions.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(28),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1B2028),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.person_outline, size: 36, color: Colors.white30),
                  const SizedBox(height: 10),
                  const Text(
                    'No hay acompañantes registrados todavía',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Haz clic en "+ Agregar Familiar" para vincular un socio existente como acompañante.',
                    style: TextStyle(fontSize: 12, color: Colors.white38),
                  ),
                ],
              ),
            ),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: group.companions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final comp = group.companions[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B2028),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.purple.withValues(alpha: 0.2),
                        child: Text(
                          comp.memberName.isNotEmpty ? comp.memberName[0].toUpperCase() : 'F',
                          style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Nombre y Datos
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  comp.memberName,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.purpleAccent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    comp.relationship,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.purpleAccent),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Código: ${comp.memberCode ?? "S/C"}${comp.memberPhone != null && comp.memberPhone!.isNotEmpty ? " • Tel: ${comp.memberPhone}" : ""}${comp.memberEmail != null && comp.memberEmail!.isNotEmpty ? " • ${comp.memberEmail}" : ""}',
                              style: const TextStyle(fontSize: 12, color: Colors.white54),
                            ),
                          ],
                        ),
                      ),

                      // Estado
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Activo',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Botón Desvincular
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                        tooltip: 'Desvincular Familiar',
                        onPressed: () => _confirmRemoveCompanion(group, comp),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // Diálogo para Agregar Familiar
  Future<void> _openAddCompanionDialog(GroupModel group) async {
    final memberService = ref.read(memberServiceProvider);
    final groupService = ref.read(groupServiceProvider);

    // Cargar socios activos para seleccionar
    final membersResponse = await memberService.getMembers(limit: 100);
    final existingCompanionIds = group.companions.map((c) => c.memberId).toSet();
    
    // Filtrar para no mostrar al titular ni a quienes ya están en el grupo
    final availableMembers = membersResponse.members.where((m) {
      if (m.id == _currentMember.id) return false;
      if (existingCompanionIds.contains(m.id)) return false;
      return true;
    }).toList();

    if (!mounted) return;

    String? selectedMemberId;
    String selectedRelationship = 'Esposo/a';
    final customRelCtrl = TextEditingController();
    bool isCustomRel = false;
    bool isSubmitting = false;
    String searchQuery = '';

    final relationshipsList = ['Esposo/a', 'Hijo/a', 'Hermano/a', 'Padre/Madre', 'Primo/a', 'Sobrino/a', 'Otro'];

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final filteredMembers = availableMembers.where((m) {
            if (searchQuery.trim().isEmpty) return true;
            final q = searchQuery.toLowerCase();
            return m.fullName.toLowerCase().contains(q) ||
                (m.documentId?.toLowerCase().contains(q) ?? false) ||
                (m.memberCode?.toLowerCase().contains(q) ?? false);
          }).toList();

          return AlertDialog(
            backgroundColor: const Color(0xFF1B2028),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person_add_alt_1, color: Colors.purpleAccent, size: 22),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Agregar Familiar al Grupo',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
                ),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vincula a un socio existente al grupo "${group.name}". Se sincronizará su vigencia y acceso.',
                      style: const TextStyle(fontSize: 13, color: Colors.white60),
                    ),
                    const SizedBox(height: 16),

                    // Buscar socio
                    const Text('Buscar Socio *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                    const SizedBox(height: 6),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre, código o cédula...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onChanged: (val) => setDialogState(() => searchQuery = val),
                    ),

                    const SizedBox(height: 10),

                    // Lista de resultados
                    Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: const Color(0xFF14171C),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: filteredMembers.isEmpty
                          ? const Center(
                              child: Text(
                                'No se encontraron socios disponibles.\nAsegúrate de que esté registrado en el sistema.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: Colors.white38),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredMembers.length,
                              itemBuilder: (context, idx) {
                                final m = filteredMembers[idx];
                                final isSelected = m.id == selectedMemberId;
                                return ListTile(
                                  dense: true,
                                  selected: isSelected,
                                  selectedTileColor: Colors.purple.withValues(alpha: 0.15),
                                  leading: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: isSelected ? Colors.purpleAccent : Colors.white12,
                                    child: Text(
                                      m.firstName.isNotEmpty ? m.firstName[0].toUpperCase() : 'S',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : Colors.white70,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    m.fullName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? Colors.purpleAccent : Colors.white,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Código: ${m.displayCode} • ${m.phone ?? m.email ?? "Sin contacto"}',
                                    style: const TextStyle(fontSize: 11, color: Colors.white54),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(Icons.check_circle, color: Colors.purpleAccent, size: 18)
                                      : null,
                                  onTap: () => setDialogState(() => selectedMemberId = m.id),
                                );
                              },
                            ),
                    ),

                    const SizedBox(height: 18),

                    // Parentesco
                    const Text('Parentesco / Relación *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: relationshipsList.map((rel) {
                        final isSel = (!isCustomRel && selectedRelationship == rel) || (isCustomRel && rel == 'Otro');
                        return ChoiceChip(
                          label: Text(rel, style: TextStyle(fontSize: 12, color: isSel ? Colors.white : Colors.white70)),
                          selected: isSel,
                          selectedColor: Colors.purpleAccent.shade700,
                          backgroundColor: const Color(0xFF272D37),
                          onSelected: (selected) {
                            if (selected) {
                              setDialogState(() {
                                if (rel == 'Otro') {
                                  isCustomRel = true;
                                } else {
                                  isCustomRel = false;
                                  selectedRelationship = rel;
                                }
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),

                    if (isCustomRel) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: customRelCtrl,
                        decoration: InputDecoration(
                          hintText: 'Escribe el parentesco (ej: Ahijado, Sobrina, etc.)',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent.shade400,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: (selectedMemberId == null || isSubmitting)
                    ? null
                    : () async {
                        setDialogState(() => isSubmitting = true);
                        final rel = isCustomRel && customRelCtrl.text.trim().isNotEmpty
                            ? customRelCtrl.text.trim()
                            : selectedRelationship;

                        final result = await groupService.addCompanion(
                          groupId: group.id,
                          memberId: selectedMemberId!,
                          relationship: rel,
                        );

                        if (context.mounted) {
                          Navigator.of(ctx).pop();
                          if (result.success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✓ Familiar agregado al grupo exitosamente'),
                                backgroundColor: AppTheme.success,
                              ),
                            );
                            await _loadAllHistory();
                            ref.read(membersProvider.notifier).loadMembers();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result.message ?? 'Error al agregar familiar'),
                                backgroundColor: AppTheme.error,
                              ),
                            );
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Guardar y Vincular', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  // Diálogo para Desvincular Familiar
  Future<void> _confirmRemoveCompanion(GroupModel group, GroupCompanionModel companion) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B2028),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
            SizedBox(width: 10),
            Text('¿Desvincular Familiar?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas retirar a "${companion.memberName}" (${companion.relationship}) del grupo familiar?\n\nSu membresía asociada quedará cancelada.',
          style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sí, Desvincular'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final res = await ref.read(groupServiceProvider).removeCompanion(
        groupId: group.id,
        companionId: companion.id,
      );

      if (mounted) {
        if (res.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Familiar desvinculado del grupo'),
              backgroundColor: AppTheme.success,
            ),
          );
          await _loadAllHistory();
          ref.read(membersProvider.notifier).loadMembers();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res.message ?? 'Error al desvincular familiar'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }
}

