import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../members/models/member_model.dart';
import '../models/product_model.dart';
import '../services/pos_service.dart';

final posServiceProvider = Provider<PosService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PosService(apiClient);
});

class PosState {
  final bool isLoading;
  final bool isProcessingSale;
  final List<ProductModel> products;
  final String selectedCategory;
  final String searchQuery;
  final List<CartItemModel> cart;
  final MemberModel? selectedMember;
  final String paymentMethod; // 'cash', 'card', 'transfer'
  final double discount;
  final double amountReceived;
  final String? error;

  const PosState({
    this.isLoading = false,
    this.isProcessingSale = false,
    this.products = const [],
    this.selectedCategory = 'all',
    this.searchQuery = '',
    this.cart = const [],
    this.selectedMember,
    this.paymentMethod = 'cash',
    this.discount = 0.0,
    this.amountReceived = 0.0,
    this.error,
  });

  List<ProductModel> get filteredProducts {
    return products.where((p) {
      final matchesCat = selectedCategory == 'all' || p.category.toLowerCase() == selectedCategory.toLowerCase();
      final q = searchQuery.toLowerCase().trim();
      final matchesQuery = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          (p.barcode != null && p.barcode!.toLowerCase().contains(q));
      return matchesCat && matchesQuery;
    }).toList();
  }

  List<String> get categories {
    final set = <String>{'all'};
    for (final p in products) {
      if (p.category.isNotEmpty) set.add(p.category);
    }
    return set.toList();
  }

  double get subtotal => cart.fold(0.0, (sum, item) => sum + item.subtotal);
  double get total => (subtotal - discount).clamp(0.0, double.infinity);
  double get change => amountReceived >= total ? (amountReceived - total) : 0.0;
  int get totalItemCount => cart.fold(0, (sum, item) => sum + item.quantity);

  PosState copyWith({
    bool? isLoading,
    bool? isProcessingSale,
    List<ProductModel>? products,
    String? selectedCategory,
    String? searchQuery,
    List<CartItemModel>? cart,
    MemberModel? selectedMember,
    bool clearMember = false,
    String? paymentMethod,
    double? discount,
    double? amountReceived,
    String? error,
  }) {
    return PosState(
      isLoading: isLoading ?? this.isLoading,
      isProcessingSale: isProcessingSale ?? this.isProcessingSale,
      products: products ?? this.products,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      cart: cart ?? this.cart,
      selectedMember: clearMember ? null : (selectedMember ?? this.selectedMember),
      paymentMethod: paymentMethod ?? this.paymentMethod,
      discount: discount ?? this.discount,
      amountReceived: amountReceived ?? this.amountReceived,
      error: error,
    );
  }
}

class PosNotifier extends Notifier<PosState> {
  @override
  PosState build() {
    Future.microtask(() => loadProducts());
    return const PosState(isLoading: true);
  }

  Future<void> loadProducts() async {
    state = state.copyWith(isLoading: true, error: null);
    final service = ref.read(posServiceProvider);
    final list = await service.getProducts();
    state = state.copyWith(isLoading: false, products: list);
  }

  void setSearchQuery(String q) {
    state = state.copyWith(searchQuery: q);
  }

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  void addToCart(ProductModel product) {
    final currentCart = List<CartItemModel>.from(state.cart);
    final index = currentCart.indexWhere((item) => item.product.id == product.id);

    if (index >= 0) {
      // Check stock limit if available
      final existing = currentCart[index];
      if (product.quantityAvailable > 0 && existing.quantity >= product.quantityAvailable) {
        // Stock limit reached
        return;
      }
      existing.quantity += 1;
    } else {
      currentCart.add(CartItemModel(product: product, quantity: 1, unitPrice: product.price));
    }

    state = state.copyWith(cart: currentCart);
  }

  void updateQuantity(String productId, int delta) {
    final currentCart = List<CartItemModel>.from(state.cart);
    final index = currentCart.indexWhere((item) => item.product.id == productId);

    if (index >= 0) {
      final item = currentCart[index];
      final newQty = item.quantity + delta;

      if (newQty <= 0) {
        currentCart.removeAt(index);
      } else {
        if (item.product.quantityAvailable > 0 && newQty > item.product.quantityAvailable) {
          return; // Can't exceed available stock
        }
        item.quantity = newQty;
      }
      state = state.copyWith(cart: currentCart);
    }
  }

  void removeFromCart(String productId) {
    final currentCart = List<CartItemModel>.from(state.cart);
    currentCart.removeWhere((item) => item.product.id == productId);
    state = state.copyWith(cart: currentCart);
  }

  void clearCart() {
    state = state.copyWith(cart: [], discount: 0.0, amountReceived: 0.0, clearMember: true);
  }

  void selectMember(MemberModel? member) {
    state = state.copyWith(selectedMember: member, clearMember: member == null);
  }

  void setPaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }

  void setDiscount(double discount) {
    state = state.copyWith(discount: discount);
  }

  void setAmountReceived(double amount) {
    state = state.copyWith(amountReceived: amount);
  }

  Future<Map<String, dynamic>?> processSale() async {
    if (state.cart.isEmpty) return null;

    state = state.copyWith(isProcessingSale: true, error: null);
    final service = ref.read(posServiceProvider);

    try {
      final items = state.cart.map((i) => {
        'productId': i.product.id,
        'quantity': i.quantity,
        'unitPrice': i.unitPrice,
      }).toList();

      final result = await service.createSale(
        memberId: (state.selectedMember?.userId != null && state.selectedMember!.userId!.isNotEmpty)
            ? state.selectedMember!.userId
            : state.selectedMember?.id,
        customerName: state.selectedMember?.fullName ?? 'Cliente Mostrador',
        items: items,
        discount: state.discount,
        paymentMethod: state.paymentMethod,
        notes: 'Venta realizada desde SGGI 2.0 POS',
      );

      // Reload products to update stock quantities
      await loadProducts();
      clearCart();

      state = state.copyWith(isProcessingSale: false);
      return result;
    } catch (e) {
      state = state.copyWith(isProcessingSale: false, error: e.toString());
      return null;
    }
  }
}

final posProvider = NotifierProvider<PosNotifier, PosState>(() {
  return PosNotifier();
});
