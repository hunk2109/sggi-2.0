import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/inventory_product_model.dart';
import '../providers/inventory_provider.dart';

class StockAdjustmentDialog extends ConsumerStatefulWidget {
  final InventoryProductModel product;

  const StockAdjustmentDialog({super.key, required this.product});

  @override
  ConsumerState<StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends ConsumerState<StockAdjustmentDialog> {
  int _delta = 1;
  bool _isAddition = true;
  bool _isLoading = false;

  Future<void> _handleAdjust() async {
    final finalDelta = _isAddition ? _delta : -_delta;
    setState(() => _isLoading = true);

    final success = await ref.read(inventoryProvider.notifier).adjustStock(widget.product.id, finalDelta);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stock actualizado: ${widget.product.quantityAvailable + finalDelta} unidades'),
          backgroundColor: AppTheme.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error actualizando stock'), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final newStock = widget.product.quantityAvailable + (_isAddition ? _delta : -_delta);

    return Dialog(
      backgroundColor: const Color(0xFF1E232B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.swap_vert, color: AppTheme.primary, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ajustar Stock: ${widget.product.name}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Current Stock Info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Stock Actual en Sistema:', style: TextStyle(fontSize: 12, color: Colors.white70)),
                  Text(
                    '${widget.product.quantityAvailable} unidades',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Operation Type Segment
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Entrada (+ Agregar)')),
                    selected: _isAddition,
                    selectedColor: Colors.green,
                    onSelected: (_) => setState(() => _isAddition = true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Salida (- Reducir)')),
                    selected: !_isAddition,
                    selectedColor: Colors.redAccent,
                    onSelected: (_) => setState(() => _isAddition = false),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Amount Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 28),
                  onPressed: _delta > 1 ? () => setState(() => _delta--) : null,
                ),
                const SizedBox(width: 16),
                Text(
                  '$_delta',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 28),
                  onPressed: () => setState(() => _delta++),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Quick Preset Chips
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [1, 5, 10, 20, 50].map((preset) {
                return ActionChip(
                  label: Text('+$preset', style: const TextStyle(fontSize: 11)),
                  backgroundColor: const Color(0xFF16191E),
                  onPressed: () => setState(() => _delta = preset),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Result preview
            Center(
              child: Text(
                'Nuevo Stock resultante: $newStock unidades',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: newStock >= 0 ? Colors.greenAccent : Colors.redAccent,
                ),
              ),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: (_isLoading || newStock < 0) ? null : _handleAdjust,
                  child: _isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Aplicar Ajuste'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
