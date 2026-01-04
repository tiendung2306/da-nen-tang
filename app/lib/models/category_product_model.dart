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
  final String? defaultUnit;
  final int? avgShelfLife;
  final String? description;
  final String? imageUrl;
  final int? categoryId;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    this.id,
    this.name,
    this.defaultUnit,
    this.avgShelfLife,
    this.description,
    this.imageUrl,
    this.categoryId,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Extract categoryId from categories array if present
    int? extractedCategoryId = json['categoryId'] as int?;
    if (extractedCategoryId == null && json['categories'] is List) {
      final categories = json['categories'] as List;
      if (categories.isNotEmpty && categories.first is Map) {
        extractedCategoryId = (categories.first as Map)['id'] as int?;
      }
    }

    return Product(
      id: json['id'] as int?,
      name: json['name'] as String?,
      defaultUnit: json['defaultUnit'] as String?,
      avgShelfLife: json['avgShelfLife'] as int?,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      categoryId: extractedCategoryId,
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
      'defaultUnit': defaultUnit,
      'avgShelfLife': avgShelfLife,
      'description': description,
      'imageUrl': imageUrl,
      'categoryId': categoryId,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() =>
      'Product(id: $id, name: $name, defaultUnit: $defaultUnit)';
}
