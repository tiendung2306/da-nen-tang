# Backend Setup cho Fireworks AI Integration

## 🎯 Tổng quan

Backend đã được cấu hình để proxy các request AI đến Fireworks AI, đảm bảo:
- ✅ API key được bảo mật
- ✅ Rate limiting: 10 requests/user/day
- ✅ Authentication required
- ✅ Cost tracking
- ✅ Error handling

## 📦 Dependencies đã thêm

Đã cập nhật `build.gradle.kts`:

```kotlin
// WebClient for external API calls
implementation("org.springframework.boot:spring-boot-starter-webflux")

// Rate Limiting
implementation("com.bucket4j:bucket4j-core:8.7.0")
```

## ⚙️ Cấu hình

### 1. Lấy Fireworks AI API Key

1. Truy cập: https://fireworks.ai
2. Đăng ký tài khoản (có $1 credit miễn phí)
3. Vào **Settings** → **API Keys**
4. Tạo API key mới

### 2. Cấu hình trong Backend

**Khuyến nghị: Sử dụng file .env**

1. Copy file `.env.example` thành `.env`:
   ```bash
   cp .env.example .env
   ```

2. Mở file `.env` và điền API key:
   ```bash
   FIREWORKS_API_KEY=fw_xxxxxxxxxxxxx
   ```

3. File `.env` đã được thêm vào `.gitignore` (an toàn!)

**Alternative: Environment Variable**

```bash
# Linux/Mac
export FIREWORKS_API_KEY=fw_xxxxxxxxxxxxx

# Windows PowerShell  
$env:FIREWORKS_API_KEY="fw_xxxxxxxxxxxxx"
```

**❌ KHÔNG nên: Hardcode trong application.yml**

⚠️ **Không bao giờ commit API key vào Git!**

### 3. Build & Run Backend

```bash
# Build
./gradlew build

# Run
./gradlew bootRun

# Hoặc với environment variable
FIREWORKS_API_KEY=fw_xxx ./gradlew bootRun
```

## 🔌 API Endpoints

### 1. Generate Recipe Suggestion

**POST** `/api/v1/ai/recipes/suggest`

**Headers:**
```
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json
```

**Request Body:**
```json
{
  "availableIngredients": ["Thịt heo", "Cà chua", "Hành tây"],
  "servings": 4,
  "cuisineType": "Việt Nam",
  "dietaryPreference": "ít dầu mỡ"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "title": "Thịt heo xào cà chua",
    "description": "Món ăn đơn giản, dễ làm",
    "difficulty": "EASY",
    "servings": 4,
    "prepTime": 15,
    "cookTime": 20,
    "ingredients": [
      {
        "name": "Thịt heo",
        "quantity": 300,
        "unit": "gram",
        "note": "thái miếng vừa",
        "isOptional": false
      }
    ],
    "instructions": "Bước 1: ...\nBước 2: ...",
    "notes": "Tips và mẹo..."
  }
}
```

**Error Responses:**

- `401 Unauthorized`: Token không hợp lệ
- `429 Too Many Requests`: Vượt quá 10 requests/day
- `400 Bad Request`: Thiếu nguyên liệu
- `500 Internal Server Error`: Lỗi từ Fireworks AI

### 2. Check Rate Limit

**GET** `/api/v1/ai/recipes/rate-limit`

**Headers:**
```
Authorization: Bearer <JWT_TOKEN>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "remainingRequests": 7,
    "maxRequests": 10,
    "resetPeriod": "24 hours"
  }
}
```

## 🛡️ Security Features

### 1. Authentication
- Tất cả endpoint yêu cầu JWT token
- Token được validate trước khi xử lý

### 2. Rate Limiting
- 10 requests/user/day
- Sử dụng Bucket4j với in-memory storage
- Reset sau 24 giờ

### 3. API Key Protection
- API key không bao giờ được gửi đến client
- Stored in environment variables
- Backend proxy tất cả requests

## 📊 Monitoring & Logging

Backend tự động log:
- User ID và số lượng ingredients
- Token usage từ Fireworks AI
- Rate limit violations
- Errors và exceptions

Xem logs:
```bash
tail -f logs/spring-boot-application.log
```

## 🧪 Testing

### Test bằng curl:

```bash
# 1. Login để lấy token
TOKEN=$(curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"test123"}' \
  | jq -r '.data.accessToken')

# 2. Generate recipe
curl -X POST http://localhost:8080/api/v1/ai/recipes/suggest \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "availableIngredients": ["Thịt heo", "Cà chua"],
    "servings": 4
  }'

# 3. Check rate limit
curl http://localhost:8080/api/v1/ai/recipes/rate-limit \
  -H "Authorization: Bearer $TOKEN"
```

### Test bằng Swagger UI:

1. Mở: http://localhost:8080/swagger-ui.html
2. Authenticate với JWT token
3. Test endpoint `/api/v1/ai/recipes/suggest`

## 🚀 Production Deployment

### 1. Environment Variables

Cần set trong production:

```bash
FIREWORKS_API_KEY=fw_xxxxxxxxxxxxx
SPRING_PROFILES_ACTIVE=prod
```

### 2. Database

Rate limit buckets hiện tại là in-memory. Để persistent across restarts:

```kotlin
// TODO: Implement Redis backend for Bucket4j
// implementation("com.bucket4j:bucket4j-redis:8.7.0")
```

### 3. Monitoring

Thêm metrics cho AI usage:

```yaml
management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus
```

## 💰 Cost Estimation

### Fireworks AI Pricing:
- $0.9/1M tokens
- Average recipe = 1,500 tokens (~$0.00135/recipe)

### With Rate Limiting:
- Max 10 requests/user/day
- 100 users = 1,000 requests/day
- Cost: ~$1.35/day = $40/month

### Free Tier:
- $1 credit = ~740 recipes
- Good for testing với <100 users

## 🔧 Troubleshooting

### Error: "Invalid API key"
```
✓ Check FIREWORKS_API_KEY environment variable
✓ Verify key format: fw_xxxxxxxxx
✓ Check account status on fireworks.ai
```

### Error: "Connection timeout"
```
✓ Check internet connection
✓ Verify firewall rules
✓ Increase timeout in FireworksAIService
```

### Rate limit not working
```
✓ Buckets are in-memory, reset on app restart
✓ Each user has separate bucket
✓ Check userId from JWT
```

## 📝 Files Changed

### Backend:
- ✅ `dto/ai/AIDtos.kt` - Request/Response DTOs
- ✅ `service/FireworksAIService.kt` - Fireworks AI integration
- ✅ `controller/AIController.kt` - REST endpoints
- ✅ `build.gradle.kts` - Dependencies
- ✅ `application.yml` - Configuration

### Flutter:
- ✅ `services/fireworks_ai_service.dart` - Call backend instead of direct API
- ✅ `pages/recipe/ai_recipe_suggestion_dialog.dart` - UI (no changes needed)
- ✅ `pages/recipe/create_recipe_page.dart` - Integration (no changes needed)

## 🎉 Next Steps

1. Set `FIREWORKS_API_KEY` environment variable
2. Run backend: `./gradlew bootRun`
3. Test endpoint với Swagger UI
4. Deploy to production
5. Monitor usage và cost

## 📞 Support

- Fireworks AI: https://docs.fireworks.ai
- Issues: https://github.com/your-repo/issues
