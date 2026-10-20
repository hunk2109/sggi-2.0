import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../cash_register/providers/cash_register_provider.dart';
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

  // Opciones de flujo de caja
  bool _generateCashExpense = false;
  bool _generateCashIncome = false;

  late TextEditingController _costController;
  late TextEditingController _incomePriceController;
  late TextEditingController _customReasonController;
  String _selectedReason = 'Dañado / Vencido';

  final List<String> _commonReasons = [
    'Dañado / Vencido',
    'Consumo / Uso Interno',
    'Ajuste por Conteo Físico',
    'Devolución a Proveedor',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    _costController = TextEditingController(
      text: widget.product.cost > 0 ? widget.product.cost.toStringAsFixed(2) : '0.00',
    );
    _incomePriceController = TextEditingController(
      text: widget.product.price > 0 ? widget.product.price.toStringAsFixed(2) : '0.00',
    );
    _customReasonController = TextEditingController();
  }

  @override
  void dispose() {
    _costController.dispose();
    _incomePriceController.dispose();
    _customReasonController.dispose();
    super.dispose();
  }

  double get _unitCost {
    return double.tryParse(_costController.text.trim()) ?? 0.0;
  }

  double get _unitIncomePrice {
    return double.tryParse(_incomePriceController.text.trim()) ?? 0.0;
  }

  double get _totalExpense {
    return _unitCost * _delta;
  }

  double get _totalIncome {
    return _unitIncomePrice * _delta;
  }

  Future<void> _handleAdjust() async {
    final cashState = ref.read(cashRegisterProvider);
    if (!cashState.isRegisterOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Operación no permitida: No hay una caja abierta.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final finalDelta = _isAddition ? _delta : -_delta;
    final reason = _selectedReason == 'Otro'
        ? (_customReasonController.text.trim().isNotEmpty ? _customReasonController.text.trim() : 'Ajuste manual')
        : _selectedReason;

    setState(() => _isLoading = true);

    final success = await ref.read(inventoryProvider.notifier).adjustStock(
          widget.product.id,
          finalDelta,
          unitCost: (_isAddition && _generateCashExpense) ? _unitCost : null,
          generateCashExpense: _isAddition && _generateCashExpense,
          reason: !_isAddition ? reason : null,
          generateCashIncome: !_isAddition && _generateCashIncome,
          unitPrice: (!_isAddition && _generateCashIncome) ? _unitIncomePrice : null,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      // Refrescar caja para reflejar el movimiento si aplica
      if ((_isAddition && _generateCashExpense) || (!_isAddition && _generateCashIncome)) {
        ref.read(cashRegisterProvider.notifier).loadInitialData();
      }

      Navigator.of(context).pop(true);
      
      String message;
      if (_isAddition) {
        message = _generateCashExpense
            ? 'Entrada registrada (+$_delta). Gasto en caja: ' r'RD$ ' + _totalExpense.toStringAsFixed(2)
            : 'Entrada registrada (+$_delta) sin gasto en caja.';
      } else {
        message = _generateCashIncome
            ? 'Salida registrada (-$_delta). Ingreso en caja: ' r'RD$ ' + _totalIncome.toStringAsFixed(2)
            : 'Salida registrada (-$_delta). Sin movimiento en caja.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.success,
        ),
      );
    } else {
      final err = ref.read(inventoryProvider).error ?? 'Error al procesar el ajuste de stock';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cashState = ref.watch(cashRegisterProvider);
    final isRegisterOpen = cashState.isRegisterOpen;
    final newStock = widget.product.quantityAvailable + (_isAddition ? _delta : -_delta);

    return Dialog(
      backgroundColor: const Color(0xFF1E232B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.swap_vert, color: AppTheme.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Movimiento de Inventario',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          widget.product.name,
                          style: const TextStyle(fontSize: 13, color: Colors.white70),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Colors.white54),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              const Divider(height: 24, color: AppTheme.darkBorder),

              // Alerta de estado de Caja
              if (!isRegisterOpen)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.error.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_clock, color: AppTheme.error, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Caja Cerrada',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 13),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Debe haber una caja abierta para registrar entradas o salidas de productos.',
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Caja activa: Las operaciones de caja quedarán vinculadas al turno actual.',
                          style: TextStyle(color: Colors.greenAccent, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),

              // Stock Actual
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.darkBorder.withValues(alpha: 0.5)),
                ),
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

              // Operation Selector
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(
                        child: Text('Entrada (+ Agregar)', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      selected: _isAddition,
                      selectedColor: const Color(0xFF107C41),
                      backgroundColor: const Color(0xFF16191E),
                      onSelected: isRegisterOpen ? (_) => setState(() => _isAddition = true) : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(
                        child: Text('Salida (- Reducir)', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      selected: !_isAddition,
                      selectedColor: const Color(0xFFC53929),
                      backgroundColor: const Color(0xFF16191E),
                      onSelected: isRegisterOpen ? (_) => setState(() => _isAddition = false) : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Amount Selector
              const Text('Cantidad de unidades:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 28),
                    onPressed: (isRegisterOpen && _delta > 1) ? () => setState(() => _delta--) : null,
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.darkBorder),
                    ),
                    child: Text(
                      '$_delta',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 28),
                    onPressed: isRegisterOpen ? () => setState(() => _delta++) : null,
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Quick Presets
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [1, 5, 10, 20, 50].map((preset) {
                  return ActionChip(
                    label: Text('+$preset', style: const TextStyle(fontSize: 11)),
                    backgroundColor: const Color(0xFF16191E),
                    onPressed: isRegisterOpen ? () => setState(() => _delta = preset) : null,
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // ============================================
              // SECCIÓN: ENTRADA (+ AGREGAR)
              // ============================================
              if (_isAddition) ...[
                // Switch para determinar si genera gasto en caja
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16191E),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.darkBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.payments_outlined,
                        color: _generateCashExpense ? Colors.amber : Colors.white38,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '¿Generar gasto en caja?',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            Text(
                              _generateCashExpense
                                  ? 'Registrará una salida de efectivo en la caja activa.'
                                  : 'No afectará el dinero de la caja chica.',
                              style: const TextStyle(fontSize: 11, color: Colors.white60),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _generateCashExpense,
                        activeThumbColor: Colors.amber,
                        onChanged: isRegisterOpen ? (val) => setState(() => _generateCashExpense = val) : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Asignar precio/costo si genera gasto en caja
                if (_generateCashExpense) ...[
                  const Text(r'Costo de Compra Unitario (RD$) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _costController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    enabled: isRegisterOpen,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.attach_money, size: 18),
                      hintText: '0.00',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),

                  // Resumen del gasto en caja
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Gasto total a debitar de Caja:', style: TextStyle(fontSize: 12, color: Colors.amber)),
                            Text(
                              r'RD$ ' + _totalExpense.toStringAsFixed(2),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.amber),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Se registrará una salida de efectivo en la caja activa por el costo total de esta compra/entrada.',
                          style: TextStyle(fontSize: 10, color: Colors.white60),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.info_outline, size: 18, color: Colors.white70),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Esta entrada solo incrementará el stock físico. No afectará el balance de efectivo de la caja.',
                            style: TextStyle(fontSize: 11, color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ] else ...[
                // ============================================
                // SECCIÓN: SALIDA (- REDUCIR)
                // ============================================
                // Motivo de la salida
                const Text('Motivo de la Salida *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedReason,
                  dropdownColor: const Color(0xFF1E232B),
                  items: _commonReasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: isRegisterOpen ? (val) => setState(() => _selectedReason = val ?? _commonReasons.first) : null,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.assignment_outlined, size: 18),
                  ),
                ),
                if (_selectedReason == 'Otro') ...[
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _customReasonController,
                    enabled: isRegisterOpen,
                    decoration: const InputDecoration(
                      hintText: 'Especifique el motivo...',
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Switch para determinar si genera ingreso en caja chica
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16191E),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.darkBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.price_check,
                        color: _generateCashIncome ? Colors.greenAccent : Colors.white38,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '¿Generar ingreso en caja chica?',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            Text(
                              _generateCashIncome
                                  ? 'Registrará una entrada de efectivo en la caja activa.'
                                  : 'Salida sin cobro (merma, consumo interno o daño).',
                              style: const TextStyle(fontSize: 11, color: Colors.white60),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _generateCashIncome,
                        activeThumbColor: Colors.greenAccent,
                        onChanged: isRegisterOpen ? (val) => setState(() => _generateCashIncome = val) : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Asignar precio/monto si genera ingreso
                if (_generateCashIncome) ...[
                  const Text(r'Precio / Cobro Unitario de Ingreso (RD$) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _incomePriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    enabled: isRegisterOpen,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.attach_money, size: 18),
                      hintText: '0.00',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),

                  // Resumen de ingreso en caja
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Ingreso total a sumar a la Caja:', style: TextStyle(fontSize: 12, color: Colors.greenAccent)),
                            Text(
                              r'RD$ ' + _totalIncome.toStringAsFixed(2),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Se registrará una entrada de dinero en la caja activa por el valor total de esta salida.',
                          style: TextStyle(fontSize: 10, color: Colors.white60),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.info_outline, size: 18, color: Colors.white70),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Esta salida no registrará cobro ni entrada de dinero en la caja.',
                            style: TextStyle(fontSize: 11, color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 16),

              // Preview nuevo stock
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Nuevo Stock resultante:', style: TextStyle(fontSize: 12, color: Colors.white70)),
                    Text(
                      '$newStock unidades',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: newStock >= 0 ? Colors.greenAccent : Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isAddition ? const Color(0xFF107C41) : const Color(0xFFC53929),
                    ),
                    onPressed: (_isLoading || !isRegisterOpen || newStock < 0) ? null : _handleAdjust,
                    child: _isLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_isAddition ? 'Registrar Entrada' : 'Registrar Salida'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
