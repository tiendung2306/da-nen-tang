# Hướng dẫn cấu hình file .env

## Backend (Spring Boot)

### Bước 1: Tạo file .env

```bash
cd be
cp .env.example .env
```

### Bước 2: Điền API key

Mở file `.env` và thay thế:

```bash
FIREWORKS_API_KEY=your_fireworks_api_key_here
```

Thành:

```bash
FIREWORKS_API_KEY=fw_xxxxxxxxxxxxx
```

### Bước 3: Verify

File `.env` của bạn sẽ như thế này:

```bash
# Fireworks AI Configuration
FIREWORKS_API_KEY=fw_3kj2h4kjh23k4jh23k4jh23k4jh

# Instructions:
# 1. Get your API key from https://app.fireworks.ai/settings/users/api-keys
# 2. Replace 'your_fireworks_api_key_here' with your actual API key
# 3. Format: fw_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
# 4. NEVER commit this file to Git!
```

### Bước 4: Run backend

```bash
./gradlew bootRun
```

Backend sẽ tự động load từ `.env` file!

## 🔒 Bảo mật

✅ **File `.env` đã được thêm vào `.gitignore`**
```gitignore
# Environment
.env
.env.local
.env.*.local
```

✅ **File `.env.example` được commit** (không chứa secret)
✅ **File `.env` KHÔNG được commit** (chứa API key thật)

## 🚀 Production Deployment

### Docker

Trong `docker-compose.yml`:

```yaml
services:
  backend:
    env_file:
      - .env
```

### Kubernetes

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: fireworks-secret
stringData:
  FIREWORKS_API_KEY: fw_xxxxxxxxxxxxx
```

### Heroku / Railway / Vercel

Set trong dashboard:
```
FIREWORKS_API_KEY=fw_xxxxxxxxxxxxx
```

## 🧪 Testing

Kiểm tra xem API key đã load chưa:

```bash
# Run backend
./gradlew bootRun

# Check logs
tail -f logs/spring.log

# Tìm dòng này:
# [INFO] FireworksAIService - API Key loaded successfully
```

## ❌ Troubleshooting

### "API key is required"

```bash
# Kiểm tra file .env tồn tại
ls -la .env

# Kiểm tra nội dung (cẩn thận, đừng share!)
cat .env

# Restart backend
./gradlew bootRun
```

### "Invalid API key format"

```bash
# API key phải có format: fw_xxxxxxxxx
# Không có dấu cách, quotes
# Đúng: FIREWORKS_API_KEY=fw_abc123
# Sai: FIREWORKS_API_KEY="fw_abc123"
# Sai: FIREWORKS_API_KEY = fw_abc123
```

## 📝 Best Practices

1. ✅ **Luôn dùng `.env` cho local development**
2. ✅ **Commit `.env.example` (không có secrets)**
3. ✅ **KHÔNG commit `.env` (có secrets)**
4. ✅ **Sử dụng different keys cho dev/staging/prod**
5. ✅ **Rotate keys định kỳ**
6. ✅ **Monitor usage trên Fireworks dashboard**

## 🔄 Update API Key

Khi cần đổi key:

1. Tạo key mới trên Fireworks.ai
2. Update file `.env`:
   ```bash
   FIREWORKS_API_KEY=fw_new_key_here
   ```
3. Restart backend:
   ```bash
   ./gradlew bootRun
   ```
4. Revoke key cũ trên Fireworks dashboard

## 📚 Dependencies

Backend sử dụng `spring-dotenv` để load `.env`:

```kotlin
// build.gradle.kts
implementation("me.paulschwarz:spring-dotenv:4.0.0")
```

Library này tự động load `.env` khi app start!
