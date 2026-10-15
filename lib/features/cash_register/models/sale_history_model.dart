import '../../pos/models/product_model.dart';

class SaleHistoryItemModel {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  SaleHistoryItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory SaleHistoryItemModel.fromJson(Map<String, dynamic> json) {
    final productMap = json['product'] as Map<String, dynamic>?;
    final name = productMap?['name']?.toString() ??
        json['productName']?.toString() ??
        'Producto #${json['productId'] ?? ''}';

    final qty = (json['quantity'] is num)
        ? (json['quantity'] as num).toInt()
        : int.tryParse(json['quantity']?.toString() ?? '1') ?? 1;

    final price = (json['unitPrice'] is num)
        ? (json['unitPrice'] as num).toDouble()
        : double.tryParse(json['unitPrice']?.toString() ?? '0') ?? 0.0;

    final sub = (json['subtotal'] is num)
        ? (json['subtotal'] as num).toDouble()
        : double.tryParse(json['subtotal']?.toString() ?? '') ?? (qty * price);

    return SaleHistoryItemModel(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      productName: name,
      quantity: qty,
      unitPrice: price,
      subtotal: sub,
    );
  }
}

class SaleHistoryModel {
  final String id;
  final String? memberId;
  final String customerName;
  final String? cashRegisterId;
  final double totalAmount;
  final double discount;
  final String paymentMethod;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final List<SaleHistoryItemModel> items;

  SaleHistoryModel({
    required this.id,
    this.memberId,
    required this.customerName,
    this.cashRegisterId,
    required this.totalAmount,
    this.discount = 0.0,
    required this.paymentMethod,
    this.status = 'completed',
    this.notes,
    required this.createdAt,
    this.items = const [],
  });

  factory SaleHistoryModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    List<SaleHistoryItemModel> parsedItems = [];
    if (rawItems is List) {
      parsedItems = rawItems
          .whereType<Map<String, dynamic>>()
          .map((i) => SaleHistoryItemModel.fromJson(i))
          .toList();
    }

    DateTime parsedDate = DateTime.now();
    if (json['createdAt'] != null) {
      parsedDate = (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()).toLocal();
    }

    final total = (json['totalAmount'] is num)
        ? (json['totalAmount'] as num).toDouble()
        : double.tryParse(json['totalAmount']?.toString() ?? '0') ?? 0.0;

    final disc = (json['discount'] is num)
        ? (json['discount'] as num).toDouble()
        : double.tryParse(json['discount']?.toString() ?? '0') ?? 0.0;

    return SaleHistoryModel(
      id: json['id']?.toString() ?? '',
      memberId: json['memberId']?.toString(),
      customerName: json['customerName']?.toString() ?? 'Cliente Mostrador',
      cashRegisterId: json['cashRegisterId']?.toString(),
      totalAmount: total,
      discount: disc,
      paymentMethod: json['paymentMethod']?.toString() ?? 'cash',
      status: json['status']?.toString() ?? 'completed',
      notes: json['notes']?.toString(),
      createdAt: parsedDate,
      items: parsedItems,
    );
  }

  /// Convierte los ítems a CartItemModel para re-impresión exacta del ticket
  List<CartItemModel> toCartItems() {
    return items.map((i) {
      return CartItemModel(
        product: ProductModel(
          id: i.productId,
          name: i.productName,
          price: i.unitPrice,
          costPrice: 0.0,
          quantityAvailable: 0,
          category: '',
        ),
        quantity: i.quantity,
        unitPrice: i.unitPrice,
      );
    }).toList();
  }

  String get shortId => id.length > 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();
}
