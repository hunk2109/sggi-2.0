import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/services/receipt_printing_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../settings/providers/settings_provider.dart';
import '../dialogs/cash_withdrawal_dialog.dart';
import '../dialogs/close_cash_dialog.dart';
import '../dialogs/open_cash_dialog.dart';
import '../models/sale_history_model.dart';
import '../models/shift_payment_model.dart';
import '../providers/cash_register_provider.dart';

class CashRegisterScreen extends ConsumerStatefulWidget {
  const CashRegisterScreen({super.key});

  @override
  ConsumerState<CashRegisterScreen> createState() => _CashRegisterScreenState();
}

class _CashRegisterScreenState extends ConsumerState<CashRegisterScreen> with SingleTickerProviderStateMixin {
  final _currency = NumberFormat.currency(locale: 'es_DO', symbol: 'RD\$ ', decimalDigits: 2);
  final _dateTime = DateFormat('dd/MM/yyyy hh:mm a');
  final _timeFormat = DateFormat('hh:mm a');

  late TabController _tabController;
  final TextEditingController _salesSearchCtrl = TextEditingController();
  final TextEditingController _paymentsSearchCtrl = TextEditingController();

  final Map<String, List<SaleHistoryModel>> _historyShiftSales = {};
  final Map<String, List<ShiftPaymentModel>> _historyShiftPayments = {};
  final Set<String> _loadingShiftIds = {};
  final Set<String> _expandedShiftIds = {};

  Future<void> _toggleShiftExpansion(String registerId) async {
    setState(() {
      if (_expandedShiftIds.contains(registerId)) {
        _expandedShiftIds.remove(registerId);
      } else {
        _expandedShiftIds.add(registerId);
      }
    });

    if (_expandedShiftIds.contains(registerId) && (!_historyShiftSales.containsKey(registerId) || !_historyShiftPayments.containsKey(registerId))) {
      setState(() => _loadingShiftIds.add(registerId));
      try {
        final service = ref.read(cashRegisterServiceProvider);
        final results = await Future.wait([
          service.getSales(cashRegisterId: registerId, limit: 100),
          service.getPayments(registerId),
        ]);
        if (mounted) {
          setState(() {
            _historyShiftSales[registerId] = results[0] as List<SaleHistoryModel>;
            _historyShiftPayments[registerId] = results[1] as List<ShiftPaymentModel>;
            _loadingShiftIds.remove(registerId);
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _loadingShiftIds.remove(registerId));
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _salesSearchCtrl.dispose();
    _paymentsSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openOpenDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const OpenCashDialog(),
    );
    if (result == true) {
      setState(() {
        _historyShiftSales.clear();
        _expandedShiftIds.clear();
      });
      ref.read(cashRegisterProvider.notifier).loadInitialData();
    }
  }

  Future<void> _openWithdrawalDialog() async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CashWithdrawalDialog(),
    );
  }

  Future<void> _openCloseDialog() async {
    final register = ref.read(cashRegisterProvider).currentRegister;
    if (register == null) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CloseCashDialog(register: register),
    );
    if (result == true) {
      setState(() {
        _historyShiftSales.clear();
        _expandedShiftIds.clear();
      });
      ref.read(cashRegisterProvider.notifier).loadInitialData();
    }
  }

  Future<void> _reprintSaleReceipt(SaleHistoryModel sale) async {
    final gymSettings = ref.read(gymSettingsProvider).settings;
    try {
      await ReceiptPrintingService.printSaleReceipt(
        items: sale.toCartItems(),
        total: sale.totalAmount,
        subtotal: sale.totalAmount + sale.discount,
        discount: sale.discount,
        paymentMethod: sale.paymentMethod,
        amountReceived: 0,
        change: 0,
        customerName: sale.customerName,
        saleId: sale.id,
        gymSettings: gymSettings,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al imprimir comprobante: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  void _showSaleDetailDialog(SaleHistoryModel sale) {
    final isCancelled = sale.status == 'cancelled';
    final isRegisterOpen = ref.read(cashRegisterProvider).isRegisterOpen;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B2028),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            Icon(
              isCancelled ? Icons.cancel : Icons.receipt_long,
              color: isCancelled ? Colors.redAccent : AppTheme.primary,
              size: 24,
            ),
            const SizedBox(width: 10),
            Text('Detalle de Venta #${sale.shortId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isCancelled) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          sale.notes?.contains('[ANULADA') == true
                              ? sale.notes!
                              : 'Esta venta ha sido anulada y sus productos reintegrados al inventario.',
                          style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Cliente: ${sale.customerName}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(_dateTime.format(sale.createdAt), style: const TextStyle(fontSize: 12, color: Colors.white60)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text('Método de pago: ', style: TextStyle(fontSize: 12, color: Colors.white60)),
                  _buildPaymentMethodBadge(sale.paymentMethod),
                ],
              ),
              const Divider(height: 24, color: AppTheme.darkBorder),
              const Text('Artículos Comprados:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70)),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: sale.items.length,
                  separatorBuilder: (_, _) => const Divider(height: 12, color: Colors.white10),
                  itemBuilder: (_, index) {
                    final item = sale.items[index];
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text('${item.quantity}x ${item.productName}', style: const TextStyle(fontSize: 13)),
                        ),
                        Text(
                          _currency.format(item.subtotal),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const Divider(height: 24, color: AppTheme.darkBorder),
              if (sale.discount > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Descuento aplicado:', style: TextStyle(fontSize: 13, color: Colors.amberAccent)),
                      Text('- ${_currency.format(sale.discount)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                    ],
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL COBRADO:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  Text(
                    _currency.format(sale.totalAmount),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isCancelled ? Colors.redAccent : Colors.greenAccent,
                      decoration: isCancelled ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar', style: TextStyle(color: Colors.white60)),
          ),
          if (!isCancelled && isRegisterOpen)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
              ),
              icon: const Icon(Icons.cancel_outlined, size: 16),
              label: const Text('Anular Venta'),
              onPressed: () {
                Navigator.of(ctx).pop();
                _showCancelSaleDialog(sale);
              },
            ),
          if (!isCancelled)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              icon: const Icon(Icons.print, size: 16),
              label: const Text('Imprimir Ticket (Windows)'),
              onPressed: () {
                Navigator.of(ctx).pop();
                _reprintSaleReceipt(sale);
              },
            ),
        ],
      ),
    );
  }

  Future<void> _showCancelSaleDialog(SaleHistoryModel sale) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B2028),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('¿Anular esta venta?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white)),
                  Text('Ticket #${sale.shortId} • Turno de Caja Activo', style: const TextStyle(fontSize: 12, color: Colors.white54)),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: Colors.redAccent),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Esta acción cancelará la venta, devolverá automáticamente los productos al inventario y restará el importe del total de tu caja abierta.',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Cliente: ${sale.customerName}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(
                      'Total: ${_currency.format(sale.totalAmount)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.greenAccent),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Artículos que regresarán a inventario:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: sale.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('• ${item.quantity}x ${item.productName}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                          Text('+${item.quantity} al stock', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Motivo de anulación (Opcional):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 6),
                TextField(
                  controller: reasonController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Ej: Error de cobro, cliente canceló el pedido, producto devuelto...',
                    hintStyle: const TextStyle(fontSize: 12, color: Colors.white38),
                    filled: true,
                    fillColor: Colors.black26,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white12)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white12)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.redAccent)),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_forever, size: 18),
            label: const Text('Confirmar Anulación'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final reason = reasonController.text.trim();
      final success = await ref.read(cashRegisterProvider.notifier).cancelSale(
        sale.id,
        reason: reason.isNotEmpty ? reason : null,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 10),
                  Text('Venta #${sale.shortId} anulada y productos devueltos al stock.'),
                ],
              ),
              backgroundColor: Colors.green.shade800,
            ),
          );
        } else {
          final error = ref.read(cashRegisterProvider).error ?? 'Error al anular venta';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(child: Text(error)),
                ],
              ),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cashRegisterProvider);
    final notifier = ref.read(cashRegisterProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.account_balance_wallet_outlined, color: AppTheme.primary, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Control de Caja & Historial de Ventas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Actualizar caja y ventas',
                onPressed: () => notifier.loadInitialData(),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Active Shift Banner / Hero Card
          state.isLoading
              ? const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
              : _buildShiftHeroCard(state),

          const SizedBox(height: 16),

          // If shift has cash withdrawals, show them in an activity strip
          if (state.isRegisterOpen && state.currentTransactions.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E232B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.receipt_outlined, size: 16, color: Colors.orangeAccent),
                          SizedBox(width: 8),
                          Text('Salidas y Gastos Registrados en este Turno', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      Text(
                        'Total Egresos: ${_currency.format(state.totalWithdrawals)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: state.currentTransactions.map((tx) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${tx.concept}: -${_currency.format(tx.amount)} (${_timeFormat.format(tx.createdAt)})',
                          style: const TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Tab Bar de Ventas, Membresías y Cierres
          Container(
            decoration: BoxDecoration(
              color: AppTheme.darkSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.darkBorder),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primary,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              tabs: [
                Tab(
                  icon: const Icon(Icons.point_of_sale, size: 18),
                  text: state.isRegisterOpen
                      ? 'Ventas Mostrador (${state.sales.length})'
                      : 'Ventas Mostrador (0)',
                ),
                Tab(
                  icon: const Icon(Icons.card_membership, size: 18),
                  text: state.isRegisterOpen
                      ? 'Cobros Membresías (${state.payments.length})'
                      : 'Cobros Membresías (0)',
                ),
                Tab(
                  icon: const Icon(Icons.history, size: 18),
                  text: 'Historial de Cierres (${state.history.length})',
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSalesHistoryTab(state),
                _buildPaymentsHistoryTab(state),
                _buildClosuresHistoryTab(state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= TAB 1: HISTORIAL DE VENTAS DEL TURNO =================
  Widget _buildSalesHistoryTab(CashRegisterState state) {
    if (!state.isRegisterOpen) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline, size: 48, color: Colors.white38),
              ),
              const SizedBox(height: 16),
              const Text(
                'No hay un turno de caja abierto',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 6),
              const Text(
                'Esta sección solo muestra las ventas del turno activo actual.\nPara consultar ventas de turnos anteriores, diríjase a la pestaña "Historial de Cierres de Turno".',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.white54, height: 1.4),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.lock_open, size: 18),
                label: const Text('Iniciar Turno / Abrir Caja'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                ),
                onPressed: _openOpenDialog,
              ),
            ],
          ),
        ),
      );
    }

    final query = _salesSearchCtrl.text.trim().toLowerCase();
    final filteredSales = state.sales.where((s) {
      if (query.isEmpty) return true;
      final matchCustomer = s.customerName.toLowerCase().contains(query);
      final matchId = s.id.toLowerCase().contains(query);
      final matchProduct = s.items.any((i) => i.productName.toLowerCase().contains(query));
      return matchCustomer || matchId || matchProduct;
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Barra de Búsqueda y Estadísticas de Ventas
          Row(
            children: [
              Expanded(
                flex: 4,
                child: TextField(
                  controller: _salesSearchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Buscar por cliente, ticket o producto...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: _salesSearchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _salesSearchCtrl.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    fillColor: AppTheme.darkSurface,
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.darkBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.darkBorder)),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.attach_money, size: 18, color: Colors.greenAccent),
                    const SizedBox(width: 4),
                    Text(
                      'Total Facturado: ${_currency.format(state.totalSalesAmount)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.greenAccent),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Expanded(
            child: filteredSales.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_bag_outlined, size: 48, color: Colors.white24),
                        const SizedBox(height: 10),
                        Text(
                          query.isEmpty
                              ? 'No se han registrado ventas en este turno aún'
                              : 'No se encontraron ventas para "$query"',
                          style: const TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: SizedBox(
                      width: double.infinity,
                      child: DataTable(
                        headingRowHeight: 42,
                        dataRowMinHeight: 48,
                        dataRowMaxHeight: 52,
                        columns: const [
                          DataColumn(label: Text('Ticket No.', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Fecha y Hora', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Cliente', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Artículos Comprados', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Método', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: filteredSales.map((sale) {
                          final isCancelled = sale.status == 'cancelled';
                          final itemsSummary = sale.items.isNotEmpty
                              ? sale.items.map((i) => '${i.quantity}x ${i.productName}').join(', ')
                              : 'Sin desglose';

                          return DataRow(
                            cells: [
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isCancelled ? Icons.cancel_outlined : Icons.receipt_outlined,
                                      size: 14,
                                      color: isCancelled ? Colors.redAccent : Colors.white70,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '#${sale.shortId}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isCancelled ? Colors.white54 : Colors.white,
                                        decoration: isCancelled ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(Text(_dateTime.format(sale.createdAt))),
                              DataCell(
                                Text(
                                  sale.customerName,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              DataCell(
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 240),
                                  child: Text(
                                    itemsSummary,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                                  ),
                                ),
                              ),
                              DataCell(_buildPaymentMethodBadge(sale.paymentMethod)),
                              DataCell(
                                Text(
                                  _currency.format(sale.totalAmount),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isCancelled ? Colors.redAccent.withValues(alpha: 0.6) : Colors.greenAccent,
                                    decoration: isCancelled ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isCancelled
                                        ? Colors.red.withValues(alpha: 0.15)
                                        : Colors.green.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isCancelled ? 'ANULADA' : 'COMPLETADA',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isCancelled ? Colors.redAccent : Colors.greenAccent,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.visibility_outlined, size: 18),
                                      tooltip: 'Ver Detalle',
                                      onPressed: () => _showSaleDetailDialog(sale),
                                    ),
                                    if (!isCancelled)
                                      IconButton(
                                        icon: const Icon(Icons.print, size: 18, color: Colors.blueAccent),
                                        tooltip: 'Reimprimir Ticket (Windows)',
                                        onPressed: () => _reprintSaleReceipt(sale),
                                      ),
                                    if (!isCancelled && state.isRegisterOpen)
                                      IconButton(
                                        icon: const Icon(Icons.cancel_outlined, size: 18, color: Colors.redAccent),
                                        tooltip: 'Anular Venta de este Turno',
                                        onPressed: () => _showCancelSaleDialog(sale),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ================= TAB 2: HISTORIAL DE COBROS DE MEMBRESÍAS DEL TURNO =================
  Widget _buildPaymentsHistoryTab(CashRegisterState state) {
    if (!state.isRegisterOpen) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline, size: 48, color: Colors.white38),
              ),
              const SizedBox(height: 16),
              const Text(
                'No hay un turno de caja abierto',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 6),
              const Text(
                'Esta sección solo muestra los cobros de membresías del turno activo actual.\nPara consultar turnos anteriores, diríjase a la pestaña "Historial de Cierres".',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.white54, height: 1.4),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.lock_open, size: 18),
                label: const Text('Iniciar Turno / Abrir Caja'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                ),
                onPressed: _openOpenDialog,
              ),
            ],
          ),
        ),
      );
    }

    final query = _paymentsSearchCtrl.text.trim().toLowerCase();
    final filteredPayments = state.payments.where((p) {
      if (query.isEmpty) return true;
      final matchMember = p.memberName.toLowerCase().contains(query);
      final matchCode = p.memberCode.toLowerCase().contains(query);
      final matchPlan = p.planName.toLowerCase().contains(query);
      final matchId = p.id.toLowerCase().contains(query);
      return matchMember || matchCode || matchPlan || matchId;
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Barra de Búsqueda y Estadísticas de Membresías
          Row(
            children: [
              Expanded(
                flex: 4,
                child: TextField(
                  controller: _paymentsSearchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Buscar por socio, código de socio, plan...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: _paymentsSearchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _paymentsSearchCtrl.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    fillColor: AppTheme.darkSurface,
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.darkBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.darkBorder)),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.card_membership, size: 18, color: Colors.cyanAccent),
                    const SizedBox(width: 6),
                    Text(
                      'Total Membresías: ${_currency.format(state.totalPaymentsAmount)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.cyanAccent),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '(Efectivo: ${_currency.format(state.cashPaymentsAmount)})',
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Expanded(
            child: filteredPayments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.card_membership_outlined, size: 48, color: Colors.white24),
                        const SizedBox(height: 10),
                        Text(
                          query.isEmpty
                              ? 'No se han registrado cobros de membresías en este turno'
                              : 'No se encontraron cobros para "$query"',
                          style: const TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: SizedBox(
                      width: double.infinity,
                      child: DataTable(
                        headingRowHeight: 42,
                        dataRowMinHeight: 48,
                        dataRowMaxHeight: 52,
                        horizontalMargin: 16,
                        columnSpacing: 20,
                        columns: const [
                          DataColumn(label: Text('Recibo', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Hora', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Socio', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Plan / Concepto', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Método', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: filteredPayments.map((p) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  '#${p.shortId}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                              DataCell(Text(_timeFormat.format(p.paymentDate ?? p.createdAt), style: const TextStyle(fontSize: 12))),
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(p.memberName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    if (p.memberCode.isNotEmpty)
                                      Text(p.memberCode, style: const TextStyle(fontSize: 11, color: Colors.white54)),
                                  ],
                                ),
                              ),
                              DataCell(
                                Text(
                                  p.planName.isNotEmpty ? p.planName : (p.notes ?? 'Membresía'),
                                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                                ),
                              ),
                              DataCell(_buildPaymentMethodBadge(p.paymentMethod)),
                              DataCell(
                                Text(
                                  _currency.format(p.amount),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.greenAccent),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'COMPLETADO',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.greenAccent,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ================= TAB 3: HISTORIAL DE CIERRES =================
  Widget _buildClosuresHistoryTab(CashRegisterState state) {
    if (state.history.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        padding: const EdgeInsets.all(32),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long_outlined, size: 48, color: Colors.white24),
              SizedBox(height: 12),
              Text('No hay registros históricos de cajas cerradas', style: TextStyle(color: Colors.white54, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: state.history.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final reg = state.history[index];
        final isExpanded = _expandedShiftIds.contains(reg.id);
        final isLoading = _loadingShiftIds.contains(reg.id);
        final shiftSales = _historyShiftSales[reg.id] ?? [];
        final shiftPayments = _historyShiftPayments[reg.id] ?? [];
        final diff = reg.difference ?? 0.0;
        final isBalanced = diff.abs() < 0.01;

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isExpanded ? AppTheme.primary.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.06),
              width: isExpanded ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila Principal del Turno (Clickeable para desplegar ventas)
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _toggleShiftExpansion(reg.id),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: reg.isOpen ? Colors.green.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          reg.isOpen ? Icons.lock_open : Icons.lock_outline,
                          size: 20,
                          color: reg.isOpen ? Colors.greenAccent : Colors.white54,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  reg.isOpen ? 'Turno en Curso' : 'Turno Cerrado',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: reg.isOpen ? Colors.green.withValues(alpha: 0.2) : Colors.white10,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    reg.isOpen ? 'ABIERTA' : 'CERRADA',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: reg.isOpen ? Colors.greenAccent : Colors.white54,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Apertura: ${_dateTime.format(reg.createdAt)}${reg.closedAt != null ? ' • Cierre: ${_dateTime.format(reg.closedAt!)}' : ''}',
                              style: const TextStyle(fontSize: 12, color: Colors.white54),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Desglose de Valores
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildShiftSummaryItem('Fondo Inicial', _currency.format(reg.openingAmount), Colors.white70),
                          const SizedBox(width: 20),
                          _buildShiftSummaryItem(
                            'Cierre Real',
                            reg.closingAmount != null ? _currency.format(reg.closingAmount!) : '-',
                            Colors.white,
                          ),
                          const SizedBox(width: 20),
                          _buildShiftSummaryItem(
                            'Esperado',
                            reg.expectedClosure != null ? _currency.format(reg.expectedClosure!) : '-',
                            Colors.white70,
                          ),
                          const SizedBox(width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Descuadre', style: TextStyle(fontSize: 11, color: Colors.white38)),
                              const SizedBox(height: 2),
                              if (reg.difference != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isBalanced
                                        ? Colors.green.withValues(alpha: 0.15)
                                        : (diff > 0 ? Colors.blue.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15)),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _currency.format(diff),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isBalanced
                                          ? Colors.greenAccent
                                          : (diff > 0 ? Colors.blueAccent : Colors.redAccent),
                                    ),
                                  ),
                                )
                              else
                                const Text('-', style: TextStyle(fontSize: 12, color: Colors.white54)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      // Botón / Chevron Expandir
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isExpanded ? AppTheme.primary.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isExpanded ? AppTheme.primary : Colors.white12,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isExpanded ? 'Ocultar Detalles' : 'Ver Detalles',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isExpanded ? AppTheme.primary : Colors.white70,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              size: 18,
                              color: isExpanded ? AppTheme.primary : Colors.white70,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Lista Desplegable / Contraíble de Ventas y Membresías del Turno
              if (isExpanded) ...[
                const Divider(height: 1, color: Colors.white10),
                Container(
                  width: double.infinity,
                  color: Colors.black.withValues(alpha: 0.25),
                  padding: const EdgeInsets.all(16),
                  child: isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                                SizedBox(width: 12),
                                Text('Cargando registros de este turno...', style: TextStyle(color: Colors.white54, fontSize: 13)),
                              ],
                            ),
                          ),
                        )
                      : (shiftSales.isEmpty && shiftPayments.isEmpty)
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.info_outline, size: 18, color: Colors.white38),
                                    SizedBox(width: 8),
                                    Text('No se realizaron ventas ni cobros de membresías durante este turno de caja.', style: TextStyle(color: Colors.white54, fontSize: 13)),
                                  ],
                                ),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (shiftSales.isNotEmpty) ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.receipt_long, size: 16, color: AppTheme.primary),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Ventas mostrador en este turno (${shiftSales.length})',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        'Subtotal Ventas: ${_currency.format(shiftSales.where((s) => s.status != 'cancelled').fold(0.0, (sum, s) => sum + s.totalAmount))}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.greenAccent),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: DataTable(
                                      headingRowHeight: 36,
                                      dataRowMinHeight: 44,
                                      dataRowMaxHeight: 48,
                                      horizontalMargin: 12,
                                      columnSpacing: 16,
                                      columns: const [
                                        DataColumn(label: Text('Ticket', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                        DataColumn(label: Text('Hora', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                        DataColumn(label: Text('Cliente', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                        DataColumn(label: Text('Artículos Comprados', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                        DataColumn(label: Text('Método', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                        DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                        DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                        DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                      ],
                                      rows: shiftSales.map((sale) {
                                        final isCancelled = sale.status == 'cancelled';
                                        final itemsSummary = sale.items.isNotEmpty
                                            ? sale.items.map((i) => '${i.quantity}x ${i.productName}').join(', ')
                                            : 'Sin desglose';

                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              Text(
                                                '#${sale.shortId}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  decoration: isCancelled ? TextDecoration.lineThrough : null,
                                                ),
                                              ),
                                            ),
                                            DataCell(Text(_timeFormat.format(sale.createdAt), style: const TextStyle(fontSize: 12))),
                                            DataCell(Text(sale.customerName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                            DataCell(
                                              ConstrainedBox(
                                                constraints: const BoxConstraints(maxWidth: 220),
                                                child: Text(itemsSummary, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                                              ),
                                            ),
                                            DataCell(_buildPaymentMethodBadge(sale.paymentMethod)),
                                            DataCell(
                                              Text(
                                                _currency.format(sale.totalAmount),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: isCancelled ? Colors.redAccent.withValues(alpha: 0.6) : Colors.greenAccent,
                                                  decoration: isCancelled ? TextDecoration.lineThrough : null,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isCancelled ? Colors.red.withValues(alpha: 0.15) : Colors.green.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  isCancelled ? 'ANULADA' : 'COMPLETADA',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    color: isCancelled ? Colors.redAccent : Colors.greenAccent,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.visibility_outlined, size: 16),
                                                    tooltip: 'Ver Detalle',
                                                    onPressed: () => _showSaleDetailDialog(sale),
                                                  ),
                                                  if (!isCancelled)
                                                    IconButton(
                                                      icon: const Icon(Icons.print, size: 16, color: Colors.blueAccent),
                                                      tooltip: 'Reimprimir Ticket',
                                                      onPressed: () => _reprintSaleReceipt(sale),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],

                                if (shiftSales.isNotEmpty && shiftPayments.isNotEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Divider(color: Colors.white12),
                                  ),

                                if (shiftPayments.isNotEmpty) ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.card_membership, size: 16, color: Colors.cyanAccent),
                                          SizedBox(width: 8),
                                          Text(
                                            'Cobros de membresías en este turno',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        'Subtotal Membresías: ${_currency.format(shiftPayments.fold(0.0, (sum, p) => sum + p.amount))}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.cyanAccent),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: DataTable(
                                      headingRowHeight: 36,
                                      dataRowMinHeight: 44,
                                      dataRowMaxHeight: 48,
                                      horizontalMargin: 12,
                                      columnSpacing: 16,
                                      columns: const [
                                        DataColumn(label: Text('Recibo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                        DataColumn(label: Text('Hora', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                        DataColumn(label: Text('Socio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                        DataColumn(label: Text('Plan / Concepto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                        DataColumn(label: Text('Método', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                        DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                        DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                      ],
                                      rows: shiftPayments.map((p) {
                                        return DataRow(
                                          cells: [
                                            DataCell(Text('#${p.shortId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                            DataCell(Text(_timeFormat.format(p.paymentDate ?? p.createdAt), style: const TextStyle(fontSize: 12))),
                                            DataCell(
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(p.memberName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                                  if (p.memberCode.isNotEmpty)
                                                    Text(p.memberCode, style: const TextStyle(fontSize: 10, color: Colors.white54)),
                                                ],
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                p.planName.isNotEmpty ? p.planName : (p.notes ?? 'Membresía'),
                                                style: const TextStyle(fontSize: 12, color: Colors.white70),
                                              ),
                                            ),
                                            DataCell(_buildPaymentMethodBadge(p.paymentMethod)),
                                            DataCell(
                                              Text(
                                                _currency.format(p.amount),
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.greenAccent),
                                              ),
                                            ),
                                            DataCell(
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'COMPLETADO',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.greenAccent,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildShiftSummaryItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white38)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }

  Widget _buildPaymentMethodBadge(String method) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (method.toLowerCase()) {
      case 'cash':
        bg = Colors.green.withValues(alpha: 0.15);
        fg = Colors.greenAccent;
        label = 'Efectivo';
        icon = Icons.attach_money;
        break;
      case 'card':
        bg = Colors.blue.withValues(alpha: 0.15);
        fg = Colors.blueAccent;
        label = 'Tarjeta';
        icon = Icons.credit_card;
        break;
      case 'transfer':
        bg = Colors.purple.withValues(alpha: 0.15);
        fg = Colors.purpleAccent;
        label = 'Transferencia';
        icon = Icons.account_balance;
        break;
      default:
        bg = Colors.white10;
        fg = Colors.white70;
        label = method;
        icon = Icons.payment;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
        ],
      ),
    );
  }

  Widget _buildShiftHeroCard(CashRegisterState state) {
    final reg = state.currentRegister;

    if (reg == null || !reg.isOpen) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E232B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.lock_outline, size: 42, color: Colors.white38),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Caja Cerrada • No Hay Turno Activo',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Debe registrar el fondo inicial para habilitar las operaciones de cobro en mostrador.',
                      style: TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                  ],
                ),
              ],
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.lock_open, size: 18),
              label: const Text('Iniciar Turno / Abrir Caja'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              onPressed: _openOpenDialog,
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2618),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_open, color: Colors.greenAccent, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'TURNO ACTIVO • CAJA ABIERTA',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Apertura: ${_dateTime.format(reg.createdAt)}',
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Fondo Inicial: ', style: TextStyle(fontSize: 13, color: Colors.white60)),
                          Text(
                            _currency.format(reg.openingAmount),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Ventas Mostrador: ', style: TextStyle(fontSize: 13, color: Colors.white60)),
                          Text(
                            _currency.format(state.totalSalesAmount),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Membresías: ', style: TextStyle(fontSize: 13, color: Colors.white60)),
                          Text(
                            _currency.format(state.totalPaymentsAmount),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Total Cobrado: ', style: TextStyle(fontSize: 13, color: Colors.white60)),
                          Text(
                            _currency.format(state.totalShiftRevenue),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                          ),
                        ],
                      ),
                      if (state.totalWithdrawals > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Egresos: ', style: TextStyle(fontSize: 13, color: Colors.white60)),
                            Text(
                              '-${_currency.format(state.totalWithdrawals)}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.money_off_csred_outlined, size: 16),
                label: const Text('Registrar Salida / Gasto'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orangeAccent,
                  side: const BorderSide(color: Colors.orangeAccent),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onPressed: _openWithdrawalDialog,
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.lock_clock, size: 18),
                label: const Text('Cerrar Turno & Arqueo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
                onPressed: _openCloseDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
