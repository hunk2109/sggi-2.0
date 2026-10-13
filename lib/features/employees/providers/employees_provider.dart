import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/employee_model.dart';
import '../models/payroll_model.dart';
import '../services/employee_service.dart';

final employeeServiceProvider = Provider<EmployeeService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return EmployeeService(apiClient);
});

class EmployeesState {
  final bool isLoading;
  final bool isGeneratingPayroll;
  final List<EmployeeModel> employees;
  final List<PayrollModel> payrolls;
  final String searchQuery;
  final String filter; // 'all', 'active', 'inactive'
  final String roleFilter; // 'all', 'trainer', 'receptionist', 'manager', 'cashier'
  final int selectedMonth;
  final int selectedYear;
  final String? error;

  const EmployeesState({
    this.isLoading = false,
    this.isGeneratingPayroll = false,
    this.employees = const [],
    this.payrolls = const [],
    this.searchQuery = '',
    this.filter = 'all',
    this.roleFilter = 'all',
    this.selectedMonth = 10,
    this.selectedYear = 2026,
    this.error,
  });

  List<EmployeeModel> get filteredEmployees {
    return employees.where((e) {
      if (filter == 'active' && !e.isActive) return false;
      if (filter == 'inactive' && e.isActive) return false;
      if (roleFilter != 'all' && e.role.toLowerCase() != roleFilter.toLowerCase()) return false;

      final q = searchQuery.toLowerCase().trim();
      if (q.isNotEmpty) {
        final matchesName = e.fullName.toLowerCase().contains(q);
        final matchesEmail = e.email.toLowerCase().contains(q);
        final matchesPhone = e.phone.contains(q);
        if (!matchesName && !matchesEmail && !matchesPhone) return false;
      }
      return true;
    }).toList();
  }

  int get totalEmployees => employees.length;
  int get activeCount => employees.where((e) => e.isActive).length;
  int get trainersCount => employees.where((e) => e.role.toLowerCase() == 'trainer' && e.isActive).length;
  double get totalMonthlyPayroll => employees.where((e) => e.isActive).fold(0.0, (sum, e) => sum + e.salary);

  double get payrollTotalNet => payrolls.fold(0.0, (sum, p) => sum + p.netSalary);
  int get payrollPaidCount => payrolls.where((p) => p.isPaid).length;

  EmployeesState copyWith({
    bool? isLoading,
    bool? isGeneratingPayroll,
    List<EmployeeModel>? employees,
    List<PayrollModel>? payrolls,
    String? searchQuery,
    String? filter,
    String? roleFilter,
    int? selectedMonth,
    int? selectedYear,
    String? error,
  }) {
    return EmployeesState(
      isLoading: isLoading ?? this.isLoading,
      isGeneratingPayroll: isGeneratingPayroll ?? this.isGeneratingPayroll,
      employees: employees ?? this.employees,
      payrolls: payrolls ?? this.payrolls,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
      roleFilter: roleFilter ?? this.roleFilter,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedYear: selectedYear ?? this.selectedYear,
      error: error,
    );
  }
}

class EmployeesNotifier extends Notifier<EmployeesState> {
  @override
  EmployeesState build() {
    final now = DateTime.now();
    Future.microtask(() => loadAllData());
    return EmployeesState(
      isLoading: true,
      selectedMonth: now.month,
      selectedYear: now.year,
    );
  }

  Future<void> loadAllData() async {
    state = state.copyWith(isLoading: true, error: null);
    final service = ref.read(employeeServiceProvider);
    try {
      final futures = await Future.wait([
        service.getEmployees(),
        service.getPayrolls(month: state.selectedMonth, year: state.selectedYear),
      ]);

      state = state.copyWith(
        isLoading: false,
        employees: futures[0] as List<EmployeeModel>,
        payrolls: futures[1] as List<PayrollModel>,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadEmployees() async {
    final service = ref.read(employeeServiceProvider);
    try {
      final list = await service.getEmployees();
      state = state.copyWith(employees: list);
    } catch (_) {}
  }

  Future<void> loadPayrolls() async {
    final service = ref.read(employeeServiceProvider);
    try {
      final list = await service.getPayrolls(month: state.selectedMonth, year: state.selectedYear);
      state = state.copyWith(payrolls: list);
    } catch (_) {}
  }

  void setSearchQuery(String q) {
    state = state.copyWith(searchQuery: q);
  }

  void setFilter(String f) {
    state = state.copyWith(filter: f);
  }

  void setRoleFilter(String r) {
    state = state.copyWith(roleFilter: r);
  }

  void setPayrollPeriod(int month, int year) {
    state = state.copyWith(selectedMonth: month, selectedYear: year);
    loadPayrolls();
  }

  Future<bool> createEmployee(Map<String, dynamic> data) async {
    final service = ref.read(employeeServiceProvider);
    try {
      await service.createEmployee(data);
      await loadEmployees();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateEmployee(String id, Map<String, dynamic> data) async {
    final service = ref.read(employeeServiceProvider);
    try {
      await service.updateEmployee(id, data);
      await loadEmployees();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<void> toggleActive(String id) async {
    final service = ref.read(employeeServiceProvider);
    try {
      await service.toggleActive(id);
      await loadEmployees();
    } catch (_) {}
  }

  Future<bool> deleteEmployee(String id) async {
    final service = ref.read(employeeServiceProvider);
    try {
      await service.deleteEmployee(id);
      await loadEmployees();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> generatePayroll() async {
    state = state.copyWith(isGeneratingPayroll: true, error: null);
    final service = ref.read(employeeServiceProvider);
    try {
      await service.generatePayroll(month: state.selectedMonth, year: state.selectedYear);
      await loadPayrolls();
      state = state.copyWith(isGeneratingPayroll: false);
      return true;
    } catch (e) {
      state = state.copyWith(isGeneratingPayroll: false, error: e.toString());
      return false;
    }
  }

  Future<void> approvePayroll(String id) async {
    final service = ref.read(employeeServiceProvider);
    try {
      await service.approvePayroll(id);
      await loadPayrolls();
    } catch (_) {}
  }

  Future<void> markPayrollPaid(String id) async {
    final service = ref.read(employeeServiceProvider);
    try {
      await service.markPayrollPaid(id);
      await loadPayrolls();
    } catch (_) {}
  }
}

final employeesProvider = NotifierProvider<EmployeesNotifier, EmployeesState>(() {
  return EmployeesNotifier();
});
