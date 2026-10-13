import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/inventory_product_model.dart';
import '../providers/inventory_provider.dart';

class ProductFormDialog extends ConsumerStatefulWidget {
  final InventoryProductModel? productToEdit;

  const ProductFormDialog({super.key, this.productToEdit});

  @override
  ConsumerState<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _priceController;
  late final TextEditingController _costController;
  late final TextEditingController _stockController;
  late final TextEditingController _minStockController;
  late final TextEditingController _skuController;
  late final TextEditingController _supplierController;

  bool _isLoading = false;
  bool get _isEditing => widget.productToEdit != null;

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    _nameController = TextEditingController(text: p?.name ?? '');
    _categoryController = TextEditingController(text: p?.category ?? 'Suplementos');
    _priceController = TextEditingController(text: p != null ? p.price.toStringAsFixed(2) : '');
    _costController = TextEditingController(text: p != null ? p.cost.toStringAsFixed(2) : '0.00');
    _stockController = TextEditingController(text: p != null ? p.quantityAvailable.toString() : '10');
    _minStockController = TextEditingController(text: p != null ? p.minStockLevel.toString() : '5');
    _skuController = TextEditingController(text: p?.sku ?? '');
    _supplierController = TextEditingController(text: p?.supplier ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _skuController.dispose();
    _supplierController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final data = {
      'name': _nameController.text.trim(),
      'description': _nameController.text.trim(),
      'category': _categoryController.text.trim(),
      'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
      'cost': double.tryParse(_costController.text.trim()) ?? 0.0,
      'quantity': int.tryParse(_stockController.text.trim()) ?? 0,
      'minStockLevel': int.tryParse(_minStockController.text.trim()) ?? 5,
      if (_skuController.text.trim().isNotEmpty) 'sku': _skuController.text.trim(),
      'supplier': _supplierController.text.trim().isNotEmpty ? _supplierController.text.trim() : 'General',
      'purchaseDate': DateTime.now().toIso8601String().split('T')[0],
    };

    final notifier = ref.read(inventoryProvider.notifier);
    bool success;

    if (_isEditing) {
      success = await notifier.updateProduct(widget.productToEdit!.id, data);
    } else {
      success = await notifier.createProduct(data);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Producto actualizado' : 'Producto registrado en inventario'),
          backgroundColor: AppTheme.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar producto'), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E232B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 580,
        padding: const EdgeInsets.all(26),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isEditing ? Icons.edit_note : Icons.add_box_outlined,
                        color: AppTheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isEditing ? 'Editar Producto' : 'Nuevo Producto en Inventario',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Name
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nombre del Producto *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    autofocus: !_isEditing,
                    decoration: const InputDecoration(hintText: 'Ej. Proteína Whey 5lb Nutrex'),
                    validator: (v) => v?.trim().isEmpty == true ? 'Requerido' : null,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Category & SKU
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Categoría *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _categoryController,
                          decoration: const InputDecoration(hintText: 'Bebidas, Suplementos...'),
                          validator: (v) => v?.trim().isEmpty == true ? 'Requerido' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Código de Barra / SKU', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _skuController,
                          decoration: const InputDecoration(hintText: '7428812...'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Price & Cost
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Precio Venta (RD\$) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: '1500.00'),
                          validator: (v) => v?.trim().isEmpty == true ? 'Requerido' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Costo de Compra (RD\$)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _costController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: '950.00'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Stock & Min Stock
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Stock Actual (Unidades) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _stockController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: '10'),
                          validator: (v) => v?.trim().isEmpty == true ? 'Requerido' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Alerta de Stock Mínimo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _minStockController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: '5'),
                        ),
                      ],
                    ),
                  ),
                ],
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
                    onPressed: _isLoading ? null : _handleSubmit,
                    child: _isLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_isEditing ? 'Guardar Cambios' : 'Guardar Producto'),
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
