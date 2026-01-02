# Quick Start - Deploy to Production

## 🚀 Bước 1: Deploy Backend lên DigitalOcean (15 phút)

### 1.1. Chuẩn bị GitHub Repository

```bash
cd F:\app\da-nen-tang
git add .
git commit -m "Ready for production deployment"
git push origin main
```

### 1.2. Đăng ký DigitalOcean

1. Truy cập: https://www.digitalocean.com/
2. Sign up (có $200 credit miễn phí cho 60 ngày đầu)
3. Verify email và thêm payment method

### 1.3. Deploy với App Platform

1. Vào **App Platform** → **Create App**
2. Chọn **GitHub** → Authorize DigitalOcean
3. Select repository: `da-nen-tang`
4. Select branch: `main`
5. Cấu hình App:
   - **Name:** smart-grocery
   - **Source Directory:** `be`
   - **Type:** Dockerfile
   - **Dockerfile Path:** `be/Dockerfile`
   - **HTTP Port:** 8080
   - **Instance Size:** Basic ($12/month)

6. Add Database:
   - Click **Add Resource** → **Database**
   - **Engine:** PostgreSQL
   - **Version:** 15
   - **Size:** Basic ($15/month)
   - **Name:** smartgrocery-db

7. Set Environment Variables:
   ```
   JWT_SECRET=thay_bằng_secret_key_256_bit_của_bạn_ví_dụ_use_random_string_generator
   FIREWORKS_API_KEY=fw_2BRK8vPD4TBC27GBbGe3po
   DATABASE_URL=${db.DATABASE_URL}
   DATABASE_USERNAME=${db.USERNAME}
   DATABASE_PASSWORD=${db.PASSWORD}
   ```

8. Click **Create Resources** → Deploy sẽ bắt đầu (5-10 phút)

### 1.4. Lấy Production URL

Sau khi deploy xong, vào **Settings** → **Domains** để xem URL:
```
https://smart-grocery-xxxxx.ondigitalocean.app
```

Copy URL này, bạn sẽ cần để cấu hình Flutter app!

---

## 📱 Bước 2: Cấu hình Flutter App (5 phút)

### 2.1. Cập nhật Production URL

Mở file `app/lib/config/environment.dart` và thay:

```dart
case Environment.production:
  // Thay YOUR_APP_URL bằng URL thực từ DigitalOcean
  return 'https://smart-grocery-xxxxx.ondigitalocean.app/api/v1';
```

### 2.2. Test trên Development

```bash
cd F:\app\da-nen-tang\app

# Đổi về development để test local
# Sửa environment.dart: currentEnvironment = Environment.development

flutter run -d chrome
```

Test đăng nhập, tạo recipe, AI suggestion hoạt động OK.

### 2.3. Chuyển sang Production Mode

Trong `app/lib/config/environment.dart`:
```dart
static Environment currentEnvironment = Environment.production;
```

---

## 🏗️ Bước 3: Build App cho Production

### Android (APK/AAB)

```bash
cd F:\app\da-nen-tang\app

# Build AAB (cho Google Play Store)
flutter build appbundle --release

# Hoặc build APK (để test trực tiếp)
flutter build apk --release
```

**Output:**
- AAB: `build\app\outputs\bundle\release\app-release.aab`
- APK: `build\app\outputs\apk\release\app-release.apk`

### iOS (nếu có Mac)

```bash
flutter build ipa --release
```

---

## 📦 Bước 4: Publish lên Google Play Store

### 4.1. Đăng ký Google Play Console

1. Truy cập: https://play.google.com/console
2. Tạo tài khoản Developer ($25 một lần)
3. Verify identity

### 4.2. Tạo App Signing Key

```bash
keytool -genkey -v -keystore F:\app\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Tạo `android/key.properties`:
```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=F:/app/upload-keystore.jks
```

### 4.3. Upload lên Play Console

1. **Create app** trong Play Console
2. Điền thông tin:
   - **App name:** Smart Grocery
   - **Default language:** Vietnamese
   - **App or game:** App
   - **Free or paid:** Free

3. **Store listing:**
   - Short description (80 chars)
   - Full description (4000 chars)
   - App icon (512x512 PNG)
   - Feature graphic (1024x500)
   - Screenshots (tối thiểu 2)

4. **Content rating:** 
   - Complete questionnaire
   - Get rating certificate

5. **Release → Production:**
   - Upload `app-release.aab`
   - Create release notes
   - Submit for review (1-7 ngày)

---

## 🎯 Bước 5: Testing Production

### Test Backend API

```bash
# Health check
curl https://smart-grocery-xxxxx.ondigitalocean.app/actuator/health

# Test login
curl -X POST https://smart-grocery-xxxxx.ondigitalocean.app/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"password123"}'
```

### Test Flutter App

1. Cài APK lên điện thoại Android thật
2. Test đầy đủ các chức năng:
   - [ ] Đăng ký / Đăng nhập
   - [ ] Tạo family
   - [ ] Thêm fridge items
   - [ ] Tạo recipe
   - [ ] AI suggestion
   - [ ] Meal planning
   - [ ] Shopping list
3. Kiểm tra performance và crash

---

## 🔄 Bước 6: Setup Auto-Deploy (Optional)

### Bật Auto-deploy trên DigitalOcean

1. Vào App → **Settings** → **App-Level Settings**
2. Enable **Autodeploy**
3. Chọn branch `main`

Giờ mỗi khi push code lên GitHub, backend tự động deploy!

### Hoặc dùng GitHub Actions

Xem chi tiết trong `DEPLOYMENT_GUIDE.md`

---

## 📊 Monitoring & Logs

### Xem logs Backend

1. DigitalOcean → **Apps** → **smart-grocery**
2. Tab **Runtime Logs**
3. Filter by time/severity

### Database Management

1. DigitalOcean → **Databases** → **smartgrocery-db**
2. **Connection Details** để connect bằng pgAdmin hoặc DBeaver
3. **Backups** → Tự động backup mỗi ngày

---

## 💰 Chi phí ước tính

| Dịch vụ | Chi phí |
|---------|---------|
| DigitalOcean App Platform | $12/tháng |
| PostgreSQL Database | $15/tháng |
| Google Play Console | $25 một lần |
| Domain (optional) | $12/năm |
| **Tổng** | **$27/tháng + $25 setup** |

**Tip:** DigitalOcean credit $200 miễn phí cho 60 ngày đầu!

---

## 🐛 Troubleshooting

### Backend không start
```bash
# Xem logs
doctl apps logs YOUR_APP_ID --follow

# Hoặc trên web UI
App → Runtime Logs → Filter "error"
```

### Database connection failed
- Check DATABASE_URL format trong environment variables
- Verify database is running trong Resources tab
- Check trust sources trong Database settings

### App không kết nối được
- Verify production URL trong `environment.dart`
- Check SSL certificate (phải là HTTPS)
- Test API trên Postman trước
- Check CORS trong backend SecurityConfig

### Build failed
```bash
# Clean và rebuild
flutter clean
flutter pub get
flutter build appbundle --release
```

---

## 📞 Support

- **DigitalOcean Docs:** https://docs.digitalocean.com/
- **Flutter Deploy Guide:** https://flutter.dev/docs/deployment
- **Play Console Help:** https://support.google.com/googleplay/android-developer

---

## ✅ Checklist hoàn chỉnh

- [ ] Backend deployed lên DigitalOcean
- [ ] Database created và connected
- [ ] Environment variables configured
- [ ] Production URL copied
- [ ] Flutter app updated với production URL
- [ ] App tested thoroughly
- [ ] AAB/APK built successfully
- [ ] Signing key created
- [ ] Google Play Console account created
- [ ] App listing completed
- [ ] Screenshots và descriptions added
- [ ] App submitted for review
- [ ] Auto-deploy enabled
- [ ] Monitoring setup
- [ ] Backup configured

**Chúc mừng! Ứng dụng của bạn đã sẵn sàng cho production! 🎉**
