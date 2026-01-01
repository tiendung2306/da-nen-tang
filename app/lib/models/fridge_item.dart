import 'package:json_annotation/json_annotation.dart';
import 'package:flutter_boilerplate/models/product_model.dart';

part 'fridge_item.g.dart';

// A simplified model for the 'addedBy' field
@JsonSerializable()
class AddedBy {
  final int id;
  final String username;
  final String fullName;

  const AddedBy({
    required this.id,
    required this.username,
    required this.fullName,
  });

  factory AddedBy.fromJson(Map<String, dynamic> json) => _$AddedByFromJson(json);
  Map<String, dynamic> toJson() => _$AddedByToJson(this);
}

@JsonSerializable()
class FridgeItem {
  final int id;
  final int familyId;
  final String productName;
  final String? customProductName;
  final double quantity;
  final String unit;
  final DateTime? expirationDate;
  final String location;
  final String? note;
  // FIX: Use the new, simpler AddedBy model
  final AddedBy addedBy;
  final bool isExpiringSoon;
  final bool isExpired;
  final int? daysUntilExpiration;
  final List<Category>? categories;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FridgeItem({
    required this.id,
    required this.familyId,
    required this.productName,
    this.customProductName,
    required this.quantity,
    required this.unit,
    this.expirationDate,
    required this.location,
    this.note,
    required this.addedBy,
    required this.isExpiringSoon,
    required this.isExpired,
    this.daysUntilExpiration,
    this.categories,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FridgeItem.fromJson(Map<String, dynamic> json) => _$FridgeItemFromJson(json);
  Map<String, dynamic> toJson() => _$FridgeItemToJson(this);
}
