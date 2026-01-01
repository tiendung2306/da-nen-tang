# Tính năng Thông báo Hết hạn Nguyên liệu

## Tổng quan

Tính năng này giúp người dùng quản lý nguyên liệu trong tủ lạnh bằng cách hiển thị cảnh báo khi nguyên liệu sắp hết hạn.

## Các mức độ cảnh báo

### 🔴 Khẩn cấp (Critical)
- **Điều kiện**: Nguyên liệu còn ≤ 24 giờ (1 ngày) đến hạn sử dụng
- **Màu sắc**: Đỏ (#F44336)
- **Hiển thị**: 
  - Banner đỏ với chữ "SẮP HẾT HẠN TRONG 24 GIỜ!"
  - Thông báo có nhãn "KHẨN CẤP"
  - Viền đỏ đậm (2px) xung quanh card

### 🟠 Cảnh báo (Warning)
- **Điều kiện**: Nguyên liệu còn ≤ 3 ngày đến hạn sử dụng
- **Màu sắc**: Cam (#FF9800)
- **Hiển thị**:
  - Banner cam với số ngày còn lại
  - Thông báo có nhãn "CẨN THẬN"
  - Viền cam (1.5px) xung quanh card

### 🟢 Bình thường (Normal)
- **Điều kiện**: Nguyên liệu còn > 3 ngày đến hạn sử dụng
- **Màu sắc**: Xám (#757575)
- **Hiển thị**: Không có cảnh báo đặc biệt

## Các thành phần đã triển khai

### 1. ExpiryNotificationService
**File**: `lib/services/notification/expiry_notification_service.dart`

Service xử lý logic thông báo hết hạn:

- `shouldNotify(FridgeItem)`: Kiểm tra xem nguyên liệu có cần thông báo không
- `getSeverity(FridgeItem)`: Xác định mức độ nghiêm trọng (critical/warning/normal)
- `getNotificationTitle(FridgeItem)`: Tạo tiêu đề thông báo
- `getNotificationMessage(FridgeItem)`: Tạo nội dung thông báo chi tiết
- `getItemsNeedingNotification(List<FridgeItem>)`: Lọc và sắp xếp nguyên liệu cần thông báo
- `getSummaryMessage(List<FridgeItem>)`: Tạo thông báo tổng hợp

### 2. NotificationPage - Cải tiến
**File**: `lib/pages/notification/notification_page.dart`

Cải thiện hiển thị thông báo hết hạn:

- **Icon**: Sử dụng `warning_amber_rounded` với màu đỏ cho thông báo hết hạn
- **Màu nền**: 
  - Đỏ nhạt (#FFEBEE) cho thông báo khẩn cấp
  - Cam nhạt (#FFF3E0) cho thông báo cảnh báo
- **Nhãn trạng thái**: Hiển thị "KHẨN CẤP" hoặc "CẨN THẬN"
- **Tiêu đề**: Màu đỏ đậm cho thông báo khẩn cấp
- **Chấm đỏ**: Thay vì chấm cam cho thông báo chưa đọc

### 3. FridgePage - Banner cảnh báo
**File**: `lib/pages/fridge/fridge_page.dart`

Thêm banner cảnh báo tổng quan:

- Hiển thị giữa danh sách thành viên và thanh sắp xếp
- Gradient nền đỏ/cam tùy theo mức độ nghiêm trọng
- Hiển thị tổng số nguyên liệu cần chú ý
- **Clickable**: Nhấn vào banner để xem danh sách chi tiết
- Icon lớn và rõ ràng

### 4. FridgeListItem - Card cảnh báo
**File**: `lib/pages/fridge/fridge_page.dart`

Cải tiến hiển thị nguyên liệu sắp hết hạn:

- **Viền màu**: Viền đỏ/cam tùy theo mức độ
- **Nền màu**: Nền đỏ/cam nhạt
- **Banner cảnh báo**: Hiển thị ngay đầu card
  - "SẮP HẾT HẠN TRONG 24 GIỜ!" cho critical
  - "Sắp hết hạn trong X ngày" cho warning
- **Tích hợp ExpiryNotificationService**: Tự động xác định mức độ

### 5. ExpiringItemsPage - Trang chi tiết
**File**: `lib/pages/fridge/expiring_items_page.dart`

Trang hiển thị tất cả nguyên liệu sắp hết hạn:

#### Tính năng:
- **Tổng quan**: Card tổng hợp với số lượng khẩn cấp và cảnh báo
- **Phân loại**: 
  - Section "Khẩn cấp" (≤ 24h)
  - Section "Cảnh báo" (≤ 3 ngày)
- **Chi tiết nguyên liệu**:
  - Tên, số lượng, đơn vị
  - Số ngày còn lại (hiển thị to và rõ)
  - Ngày hết hạn cụ thể
  - Vị trí lưu trữ
  - Ghi chú (nếu có)
- **Pull to refresh**: Làm mới danh sách
- **Empty state**: Thông báo khi không có nguyên liệu nào sắp hết hạn

#### UI/UX:
- AppBar màu cam
- Card gradient với viền màu
- Icon trực quan cho từng vị trí
- Badge hiển thị số ngày còn lại
- Layout responsive

## Luồng người dùng

### Kịch bản 1: Thông báo từ hệ thống
1. Backend gửi thông báo khi phát hiện nguyên liệu sắp hết hạn
2. Người dùng mở trang "Thông báo"
3. Thấy thông báo với nhãn "KHẨN CẤP" hoặc "CẨN THẬN"
4. Click vào thông báo (TODO: navigate đến chi tiết nguyên liệu)

### Kịch bản 2: Kiểm tra từ Tủ lạnh
1. Người dùng mở trang "Tủ Lạnh"
2. Thấy banner cảnh báo tổng quan (nếu có)
3. Click vào banner
4. Xem danh sách đầy đủ nguyên liệu sắp hết hạn
5. Lên kế hoạch sử dụng hoặc xóa nguyên liệu

### Kịch bản 3: Xem trong danh sách
1. Người dùng scroll danh sách tủ lạnh
2. Nguyên liệu sắp hết hạn có banner và màu sắc nổi bật
3. Dễ dàng nhận biết và xử lý

## Cấu hình Backend

Backend cần cấu hình job tự động kiểm tra và gửi thông báo:

### Job kiểm tra hàng ngày
```kotlin
// Chạy vào 8:00 AM mỗi ngày
@Scheduled(cron = "0 0 8 * * ?")
fun checkExpiringItems() {
    // Tìm tất cả nguyên liệu có expirationDate <= now + 3 days
    // Tạo thông báo với type = FRIDGE_EXPIRY
    // Xác định mức độ: critical (<=1 day), warning (<=3 days)
}
```

### Thông báo realtime
```kotlin
// Khi thêm nguyên liệu mới
fun addFridgeItem(item: FridgeItem) {
    // Lưu vào DB
    // Kiểm tra expirationDate
    // Nếu <= 3 ngày, tạo thông báo ngay
}
```

### Format thông báo
```json
{
  "type": "FRIDGE_EXPIRY",
  "title": "⚠️ Nguyên liệu sắp hết hạn!",
  "message": "Sữa tươi sẽ hết hạn trong vòng 24 giờ. Hãy sử dụng sớm!",
  "referenceType": "FRIDGE_ITEM",
  "referenceId": 123
}
```

## Testing

### Test cases

1. **Nguyên liệu còn 24h**
   - Kiểm tra banner đỏ xuất hiện
   - Kiểm tra viền đỏ 2px
   - Kiểm tra text "KHẨN CẤP"

2. **Nguyên liệu còn 2 ngày**
   - Kiểm tra banner cam
   - Kiểm tra text "Sắp hết hạn trong 2 ngày"
   - Kiểm tra nhãn "CẨN THẬN"

3. **Nguyên liệu còn > 3 ngày**
   - Không có banner cảnh báo
   - Card hiển thị bình thường

4. **Không có nguyên liệu sắp hết hạn**
   - Banner tổng quan không hiển thị
   - ExpiringItemsPage hiển thị empty state

5. **Navigation**
   - Click banner → Mở ExpiringItemsPage
   - ExpiringItemsPage hiển thị đúng số lượng
   - Pull to refresh hoạt động

## Cải tiến tương lai

### 1. Push Notification
- Gửi notification mobile khi có nguyên liệu sắp hết hạn
- Notification hàng ngày vào buổi sáng

### 2. Gợi ý công thức
- Khi nguyên liệu sắp hết hạn, gợi ý công thức sử dụng nguyên liệu đó
- Navigate đến RecipePage với filter

### 3. Tự động thêm vào Shopping List
- Nút "Mua lại" trên ExpiringItemsPage
- Tự động thêm vào danh sách mua sắm

### 4. Thống kê
- Biểu đồ theo dõi số nguyên liệu hết hạn mỗi tháng
- Insights: Nguyên liệu nào hay hết hạn nhất

### 5. Smart reminder
- Học thói quen sử dụng của người dùng
- Nhắc trước nhiều ngày hơn cho nguyên liệu ít dùng

## Dependencies

- `intl: ^0.20.0` - Format ngày tháng
- `provider: ^6.1.2` - State management
- `timeago: ^3.6.1` - Format thời gian tương đối

## API Endpoints

Backend cần cung cấp:

```
GET /api/v1/families/{familyId}/fridge-items/expiring
  - Trả về danh sách nguyên liệu sắp hết hạn
  - Filter: days (default: 3)
  
GET /api/v1/notifications
  - Bao gồm thông báo FRIDGE_EXPIRY
  
POST /api/v1/notifications
  - Tạo thông báo mới (dùng bởi scheduled job)
```

## Màu sắc sử dụng

```dart
// Critical - Đỏ
Colors.red           // #F44336
Colors.red[50]       // #FFEBEE (nền)
Colors.red[100]      // #FFCDD2 (gradient)
Colors.red[300]      // #E57373 (border)
Colors.red[700]      // #D32F2F (icon)
Colors.red[800]      // #C62828 (text)
Colors.red[900]      // #B71C1C (text đậm)

// Warning - Cam
Colors.orange        // #FF9800
Colors.orange[50]    // #FFF3E0 (nền)
Colors.orange[100]   // #FFE0B2 (gradient)
Colors.orange[300]   // #FFB74D (border)
Colors.orange[700]   // #F57C00 (icon)
Colors.orange[800]   // #EF6C00 (text)
Colors.orange[900]   // #E65100 (text đậm)
```

## Notes

- Tất cả logic tính toán thời gian dựa trên `expirationDate` từ backend
- `daysUntilExpiration` từ backend được ưu tiên sử dụng
- Service không gọi API, chỉ xử lý logic frontend
- Thông báo được backend tạo tự động qua scheduled job
