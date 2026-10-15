import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/dashboard_model.dart';
import '../services/dashboard_service.dart';

final dashboardServiceProvider = Provider<DashboardService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DashboardService(apiClient);
});

class DashboardState {
  final bool isLoading;
  final String? error;
  final DashboardOverviewModel? data;

  const DashboardState({
    this.isLoading = false,
    this.error,
    this.data,
  });

  DashboardState copyWith({
    bool? isLoading,
    String? error,
    DashboardOverviewModel? data,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      data: data ?? this.data,
    );
  }
}

class DashboardNotifier extends Notifier<DashboardState> {
  @override
  DashboardState build() {
    Future.microtask(() => loadOverview());
    return const DashboardState(isLoading: true);
  }

  Future<void> loadOverview() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final service = ref.read(dashboardServiceProvider);
      final overview = await service.getOverview();
      state = state.copyWith(isLoading: false, data: overview, error: null);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}

final dashboardProvider = NotifierProvider<DashboardNotifier, DashboardState>(() {
  return DashboardNotifier();
});
