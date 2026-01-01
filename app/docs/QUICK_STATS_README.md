# Tính năng Thống kê nhanh - Home Page

## Tổng quan

Tính năng "Thống kê nhanh" trên trang chủ cung cấp cho người dùng cái nhìn tổng quan về tình trạng tủ lạnh và danh sách mua sắm của gia đình.

## Các thành phần

### 1. Summary Card (Card tổng quan)
Hiển thị 3 chỉ số quan trọng nhất:
- **Tổng số món**: Tổng số nguyên liệu trong tủ lạnh
- **Đang dùng**: Số nguyên liệu còn tốt và có thể sử dụng
- **Cần chú ý**: Tổng số nguyên liệu sắp hết hạn + đã hết hạn

**Thiết kế:**
- Gradient xanh lá (green[50] → green[100])
- 3 cột với divider giữa các cột
- Icon màu sắc riêng cho mỗi chỉ số
- Số lớn và dễ nhìn (24px, bold)

### 2. Stat Cards (Cards thống kê chi tiết)

#### Row 1: Thống kê tủ lạnh
1. **Thực phẩm trong tủ** 🟢
   - Icon: `kitchen`
   - Màu: Teal
   - Giá trị: `fridgeStats.activeItems`
   - Click: TODO - Navigate to Fridge page

2. **Sắp hết hạn** 🟠
   - Icon: `warning_amber`
   - Màu: Orange
   - Giá trị: `fridgeStats.expiringSoonItems`
   - Click: TODO - Navigate to Expiring Items page

3. **Đã hết hạn** 🔴
   - Icon: `delete_outline`
   - Màu: Red
   - Giá trị: `fridgeStats.expiredItems`
   - Click: TODO - Navigate to Expired Items

#### Row 2: Thống kê chung
1. **Danh sách đang mua** 🔵
   - Icon: `checklist`
   - Màu: Blue
   - Giá trị: `shoppingLists.length`
   - Click: ✅ Navigate to Shopping List Page

2. **Đã sử dụng** 🟢
   - Icon: `check_circle_outline`
   - Màu: Green
   - Giá trị: `fridgeStats.consumedItems`
   - Click: None

3. **Tổng số món** 🟣
   - Icon: `inventory_2_outlined`
   - Màu: Purple
   - Giá trị: `fridgeStats.totalItems`
   - Click: None

### 3. Location Breakdown (Phân bổ theo vị trí)

Hiển thị số lượng nguyên liệu trong từng vị trí:
- **Ngăn đông** (FREEZER)
  - Icon: `ac_unit`
  - Màu: Blue
  
- **Ngăn mát** (COOLER)
  - Icon: `kitchen`
  - Màu: Cyan
  
- **Kệ bếp** (PANTRY)
  - Icon: `shelves`
  - Màu: Brown

**Thiết kế:**
- Cards riêng biệt cho mỗi vị trí
- Icon + tên vị trí + badge số lượng
- Chỉ hiển thị khi có dữ liệu

### 4. Nút "Làm mới"

- Vị trí: Góc phải tiêu đề "Thống kê nhanh"
- Icon: `refresh`
- Chức năng: Tải lại dữ liệu thống kê
- Chỉ hiển thị khi đã chọn gia đình

## Data Flow

### Loading Statistics

```dart
void initState() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadStatistics();
  });
}

void _loadStatistics() {
  final selectedFamily = context.read<FamilyProvider>().selectedFamily;
  if (selectedFamily != null) {
    // Load fridge statistics
    context.read<FridgeProvider>().fetchStatistics(selectedFamily.id);
    
    // Load active shopping lists
    context.read<ShoppingListProvider>().fetchActiveShoppingLists(selectedFamily.id);
  }
}
```

### Data Sources

1. **FridgeProvider.statistics** (`FridgeStatistics`)
   ```dart
   - totalItems: int
   - activeItems: int
   - expiringSoonItems: int
   - expiredItems: int
   - consumedItems: int
   - discardedItems: int
   - itemsByLocation: Map<String, int>
   - itemsByCategory: Map<String, int>
   ```

2. **ShoppingListProvider.shoppingLists** (`List<ShoppingList>`)
   - Chỉ lấy danh sách active (status != COMPLETED)

## UI Features

### 1. Loading State
- Hiển thị `--` khi chưa có dữ liệu
- Placeholder màu xám (`Colors.grey[300]`) với shimmer effect
- SizedBox 40x24 để giữ layout không bị nhảy

### 2. Interactive Cards
- Tất cả StatCard đều có `InkWell` với `onTap`
- Border radius: 12px
- Hover effect (ripple)
- Một số card có navigation, một số chỉ hiển thị

### 3. Color Scheme

| Metric | Color | Purpose |
|--------|-------|---------|
| Teal | `Colors.teal` | Thực phẩm có sẵn (positive) |
| Orange | `Colors.orange` | Cảnh báo (warning) |
| Red | `Colors.red` | Nguy hiểm (danger) |
| Blue | `Colors.blue` | Thông tin (info) |
| Green | `Colors.green` | Thành công (success) |
| Purple | `Colors.purple` | Tổng hợp (general) |

### 4. Responsive Design
- Sử dụng `Expanded` để chia đều không gian
- Spacing nhất quán: 12px giữa các cards
- Padding: 16px cho containers
- Font sizes:
  - Tiêu đề: 18px bold
  - Giá trị: 20-24px bold
  - Label: 11-12px regular

## Backend API

### Fridge Statistics
```
GET /api/v1/families/{familyId}/fridge-items/statistics
```

**Response:**
```json
{
  "data": {
    "totalItems": 25,
    "activeItems": 18,
    "expiringSoonItems": 5,
    "expiredItems": 2,
    "consumedItems": 100,
    "discardedItems": 15,
    "itemsByLocation": {
      "FREEZER": 8,
      "COOLER": 12,
      "PANTRY": 5
    },
    "itemsByCategory": {
      "VEGETABLES": 10,
      "MEAT": 8,
      "DAIRY": 7
    }
  }
}
```

### Active Shopping Lists
```
GET /api/v1/families/{familyId}/shopping-lists/active
```

## Usage Example

```dart
// In HomePage
Consumer2<FridgeProvider, ShoppingListProvider>(
  builder: (context, fridgeProvider, shoppingProvider, child) {
    final fridgeStats = fridgeProvider.statistics;
    final shoppingLists = shoppingProvider.shoppingLists;
    
    return _StatCard(
      icon: Icons.kitchen,
      label: 'Thực phẩm\ntrong tủ',
      value: fridgeStats?.activeItems.toString() ?? '--',
      color: Colors.teal,
      onTap: () {
        // Navigate to Fridge page
      },
    );
  },
)
```

## TODO / Future Improvements

### Navigation
- [ ] Navigate to Fridge page khi click "Thực phẩm trong tủ"
- [ ] Navigate to Expiring Items page khi click "Sắp hết hạn"
- [ ] Navigate to Expired Items filter khi click "Đã hết hạn"

### Features
- [ ] Pull-to-refresh cho toàn bộ home page
- [ ] Animate số khi thay đổi (CountUp animation)
- [ ] Biểu đồ pie chart cho location breakdown
- [ ] Thêm trends (tăng/giảm so với tuần trước)
- [ ] Cache statistics để load nhanh hơn
- [ ] Notification dot khi có số lượng "Cần chú ý" > 0

### Performance
- [ ] Debounce refresh button
- [ ] Lazy load location breakdown
- [ ] Skeleton loading thay vì placeholder

### Analytics
- [ ] Track user clicks on stat cards
- [ ] Monitor which stats users care about most
- [ ] A/B test different layouts

## Testing

### Test Cases

1. **No Family Selected**
   - Statistics không load
   - Hiển thị `--` cho tất cả cards
   - Refresh button không hiển thị

2. **Family Selected - No Data**
   - Call API success
   - Hiển thị `0` cho các chỉ số
   - Location breakdown không hiển thị

3. **Family Selected - Has Data**
   - Hiển thị đúng số liệu
   - Location breakdown hiển thị
   - Refresh button hoạt động

4. **Navigation**
   - Click "Danh sách đang mua" → Navigate to Shopping List Page
   - Click các card khác → TODO message

5. **Refresh**
   - Click refresh → Reload data
   - Loading indicator hiển thị
   - Data updated

## Files Modified

- `lib/pages/home/home_page.dart`: Thêm StatefulWidget, load statistics, UI components

## Dependencies

- `provider: ^6.1.2` - State management
- `flutter_boilerplate/providers/fridge_provider.dart` - Fridge statistics
- `flutter_boilerplate/providers/shopping_list_provider.dart` - Shopping lists
- `flutter_boilerplate/providers/family_provider.dart` - Selected family

## Screenshots

```
┌─────────────────────────────────────┐
│  Thống kê nhanh 📊    [Làm mới]    │
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐   │
│  │ 📦 25  │ ✅ 18  │ ⚠️ 7    │   │  ← Summary Card
│  │ Tổng   │ Đang   │ Cần     │   │
│  │ số món │ dùng   │ chú ý   │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌────┐  ┌────┐  ┌────┐           │
│  │ 18 │  │ 5  │  │ 2  │           │  ← Row 1
│  │🏠  │  │⚠️  │  │❌  │           │
│  └────┘  └────┘  └────┘           │
│                                     │
│  ┌────┐  ┌────┐  ┌────┐           │
│  │ 3  │  │100 │  │ 25 │           │  ← Row 2
│  │📋  │  │✅  │  │📦  │           │
│  └────┘  └────┘  └────┘           │
│                                     │
│  Phân bổ theo vị trí 📍            │
│  ┌─────────────────────────┐       │
│  │ ❄️  Ngăn đông      8 món│       │  ← Location
│  │ 🧊  Ngăn mát      12 món│       │    Breakdown
│  │ 📚  Kệ bếp         5 món│       │
│  └─────────────────────────┘       │
└─────────────────────────────────────┘
```

## Notes

- Tất cả API calls đều handle error gracefully
- Khi không có family được chọn, không call API
- Statistics được cache trong provider
- Refresh button cho phép manual reload
- Tất cả numbers đều format rõ ràng (không có decimal)
