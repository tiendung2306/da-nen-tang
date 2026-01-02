import 'package:json_annotation/json_annotation.dart';
import 'package:flutter_boilerplate/models/auth_model.dart';

part 'shopping_list_model.g.dart';

enum ShoppingListStatus { PLANNING, SHOPPING, COMPLETED }

@JsonSerializable()
class ShoppingList {
  final int id;
  final String name;
  final String? description;
  final int familyId;
  @JsonKey(unknownEnumValue: ShoppingListStatus.PLANNING)
  final ShoppingListStatus status;
  final int? version;
  final UserInfo? createdBy;
  final UserInfo? assignedTo;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<ShoppingItem>? items;
  final int? itemCount;
  final int? boughtCount;

  int get totalItems => itemCount ?? items?.length ?? 0;
  int get boughtItems => boughtCount ?? items?.where((item) => item.isBought).length ?? 0;
  double get progress => totalItems > 0 ? boughtItems / totalItems : 0;

  ShoppingList({
    required this.id,
    required this.name,
    this.description,
    required this.familyId,
    required this.status,
    this.version,
    this.createdBy,
    this.assignedTo,
    this.createdAt,
    this.updatedAt,
    this.items,
    this.itemCount,
    this.boughtCount,
  });

  factory ShoppingList.fromJson(Map<String, dynamic> json) => _$ShoppingListFromJson(json);
  Map<String, dynamic> toJson() => _$ShoppingListToJson(this);
}

@JsonSerializable()
class ShoppingItem {
  final int id;
  @JsonKey(name: 'productName')
  final String name;
  final double quantity;
  final String unit;
  final String? note;
  final bool isBought;
  final UserInfo? assignedTo;
  final UserInfo? boughtBy;
  final DateTime? boughtAt;
  final int? productId;
  final String? productImageUrl;
  final int? version;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    this.note,
    required this.isBought,
    this.assignedTo,
    this.boughtBy,
    this.boughtAt,
    this.productId,
    this.productImageUrl,
    this.version,
  });

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => _$ShoppingItemFromJson(json);
  Map<String, dynamic> toJson() => _$ShoppingItemToJson(this);
}

@JsonSerializable()
class CreateShoppingListRequest {
  final int familyId;
  final String name;
  final String? description;
  final int? assignedToId;
  final List<CreateShoppingItemRequest>? items;

  CreateShoppingListRequest({
    required this.familyId,
    required this.name,
    this.description,
    this.assignedToId,
    this.items,
  });

  factory CreateShoppingListRequest.fromJson(Map<String, dynamic> json) => _$CreateShoppingListRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateShoppingListRequestToJson(this);
}

@JsonSerializable()
class CreateShoppingItemRequest {
  final int? masterProductId;
  final String? customProductName;
  final double quantity;
  final String unit;
  final String? note;
  final int? assignedToId;

  CreateShoppingItemRequest({
    this.masterProductId,
    this.customProductName,
    required this.quantity,
    required this.unit,
    this.note,
    this.assignedToId,
  });

  factory CreateShoppingItemRequest.fromJson(Map<String, dynamic> json) => _$CreateShoppingItemRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateShoppingItemRequestToJson(this);
}

@JsonSerializable()
class UpdateShoppingItemRequest {
  final bool? isBought;
  final double? quantity;
  final String? note;
  final int? assignedToId;
  final int? version;

  UpdateShoppingItemRequest({
    this.isBought,
    this.quantity,
    this.note,
    this.assignedToId,
    this.version,
  });

  factory UpdateShoppingItemRequest.fromJson(Map<String, dynamic> json) => _$UpdateShoppingItemRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateShoppingItemRequestToJson(this);
}
