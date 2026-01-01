import 'package:json_annotation/json_annotation.dart';

part 'fridge_statistics.g.dart';

@JsonSerializable()
class FridgeStatistics {
  final int totalItems;
  
  @JsonKey(name: 'expiringSoonCount')
  final int expiringSoonItems;
  
  @JsonKey(name: 'expiredCount')
  final int expiredItems;
  
  final Map<String, int>? itemsByLocation;
  
  @JsonKey(name: 'itemsByStatus')
  final Map<String, int>? itemsByCategory;

  const FridgeStatistics({
    required this.totalItems,
    required this.expiringSoonItems,
    required this.expiredItems,
    this.itemsByLocation,
    this.itemsByCategory,
  });

  // Computed properties
  // totalItems từ backend đã là số items active (không bao gồm consumed/discarded)
  // nên activeItems = totalItems - expiredItems
  int get activeItems => totalItems - expiredItems;
  
  // Backend chỉ trả về active items nên không có consumed/discarded
  // Trả về 0 hoặc lấy từ itemsByCategory nếu có
  int get consumedItems => itemsByCategory?['CONSUMED'] ?? 0;
  int get discardedItems => itemsByCategory?['DISCARDED'] ?? 0;

  factory FridgeStatistics.fromJson(Map<String, dynamic> json) => _$FridgeStatisticsFromJson(json);
  Map<String, dynamic> toJson() => _$FridgeStatisticsToJson(this);
}
