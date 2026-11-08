# SoundShare Web trên Render và Safari iPhone

Nhánh triển khai hiện tại: `develop`, bao gồm V7/V9 và V11 đã merge; `feature/safari-web-deploy` là nhánh chuẩn bị ban đầu. Docker build Flutter Web rồi Express phục vụ cả UI và `/api/v1` qua cùng HTTPS origin. Không cần Mac, Xcode hoặc Apple Developer Account để mở website trên iPhone. Đây là cấu hình bản thử; kiểm tra trên thiết bị thật vẫn cần thực hiện sau khi deploy.

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
docker run --rm --entrypoint node soundshare-web -e "const fs=require('node:fs'); for(const p of ['/app/build/web/index.html','/app/build/web/canvaskit/canvaskit.wasm','src/database/migrations/007_synced_lyrics.sql']) { if(!fs.existsSync(p)) process.exit(1); } if(process.getuid()===0 || fs.existsSync('.env')) process.exit(1); console.log('Runtime files and user verified');"
```

## Tạo service

1. Kết nối GitHub repository `TieuBao-IT89/SoundShare` trong Render. Chọn **New → Blueprint**, branch `develop`, file `render.yaml`; hoặc tạo Web Service Docker theo `develop`, với context root và `./Dockerfile`.
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

### Lỗi giải nén SDK trên Render

Lần deploy đầu trên service `soundshare-783s.onrender.com` (commit `5221e54`) dừng tại `flutter precache --web`: GNU tar cố khôi phục owner `uid 397546, gid 5000` từ `gradle-wrapper.tgz` và Render trả `Cannot change ownership ... Invalid argument`. Thông báo Flutter gợi ý kiểm tra mạng là lỗi bọc ngoài; log cụ thể cho thấy bước giải nén bị từ chối quyền sở hữu.

Builder đặt `TAR_OPTIONS=--no-same-owner` trước các lệnh Flutter để tar không khôi phục UID/GID của archive. Biến chỉ có trong stage Flutter, không đưa vào Node runtime; không đổi API URL, credential hoặc dữ liệu. Sau khi merge bản sửa vào nhánh `develop` mà service đang theo dõi, chọn **Manual Deploy → Deploy latest commit**. Chỉ xóa build cache nếu lần deploy mới vẫn dùng đầu vào cũ; cần kiểm tra commit và log mới trước khi coi lỗi đã hết.

Đã tải đúng archive trong log, xác nhận metadata `(397546, 5000)` và giải nén bằng GNU tar 1.35 trên Windows với `TAR_OPTIONS=--no-same-owner` kế thừa qua môi trường: thành công, có `gradle-wrapper.jar` và `gradlew`. Kiểm tra này xác nhận tùy chọn và archive, không tái tạo namespace Linux của Render hoặc thay thế lần Docker build mới. Xem [tài liệu GNU tar về quyền sở hữu](https://www.gnu.org/software/tar/manual/tar.html).

Service URL đã biết: `https://soundshare-783s.onrender.com`. Khi deploy, `CLERK_AUTHORIZED_PARTIES` phải chứa origin này; `WEB_API_BASE_URL` có thể bỏ trống để dùng cùng origin. Lỗi giải nén trên xảy ra trước startup, không chứng minh các cấu hình runtime hoặc schema đã hợp lệ.

Server hiện kiểm tra migration 001–007 trước khi mở cổng, không tự migrate khi startup. Chuẩn bị database staging trước lần deploy đầu: trong terminal riêng đã cấu hình biến môi trường của **staging**, chạy `npm --prefix backend run migrate`, sau đó `npm --prefix backend run db:check`. Không thay `.env` development đang dùng và không chạy lệnh này trên production. Có thể chạy cùng lệnh trong image với `docker run --rm --env-file C:\private\soundshare-staging.env soundshare-web npm run migrate` sau khi build. Chỉ đường dẫn file xuất hiện trong history, không có credential.

Free không hỗ trợ pre-deploy command, shell hoặc one-off job; vì vậy phải chuẩn bị schema từ máy được cấp quyền trước khi khởi động service. Với môi trường trả phí, có thể cấu hình `preDeployCommand: npm run migrate` sau khi rà soát migration và xác nhận database đích. Không có migration tự động trong Blueprint hiện tại.

Clerk Sessions → Customize session token cần claim `{"aud":"soundshare-api"}`. Cặp key phải cùng instance; issuer/audience/expiry/signature và authorized parties vẫn được server xác minh. Clerk Development chỉ dành cho thử nghiệm. Đưa lên production chính thức cần domain do bạn sở hữu, DNS và OAuth credentials riêng theo [hướng dẫn Clerk](https://clerk.com/docs/guides/development/deployment/production).

V9 dùng notification outbox bền vững. Process hiện tại giao thông báo mỗi 15 giây khi đang chạy; `npm run notifications:deliver` là lệnh worker có thể chạy bằng scheduler riêng đã được cấp quyền. Free service ngủ sau 15 phút không có request: timer ngừng, thông báo chờ trong Neon rồi tiếp tục giao khi service thức. Không có push notification iOS. Muốn giao liên tục cần service luôn chạy và scheduler đáng tin cậy; Blueprint thử không tự tạo dịch vụ trả phí. [Giới hạn Free](https://render.com/docs/free).

## Ping định kỳ tùy chọn

`backend/src/config/cron.js` cung cấp job ping public origin của chính backend. Dùng timer có sẵn của Node, không thêm package `cron`. Trong **Render → Environment**, đặt:

```dotenv
NODE_ENV=production
KEEP_ALIVE_ENABLED=true
API_URL=https://soundshare-783s.onrender.com
```

`API_URL` là origin HTTPS, không có `/api`, query, fragment hoặc thông tin đăng nhập; khác với `WEB_API_BASE_URL` dành cho Flutter. Job tự gọi **GET `/api/v1/health`**, không phải `/api/health`. Chỉ bật khi đồng thời có `NODE_ENV=production` và `KEEP_ALIVE_ENABLED=true`; Blueprint và `.env.example` mặc định tắt. Không chỉnh `.env` thật trong repository để bật trên Render.

Sau khi server mở cổng, job ping một lần rồi lặp lại mỗi **14 phút thực**, thay vì cron expression `*/14` vốn chạy ở phút 00, 14, 28, 42, 56 và có khoảng cách 4 phút qua giờ mới. Mỗi request có timeout 10 giây, chặn request chồng nhau, không đi theo redirect và giải phóng response body. Timer không giữ process sống khi server đã đóng; đóng server hủy request đang chờ. URL sai chỉ vô hiệu job và log `KEEP_ALIVE_CONFIG_INVALID`, không làm server dừng. Log chỉ gồm mã sự kiện và HTTP status; không in URL, nội dung response hoặc lỗi mạng gốc. `KEEP_ALIVE_OK` chỉ xác nhận lần ping trả 200.

**Self-ping chỉ chạy khi process còn hoạt động.** Khi Render đã cho service ngủ hoặc restart, timer cũng dừng; job không tự gọi dậy được và không bảo đảm hoạt động liên tục. Theo [Render Free](https://render.com/docs/free#spinning-down-on-idle), service ngủ sau 15 phút không có inbound traffic, thức khi có request mới và có thể mất khoảng một phút. Giới hạn giờ chạy và khả năng restart/suspend của Free vẫn áp dụng.

Để request vẫn đến khi process ngủ, thiết lập scheduler/HTTP monitor **bên ngoài service** với GET `https://soundshare-783s.onrender.com/api/v1/health`, lịch `*/10 * * * *` và timeout khoảng 90 giây cho cold start. Không cần Bearer token hay secret cho health. Khi dùng lịch ngoài, có thể giữ `KEEP_ALIVE_ENABLED=false` để tránh hai nguồn ping. Hướng dẫn này chưa tạo hoặc kích hoạt tài khoản scheduler nào. Nếu cần độ sẵn sàng cho production, cân nhắc compute plan luôn chạy; [Render Cron Jobs](https://render.com/docs/cronjobs#compute-plans-and-billing) có phí riêng, không được tạo tự động trong thay đổi này.

Kiểm tra tự động: `node --test backend/test/cron.test.js` kiểm tra opt-in/môi trường, URL sai và log an toàn, lịch 14 phút/endpoint đúng, request chồng nhau, timeout/recovery và hủy khi đóng. Bộ cron/backend Web-auth/Web JavaScript có **34/34 test đạt**. Ping không xử lý lỗi schema/startup.

Ghi nhận ngày **08/11/2026**: migration 007 đã áp dụng trên database cấu hình trong `backend/.env`, read-only schema check đạt; xem [chi tiết V11](soundshare-v11-lyrics.md#migration-và-triển-khai). Người vận hành cung cấp Environment Render với `NODE_ENV=production`, `KEEP_ALIVE_ENABLED=true` và đúng public `API_URL`. Kiểm tra HTTP tới service trả **200**, health báo healthy và bundle Web có phần V11. Đây chưa xác nhận log `KEEP_ALIVE_OK` của bản ping mới: cần deploy commit chứa `backend/src/config/cron.js`, rồi xem Logs. Không có kết nối Dashboard/API Render để tự bấm deploy hoặc đọc log; Blueprint tắt auto-deploy, còn service tạo thủ công giữ thiết lập riêng trên Dashboard. Không lưu hoặc công khai bản sao Environment thật.

## Nghiệm thu trên iPhone

Sau khi Render báo deploy thành công, xác minh `/api/v1/health` trả `200`, `/` trả HTML, CanvasKit tải được, endpoint riêng tư trả `401` khi thiếu token. Sau đó mở **Safari trên iPhone thật** bằng HTTPS:

- Đăng ký/đăng nhập, OTP hoặc Google nếu đã cấu hình; refresh vẫn giữ phiên, đăng xuất dừng audio. Nếu `401`, kiểm tra audience/origin trước khi sửa dữ liệu.
- Tìm kiếm, mở hồ sơ, follow/unfollow giữa hai tài khoản thử; không hiển thị bài private của người khác.
- Chạm Play để phát; kiểm tra pause, tua, bài tiếp theo và Cloudinary signed URL. Safari có thể yêu cầu thao tác người dùng trước khi cho phát; lần đầu vào Shorts không tự phát.
- Vuốt Shorts, nghe thử, mở bài đầy đủ và quay về; kiểm tra một player duy nhất, button không bị safe area che.
- Viết/reply/thích/xóa bình luận; mở tài khoản nhận để xem notification, unread và đánh dấu đã đọc. Không coi việc chỉ mở được inbox là nghiệm thu luồng thông báo.
- Kiểm tra bàn phím ở comment sheet, cuộn dọc/ngang, xoay màn hình, upload MP3 hợp lệ và thông báo lỗi khi sai loại/kích thước.
- Đổi tab, khóa màn hình, trở lại và thử khi service vừa thức. Đây là Web Safari; chưa cam kết hành vi background/native lock screen của ứng dụng iOS.

Không ghi token, signed URL, email thật hoặc chuỗi kết nối vào ảnh chụp/log nghiệm thu. Chỉ ghi phiên bản iOS, commit deploy, bước kiểm tra, HTTP status/error code an toàn và kết quả. Service đã được tạo tại `https://soundshare-783s.onrender.com`, nhưng lần deploy đầu thất bại ở bước giải nén SDK; chưa có bản chạy thành công hoặc kết quả Safari thật.

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
| Docker build / service Render / Safari iPhone | Máy local không có Docker, người dùng chọn bỏ CI. Render đã build lần đầu trên develop `5221e54`, thất bại khi giải nén Gradle Wrapper; đã chuẩn bị sửa TAR_OPTIONS, chờ build lại. Safari chưa nghiệm thu |
