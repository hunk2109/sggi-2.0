import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/attendance_model.dart';
import '../services/access_service.dart';

final accessServiceProvider = Provider<AccessService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AccessService(apiClient);
});

class AccessState {
  final bool isLoading;
  final bool isProcessingScan;
  final List<AttendanceModel> attendances;
  final AccessScanResult? lastScan;
  final String filter; // 'all' | 'authorized' | 'rejected'

  const AccessState({
    this.isLoading = false,
    this.isProcessingScan = false,
    this.attendances = const [],
    this.lastScan,
    this.filter = 'all',
  });

  int get totalToday => attendances.length;
  int get authorizedCount => attendances.where((a) => a.isAuthorized).length;
  int get rejectedCount => attendances.where((a) => !a.isAuthorized).length;

  List<AttendanceModel> get filteredAttendances {
    if (filter == 'authorized') return attendances.where((a) => a.isAuthorized).toList();
    if (filter == 'rejected') return attendances.where((a) => !a.isAuthorized).toList();
    return attendances;
  }

  AccessState copyWith({
    bool? isLoading,
    bool? isProcessingScan,
    List<AttendanceModel>? attendances,
    AccessScanResult? lastScan,
    String? filter,
  }) {
    return AccessState(
      isLoading: isLoading ?? this.isLoading,
      isProcessingScan: isProcessingScan ?? this.isProcessingScan,
      attendances: attendances ?? this.attendances,
      lastScan: lastScan ?? this.lastScan,
      filter: filter ?? this.filter,
    );
  }
}

class AccessNotifier extends Notifier<AccessState> {
  @override
  AccessState build() {
    Future.microtask(() => loadRecentAttendances());
    return const AccessState(isLoading: true);
  }

  Future<void> loadRecentAttendances() async {
    state = state.copyWith(isLoading: true);
    final service = ref.read(accessServiceProvider);
    final list = await service.getRecentAttendances();
    state = state.copyWith(isLoading: false, attendances: list);
  }

  void setFilter(String filter) {
    state = state.copyWith(filter: filter);
  }

  Future<AccessScanResult> scanCode(String code) async {
    state = state.copyWith(isProcessingScan: true);
    final service = ref.read(accessServiceProvider);
    final result = await service.registerByCode(code);

    // Refresh history
    final updatedList = await service.getRecentAttendances();
    state = state.copyWith(
      isProcessingScan: false,
      lastScan: result,
      attendances: updatedList,
    );
    return result;
  }

  Future<AccessScanResult> scanById(String memberId, {String? notes}) async {
    state = state.copyWith(isProcessingScan: true);
    final service = ref.read(accessServiceProvider);
    final result = await service.registerById(memberId, notes: notes);

    final updatedList = await service.getRecentAttendances();
    state = state.copyWith(
      isProcessingScan: false,
      lastScan: result,
      attendances: updatedList,
    );
    return result;
  }

  void clearLastScan() {
    state = state.copyWith(lastScan: null);
  }
}

final accessProvider = NotifierProvider<AccessNotifier, AccessState>(() {
  return AccessNotifier();
});
