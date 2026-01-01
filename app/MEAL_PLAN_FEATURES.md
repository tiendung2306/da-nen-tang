# Tính năng Thực đơn - Meal Plan Features

## Tổng quan
Hệ thống quản lý thực đơn đã được hoàn thiện với đầy đủ các tính năng CRUD và các chức năng nâng cao.

## Các tính năng chính

### 1. Quản lý Thực đơn (Meal Plan Management)

#### Thêm thực đơn mới
- **UI**: Floating Action Button ➜ "Thêm thực đơn mới"
- **Chức năng**: Tạo thực đơn cho bữa ăn (Sáng/Trưa/Tối/Phụ) trong ngày
- **Fields**: Loại bữa ăn, ngày, ghi chú

#### Xem thực đơn
- **UI**: Hiển thị dạng lịch với chế độ tuần
- **Chức năng**: Xem thực đơn theo ngày, vuốt để chuyển ngày
- **Màu sắc**: Mỗi bữa ăn có màu riêng (Sáng-vàng, Trưa-cam, Tối-đỏ, Phụ-nâu)

#### Sửa ghi chú thực đơn ⭐ MỚI
- **UI**: Menu ⋮ trên meal card ➜ "Sửa ghi chú"
- **API**: `PUT /meal-plans/{id}` với field `note`
- **Chức năng**: Cập nhật ghi chú cho thực đơn

#### Xóa thực đơn
- **UI**: Menu ⋮ trên meal card ➜ "Xóa"
- **API**: `DELETE /meal-plans/{id}`
- **Chức năng**: Xóa toàn bộ thực đơn và các món ăn bên trong

#### Sao chép thực đơn ⭐ MỚI
- **UI**: Menu ⋮ trên meal card ➜ "Sao chép"
- **API**: `POST /meal-plans/{id}/copy`
- **Chức năng**: 
  - Sao chép thực đơn sang ngày khác
  - Có thể chọn bữa ăn khác (optional)
  - Tự động copy tất cả món ăn
- **Params**:
  ```json
  {
    "targetDate": "2024-01-15",
    "targetMealType": "LUNCH"  // optional
  }
  ```

### 2. Quản lý Món ăn (Meal Item Management)

#### Thêm món ăn
- **UI**: Nút ➕ trên meal card
- **API**: `POST /meal-plans/{mealPlanId}/items`
- **Fields**: Tên món, số phần ăn, ghi chú
- **Chức năng**: Thêm món ăn vào thực đơn

#### Sửa món ăn ⭐ MỚI
- **UI**: Icon ✏️ bên cạnh món ăn
- **API**: `PUT /meal-items/{itemId}`
- **Fields**: Tên món, số phần ăn, ghi chú
- **Chức năng**: Chỉnh sửa thông tin món ăn

#### Xóa món ăn
- **UI**: Icon 🗑️ bên cạnh món ăn
- **API**: `DELETE /meal-items/{id}`
- **Chức năng**: Xóa món ăn khỏi thực đơn

#### Xem danh sách món ăn
- **UI**: Hiển thị dạng list với số thứ tự
- **API**: `GET /meal-plans/{mealPlanId}/items`
- **Display**: 
  - Tên món
  - Số phần ăn
  - Ghi chú (nếu có)

### 3. Tạo Danh sách Mua sắm ⭐ MỚI

#### Tạo từ thực đơn
- **UI**: Floating Action Button ➜ "Tạo danh sách mua sắm"
- **API**: `POST /families/{familyId}/meal-plans/generate-shopping-list`
- **Chức năng**:
  - Chọn khoảng thời gian (từ ngày - đến ngày)
  - Tự động phân tích tất cả món ăn trong khoảng thời gian
  - Tạo danh sách mua sắm với các nguyên liệu cần thiết
  - Tránh trùng lặp nguyên liệu
- **Params**:
  ```json
  {
    "startDate": "2024-01-15",
    "endDate": "2024-01-21"
  }
  ```

## Cấu trúc API

### Endpoints đã được implement

1. **GET** `/meal-plans/family/{familyId}/date/{date}` - Lấy thực đơn theo ngày
2. **POST** `/meal-plans` - Tạo thực đơn mới
3. **PUT** `/meal-plans/{id}` - Cập nhật thực đơn
4. **DELETE** `/meal-plans/{id}` - Xóa thực đơn
5. **POST** `/meal-plans/{id}/copy` ⭐ - Sao chép thực đơn
6. **GET** `/meal-plans/{mealPlanId}/items` ⭐ - Lấy danh sách món ăn
7. **POST** `/meal-plans/{mealPlanId}/items` - Thêm món ăn
8. **PUT** `/meal-items/{itemId}` ⭐ - Cập nhật món ăn
9. **DELETE** `/meal-items/{id}` - Xóa món ăn
10. **POST** `/families/{familyId}/meal-plans/generate-shopping-list` ⭐ - Tạo danh sách mua sắm

⭐ = Tính năng mới được thêm trong phiên làm việc này

## Models

### MealPlan
```dart
{
  "id": int,
  "familyId": int,
  "date": DateTime,
  "mealType": MealType,
  "note": String?,
  "items": List<MealItem>
}
```

### MealItem
```dart
{
  "id": int,
  "recipeId": int?,
  "recipeName": String?,
  "customDishName": String?,
  "servings": int,
  "note": String?
}
```

### CreateMealItemRequest
```dart
{
  "recipeId": int?,
  "customDishName": String?,
  "servings": int,
  "note": String?
}
```

## Provider Methods

### MealPlanProvider

```dart
// Existing methods
- fetchDailyMealPlans(familyId, date)
- createMealPlan(request)
- updateMealPlan(id, {note})
- deleteMealPlan(id)
- addMealItem(mealPlanId, item)
- deleteMealItem(itemId, mealPlanId)

// New methods ⭐
- updateMealItem(itemId, mealPlanId, updatedItem)
- fetchMealItems(mealPlanId)
- copyMealPlan(id, {targetDate, targetMealType})
- generateShoppingListFromMealPlans(familyId, {startDate, endDate})
```

## UI Components

### Meal Card
- Header: Tên bữa ăn + Menu actions + Nút thêm món
- Body: Danh sách món ăn với actions (Edit, Delete)
- Empty State: Thông báo chưa có món ăn

### Dialogs
1. **Add Meal Plan Dialog**: Chọn bữa ăn, ngày, ghi chú
2. **Add Meal Item Dialog**: Nhập tên món, số phần, ghi chú
3. **Edit Meal Item Dialog** ⭐: Giống Add, có sẵn dữ liệu
4. **Edit Note Dialog** ⭐: Chỉnh sửa ghi chú thực đơn
5. **Copy Meal Plan Dialog** ⭐: Chọn ngày + bữa ăn đích
6. **Generate Shopping List Dialog** ⭐: Chọn khoảng thời gian
7. **Delete Confirmation Dialogs**: Xác nhận xóa meal plan/item

### Bottom Sheet Menu
- Thêm thực đơn mới
- Tạo danh sách mua sắm từ thực đơn

## Workflow sử dụng

### Quy trình tạo thực đơn tuần
1. Nhấn FAB ➜ "Thêm thực đơn mới"
2. Chọn bữa ăn và ngày
3. Thêm các món ăn vào thực đơn
4. Lặp lại cho các bữa ăn khác trong tuần

### Quy trình sao chép thực đơn
1. Tìm thực đơn cần sao chép
2. Nhấn menu ⋮ ➜ "Sao chép"
3. Chọn ngày đích
4. (Optional) Chọn bữa ăn đích
5. Xác nhận sao chép

### Quy trình tạo danh sách mua sắm
1. Nhấn FAB ➜ "Tạo danh sách mua sắm"
2. Chọn khoảng thời gian (VD: tuần này)
3. Hệ thống phân tích tất cả món ăn
4. Tự động tạo shopping list
5. Xem trong trang "Danh sách mua sắm"

## Màu sắc & Icon

### Meal Types
- 🌅 **Sáng (BREAKFAST)**: Vàng (Colors.amber)
- ☀️ **Trưa (LUNCH)**: Cam (Colors.orange)
- 🌙 **Tối (DINNER)**: Đỏ cam (Colors.deepOrange)
- 🍪 **Phụ (SNACK)**: Nâu (Colors.brown)

### Actions
- ➕ Thêm: Orange
- ✏️ Sửa: Blue
- 🗑️ Xóa: Red
- 📋 Sao chép: Default
- 🛒 Shopping list: Green

## Testing Checklist

- [ ] Tạo thực đơn mới thành công
- [ ] Thêm/sửa/xóa món ăn
- [ ] Sao chép thực đơn sang ngày khác
- [ ] Sao chép thực đơn sang bữa ăn khác
- [ ] Sửa ghi chú thực đơn
- [ ] Xóa thực đơn
- [ ] Tạo shopping list từ 1 ngày
- [ ] Tạo shopping list từ nhiều ngày
- [ ] Hiển thị note của món ăn
- [ ] Vuốt chuyển ngày hoạt động mượt

## Notes
- Tất cả các dialog đều có validation
- Các thao tác xóa đều có confirmation
- Thông báo thành công/thất bại rõ ràng
- UI responsive và user-friendly
- Code tuân theo Flutter best practices
