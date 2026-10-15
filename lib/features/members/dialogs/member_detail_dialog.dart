import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/receipt_printing_service.dart';
import '../../../../core/theme/app_theme.dart';
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

  final _currencyFormat = NumberFormat.currency(locale: 'es_DO', symbol: 'RD\$ ', decimalDigits: 2);
  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _dateTimeFormat = DateFormat('dd/MM/yyyy hh:mm a');

  @override
  void initState() {
    super.initState();
    _currentMember = widget.member;
    _tabController = TabController(length: 4, vsync: this);
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

    try {
      final futures = await Future.wait([
        service.getMembershipsHistory(_currentMember.id),
        service.getPaymentHistory(_currentMember.id),
        service.getAttendancesHistory(_currentMember.id),
        service.getMemberById(_currentMember.id),
      ]);

      if (mounted) {
        setState(() {
          _membershipsHistory = futures[0] as List<Map<String, dynamic>>;
          _paymentHistory = futures[1] as Map<String, dynamic>;
          _attendancesHistory = futures[2] as List<Map<String, dynamic>>;
          _currentMember = futures[3] as MemberModel;
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
                            ? 'Última: ${_dateFormat.format(DateTime.tryParse(_attendancesHistory.first['visitDate']?.toString() ?? '') ?? DateTime.now())}'
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
              final startDt = startRaw != null ? DateTime.tryParse(startRaw) : null;
              final endDt = endRaw != null ? DateTime.tryParse(endRaw) : null;
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
                  DataCell(Text(dt != null ? _dateTimeFormat.format(dt) : '-')),
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
    final startDate = rawStart != null ? DateTime.tryParse(rawStart) : null;
    final endDate = rawEnd != null ? DateTime.tryParse(rawEnd) : _currentMember.membershipEndDate;

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
                  DataCell(Text(dt != null ? _dateTimeFormat.format(dt) : '-')),
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
}
