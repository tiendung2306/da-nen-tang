import 'package:json_annotation/json_annotation.dart';

part 'fridge_item.g.dart';

@JsonSerializable()
class FridgeItem {
  final int id;
  final String name;
  final double? quantity;
  final String? unit;
  final DateTime? purchaseDate;
  final DateTime expiryDate;
  final String? location;
  final String? imageUrl;

  // A computed property to determine if the item is expiring soon
  bool get isExpiringSoon {
    final difference = expiryDate.difference(DateTime.now()).inDays;
    return difference <= 3 && difference >= 0;
  }
  
  String get status {
     final now = DateTime.now();
    final difference = expiryDate.difference(now);

    if (difference.isNegative) {
      return 'Đã hết hạn';
    }
    final days = difference.inDays;
    if (days == 0) {
        final hours = difference.inHours;
        if (hours > 0) return 'còn $hours tiếng';
        final minutes = difference.inMinutes;
        return 'còn $minutes phút';
    }
    if (days < 30) {
      return 'còn $days ngày';
    }
    return 'còn ${days ~/ 30} tháng';
  }

  FridgeItem({
    required this.id,
    required this.name,
    this.quantity,
    this.unit,
    this.purchaseDate,
    required this.expiryDate,
    this.location,
    this.imageUrl,
  });

  factory FridgeItem.fromJson(Map<String, dynamic> json) => _$FridgeItemFromJson(json);
  Map<String, dynamic> toJson() => _$FridgeItemToJson(this);
}
