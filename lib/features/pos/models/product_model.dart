class ProductModel {
  final String id;
  final String name;
  final String category;
  final double price;
  final double? costPrice;
  final int quantityAvailable;
  final String? barcode;
  final int minStockLevel;

  ProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.costPrice,
    this.quantityAvailable = 0,
    this.barcode,
    this.minStockLevel = 0,
  });

  bool get inStock => quantityAvailable > 0;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Producto sin nombre',
      category: json['category']?.toString() ?? 'General',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      costPrice: json['costPrice'] != null
          ? double.tryParse(json['costPrice'].toString())
          : (json['cost'] != null ? double.tryParse(json['cost'].toString()) : null),
      quantityAvailable: int.tryParse(json['quantityAvailable']?.toString() ?? json['quantity']?.toString() ?? '0') ?? 0,
      barcode: json['barcode']?.toString() ?? json['sku']?.toString(),
      minStockLevel: int.tryParse(json['minStockLevel']?.toString() ?? '0') ?? 0,
    );
  }
}

class CartItemModel {
  final ProductModel product;
  int quantity;
  double unitPrice;

  CartItemModel({
    required this.product,
    this.quantity = 1,
    required this.unitPrice,
  });

  double get subtotal => quantity * unitPrice;
}
