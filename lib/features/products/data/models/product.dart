import 'package:equatable/equatable.dart';

/// Converte `numeric` do Postgres (número ou texto) em `double`.
double numericToDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

/// Item do catálogo (`products`). O preço é só para mostrar: o servidor volta
/// a lê-lo do catálogo ao criar o pedido.
class Product extends Equatable {
  const Product({
    required this.id,
    required this.slug,
    required this.name,
    required this.unitLabel,
    required this.price,
    this.description,
    this.imageUrl,
    this.sortOrder = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as String,
    slug: json['slug'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    unitLabel: (json['unit_label'] as String?) ?? 'unidade',
    price: numericToDouble(json['price']),
    imageUrl: json['image_url'] as String?,
    sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final String slug;
  final String name;
  final String? description;
  final String unitLabel;
  final double price;
  final String? imageUrl;
  final int sortOrder;

  @override
  List<Object?> get props => [
    id,
    slug,
    name,
    description,
    unitLabel,
    price,
    imageUrl,
    sortOrder,
  ];
}
