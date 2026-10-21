import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_permissions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../cash_register/dialogs/open_cash_dialog.dart';
import '../../cash_register/providers/cash_register_provider.dart';
import '../../members/models/member_model.dart';
import '../../members/providers/members_provider.dart';
import '../dialogs/checkout_success_dialog.dart';
import '../models/product_model.dart';
import '../providers/pos_provider.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _searchController = TextEditingController();
  final _receivedController = TextEditingController();
  final _currency = NumberFormat.currency(locale: 'en_US', symbol: 'RD\$ ', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(cashRegisterProvider.notifier).loadInitialData();
    });
  }

  Future<void> _openOpenCashDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const OpenCashDialog(),
    );
    if (result == true) {
      ref.read(cashRegisterProvider.notifier).loadInitialData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('¡Caja abierta exitosamente! Ventas habilitadas.'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _receivedController.dispose();
    super.dispose();
  }

  void _openMemberSelector() {
    final searchCtrl = TextEditingController();
    List<MemberModel> searchResults = [];
    bool isSearching = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E232B),
            title: const Text('Asignar Venta a Socio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: 480,
              height: 380,
              child: Column(
                children: [
                  TextField(
                    controller: searchCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Buscar socio por nombre o cédula...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (val) async {
                      if (val.trim().length >= 2) {
                        setDialogState(() => isSearching = true);
                        final s = ref.read(memberServiceProvider);
                        final res = await s.searchMembers(val.trim());
                        setDialogState(() {
                          searchResults = res;
                          isSearching = false;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: isSearching
                        ? const Center(child: CircularProgressIndicator())
                        : searchResults.isEmpty
                            ? const Center(child: Text('Escriba para buscar o seleccione Cliente Mostrador', style: TextStyle(color: Colors.white38)))
                            : ListView.builder(
                                itemCount: searchResults.length,
                                itemBuilder: (context, index) {
                                  final m = searchResults[index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                                      child: Text(m.firstName.isNotEmpty ? m.firstName[0].toUpperCase() : 'S', style: const TextStyle(color: AppTheme.primary)),
                                    ),
                                    title: Text(m.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('Código: ${m.displayCode}'),
                                    onTap: () {
                                      ref.read(posProvider.notifier).selectMember(m);
                                      Navigator.of(ctx).pop();
                                    },
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  ref.read(posProvider.notifier).selectMember(null);
                  Navigator.of(ctx).pop();
                },
                child: const Text('Cliente Mostrador (Sin socio)'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleCheckout() async {
    final isRegisterOpen = ref.read(cashRegisterProvider).isRegisterOpen;
    if (!isRegisterOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.lock, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text('Ventas bloqueadas: Debe abrir un turno de caja para poder facturar.'),
              ),
            ],
          ),
          backgroundColor: AppTheme.error,
          action: SnackBarAction(
            label: 'ABRIR CAJA',
            textColor: Colors.white,
            onPressed: _openOpenCashDialog,
          ),
        ),
      );
      _openOpenCashDialog();
      return;
    }

    final state = ref.read(posProvider);
    if (state.cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El carrito está vacío'), backgroundColor: AppTheme.warning),
      );
      return;
    }

    final total = state.total;
    final subtotal = state.subtotal;
    final discount = state.discount;
    final change = state.change;
    final method = state.paymentMethod;
    final amountReceived = state.amountReceived;
    final customerName = state.selectedMember?.fullName ?? 'Cliente Mostrador';
    final cartItems = List<CartItemModel>.from(state.cart);

    final result = await ref.read(posProvider.notifier).processSale();

    if (!mounted) return;

    if (result != null) {
      _receivedController.clear();
      if (method == 'credit_balance') {
        ref.read(membersProvider.notifier).loadMembers();
      }
      showDialog(
        context: context,
        builder: (_) => CheckoutSuccessDialog(
          total: total,
          subtotal: subtotal,
          discount: discount,
          paymentMethod: method,
          amountReceived: amountReceived,
          change: change,
          customerName: customerName,
          items: cartItems,
          saleId: result['id']?.toString() ?? result['saleId']?.toString(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error ?? 'Error procesando la venta'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(posProvider);
    final notifier = ref.read(posProvider.notifier);
    final cashState = ref.watch(cashRegisterProvider);
    final isRegisterOpen = cashState.isRegisterOpen;
    final authState = ref.watch(authProvider);
    final canSell = authState.hasPermission(AppPermissions.posSell);
    final canOpenCash = authState.hasPermission(AppPermissions.cashOpen);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (!isRegisterOpen) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2E1518),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5), width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_clock, color: Colors.redAccent, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TURNO DE CAJA CERRADO • VENTAS DESHABILITADAS',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Debe iniciar un turno de caja registrando el fondo inicial para poder cobrar en el Punto de Venta.',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (canOpenCash)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.lock_open, size: 16),
                      label: const Text('Abrir Turno / Caja'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      onPressed: _openOpenCashDialog,
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.lock_outline, size: 16, color: Colors.white38),
                          SizedBox(width: 6),
                          Text('Sin permiso para abrir caja', style: TextStyle(color: Colors.white38, fontSize: 12)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          // LEFT PANEL: Product Catalog (~62% width)
          Expanded(
            flex: 62,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Search & Quick Category Filter
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar producto por nombre o código de barras...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    notifier.setSearchQuery('');
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (val) => notifier.setSearchQuery(val),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Actualizar catálogo',
                      onPressed: () => notifier.loadProducts(),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Category Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: state.categories.map((cat) {
                      final isSelected = state.selectedCategory == cat;
                      final label = cat == 'all' ? 'Todos los Productos' : cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.white70)),
                          selected: isSelected,
                          selectedColor: AppTheme.primary,
                          backgroundColor: const Color(0xFF1E232B),
                          onSelected: (_) => notifier.setCategory(cat),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 16),

                // Product Grid
                Expanded(
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : state.filteredProducts.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inventory_2_outlined, size: 48, color: Colors.white24),
                                  SizedBox(height: 12),
                                  Text('No se encontraron productos', style: TextStyle(color: Colors.white54)),
                                ],
                              ),
                            )
                          : GridView.builder(
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 220,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 1.15,
                              ),
                              itemCount: state.filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = state.filteredProducts[index];
                                return _buildProductCard(product, notifier, isRegisterOpen, canSell);
                              },
                            ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // RIGHT PANEL: Cart & POS Register (~38% width)
          Expanded(
            flex: 38,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cart Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.point_of_sale, color: AppTheme.primary, size: 22),
                          const SizedBox(width: 8),
                          const Text(
                            'Comprobante POS',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${state.totalItemCount} ítems',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary),
                            ),
                          ),
                        ],
                      ),
                      if (state.cart.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.delete_sweep_outlined, size: 20, color: Colors.redAccent),
                          tooltip: 'Vaciar Carrito',
                          onPressed: () => notifier.clearCart(),
                        ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Customer Selector Bar
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _openMemberSelector,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            state.selectedMember != null ? Icons.person : Icons.person_outline,
                            size: 18,
                            color: state.selectedMember != null ? AppTheme.primary : Colors.white54,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.selectedMember != null
                                  ? '${state.selectedMember!.fullName} (#${state.selectedMember!.displayCode})'
                                  : 'Cliente Mostrador / General',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (state.selectedMember != null && state.selectedMember!.creditBalance > 0) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.teal.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.account_balance_wallet, size: 11, color: Colors.tealAccent),
                                  const SizedBox(width: 4),
                                  Text(
                                    _currency.format(state.selectedMember!.creditBalance),
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.tealAccent),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          const Icon(Icons.edit, size: 14, color: Colors.white38),
                        ],
                      ),
                    ),
                  ),

                  const Divider(height: 20),

                  // Cart Item List
                  Expanded(
                    child: state.cart.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.white24),
                                SizedBox(height: 10),
                                Text('Carrito vacío', style: TextStyle(color: Colors.white54, fontSize: 13)),
                                SizedBox(height: 4),
                                Text('Haz clic en los productos para agregarlos', style: TextStyle(color: Colors.white24, fontSize: 11)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: state.cart.length,
                            separatorBuilder: (_, index) => const Divider(height: 8, color: Colors.white10),
                            itemBuilder: (context, index) {
                              final item = state.cart[index];
                              return Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.product.name,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${_currency.format(item.unitPrice)} c/u',
                                          style: const TextStyle(fontSize: 11, color: Colors.white54),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Quantity controls
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, size: 18),
                                        onPressed: () => notifier.updateQuantity(item.product.id, -1),
                                      ),
                                      Text(
                                        '${item.quantity}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline, size: 18),
                                        onPressed: () => notifier.updateQuantity(item.product.id, 1),
                                      ),
                                    ],
                                  ),
                                  // Item Subtotal
                                  SizedBox(
                                    width: 75,
                                    child: Text(
                                      _currency.format(item.subtotal),
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),

                  const Divider(height: 20),

                  // Financial Totals & Payment Method
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal:', style: TextStyle(fontSize: 12, color: Colors.white70)),
                          Text(_currency.format(state.subtotal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Total Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('TOTAL A COBRAR:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text(
                            _currency.format(state.total),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Payment Method Selector
                      Row(
                        children: [
                          _buildPaymentMethodOption('cash', 'Efectivo', Icons.money, state.paymentMethod, notifier),
                          const SizedBox(width: 6),
                          _buildPaymentMethodOption('card', 'Tarjeta', Icons.credit_card, state.paymentMethod, notifier),
                          const SizedBox(width: 6),
                          _buildPaymentMethodOption('transfer', 'Transf.', Icons.account_balance, state.paymentMethod, notifier),
                          if (state.selectedMember != null && state.selectedMember!.creditBalance > 0) ...[
                            const SizedBox(width: 6),
                            _buildPaymentMethodOption('credit_balance', 'Saldo Favor', Icons.account_balance_wallet, state.paymentMethod, notifier, isTeal: true),
                          ],
                        ],
                      ),

                      // If Credit Balance: Notice banner
                      if (state.paymentMethod == 'credit_balance') ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.teal.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.account_balance_wallet, color: Colors.tealAccent, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Se descontará de su Saldo a Favor (Disponible: ${_currency.format(state.selectedMember?.creditBalance ?? 0)})',
                                  style: const TextStyle(fontSize: 11, color: Colors.tealAccent, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // If Cash: Fast change calculation input
                      if (state.paymentMethod == 'cash') ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _receivedController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                decoration: const InputDecoration(
                                  hintText: 'Paga con RD\$',
                                  prefixIcon: Icon(Icons.attach_money, size: 18),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                onChanged: (v) {
                                  final amount = double.tryParse(v) ?? 0.0;
                                  notifier.setAmountReceived(amount);
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (state.change > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  'Devuelta: ${_currency.format(state.change)}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber),
                                ),
                              ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 14),

                      // Big Checkout Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          icon: state.isProcessingSale
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Icon(
                                  !isRegisterOpen
                                      ? Icons.lock_outline
                                      : (!canSell ? Icons.block : Icons.check_circle_outline),
                                  size: 20,
                                ),
                          label: Text(
                            state.isProcessingSale
                                ? 'Procesando...'
                                : !isRegisterOpen
                                    ? (canOpenCash ? 'CAJA CERRADA • INICIAR TURNO' : 'CAJA CERRADA (Sin permiso para abrir)')
                                    : (!canSell
                                        ? 'SIN PERMISO PARA REGISTRAR VENTAS'
                                        : 'COBRAR ${_currency.format(state.total)}'),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: !isRegisterOpen
                                ? (canOpenCash ? Colors.red.shade900 : Colors.white12)
                                : (!canSell ? Colors.white12 : AppTheme.success),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: !isRegisterOpen
                              ? (canOpenCash ? _openOpenCashDialog : null)
                              : (!canSell || state.cart.isEmpty || state.isProcessingSale)
                                  ? null
                                  : _handleCheckout,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  ],
),
);
  }

  Widget _buildProductCard(ProductModel product, PosNotifier notifier, bool isRegisterOpen, bool canSell) {
    final hasStock = product.inStock;

    return Material(
      color: const Color(0xFF1B2028),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: !isRegisterOpen
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.lock, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Expanded(child: Text('Caja cerrada: Debe abrir la caja para poder vender.')),
                      ],
                    ),
                    backgroundColor: AppTheme.error,
                    action: SnackBarAction(
                      label: 'ABRIR CAJA',
                      textColor: Colors.white,
                      onPressed: _openOpenCashDialog,
                    ),
                  ),
                );
              }
            : (!canSell
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.shield_outlined, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Expanded(child: Text('No tiene permisos para registrar ventas en mostrador.')),
                          ],
                        ),
                        backgroundColor: AppTheme.error,
                      ),
                    );
                  }
                : (hasStock ? () => notifier.addToCart(product) : null)),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            product.category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10, color: Colors.white54),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: hasStock ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          hasStock ? 'Stock: ${product.quantityAvailable}' : 'Agotado',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: hasStock ? Colors.greenAccent : Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: hasStock ? Colors.white : Colors.white38,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      _currency.format(product.price),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: hasStock ? Colors.greenAccent : Colors.white24,
                      ),
                    ),
                  ),
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: hasStock ? AppTheme.primary.withValues(alpha: 0.2) : Colors.white10,
                    child: Icon(Icons.add, size: 14, color: hasStock ? AppTheme.primary : Colors.white24),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodOption(String key, String label, IconData icon, String activeKey, PosNotifier notifier, {bool isTeal = false}) {
    final isSelected = activeKey == key;
    final selectedColor = isTeal ? Colors.teal : AppTheme.primary;
    return Expanded(
      child: Material(
        color: isSelected ? selectedColor : const Color(0xFF1E232B),
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => notifier.setPaymentMethod(key),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: isSelected ? Colors.white : (isTeal ? Colors.tealAccent : Colors.white60)),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : (isTeal ? Colors.tealAccent : Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
