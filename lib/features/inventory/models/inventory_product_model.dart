class InventoryProductModel {
  final String id;
  final String name;
  final String category;
  final double price;
  final double cost;
  final int quantityAvailable;
  final int minStockLevel;
  final String? sku;
  final String? supplier;
  final bool isActive;

  InventoryProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.cost = 0.0,
    required this.quantityAvailable,
    this.minStockLevel = 5,
    this.sku,
    this.supplier,
    this.isActive = true,
  });

  bool get isOutOfStock => quantityAvailable <= 0;
  bool get isLowStock => quantityAvailable > 0 && quantityAvailable <= minStockLevel;

  String get stockStatusLabel {
    if (isOutOfStock) return 'Agotado';
    if (isLowStock) return 'Stock Bajo';
    return 'Disponible';
  }

  factory InventoryProductModel.fromJson(Map<String, dynamic> json) {
    return InventoryProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Sin Nombre',
      category: json['category']?.toString() ?? 'General',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      cost: double.tryParse(json['cost']?.toString() ?? json['costPrice']?.toString() ?? '0') ?? 0.0,
      quantityAvailable: int.tryParse(json['quantityAvailable']?.toString() ?? json['quantity']?.toString() ?? '0') ?? 0,
      minStockLevel: int.tryParse(json['minStockLevel']?.toString() ?? '5') ?? 5,
      sku: json['sku']?.toString() ?? json['barcode']?.toString(),
      supplier: json['supplier']?.toString(),
      isActive: json['isActive'] != false,
    );
  }
}
