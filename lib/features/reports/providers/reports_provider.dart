import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/analytics_model.dart';
import '../services/reports_service.dart';

final reportsServiceProvider = Provider<ReportsService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReportsService(apiClient);
});

class ReportsState {
  final FinancialAnalyticsModel? analytics;
  final bool isLoading;
  final String selectedRange; // 'weekly', 'monthly', 'quarterly', 'yearly'
  final String? error;

  const ReportsState({
    this.analytics,
    this.isLoading = false,
    this.selectedRange = 'monthly',
    this.error,
  });

  ReportsState copyWith({
    FinancialAnalyticsModel? analytics,
    bool? isLoading,
    String? selectedRange,
    String? error,
  }) {
    return ReportsState(
      analytics: analytics ?? this.analytics,
      isLoading: isLoading ?? this.isLoading,
      selectedRange: selectedRange ?? this.selectedRange,
      error: error,
    );
  }
}

class ReportsNotifier extends Notifier<ReportsState> {
  ReportsService get _service => ref.read(reportsServiceProvider);

  @override
  ReportsState build() {
    Future.microtask(() => fetchAnalytics());
    return const ReportsState(isLoading: true, selectedRange: 'weekly');
  }

  Future<void> fetchAnalytics({String? range}) async {
    final targetRange = range ?? state.selectedRange;
    state = state.copyWith(isLoading: true, selectedRange: targetRange, error: null);

    try {
      final data = await _service.getFinancialAndBehaviorAnalytics(range: targetRange);
      state = state.copyWith(analytics: data, isLoading: false);
    } catch (e, stack) {
      debugPrint('[ReportsProvider] Error al obtener analíticas: $e\n$stack');
      state = state.copyWith(
        isLoading: false,
        error: 'No se pudieron cargar los datos de análisis: ${e.toString()}',
      );
    }
  }

  void changeRange(String newRange) {
    if (state.selectedRange != newRange) {
      fetchAnalytics(range: newRange);
    }
  }
}

final reportsProvider = NotifierProvider<ReportsNotifier, ReportsState>(() {
  return ReportsNotifier();
});
