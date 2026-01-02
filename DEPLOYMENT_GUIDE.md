# Hướng dẫn Deploy Ứng dụng Smart Grocery

## Tổng quan kiến trúc Production

```
┌─────────────────┐         ┌──────────────────────┐
│  Mobile Users   │────────▶│  DigitalOcean        │
│  (iOS/Android)  │         │  - Backend API       │
│  từ App Store   │         │  - PostgreSQL DB     │
└─────────────────┘         │  - Domain & SSL      │
                            └──────────────────────┘
```

---

## Phần 1: Deploy Backend lên DigitalOcean

### Option 1: DigitalOcean App Platform (Khuyến nghị - Dễ nhất)

**Ưu điểm:**
- Tự động build, deploy, và scale
- Tích hợp sẵn database
- SSL/TLS miễn phí
- Tự động backup
- CI/CD tích hợp với GitHub

**Chi phí:** ~$12-25/tháng (Basic + Database)

#### Bước 1: Chuẩn bị code

1. Tạo `Dockerfile` trong thư mục `be/`:

```dockerfile
# be/Dockerfile
FROM gradle:8.5-jdk17 AS build
WORKDIR /app
COPY . .
RUN gradle build -x test --no-daemon

FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=build /app/build/libs/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

2. Tạo `.dockerignore`:

```
# be/.dockerignore
.gradle
build
.env
*.log
.git
```

3. Đảm bảo `application.yml` sử dụng environment variables:

```yaml
spring:
  datasource:
    url: ${DATABASE_URL}
    username: ${DATABASE_USERNAME}
    password: ${DATABASE_PASSWORD}
  
server:
  port: ${PORT:8080}

jwt:
  secret: ${JWT_SECRET}
  access-token-expiration: 3600000
  refresh-token-expiration: 604800000

fireworks:
  ai:
    api-key: ${FIREWORKS_API_KEY}
```

#### Bước 2: Push code lên GitHub

```bash
cd F:\app\da-nen-tang
git add .
git commit -m "Prepare for production deployment"
git push origin main
```

#### Bước 3: Deploy trên DigitalOcean App Platform

1. Đăng ký tài khoản DigitalOcean: https://www.digitalocean.com/
2. Vào **App Platform** → **Create App**
3. Kết nối GitHub repository của bạn
4. Chọn branch `main`
5. Cấu hình:
   - **Source Directory:** `be`
   - **Dockerfile:** `be/Dockerfile`
   - **Port:** 8080
   - **Instance Type:** Basic ($12/tháng)

6. Tạo PostgreSQL Database:
   - Trong cùng App, thêm **Database**
   - Chọn **PostgreSQL 15**
   - Instance: Basic ($15/tháng)
   - DigitalOcean tự động inject `DATABASE_URL`

7. Thêm Environment Variables:
   ```
   JWT_SECRET=<generate-random-secret-key-at-least-256-bits>
   FIREWORKS_API_KEY=fw_2BRK8vPD4TBC27GBbGe3po
   DATABASE_USERNAME=${db.USERNAME}
   DATABASE_PASSWORD=${db.PASSWORD}
   DATABASE_URL=${db.DATABASE_URL}
   ```

8. Deploy → DigitalOcean sẽ build và deploy tự động

#### Bước 4: Lấy Production URL

Sau khi deploy thành công, bạn sẽ có URL dạng:
```
https://smart-grocery-api-xxxxx.ondigitalocean.app
```

Hoặc cấu hình custom domain:
```
https://api.smartgrocery.com
```

### Option 2: DigitalOcean Droplet (Linh hoạt hơn, phức tạp hơn)

**Chi phí:** ~$6-12/tháng

<details>
<summary>Click để xem hướng dẫn chi tiết</summary>

#### Bước 1: Tạo Droplet

1. Vào DigitalOcean → **Droplets** → **Create**
2. Chọn:
   - **Image:** Ubuntu 22.04 LTS
   - **Plan:** Basic ($6/tháng - 1GB RAM)
   - **Region:** Singapore (gần Việt Nam nhất)
   - **Authentication:** SSH keys hoặc Password

#### Bước 2: Cài đặt môi trường

SSH vào server:
```bash
ssh root@your-droplet-ip
```

Cài đặt Docker:
```bash
apt update
apt install -y docker.io docker-compose
systemctl start docker
systemctl enable docker
```

Cài đặt PostgreSQL:
```bash
docker run -d \
  --name postgres \
  -e POSTGRES_DB=smartgrocery \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=<secure-password> \
  -p 5432:5432 \
  -v postgres_data:/var/lib/postgresql/data \
  --restart always \
  postgres:15
```

#### Bước 3: Deploy Backend

Tạo `docker-compose.yml` trên server:

```yaml
version: '3.8'
services:
  backend:
    image: your-dockerhub-username/smart-grocery-backend:latest
    ports:
      - "8080:8080"
    environment:
      - DATABASE_URL=jdbc:postgresql://postgres:5432/smartgrocery
      - DATABASE_USERNAME=admin
      - DATABASE_PASSWORD=<secure-password>
      - JWT_SECRET=<your-jwt-secret>
      - FIREWORKS_API_KEY=<your-api-key>
    depends_on:
      - postgres
    restart: always

  postgres:
    image: postgres:15
    environment:
      - POSTGRES_DB=smartgrocery
      - POSTGRES_USER=admin
      - POSTGRES_PASSWORD=<secure-password>
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: always

volumes:
  postgres_data:
```

Deploy:
```bash
docker-compose up -d
```

#### Bước 4: Cấu hình Nginx & SSL

```bash
apt install -y nginx certbot python3-certbot-nginx

# Tạo config Nginx
cat > /etc/nginx/sites-available/smartgrocery <<EOF
server {
    listen 80;
    server_name api.yourdomain.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

ln -s /etc/nginx/sites-available/smartgrocery /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx

# Cài SSL (miễn phí từ Let's Encrypt)
certbot --nginx -d api.yourdomain.com
```

</details>

---

## Phần 2: Cấu hình Flutter App cho Production

### Bước 1: Tạo Environment Configurations

Tạo file `lib/config/environment.dart`:

```dart
enum Environment { development, production }

class AppConfig {
  static Environment currentEnvironment = Environment.production;
  
  static String get apiBaseUrl {
    switch (currentEnvironment) {
      case Environment.development:
        return 'http://127.0.0.1:8080/api/v1';
      case Environment.production:
        return 'https://smart-grocery-api-xxxxx.ondigitalocean.app/api/v1';
    }
  }
  
  static String get fileBaseUrl {
    switch (currentEnvironment) {
      case Environment.development:
        return 'http://127.0.0.1:8080';
      case Environment.production:
        return 'https://smart-grocery-api-xxxxx.ondigitalocean.app';
    }
  }
}
```

### Bước 2: Cập nhật ApiConfig

Sửa file `lib/constants/api_config.dart`:

```dart
import 'package:flutter_boilerplate/config/environment.dart';

class ApiConfig {
  static String get baseUrl => AppConfig.apiBaseUrl;
  static String get fileBaseUrl => AppConfig.fileBaseUrl;
  
  // ... rest of the code
}
```

### Bước 3: Build cho Production

**Android:**
```bash
cd F:\app\da-nen-tang\app
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

**iOS:**
```bash
flutter build ipa --release
```
Output: `build/ios/ipa/*.ipa`

---

## Phần 3: Publish lên App Stores

### 3.1. Google Play Store (Android)

#### Yêu cầu:
- Tài khoản Google Play Developer ($25 một lần)
- Package name: `com.smartgrocery.app`
- App signing key

#### Bước 1: Tạo Signing Key

```bash
keytool -genkey -v -keystore F:\app\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Tạo file `android/key.properties`:
```properties
storePassword=<password-from-previous-command>
keyPassword=<password-from-previous-command>
keyAlias=upload
storeFile=F:/app/upload-keystore.jks
```

Cập nhật `android/app/build.gradle`:
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

#### Bước 2: Publish

1. Đăng nhập https://play.google.com/console
2. **Create app** → Điền thông tin:
   - App name: Smart Grocery
   - Language: Vietnamese
   - App type: Free/Paid
3. Upload `app-release.aab`
4. Điền đầy đủ:
   - Store listing (mô tả, screenshots, icon)
   - Content rating
   - Privacy policy
   - Pricing & distribution
5. Submit for review (1-7 ngày)

### 3.2. Apple App Store (iOS)

#### Yêu cầu:
- Apple Developer Account ($99/năm)
- MacBook (để build iOS)
- Bundle ID: `com.smartgrocery.app`

#### Bước 1: Cấu hình Xcode

1. Mở `ios/Runner.xcworkspace` trong Xcode
2. Chọn **Signing & Capabilities**
3. Chọn Team (Apple Developer Account)
4. Xcode tự động tạo provisioning profile

#### Bước 2: Build & Archive

1. Product → Archive
2. Distribute App → App Store Connect
3. Upload

#### Bước 3: Submit trên App Store Connect

1. Đăng nhập https://appstoreconnect.apple.com
2. **My Apps** → **+** → New App
3. Điền thông tin:
   - Name: Smart Grocery
   - Language: Vietnamese
   - Bundle ID
   - SKU
4. Upload screenshots, description, keywords
5. Select build đã upload
6. Submit for review (1-3 ngày)

---

## Phần 4: CI/CD - Auto Deploy khi Update

### Option A: GitHub Actions (Miễn phí)

Tạo file `.github/workflows/deploy.yml`:

```yaml
name: Deploy Backend

on:
  push:
    branches: [main]
    paths:
      - 'be/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Deploy to DigitalOcean
        uses: digitalocean/action-doctl@v2
        with:
          token: ${{ secrets.DIGITALOCEAN_TOKEN }}
      
      - name: Trigger App Platform Deploy
        run: |
          doctl apps create-deployment ${{ secrets.APP_ID }} --wait
```

Thêm secrets trong GitHub repo settings:
- `DIGITALOCEAN_TOKEN`
- `APP_ID`

### Option B: DigitalOcean App Platform Auto-Deploy

1. Trong App settings, bật **Autodeploy**
2. Mỗi khi push code lên GitHub branch `main`, tự động deploy

---

## Phần 5: Monitoring & Maintenance

### 5.1. Backend Monitoring

**DigitalOcean App Platform:**
- Built-in metrics: CPU, Memory, Request rate
- Logs viewer
- Alerts qua email

**Sentry (Error tracking):**
```gradle
// be/build.gradle.kts
implementation("io.sentry:sentry-spring-boot-starter:7.0.0")
```

### 5.2. Database Backup

**DigitalOcean Managed Database:**
- Auto daily backup (7 days retention)
- Manual backup trước khi update lớn

### 5.3. Update Strategy

#### Backend Update:
1. Test thoroughly trên local
2. Push code lên GitHub
3. Auto deploy hoặc trigger manual deploy
4. Monitor logs và errors
5. Rollback nếu có vấn đề (DigitalOcean hỗ trợ)

#### App Update:
1. Bump version trong `pubspec.yaml`:
   ```yaml
   version: 1.0.1+2  # version_name+build_number
   ```
2. Build mới:
   ```bash
   flutter build appbundle --release  # Android
   flutter build ipa --release        # iOS
   ```
3. Upload lên Play Console / App Store Connect
4. Submit for review
5. Users tự động nhận update notification

---

## Phần 6: Chi phí ước tính hàng tháng

| Dịch vụ | Chi phí | Ghi chú |
|---------|---------|---------|
| DigitalOcean App Platform | $12 | Backend instance |
| DigitalOcean Managed PostgreSQL | $15 | Database với backup |
| Domain name | $12/năm | Optional |
| SSL Certificate | Miễn phí | Let's Encrypt |
| Apple Developer | $99/năm | Nếu có iOS app |
| Google Play Console | $25 một lần | Android only |
| **Tổng** | **~$27/tháng** | Không kể iOS |

### Tiết kiệm chi phí:

**Option tiết kiệm ($12/tháng):**
- Dùng DigitalOcean Droplet ($6)
- Cài PostgreSQL trên cùng Droplet
- Tự quản lý backup

---

## Phần 7: Security Checklist

Trước khi production, đảm bảo:

- [ ] Đổi tất cả passwords mặc định
- [ ] Sử dụng HTTPS (SSL) cho tất cả API calls
- [ ] JWT secret key đủ mạnh (256-bit)
- [ ] Database không public, chỉ backend access được
- [ ] Enable firewall trên DigitalOcean
- [ ] Backup database tự động
- [ ] Rate limiting cho API endpoints
- [ ] Input validation
- [ ] SQL injection protection (đã có sẵn với JPA)
- [ ] XSS protection
- [ ] CORS cấu hình đúng
- [ ] Sensitive data trong .env, không commit lên Git
- [ ] Privacy policy và Terms of Service cho app

---

## Phần 8: Troubleshooting

### Backend không start:
```bash
# Check logs
doctl apps logs <app-id>

# Hoặc trên Droplet
docker-compose logs -f backend
```

### Database connection failed:
- Kiểm tra DATABASE_URL format
- Verify username/password
- Check firewall rules

### App không connect được backend:
- Kiểm tra URL trong ApiConfig
- Test API trên Postman trước
- Check CORS configuration
- Verify SSL certificate

---

## Bước tiếp theo

1. **Ngay bây giờ:**
   - [ ] Push code lên GitHub
   - [ ] Đăng ký DigitalOcean
   - [ ] Deploy backend lên App Platform

2. **Trong 1-2 ngày:**
   - [ ] Test production API
   - [ ] Update Flutter app với production URL
   - [ ] Build release APK/AAB

3. **Trong 1 tuần:**
   - [ ] Đăng ký Google Play Console
   - [ ] Tạo store listing
   - [ ] Submit app for review

4. **Trong 2 tuần:**
   - [ ] App được approve
   - [ ] Public trên Play Store
   - [ ] Invite beta testers
   - [ ] Thu thập feedback

Bạn có câu hỏi gì về bất kỳ phần nào không?
