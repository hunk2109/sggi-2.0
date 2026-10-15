import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../dialogs/product_form_dialog.dart';
import '../dialogs/stock_adjustment_dialog.dart';
import '../models/inventory_product_model.dart';
import '../providers/inventory_provider.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchController = TextEditingController();
  final _currency = NumberFormat.currency(locale: 'en_US', symbol: 'RD\$ ', decimalDigits: 2);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCreateProduct() {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ProductFormDialog(),
    );
  }

  void _openEditProduct(InventoryProductModel product) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProductFormDialog(productToEdit: product),
    );
  }

  void _openStockAdjustment(InventoryProductModel product) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => StockAdjustmentDialog(product: product),
    );
  }

  Future<void> _confirmDeleteProduct(InventoryProductModel product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E232B),
        title: const Text('Eliminar Producto', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('¿Está seguro de eliminar ${product.name} del inventario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(inventoryProvider.notifier).deleteProduct(product.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Producto eliminado' : 'Error al eliminar producto'),
            backgroundColor: success ? AppTheme.success : AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryProvider);
    final notifier = ref.read(inventoryProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 4 Metric Summary Cards
          Row(
            children: [
              _buildMetricCard(
                icon: Icons.inventory_2_outlined,
                label: 'Total Productos',
                value: '${state.totalProducts}',
                color: Colors.blueAccent,
              ),
              const SizedBox(width: 12),
              _buildMetricCard(
                icon: Icons.attach_money,
                label: 'Valor Total Inventario',
                value: _currency.format(state.totalInventoryValue),
                color: Colors.greenAccent,
              ),
              const SizedBox(width: 12),
              _buildMetricCard(
                icon: Icons.warning_amber_rounded,
                label: 'Stock Bajo',
                value: '${state.lowStockCount}',
                color: Colors.amber,
              ),
              const SizedBox(width: 12),
              _buildMetricCard(
                icon: Icons.remove_shopping_cart_outlined,
                label: 'Agotados',
                value: '${state.outOfStockCount}',
                color: Colors.redAccent,
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Control Bar: Search, Filters, New Product Button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar producto por nombre o SKU...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              notifier.setSearchQuery('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onChanged: (val) => notifier.setSearchQuery(val),
                ),
              ),
              const SizedBox(width: 12),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFilterChip('all', 'Todos', state.filter, (f) => notifier.setFilter(f)),
                  const SizedBox(width: 6),
                  _buildFilterChip('low_stock', 'Stock Bajo', state.filter, (f) => notifier.setFilter(f)),
                  const SizedBox(width: 6),
                  _buildFilterChip('out_of_stock', 'Agotados', state.filter, (f) => notifier.setFilter(f)),
                ],
              ),

              const SizedBox(width: 12),

              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Actualizar inventario',
                onPressed: () => notifier.loadProducts(),
              ),
              const SizedBox(width: 6),

              ElevatedButton.icon(
                icon: const Icon(Icons.add_box, size: 18),
                label: const Text('Nuevo Producto'),
                onPressed: _openCreateProduct,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Main Table Container
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.filteredProducts.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 48, color: Colors.white24),
                              SizedBox(height: 10),
                              Text('No se encontraron productos en inventario', style: TextStyle(color: Colors.white54)),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          child: SizedBox(
                            width: double.infinity,
                            child: DataTable(
                              headingRowHeight: 44,
                              dataRowMinHeight: 48,
                              dataRowMaxHeight: 48,
                              columns: const [
                                DataColumn(label: Text('Producto', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Categoría', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Precio Venta', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Costo', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Stock', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: state.filteredProducts.map((p) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4)),
                                        child: Text(p.category, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                                      ),
                                    ),
                                    DataCell(Text(_currency.format(p.price), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent))),
                                    DataCell(Text(_currency.format(p.cost), style: const TextStyle(color: Colors.white60, fontSize: 12))),
                                    DataCell(
                                      Text(
                                        '${p.quantityAvailable}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: p.isOutOfStock ? Colors.redAccent : (p.isLowStock ? Colors.amber : Colors.white),
                                        ),
                                      ),
                                    ),
                                    DataCell(_buildStockBadge(p)),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.swap_vert, size: 18),
                                            tooltip: 'Ajustar Stock (+/-)',
                                            color: AppTheme.primary,
                                            onPressed: () => _openStockAdjustment(p),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 18),
                                            tooltip: 'Editar Producto',
                                            color: Colors.white70,
                                            onPressed: () => _openEditProduct(p),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 18),
                                            tooltip: 'Eliminar Producto',
                                            color: Colors.redAccent.withValues(alpha: 0.7),
                                            onPressed: () => _confirmDeleteProduct(p),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({required IconData icon, required String label, required String value, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1B2028),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54)),
                  const SizedBox(height: 2),
                  Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, String activeFilter, Function(String) onSelect) {
    final isSelected = activeFilter == key;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.white70)),
      selected: isSelected,
      selectedColor: AppTheme.primary,
      backgroundColor: const Color(0xFF1F242C),
      onSelected: (_) => onSelect(key),
    );
  }

  Widget _buildStockBadge(InventoryProductModel p) {
    Color bg;
    Color fg;
    String label = p.stockStatusLabel;

    if (p.isOutOfStock) {
      bg = Colors.red.withValues(alpha: 0.15);
      fg = Colors.redAccent;
    } else if (p.isLowStock) {
      bg = Colors.amber.withValues(alpha: 0.15);
      fg = Colors.amber;
    } else {
      bg = Colors.green.withValues(alpha: 0.15);
      fg = Colors.greenAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
    );
  }
}
