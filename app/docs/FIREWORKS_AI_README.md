# Hướng dẫn sử dụng AI Recipe Suggestion

## ⚠️ QUAN TRỌNG: Production Ready

Tính năng này đã được cập nhật để **sử dụng Backend Proxy** thay vì gọi trực tiếp Fireworks AI API. Điều này đảm bảo:

- ✅ **Bảo mật API Key**: Key được lưu trên backend, không lộ ra client
- ✅ **Rate Limiting**: 10 requests/user/day
- ✅ **Cost Control**: Tracking và monitoring usage
- ✅ **Authentication**: Chỉ user đăng nhập mới sử dụng được

## 🎯 Kiến trúc

```
Flutter App → Backend (Spring Boot) → Fireworks AI
              ↑ API Key ở đây (an toàn)
```

## 📋 Cấu hình Backend

### Quick Start với .env file

**Bước 1: Lấy API Key**
1. Đăng ký: https://fireworks.ai (có $1 credit miễn phí)
2. Vào: https://app.fireworks.ai/settings/users/api-keys
3. Tạo key mới → Copy (format: `fw_xxxxxxxxx`)

**Bước 2: Tạo file .env**
```bash
cd be
cp .env.example .env
```

Mở file `be/.env` và điền API key:
```bash
FIREWORKS_API_KEY=fw_your_actual_key_here
```

**Bước 3: Run Backend**
```bash
cd be
./gradlew bootRun
```

✅ Backend tự động load từ `.env` file!
✅ File `.env` đã trong `.gitignore` (an toàn!)

📖 **Chi tiết**: Xem `be/ENV_SETUP.md` hoặc `README_FIREWORKS_AI.md`

⚠️ **Không commit API key vào Git!**

### Bước 3: Run Backend

```bash
cd be
./gradlew bootRun
```

Backend sẽ chạy tại: http://localhost:8080

### Bước 4: Flutter App tự động kết nối

Flutter app đã được cấu hình để gọi backend API. Không cần thay đổi gì!

## 📱 Model AI sử dụng

- **llama-v3p3-70b-instruct**: Model ngôn ngữ lớn của Meta
- Tốc độ: Nhanh (~2-3 giây/công thức)  
- Chi phí: $0.9/1M tokens
- H🔒 Bảo mật & Rate Limiting

### Rate Limiting
- **10 requests/user/day**
- Reset sau 24 giờ
- Kiểm tra số lượng còn lại: GET `/api/v1/ai/recipes/rate-limit`

### Authentication
- Tất cả request cần JWT token
- User phải đăng nhập
- Token tự động gửi kèm request

### API Key Security  
- ✅ Key được lưu trên backend
- ✅ Không bao giờ gửi đến client
- ✅ Backend proxy tất cả requests
- ✅ Safe cho production deployment
7. Xem preview và nhấn **Sử dụng công thức này**
8. Chỉnh sửa nếu cần và **Lưu**

### Ví dụ
**Nguyên liệu trong tủ lạnh:**
- Thịt heo
- Cà chua
- Hành tây
- Tỏi

**AI sẽ đề xuất:**
- Tên món: Thịt heo xào cà chua
- Mô tả: Món ăn đơn giản, dễ làm
- Độ khó: Dễ
- Nguyên liệu chi tiết với số lượng
- Các bước thực hiện
- Tips & Notes

## Giới hạn & Chi phí

### Free tier
- $1 credit miễn phí khi đăng ký
- ~1,000 requests đề xuất công thức
- Không cần thẻ tín dụng

### Paid tier (nếu cần)
- Pay-as-you-go: Chỉ trả khi sử dụng
- $0.9/1M tokens (~2,000 công thức = $1)
- Không có phí cố định hàng tháng

## Tối ưu hóa

### Giảm chi phí
1. Chỉ chọn nguyên liệu quan trọng (5-8 loại)
2. Hạn chế số lần generate lại
3. Cache kết quả cho nguyên liệu tương tự

### Cải thiện chất lượng
1. Chọn đầy đủ nguyên liệu từ tủ lạnh
2. Điền thông tin sở thích ăn uống
3. Chỉ định loại ẩm thực cụ thể

## Xử lý lỗi

### Lỗi thường gặp

**1. "Lỗi kết nối Fireworks AI"**
- Kiểm tra kết nối internet
- Verify API key đúng format
- Đảm bảo account còn credit

**2. "Không thể phân tích phản hồi từ AI"**
- Model trả về format không đúng
- Thử generate lại
- Kiểm tra log để debug
⚙️ Chi tiết kỹ thuật

### Backend Stack
- **Service**: `FireworksAIService.kt`
- **Controller**: `AIController.kt`  
- **DTOs**: `AIDtos.kt`
- **Rate Limiter**: Bucket4j (10 req/day/user)

### Flutter Stack
- **Service**: `fireworks_ai_service.dart` (gọi backend API)
- **UI**: `ai_recipe_suggestion_dialog.dart`
- **Integration**: `create_recipe_page.dart`

### API Endpoints

**POST** `/api/v1/ai/recipes/suggest`
```json
{
  "availableIngredients": ["Thịt heo", "Cà chua"],
  "servings": 4,
  "cuisineType": "Việt Nam",
  "dietaryPreference": "ít dầu mỡ"
}
```

**GET** `/api/v1/ai/recipes/rate-limit`
```json
{
  "remainingRequests": 7,
  "maxRequests": 10
}
```

## 💰 Chi phí

### Free Tier
- $1 credit miễn phí
- ~740 công thức
- Đủ cho testing

### Paid (nếu cần)
- $0.9/1M tokens
- ~$0.00135/công thức
- 100 users × 10 req/day = $40/month

## 🔧 Troubleshooting
- Thêm vào `.gitignore`:
  ```
  lib/services/fireworks_ai_service.dart
  ```
- Hoặc sử dụng environment variables
- Trong production: Sử dụng backend proxy để bảo mật API key
