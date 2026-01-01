import 'package:flutter_boilerplate/models/fridge_item.dart';

/// Service xử lý logic thông báo hết hạn nguyên liệu
class ExpiryNotificationService {
  /// Kiểm tra xem một nguyên liệu có cần thông báo không
  /// - Trả về true nếu còn ≤ 3 ngày hoặc ≤ 24 giờ
  static bool shouldNotify(FridgeItem item) {
    if (item.expirationDate == null) return false;
    
    final daysUntil = item.daysUntilExpiration ?? _calculateDaysUntilExpiry(item.expirationDate!);
    return daysUntil <= 3;
  }

  /// Xác định mức độ nghiêm trọng của thông báo hết hạn
  /// - critical: <= 1 ngày (24 giờ)
  /// - warning: <= 3 ngày
  /// - normal: > 3 ngày
  static String getSeverity(FridgeItem item) {
    if (item.expirationDate == null) return 'normal';
    
    final daysUntil = item.daysUntilExpiration ?? _calculateDaysUntilExpiry(item.expirationDate!);
    
    if (daysUntil <= 1) return 'critical';
    if (daysUntil <= 3) return 'warning';
    return 'normal';
  }

  /// Tạo tiêu đề thông báo dựa trên mức độ nghiêm trọng
  static String getNotificationTitle(FridgeItem item) {
    final severity = getSeverity(item);
    final productName = item.customProductName ?? item.productName;
    
    switch (severity) {
      case 'critical':
        return '⚠️ Nguyên liệu sắp hết hạn!';
      case 'warning':
        return '⏰ Nhắc nhở hạn sử dụng';
      default:
        return 'Thông báo hạn sử dụng';
    }
  }

  /// Tạo nội dung thông báo chi tiết
  static String getNotificationMessage(FridgeItem item) {
    final productName = item.customProductName ?? item.productName;
    final daysUntil = item.daysUntilExpiration ?? _calculateDaysUntilExpiry(item.expirationDate!);
    
    if (daysUntil <= 0) {
      return '$productName đã hết hạn. Hãy kiểm tra và loại bỏ nếu cần.';
    } else if (daysUntil <= 1) {
      return '$productName sẽ hết hạn trong vòng 24 giờ. Hãy sử dụng sớm!';
    } else if (daysUntil <= 3) {
      return '$productName sẽ hết hạn trong $daysUntil ngày. Lên kế hoạch sử dụng nhé!';
    } else {
      return '$productName sẽ hết hạn trong $daysUntil ngày.';
    }
  }

  /// Tính số ngày còn lại đến hạn sử dụng
  static int _calculateDaysUntilExpiry(DateTime expirationDate) {
    final now = DateTime.now();
    final difference = expirationDate.difference(now);
    return difference.inDays;
  }

  /// Lấy màu sắc cho thông báo dựa trên mức độ nghiêm trọng
  static String getColorCode(String severity) {
    switch (severity) {
      case 'critical':
        return '#F44336'; // Đỏ - Khẩn cấp
      case 'warning':
        return '#FF9800'; // Cam - Cảnh báo
      default:
        return '#757575'; // Xám - Bình thường
    }
  }

  /// Lọc danh sách nguyên liệu cần thông báo
  static List<FridgeItem> getItemsNeedingNotification(List<FridgeItem> items) {
    return items.where((item) => shouldNotify(item)).toList()
      ..sort((a, b) {
        // Sắp xếp theo mức độ nghiêm trọng: critical > warning > normal
        final severityA = getSeverity(a);
        final severityB = getSeverity(b);
        
        if (severityA == severityB) {
          // Nếu cùng mức độ, sắp xếp theo ngày hết hạn (gần nhất trước)
          final daysA = a.daysUntilExpiration ?? 999;
          final daysB = b.daysUntilExpiration ?? 999;
          return daysA.compareTo(daysB);
        }
        
        // Đưa critical lên đầu
        if (severityA == 'critical') return -1;
        if (severityB == 'critical') return 1;
        
        // Sau đó là warning
        if (severityA == 'warning') return -1;
        if (severityB == 'warning') return 1;
        
        return 0;
      });
  }

  /// Tạo thông báo tổng hợp
  static String getSummaryMessage(List<FridgeItem> items) {
    final needNotification = getItemsNeedingNotification(items);
    if (needNotification.isEmpty) {
      return 'Tất cả nguyên liệu đều trong thời hạn tốt';
    }

    final critical = needNotification.where((item) => getSeverity(item) == 'critical').length;
    final warning = needNotification.where((item) => getSeverity(item) == 'warning').length;

    if (critical > 0 && warning > 0) {
      return 'Có $critical nguyên liệu sắp hết hạn trong 24h và $warning nguyên liệu trong 3 ngày';
    } else if (critical > 0) {
      return 'Có $critical nguyên liệu sắp hết hạn trong 24 giờ';
    } else if (warning > 0) {
      return 'Có $warning nguyên liệu sắp hết hạn trong 3 ngày';
    }

    return 'Có ${needNotification.length} nguyên liệu cần chú ý';
  }
}
