import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_permissions.dart';
import '../../../core/services/receipt_printing_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../dialogs/cancel_sale_dialog.dart';
import '../dialogs/cash_withdrawal_dialog.dart';
import '../dialogs/close_cash_dialog.dart';
import '../dialogs/open_cash_dialog.dart';
import '../dialogs/sale_detail_dialog.dart';
import '../models/sale_history_model.dart';
import '../providers/cash_register_provider.dart';
import '../widgets/closures_history_tab.dart';
import '../widgets/payments_history_tab.dart';
import '../widgets/sales_history_tab.dart';
import '../widgets/shift_hero_card.dart';
import '../widgets/shift_transactions_strip.dart';

class CashRegisterScreen extends ConsumerStatefulWidget {
  const CashRegisterScreen({super.key});

  @override
  ConsumerState<CashRegisterScreen> createState() => _CashRegisterScreenState();
}

class _CashRegisterScreenState extends ConsumerState<CashRegisterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openOpenDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const OpenCashDialog(),
    );
    if (result == true) {
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
    final isRegisterOpen = ref.read(cashRegisterProvider).isRegisterOpen;
    final canVoidSale = ref.read(authProvider).hasPermission(AppPermissions.posVoidSale);

    SaleDetailDialog.show(
      context: context,
      sale: sale,
      isRegisterOpen: isRegisterOpen,
      canVoidSale: canVoidSale,
      onReprint: () => _reprintSaleReceipt(sale),
      onCancelSale: () => _showCancelSaleDialog(sale),
    );
  }

  Future<void> _showCancelSaleDialog(SaleHistoryModel sale) async {
    final reason = await CancelSaleDialog.show(context, sale);

    if (reason != null) {
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
              backgroundColor: AppTheme.success,
            ),
          );
        } else {
          final error = ref.read(cashRegisterProvider).error ?? 'Error desconocido al anular venta';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Error: $error')),
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
    final authState = ref.watch(authProvider);

    final canOpen = authState.hasPermission(AppPermissions.cashOpen);
    final canClose = authState.hasPermission(AppPermissions.cashClose);
    final canWithdraw = authState.hasPermission(AppPermissions.cashWithdraw);
    final canViewHistory = authState.hasPermission(AppPermissions.cashViewHistory);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: const [
                    Icon(Icons.account_balance_wallet_outlined, color: AppTheme.primary, size: 24),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Control de Caja & Historial de Ventas',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
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
              : ShiftHeroCard(
                  state: state,
                  canOpen: canOpen,
                  canClose: canClose,
                  canWithdraw: canWithdraw,
                  onOpen: _openOpenDialog,
                  onClose: _openCloseDialog,
                  onWithdraw: _openWithdrawalDialog,
                ),

          const SizedBox(height: 16),

          // If shift has cash transactions (withdrawals or inflows), show them in an activity strip
          if (state.isRegisterOpen && state.currentTransactions.isNotEmpty) ...[
            ShiftTransactionsStrip(
              transactions: state.currentTransactions,
              totalInflows: state.totalInflows,
              totalWithdrawals: state.totalWithdrawals,
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
                  icon: Icon(
                    canViewHistory ? Icons.history : Icons.lock_outline,
                    size: 18,
                    color: canViewHistory ? null : Colors.amber,
                  ),
                  text: canViewHistory
                      ? 'Historial de Cierres (${state.history.length})'
                      : 'Historial de Cierres (Restringido)',
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
                SalesHistoryTab(
                  state: state,
                  onOpenRegister: _openOpenDialog,
                  onViewSale: _showSaleDetailDialog,
                  onReprintSale: _reprintSaleReceipt,
                  onCancelSale: _showCancelSaleDialog,
                ),
                PaymentsHistoryTab(
                  state: state,
                  onOpenRegister: _openOpenDialog,
                ),
                ClosuresHistoryTab(
                  state: state,
                  onViewSale: _showSaleDetailDialog,
                  onReprintSale: _reprintSaleReceipt,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
