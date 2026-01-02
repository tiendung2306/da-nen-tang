# Quick Start: Fireworks AI Setup với .env

## 🚀 Setup nhanh (3 bước)

### Bước 1: Lấy API Key
1. Đăng ký tại: https://fireworks.ai
2. Vào: https://app.fireworks.ai/settings/users/api-keys
3. Tạo key mới → Copy (format: `fw_xxxxxxxxx`)

### Bước 2: Tạo file .env
```bash
cd be
cp .env.example .env
```

Mở `.env` và điền:
```bash
FIREWORKS_API_KEY=fw_your_actual_key_here
```

### Bước 3: Run
```bash
# Backend
cd be
./gradlew bootRun

# Flutter (terminal mới)
cd app
flutter run -d chrome
```

## ✅ Xác nhận hoạt động

1. Backend chạy: http://localhost:8080
2. Swagger UI: http://localhost:8080/swagger-ui.html
3. Test endpoint: `POST /api/v1/ai/recipes/suggest`
4. Trong Flutter: Nhấn icon ⭐ khi tạo công thức

## 📁 Files quan trọng

```
be/
├── .env                          # API key (KHÔNG commit!)
├── .env.example                  # Template (commit OK)
├── .gitignore                    # .env đã được ignore
├── ENV_SETUP.md                  # Chi tiết về .env
└── FIREWORKS_AI_BACKEND_SETUP.md # Full documentation

app/
└── docs/
    └── FIREWORKS_AI_README.md    # Flutter guide
```

## ⚠️ Quan trọng

- ✅ `.env` đã được add vào `.gitignore`
- ✅ Chỉ commit `.env.example` (không có secrets)
- ✅ File `.env` chứa API key thật (KHÔNG commit!)
- ✅ Mỗi developer có `.env` riêng của mình

## 🔒 Bảo mật

API key trong `.env` **KHÔNG BAO GIỜ** được:
- ❌ Commit lên Git
- ❌ Share qua chat/email
- ❌ Screenshot/chụp màn hình
- ❌ Deploy lên public server

✅ Đúng cách:
- `.env` chỉ ở local machine
- Production dùng secrets management (K8s, AWS, etc.)
- Rotate key thường xuyên

## 🐛 Troubleshooting

**Backend không start?**
```bash
# Kiểm tra .env tồn tại
ls -la be/.env

# Kiểm tra format (không có dấu cách)
cat be/.env

# Phải là: FIREWORKS_API_KEY=fw_xxx
# KHÔNG phải: FIREWORKS_API_KEY = "fw_xxx"
```

**Flutter: "Lỗi kết nối"?**
```bash
# Backend phải đang chạy
curl http://localhost:8080/actuator/health

# Response: {"status":"UP"}
```

## 📚 Tài liệu chi tiết

- **Setup .env**: `be/ENV_SETUP.md`
- **Backend full guide**: `be/FIREWORKS_AI_BACKEND_SETUP.md`
- **Flutter guide**: `app/docs/FIREWORKS_AI_README.md`
- **Fireworks docs**: https://docs.fireworks.ai

## 💡 Tips

1. **Development**: Dùng `.env` file
2. **Production**: Dùng environment variables / secrets
3. **Testing**: Dùng separate API key
4. **Monitoring**: Check usage tại https://app.fireworks.ai/account/usage
