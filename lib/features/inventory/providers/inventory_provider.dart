import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/inventory_product_model.dart';
import '../services/inventory_service.dart';

final inventoryServiceProvider = Provider<InventoryService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return InventoryService(apiClient);
});

class InventoryState {
  final bool isLoading;
  final List<InventoryProductModel> products;
  final String searchQuery;
  final String selectedCategory;
  final String filter; // 'all' | 'low_stock' | 'out_of_stock'
  final String? error;

  const InventoryState({
    this.isLoading = false,
    this.products = const [],
    this.searchQuery = '',
    this.selectedCategory = 'all',
    this.filter = 'all',
    this.error,
  });

  List<InventoryProductModel> get filteredProducts {
    return products.where((p) {
      // Category filter
      final matchesCat = selectedCategory == 'all' || p.category.toLowerCase() == selectedCategory.toLowerCase();
      // Status filter
      bool matchesStatus = true;
      if (filter == 'low_stock') matchesStatus = p.isLowStock;
      if (filter == 'out_of_stock') matchesStatus = p.isOutOfStock;

      // Query filter
      final q = searchQuery.toLowerCase().trim();
      final matchesQuery = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          (p.sku != null && p.sku!.toLowerCase().contains(q));

      return matchesCat && matchesStatus && matchesQuery;
    }).toList();
  }

  List<String> get categories {
    final set = <String>{'all'};
    for (final p in products) {
      if (p.category.isNotEmpty) set.add(p.category);
    }
    return set.toList();
  }

  int get totalProducts => products.length;
  int get lowStockCount => products.where((p) => p.isLowStock).length;
  int get outOfStockCount => products.where((p) => p.isOutOfStock).length;
  double get totalInventoryValue => products.fold(0.0, (sum, p) => sum + (p.price * p.quantityAvailable));

  InventoryState copyWith({
    bool? isLoading,
    List<InventoryProductModel>? products,
    String? searchQuery,
    String? selectedCategory,
    String? filter,
    String? error,
  }) {
    return InventoryState(
      isLoading: isLoading ?? this.isLoading,
      products: products ?? this.products,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      filter: filter ?? this.filter,
      error: error,
    );
  }
}

class InventoryNotifier extends Notifier<InventoryState> {
  @override
  InventoryState build() {
    Future.microtask(() => loadProducts());
    return const InventoryState(isLoading: true);
  }

  Future<void> loadProducts() async {
    state = state.copyWith(isLoading: true, error: null);
    final service = ref.read(inventoryServiceProvider);
    try {
      final list = await service.getProducts();
      state = state.copyWith(isLoading: false, products: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setSearchQuery(String q) {
    state = state.copyWith(searchQuery: q);
  }

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  void setFilter(String filter) {
    state = state.copyWith(filter: filter);
  }

  Future<bool> createProduct(Map<String, dynamic> data) async {
    final service = ref.read(inventoryServiceProvider);
    try {
      await service.createProduct(data);
      await loadProducts();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateProduct(String id, Map<String, dynamic> data) async {
    final service = ref.read(inventoryServiceProvider);
    try {
      await service.updateProduct(id, data);
      await loadProducts();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    final service = ref.read(inventoryServiceProvider);
    try {
      await service.deleteProduct(id);
      await loadProducts();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> adjustStock(String id, int delta) async {
    final service = ref.read(inventoryServiceProvider);
    try {
      if (delta >= 0) {
        await service.addStock(id, delta);
      } else {
        await service.removeStock(id, delta.abs());
      }
      await loadProducts();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final inventoryProvider = NotifierProvider<InventoryNotifier, InventoryState>(() {
  return InventoryNotifier();
});
