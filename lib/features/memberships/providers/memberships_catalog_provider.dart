import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../members/providers/members_provider.dart';
import '../models/membership_model.dart';
import '../services/membership_service.dart';

class MembershipsCatalogState {
  final bool isLoading;
  final List<MembershipModel> memberships;
  final String filter; // 'all', 'active', 'inactive'
  final String searchQuery;
  final String? errorMessage;

  const MembershipsCatalogState({
    this.isLoading = false,
    this.memberships = const [],
    this.filter = 'all',
    this.searchQuery = '',
    this.errorMessage,
  });

  List<MembershipModel> get filteredMemberships {
    return memberships.where((m) {
      // Filter by status
      if (filter == 'active' && !m.isActive) return false;
      if (filter == 'inactive' && m.isActive) return false;

      // Filter by search query
      if (searchQuery.trim().isNotEmpty) {
        final query = searchQuery.trim().toLowerCase();
        final matchName = m.name.toLowerCase().contains(query);
        final matchDesc = (m.description ?? '').toLowerCase().contains(query);
        final matchBenefits = m.benefits.any((b) => b.toLowerCase().contains(query));
        if (!matchName && !matchDesc && !matchBenefits) return false;
      }

      return true;
    }).toList();
  }

  MembershipsCatalogState copyWith({
    bool? isLoading,
    List<MembershipModel>? memberships,
    String? filter,
    String? searchQuery,
    String? errorMessage,
  }) {
    return MembershipsCatalogState(
      isLoading: isLoading ?? this.isLoading,
      memberships: memberships ?? this.memberships,
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
    );
  }
}

class MembershipsCatalogNotifier extends Notifier<MembershipsCatalogState> {
  MembershipService get _service => ref.read(membershipServiceProvider);

  @override
  MembershipsCatalogState build() {
    Future.microtask(() => loadMemberships());
    return const MembershipsCatalogState(isLoading: true);
  }

  Future<void> loadMemberships() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _service.getAllMemberships(limit: 100);
      state = state.copyWith(isLoading: false, memberships: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setFilter(String filter) {
    state = state.copyWith(filter: filter);
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<bool> createMembership(Map<String, dynamic> data) async {
    try {
      await _service.createMembership(data);
      await loadMemberships();
      ref.invalidate(activeMembershipsProvider);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateMembership(String id, Map<String, dynamic> data) async {
    try {
      await _service.updateMembership(id, data);
      await loadMemberships();
      ref.invalidate(activeMembershipsProvider);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteMembership(String id) async {
    try {
      final ok = await _service.deleteMembership(id);
      if (ok) {
        await loadMemberships();
        ref.invalidate(activeMembershipsProvider);
      }
      return ok;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleActive(String id, bool currentStatus) async {
    try {
      final ok = await _service.toggleActive(id, currentStatus);
      if (ok) {
        await loadMemberships();
        ref.invalidate(activeMembershipsProvider);
      }
      return ok;
    } catch (e) {
      return false;
    }
  }
}

final membershipsCatalogProvider =
    NotifierProvider<MembershipsCatalogNotifier, MembershipsCatalogState>(() {
  return MembershipsCatalogNotifier();
});
