# SoundShare Web trên Render và Safari iPhone

Nhánh thử: `feature/safari-web-deploy`, dựa trên `develop` và bao gồm source V7/V9 đang có. Docker build Flutter Web rồi Express phục vụ cả UI và `/api/v1` qua cùng HTTPS origin. Không cần Mac, Xcode hoặc Apple Developer Account để mở website trên iPhone. Đây là cấu hình bản thử; kiểm tra trên thiết bị thật vẫn cần thực hiện sau khi deploy.

## Build và chạy

`Dockerfile` dùng Flutter **3.47.4**, xác minh commit `9584c6713b324636289d067944a46fd6b49df14b` (Dart **3.13.3**), Node.js **22**, `flutter pub get --enforce-lockfile` và `npm ci --omit=dev`. Không dùng image Cirrus `stable`: [nhà phát hành đã ngừng cập nhật từ tháng 5/2026](https://github.com/cirruslabs/docker-images-flutter). Runtime chạy bằng user `node`, bind `0.0.0.0:$PORT`, chỉ chứa backend và `build/web`. CanvasKit được đóng gói cục bộ bằng `--no-web-resources-cdn`; build JavaScript mặc định, không yêu cầu WasmGC trên Safari.

`.dockerignore` chỉ cho phép các đầu vào build cần thiết. Không đưa `.env`, `.local`, node_modules, Git history, log, private key hay cấu hình Neon vào context. Build chỉ đọc hai ARG công khai: `CLERK_PUBLISHABLE_KEY`, `WEB_API_BASE_URL`. Không truyền secret bằng build argument, Dockerfile hoặc lệnh CLI lưu trong shell history.

Trên máy có Docker, đặt publishable key vào biến môi trường công khai rồi chạy từ repository root:

```powershell
docker build --build-arg CLERK_PUBLISHABLE_KEY -t soundshare-web .
# Dùng file môi trường staging riêng, ngoài Git; không dùng database production.
docker run --rm -p 10000:10000 --env-file C:\private\soundshare-staging.env soundshare-web
```

Nếu không đặt `WEB_API_BASE_URL`, Web gọi API theo `Uri.base.origin`, nên Render cấp URL nào cũng không tạo request về localhost hoặc địa chỉ Android emulator. Nếu đặt URL riêng, chỉ nhận HTTPS origin (HTTP chỉ dành cho loopback local), không nhận credential, path, query hoặc fragment. Giá trị này phải đặt **khi build**. Đổi publishable key hoặc API URL cần rebuild; frontend và backend phải dùng cùng Clerk instance.

Không thêm CI Docker theo lựa chọn của người dùng. Máy chuẩn bị mã chưa có Docker; kết quả build Flutter Web không thay thế kiểm chứng toàn bộ image. Cần chạy lệnh Docker phía trên hoặc xem lần build Render đầu tiên trước khi coi container đã được nghiệm thu. Sau khi build, có thể kiểm tra cấu trúc image mà không cần credential:

```powershell
docker run --rm --entrypoint node soundshare-web -e "const fs=require('node:fs'); for(const p of ['/app/build/web/index.html','/app/build/web/canvaskit/canvaskit.wasm','src/database/migrations/006_social_discovery.sql']) { if(!fs.existsSync(p)) process.exit(1); } if(process.getuid()===0 || fs.existsSync('.env')) process.exit(1); console.log('Runtime files and user verified');"
```

## Tạo service

1. Kết nối GitHub repository `TieuBao-IT89/SoundShare` trong Render. Chọn **New → Blueprint**, branch `feature/safari-web-deploy`, file `render.yaml`; hoặc tạo Web Service Docker với context root và `./Dockerfile`.
2. Blueprint dùng Free ở Singapore, tắt auto-deploy, health check `/api/v1/health`. Đây là bản thử, không tự merge `develop`/`main`. Nếu tạo thủ công, chọn đúng các thiết lập này.
3. Điền các giá trị sau trực tiếp trong phần Environment của Render, không gửi secret qua chat hoặc commit vào Git.

| Biến | Cấu hình |
|---|---|
| `NODE_ENV` | `production` (chế độ chạy Node, kể cả bản thử) |
| `SERVE_FLUTTER_WEB` | `true` |
| `TRUST_PROXY_HOPS` | `1` cho ingress Render; local trực tiếp dùng `0` |
| `CLERK_PUBLISHABLE_KEY` | Public key dùng cho cả build Flutter và backend |
| `CLERK_SECRET_KEY` | Secret key cùng instance, chỉ backend |
| `CLERK_AUDIENCE` | `soundshare-api` |
| `CLERK_AUTHORIZED_PARTIES` | Origin HTTPS **thực tế** do Render cấp hoặc tên miền đã cấu hình |
| `WEB_API_BASE_URL` | Không bắt buộc; bỏ trống để dùng cùng origin |
| `DATABASE_URL` | Neon **staging/test branch riêng**, pooled connection với TLS |
| `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET` | Môi trường lưu trữ thử đã cấu hình; asset vẫn private/authenticated |

Render cấp HTTPS tự động. Nếu URL được thêm hậu tố để tránh trùng tên service, cập nhật `CLERK_AUTHORIZED_PARTIES` theo URL thực tế rồi deploy lại. `TRUST_PROXY_HOPS` chỉ dùng khi mọi request qua ingress tin cậy, không mở cổng runtime trực tiếp ra Internet. Giá trị sai khiến rate limit nhận sai IP; không dùng `trust proxy=true` vô điều kiện. [Host/port của Render](https://render.com/docs/web-services#host-and-port-configuration), [Express sau proxy](https://expressjs.com/en/guide/behind-proxies/).

Render cung cấp environment cho cả build và runtime, nhưng Dockerfile này chỉ tham chiếu hai giá trị công khai khi build. Không thêm secret vào ARG. [Docker trên Render](https://render.com/docs/docker), [Blueprint specification](https://render.com/docs/blueprint-spec).

## Schema, Clerk và vòng đời service

Server kiểm tra migration 001–006 trước khi mở cổng, không tự migrate khi startup. Chuẩn bị database staging trước lần deploy đầu: trong terminal riêng đã cấu hình biến môi trường của **staging**, chạy `npm --prefix backend run migrate`, sau đó `npm --prefix backend run db:check`. Không thay `.env` development đang dùng và không chạy lệnh này trên production. Có thể chạy cùng lệnh trong image với `docker run --rm --env-file C:\private\soundshare-staging.env soundshare-web npm run migrate` sau khi build. Chỉ đường dẫn file xuất hiện trong history, không có credential.

Free không hỗ trợ pre-deploy command, shell hoặc one-off job; vì vậy phải chuẩn bị schema từ máy được cấp quyền trước khi khởi động service. Với môi trường trả phí, có thể cấu hình `preDeployCommand: npm run migrate` sau khi rà soát migration và xác nhận database đích. Không có migration tự động trong Blueprint hiện tại.

Clerk Sessions → Customize session token cần claim `{"aud":"soundshare-api"}`. Cặp key phải cùng instance; issuer/audience/expiry/signature và authorized parties vẫn được server xác minh. Clerk Development chỉ dành cho thử nghiệm. Đưa lên production chính thức cần domain do bạn sở hữu, DNS và OAuth credentials riêng theo [hướng dẫn Clerk](https://clerk.com/docs/guides/development/deployment/production).

V9 dùng notification outbox bền vững. Process hiện tại giao thông báo mỗi 15 giây khi đang chạy; `npm run notifications:deliver` là lệnh worker có thể chạy bằng scheduler riêng đã được cấp quyền. Free service ngủ sau 15 phút không có request: timer ngừng, thông báo chờ trong Neon rồi tiếp tục giao khi service thức. Không có push notification iOS. Muốn giao liên tục cần service luôn chạy và scheduler đáng tin cậy; Blueprint thử không tự tạo dịch vụ trả phí. [Giới hạn Free](https://render.com/docs/free).

## Nghiệm thu trên iPhone

Sau khi Render báo deploy thành công, xác minh `/api/v1/health` trả `200`, `/` trả HTML, CanvasKit tải được, endpoint riêng tư trả `401` khi thiếu token. Sau đó mở **Safari trên iPhone thật** bằng HTTPS:

- Đăng ký/đăng nhập, OTP hoặc Google nếu đã cấu hình; refresh vẫn giữ phiên, đăng xuất dừng audio. Nếu `401`, kiểm tra audience/origin trước khi sửa dữ liệu.
- Tìm kiếm, mở hồ sơ, follow/unfollow giữa hai tài khoản thử; không hiển thị bài private của người khác.
- Chạm Play để phát; kiểm tra pause, tua, bài tiếp theo và Cloudinary signed URL. Safari có thể yêu cầu thao tác người dùng trước khi cho phát; lần đầu vào Shorts không tự phát.
- Vuốt Shorts, nghe thử, mở bài đầy đủ và quay về; kiểm tra một player duy nhất, button không bị safe area che.
- Viết/reply/thích/xóa bình luận; mở tài khoản nhận để xem notification, unread và đánh dấu đã đọc. Không coi việc chỉ mở được inbox là nghiệm thu luồng thông báo.
- Kiểm tra bàn phím ở comment sheet, cuộn dọc/ngang, xoay màn hình, upload MP3 hợp lệ và thông báo lỗi khi sai loại/kích thước.
- Đổi tab, khóa màn hình, trở lại và thử khi service vừa thức. Đây là Web Safari; chưa cam kết hành vi background/native lock screen của ứng dụng iOS.

Không ghi token, signed URL, email thật hoặc chuỗi kết nối vào ảnh chụp/log nghiệm thu. Chỉ ghi phiên bản iOS, commit deploy, bước kiểm tra, HTTP status/error code an toàn và kết quả. Chưa có service URL hoặc kết quả Safari thật cho đến khi tài khoản Render được kết nối, environment được cấu hình và các bước này được chạy.

## Kiểm tra bản chuẩn bị ngày 08/11/2026

| Kiểm tra | Kết quả |
|---|---|
| `flutter pub get`, format, `flutter analyze` | Thành công, không có vấn đề analyzer |
| `flutter test` | 317 test qua |
| `flutter test --platform chrome test/api_config_test.dart` | Không hoàn tất: test server Flutter trả 404 cho `canvaskit/chromium/canvaskit.js` và `.wasm`; đã dừng tiến trình test. Không tính là test Chrome qua |
| `node --test backend/test/*.test.js test/web/*.cjs` | 110 test qua; 1 integration test bỏ qua do không đặt `TEST_DATABASE_URL` |
| `flutter build web --release --no-web-resources-cdn --dart-define-from-file=.local/web-config.json` | Thành công (130,9 giây) |
| `render.yaml` với JSON Schema chính thức của Render | Hợp lệ |
| HTTP development: `/`, health, CanvasKit, auth thiếu token | Lần lượt 200 / 200 / 200 / 401; SHA-256 của JS phục vụ qua Express khớp bundle release mới |
| Chrome headless mở bản release qua Express local | Trang chào hiển thị được; chưa kiểm tra phiên đăng nhập hoặc Safari thật. Ảnh local: `.local/safari-deploy-local-chrome.png` (không commit) |
| Rà soát staged files và bundle với các secret backend đang cấu hình | Không phát hiện giá trị secret; `.env` không được track |
| Docker build / service Render / Safari iPhone | Chưa chạy; máy không có Docker, người dùng chọn bỏ CI Docker; cần kết nối Render và cấu hình môi trường để tiếp tục |
