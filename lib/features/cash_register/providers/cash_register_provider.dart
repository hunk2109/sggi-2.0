import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/cash_register_model.dart';
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
  final String? error;

  const CashRegisterState({
    this.isLoading = false,
    this.isProcessing = false,
    this.currentRegister,
    this.history = const [],
    this.currentTransactions = const [],
    this.error,
  });

  bool get isRegisterOpen => currentRegister != null && currentRegister!.isOpen;
  double get totalWithdrawals => currentTransactions.where((t) => t.isOut).fold(0.0, (sum, t) => sum + t.amount);

  CashRegisterState copyWith({
    bool? isLoading,
    bool? isProcessing,
    CashRegisterModel? currentRegister,
    bool clearCurrent = false,
    List<CashRegisterModel>? history,
    List<CashTransactionModel>? currentTransactions,
    String? error,
  }) {
    return CashRegisterState(
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      currentRegister: clearCurrent ? null : (currentRegister ?? this.currentRegister),
      history: history ?? this.history,
      currentTransactions: currentTransactions ?? this.currentTransactions,
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
      if (reg != null && reg.isOpen) {
        txs = await service.getCashTransactions(reg.id);
      }

      state = state.copyWith(
        isLoading: false,
        currentRegister: reg,
        history: futures[1] as List<CashRegisterModel>,
        currentTransactions: txs,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
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

  Future<bool> closeRegister(double closingAmount) async {
    state = state.copyWith(isProcessing: true, error: null);
    final service = ref.read(cashRegisterServiceProvider);

    try {
      await service.closeRegister(closingAmount);
      final updatedHistory = await service.getHistory();
      state = state.copyWith(
        isProcessing: false,
        clearCurrent: true,
        history: updatedHistory,
        currentTransactions: [],
      );
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
