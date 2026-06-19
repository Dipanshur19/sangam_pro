class Product {
  final String id;
  final String name;
  final double price;
  final double quantity;
  final String unit; // e.g. pcs, kg, ltr, pkt
  final DateTime createdAt;

  const Product({
    required this.id,
    required this.name,
    this.price = 0,
    this.quantity = 0,
    this.unit = 'pcs',
    required this.createdAt,
  });

  bool get isLowStock => quantity <= 5;

  Product copyWith({String? name, double? price, double? quantity, String? unit}) => Product(
        id: id,
        name: name ?? this.name,
        price: price ?? this.price,
        quantity: quantity ?? this.quantity,
        unit: unit ?? this.unit,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'price': price,
        'quantity': quantity,
        'unit': unit,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Product.fromMap(Map<String, dynamic> m) => Product(
        id: m['id'] as String,
        name: m['name'] as String? ?? '',
        price: (m['price'] as num?)?.toDouble() ?? 0,
        quantity: (m['quantity'] as num?)?.toDouble() ?? 0,
        unit: m['unit'] as String? ?? 'pcs',
        createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}
