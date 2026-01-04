// Category Model
class Category {
  final int? id;
  final String? name;
  final String? description;
  final String? imageUrl;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Category({
    this.id,
    this.name,
    this.description,
    this.imageUrl,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      isActive: json['isActive'] as bool?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() => 'Category(id: $id, name: $name, isActive: $isActive)';
}

// Product Model
class Product {
  final int? id;
  final String? name;
  final String? description;
  final String? imageUrl;
  final double? price;
  final int? quantity;
  final int? categoryId;
  final String? categoryName;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    this.id,
    this.name,
    this.description,
    this.imageUrl,
    this.price,
    this.quantity,
    this.categoryId,
    this.categoryName,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      quantity: json['quantity'] as int?,
      categoryId: json['categoryId'] as int?,
      categoryName: json['categoryName'] as String?,
      isActive: json['isActive'] as bool?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'price': price,
      'quantity': quantity,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() => 'Product(id: $id, name: $name, price: $price)';
}
