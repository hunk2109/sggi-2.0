import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/cash_register_model.dart';
import '../models/sale_history_model.dart';
import '../models/shift_payment_model.dart';
import '../services/cash_register_service.dart';

final cashRegisterServiceProvider = Provider<CashRegisterService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CashRegisterService(apiClient);
});

class CashRegisterState {
  final bool isLoading;
  final bool isProcessing;
  final CashRegisterModel? currentRegister;
  final List<CashRegisterModel> history;
  final List<CashTransactionModel> currentTransactions;
  final List<SaleHistoryModel> sales;
  final List<ShiftPaymentModel> payments;
  final String? error;

  const CashRegisterState({
    this.isLoading = false,
    this.isProcessing = false,
    this.currentRegister,
    this.history = const [],
    this.currentTransactions = const [],
    this.sales = const [],
    this.payments = const [],
    this.error,
  });

  bool get isRegisterOpen => currentRegister != null && currentRegister!.isOpen;
  double get totalWithdrawals => currentTransactions.where((t) => t.isOut).fold(0.0, (sum, t) => sum + t.amount);
  double get totalInflows => currentTransactions.where((t) => t.isIn).fold(0.0, (sum, t) => sum + t.amount);
  
  // Ventas de Mostrador (POS)
  double get totalSalesAmount => isRegisterOpen
      ? sales.where((s) => s.status != 'cancelled').fold(0.0, (sum, s) => sum + s.totalAmount)
      : 0.0;
  double get cashSalesAmount => isRegisterOpen
      ? sales.where((s) => s.status != 'cancelled' && (s.paymentMethod == 'cash' || s.paymentMethod.isEmpty)).fold(0.0, (sum, s) => sum + s.totalAmount)
      : 0.0;
  int get completedSalesCount => isRegisterOpen
      ? sales.where((s) => s.status != 'cancelled').length
      : 0;

  // Cobros de Membresías del Turno
  double get totalPaymentsAmount => isRegisterOpen
      ? payments.where((p) => p.status != 'cancelled').fold(0.0, (sum, p) => sum + p.amount)
      : 0.0;
  double get cashPaymentsAmount => isRegisterOpen
      ? payments.where((p) => p.status != 'cancelled' && p.isCash).fold(0.0, (sum, p) => sum + p.amount)
      : 0.0;
  double get otherPaymentsAmount => isRegisterOpen
      ? payments.where((p) => p.status != 'cancelled' && !p.isCash).fold(0.0, (sum, p) => sum + p.amount)
      : 0.0;
  int get completedPaymentsCount => isRegisterOpen
      ? payments.where((p) => p.status != 'cancelled').length
      : 0;

  // Totales Combinados
  double get totalShiftRevenue => totalSalesAmount + totalPaymentsAmount + totalInflows;
  double get totalCashInDrawer => isRegisterOpen
      ? (currentRegister!.openingAmount + cashSalesAmount + cashPaymentsAmount + totalInflows - totalWithdrawals)
      : 0.0;

  CashRegisterState copyWith({
    bool? isLoading,
    bool? isProcessing,
    CashRegisterModel? currentRegister,
    bool clearCurrent = false,
    List<CashRegisterModel>? history,
    List<CashTransactionModel>? currentTransactions,
    List<SaleHistoryModel>? sales,
    List<ShiftPaymentModel>? payments,
    String? error,
  }) {
    return CashRegisterState(
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      currentRegister: clearCurrent ? null : (currentRegister ?? this.currentRegister),
      history: history ?? this.history,
      currentTransactions: currentTransactions ?? this.currentTransactions,
      sales: sales ?? this.sales,
      payments: payments ?? this.payments,
      error: error,
    );
  }
}

class CashRegisterNotifier extends Notifier<CashRegisterState> {
  @override
  CashRegisterState build() {
    Future.microtask(() => loadInitialData());
    return const CashRegisterState(isLoading: true);
  }

  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true, error: null);
    final service = ref.read(cashRegisterServiceProvider);

    try {
      final futures = await Future.wait([
        service.getTodayRegister(),
        service.getHistory(),
      ]);

      final reg = futures[0] as CashRegisterModel?;
      List<CashTransactionModel> txs = [];
      List<SaleHistoryModel> salesList = [];
      List<ShiftPaymentModel> paymentsList = [];

      if (reg != null && reg.isOpen) {
        final regData = await Future.wait([
          service.getCashTransactions(reg.id),
          service.getSales(cashRegisterId: reg.id),
          service.getPayments(reg.id),
        ]);
        txs = regData[0] as List<CashTransactionModel>;
        salesList = regData[1] as List<SaleHistoryModel>;
        paymentsList = regData[2] as List<ShiftPaymentModel>;
      } else {
        salesList = [];
        paymentsList = [];
      }

      state = state.copyWith(
        isLoading: false,
        currentRegister: reg,
        history: futures[1] as List<CashRegisterModel>,
        currentTransactions: txs,
        sales: salesList,
        payments: paymentsList,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadAllSales() async {
    final service = ref.read(cashRegisterServiceProvider);
    try {
      final allSales = await service.getSales(limit: 100);
      state = state.copyWith(sales: allSales);
    } catch (_) {}
  }

  Future<bool> openRegister(double openingAmount) async {
    state = state.copyWith(isProcessing: true, error: null);
    final service = ref.read(cashRegisterServiceProvider);

    try {
      final register = await service.openRegister(openingAmount);
      final updatedHistory = await service.getHistory();
      state = state.copyWith(
        isProcessing: false,
        currentRegister: register,
        history: updatedHistory,
        currentTransactions: [],
        sales: [],
        payments: [],
      );
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  Future<bool> recordWithdrawal(String concept, double amount) async {
    final reg = state.currentRegister;
    if (reg == null) return false;

    state = state.copyWith(isProcessing: true, error: null);
    final service = ref.read(cashRegisterServiceProvider);

    try {
      await service.recordCashWithdrawal(cashRegisterId: reg.id, concept: concept, amount: amount);
      final txs = await service.getCashTransactions(reg.id);
      state = state.copyWith(isProcessing: false, currentTransactions: txs);
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  Future<bool> closeRegister(
    double closingAmount, {
    Map<String, int>? billBreakdown,
  }) async {
    state = state.copyWith(isProcessing: true, error: null);
    final service = ref.read(cashRegisterServiceProvider);

    try {
      await service.closeRegister(closingAmount, billBreakdown: billBreakdown);
      final updatedHistory = await service.getHistory();
      state = state.copyWith(
        isProcessing: false,
        clearCurrent: true,
        history: updatedHistory,
        currentTransactions: [],
        sales: [],
        payments: [],
      );
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  Future<bool> cancelSale(String saleId, {String? reason}) async {
    state = state.copyWith(isProcessing: true, error: null);
    final service = ref.read(cashRegisterServiceProvider);

    try {
      await service.cancelSale(saleId, reason: reason);
      await loadInitialData();
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }
}

final cashRegisterProvider = NotifierProvider<CashRegisterNotifier, CashRegisterState>(() {
  return CashRegisterNotifier();
});
