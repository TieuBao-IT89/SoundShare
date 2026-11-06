# SoundShare

**Chia sẻ âm nhạc của bạn. Tận hưởng từng khoảnh khắc.**

Bản giao diện **OBSIDIAN PULSE V4** tổ chức lại Trang chủ/Khám phá quanh artwork thật, thêm topbar và playback dock trên desktop, queue dạng panel/drawer, hồ sơ có cover và thư viện/playlist mới. Player tiếp tục dùng chung AudioPlayer; “Phát tất cả”/“Phát ngẫu nhiên” đọc đủ trang playlist trước khi đổi queue. Không có migration hoặc thay đổi API cho V4. Xem [audit V4](docs/ui/obsidian-pulse-v4-audit.md) và [báo cáo kiểm tra V4](docs/ui/obsidian-pulse-v4-review.md).

SoundShare là ứng dụng Flutter để nghe, khám phá và chia sẻ bản thu độc lập. V3 **NOCTURNE** bổ sung hồ sơ `@username`, follow, khám phá/trending, playlist và chia sẻ public/private trên nền thư viện riêng hiện có. Flutter gọi Express; Clerk xác thực, Neon giữ metadata và Cloudinary giữ file authenticated. Các bài cũ tiếp tục riêng tư.

Xem [hướng dẫn NOCTURNE V3](docs/nocturne-v3.md), [kiểm kê/nguồn thiết kế](docs/ui/nocturne-v3-audit.md) và [kết quả kiểm tra V3](docs/ui/nocturne-v3-review.md). Cần chạy migration 004 và khởi động lại backend khi nâng cấp; tài liệu Mystic Aurora bên dưới là lịch sử nghiệm thu trước V3.

Giao diện **NOCTURNE** dùng tiếng Việt, nền gần đen, điểm nhấn violet/cyan, font Be Vietnam Pro và bố cục thích ứng với điện thoại/desktop. [Design system](DESIGN.md) mô tả bản hiện tại; [kiểm kê Mystic Aurora](docs/ui/mystic-aurora-inventory.md), [checklist](docs/ui/mystic-aurora-checklist.md) và [báo cáo cũ](docs/ui/mystic-aurora-review.md) được giữ làm lịch sử.

## Tính năng

- Giao diện nghe nhạc nền tối, thích ứng với màn hình, có màn hình khởi động và thanh điều hướng dưới.
- Trang chủ biên tập, khám phá theo thể loại, trending theo khoảng thời gian, tìm bài hát/tài khoản/playlist qua REST API. Nội dung cộng đồng chỉ lấy bài public/active; thư viện riêng vẫn được giữ.
- Hồ sơ SoundShare có @username duy nhất, tìm kiếm không phân biệt hoa/thường, follow/unfollow và danh sách người theo dõi có phân trang.
- Trình phát nhạc hỗ trợ phát trực tuyến, tua bài, yêu thích, phát ngẫu nhiên, lặp lại và chuyển bài.
- Upload MP3 tối đa 20 MB, artwork JPG/PNG/WebP tối đa 5 MB; chỉ báo lưu thành công sau khi file và metadata được backend xác nhận.
- Lượt thích lưu trong Neon theo tài khoản. Đăng xuất dừng audio và giải phóng dữ liệu phiên; tài khoản mới bắt đầu với thư viện rỗng.
- Playlist, thích/lưu, hàng đợi dùng chung player, tiến trình nghe và feed người theo dõi. Ranking thử nghiệm chỉ dùng tương tác thực, có ngưỡng nghe và dedupe.
- Cá nhân cho sửa username, tên hiển thị, bio, avatar và cover trong SoundShare; credential vẫn do Clerk quản lý. Bài tải lên mặc định private, cần xác nhận quyền nội dung và chọn username trước khi public. Sửa/xóa chỉ dành cho owner; báo cáo nội dung lưu server, moderation qua CLI của người vận hành.

## Công nghệ

Flutter và Dart · Riverpod · GoRouter · just_audio. Backend: Node.js + Express REST API · Neon PostgreSQL · Clerk · Cloudinary. Web dùng ClerkJS 6 và UI của Clerk; SDK quản lý đăng ký, email verification, khôi phục mật khẩu và phiên. Đã xác minh đăng nhập thật, upload MP3/artwork, lưu hồ sơ qua F5, tìm @username/follow giữa hai tài khoản, phát bài công khai khi chuyển tab và ghi nhận lượt nghe hợp lệ vào Neon development/ranking. Xem báo cáo V3 để phân biệt kiểm thử tự động, nghiệm thu thật và các bước còn mở; native chưa được nghiệm thu.

## Ảnh chụp màn hình

Xem [báo cáo issue #5 với dữ liệu demo](docs/ui/issue-5-review.md) và [hướng dẫn bản Web dùng tài khoản thật](docs/auth-real-data.md). Ảnh rà soát Web chưa thay thế kiểm tra Android/iOS thật.

## Yêu cầu

- Flutter SDK tương thích với Dart `^3.13.3`.
- Android Studio cùng Android SDK và trình giả lập, hoặc thiết bị Android thật.
- Visual Studio Code cùng các tiện ích mở rộng Flutter và Dart.

## Chạy Web trên Windows

1. Cài Flutter và Node.js 22+, chạy `flutter pub get` tại thư mục gốc và `npm ci` tại `backend/`.
2. Cấu hình `backend/.env` theo `backend/.env.example` với Clerk, Cloudinary và Neon **development**. Trong Clerk Sessions → Customize session token thêm `"aud": "soundshare-api"`; đặt `CLERK_AUTHORIZED_PARTIES=http://localhost:3000` tại backend.
3. Chạy `npm run migrate` tại `backend/`. Migration 003 bổ sung thư viện riêng; 004 mở rộng hồ sơ và cộng đồng. Không tự công khai hoặc xóa dữ liệu cũ.
4. Từ thư mục gốc, chạy:

   ```powershell
   .\scripts\run-web.ps1
   # Nếu Flutter chưa có trong PATH:
   .\scripts\run-web.ps1 -FlutterExecutable 'C:\path\to\flutter\bin\flutter.bat'
   ```

5. Mở `http://localhost:3000`, đăng ký/xác minh email rồi chọn **Tải nhạc lên**. **Thư viện → Nhạc đã tải lên** hiển thị bài đã lưu; chạm trái tim để thêm vào **Yêu thích**.

Script chỉ xuất publishable key và API URL vào `.local/web-config.json` đã gitignore; không đưa `.env` backend vào build. Express chỉ phục vụ `build/web`. Secret/database URL luôn ở backend. Xem [cấu hình, kiểm tra và xử lý lỗi Clerk](docs/auth-real-data.md).

Sau đăng nhập, ứng dụng chờ phiên Clerk active và xác minh qua `/api/v1/auth/me` trong tối đa 25 giây; có thể thử lại hoặc đăng xuất khi lỗi. Neon chỉ có hồ sơ `users` sau khi endpoint này trả `200`. Nếu gặp `401` với log `token-audience-missing`, cần sửa claim session trên Clerk; kết nối Neon thành công hoặc chạy lại migration không thay thế bước xác thực này.

Để xem giao diện mẫu có chủ ý: `flutter run -d chrome --dart-define=DEMO_MODE=true`. Thiếu Clerk key trong chế độ thật sẽ hiển thị lỗi cấu hình, không tự chuyển sang dữ liệu giả.

Nội dung giao diện nằm trong `lib/l10n/app_vi.arb`; sau khi sửa copy, chạy `flutter gen-l10n`. Font và bản dịch Clerk Web được đóng gói cục bộ, kèm giấy phép trong `assets/fonts/` và `web/`. Không thêm package animation. V3 mở rộng API và schema bằng migration version hóa; các endpoint riêng trước đó vẫn hoạt động.

## Chạy Android trên Windows

1. Cài Flutter và Android Studio, sau đó tạo và khởi động Android Emulator trong Device Manager của Android Studio.
2. Mở thư mục dự án bằng VS Code và chọn trình giả lập đang chạy trong danh sách thiết bị.
3. Mở terminal tích hợp và chạy:

   ```powershell
   flutter pub get
   flutter run --dart-define=DEMO_MODE=true
   ```

Bạn cũng có thể chạy `flutter run -d <device-id>` sau khi xem các thiết bị khả dụng bằng `flutter devices`.

## Phát triển

Ứng dụng được tổ chức theo từng tính năng trong `lib/features`; theme, dịch vụ và widget dùng chung nằm trong `lib/app` và `lib/core`. Hãy chạy các lệnh sau trước khi mở pull request:

```powershell
dart format .
flutter analyze
flutter test
node --test test/web/*.cjs
```

Backend mục tiêu giao tiếp với Neon qua Express REST API; ứng dụng Flutter không kết nối trực tiếp Neon. Khi triển khai, giữ connection string và secret ở backend thông qua biến môi trường/secret manager. Không commit thông tin bí mật.

### Giao diện mobile — issue #5

Hướng thiết kế và mục tiêu cho Home, Explore, Player, Upload, Library, Profile nằm trong [DESIGN.md](DESIGN.md). Dự án dùng [Taste Skill bản Flutter](.agents/skills/design-taste-frontend/SKILL.md).

Chọn bài từ Home/Explore/Library cập nhật đúng Player; mini-player giữ bài đang chọn khi tạm dừng hoặc đổi tab. Trong chế độ thật, tìm kiếm chạy ở server và lượt thích được lưu theo tài khoản. Nội dung bên dưới mô tả chế độ demo đã nghiệm thu ở issue #5.

Với `DEMO_MODE=true`, catalog/nghệ sĩ/artwork là mẫu, bốn bài dùng chung một URL audio demo và lượt thích chỉ tồn tại trong phiên. Upload demo chỉ tạo bản xem trước trên thiết bị. Chế độ thật gửi file và metadata tới Express; validation client không thay thế kiểm tra MIME/magic bytes phía server.

Kiểm thử tương tác và bố cục nằm trong `test/mobile_experience_test.dart`, giả lập audio player, catalog và file picker; không dùng tài khoản, Neon hay Cloudinary thật. Xem kết quả kiểm tra và giới hạn rà soát giao diện trong [DESIGN.md](DESIGN.md).

### Khám phá thể loại và bộ sưu tập — issue #7

Home có hai lối vào **Sample collections**: Softer corners (Dream pop/Indie folk) và After hours (Alternative/Electronic), kèm số bài trong catalog mẫu. Explore có chip thể loại lấy từ catalog và chip bộ sưu tập. Từ khóa, thể loại và bộ sưu tập kết hợp với nhau; kết quả cần khớp mọi lựa chọn.

**Clear search** chỉ xóa từ khóa; **All genres** và **All collections** bỏ nhóm tương ứng; chạm lại chip đang chọn cũng bỏ lựa chọn đó. **Clear all** xóa toàn bộ và đưa trang về đầu. Link như `/explore?collection=after-hours&genre=Electronic&q=Blue` mở đúng bộ lọc; quay lại từ Player giữ nguyên lựa chọn. Nhấn tab Explore từ tab khác mở chế độ duyệt mặc định.

Hai bộ sưu tập nhóm bài theo thể loại, chưa có cá nhân hóa. Trong chế độ thật, chúng lọc thư viện riêng qua API; chế độ demo giữ nội dung mẫu. Kiểm thử nằm trong `test/discovery_test.dart`; xem [báo cáo demo issue #7](docs/ui/issue-7-review.md).

## Đóng góp

Xem [CONTRIBUTING.md](CONTRIBUTING.md) để biết quy trình làm việc và hướng dẫn tạo pull request. Tất cả người đóng góp cần tuân thủ [Quy tắc ứng xử](CODE_OF_CONDUCT.md).

## Bảo mật

Vui lòng báo cáo lỗ hổng riêng tư theo hướng dẫn trong [SECURITY.md](SECURITY.md).

## Giấy phép

SoundShare được phát hành theo giấy phép MIT. Xem [LICENSE](LICENSE).

## Backend SoundShare

Phần backend của SoundShare được xây dựng bằng Node.js và Express.

### Yêu cầu

- Node.js 22 trở lên (bộ kiểm thử đã chạy với Node.js 22.14.0)
- npm
- Neon PostgreSQL

### Cài đặt

Từ thư mục gốc của kho mã nguồn, chuyển vào thư mục `backend/` và cài các gói phụ thuộc:

```bash
cd backend
npm install
```

### Biến môi trường

Tạo `backend/.env` từ `backend/.env.example`, sau đó điền các giá trị phù hợp với môi trường chạy. Ví dụ:

```env
PORT=3000
NODE_ENV=development
DATABASE_URL=your_neon_connection_string
```

Không commit `.env` lên Git. Khi kiểm tra trên máy cá nhân, hãy dùng cơ sở dữ liệu phát triển hoặc kiểm thử; không dùng cơ sở dữ liệu production.

### Chạy máy chủ phát triển

Chạy lệnh sau từ thư mục `backend/`:

```bash
npm run dev
```

### Cơ sở dữ liệu

SoundShare sử dụng Neon PostgreSQL thông qua nhóm kết nối của package `pg`.

#### Kiểm tra kết nối cơ sở dữ liệu

Chạy từ thư mục `backend/`:

```bash
node test-database.js
```

#### Chạy migration

Lệnh sau áp dụng migration lên cơ sở dữ liệu được chỉ định bởi `DATABASE_URL`. Hãy kiểm tra đúng môi trường trước khi chạy:

```bash
npm run migrate
```

Các file migration nằm trong `src/database/migrations/`. Những migration đã chạy được ghi nhận trong bảng `schema_migrations`.

Migration `002_create_media_assets.sql` bổ sung metadata cho file Cloudinary, lưu trực tiếp `clerk_user_id` để không phụ thuộc việc đồng bộ bảng `users`. Nếu migration thất bại, giữ nguyên trạng thái để kiểm tra lỗi; không tự tạo bảng thủ công trên Neon.

Sau khi migration thành công, có thể kiểm tra các cột bằng truy vấn chỉ đọc trong Neon SQL Editor:

```sql
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'media_assets'
ORDER BY ordinal_position;
```

Kiểm thử migration và ràng buộc `media_assets` dùng `npm run test:media-assets` trong `backend/`. Cần cấu hình biến môi trường `TEST_DATABASE_URL` tới PostgreSQL test riêng, khác database ứng dụng; không dùng production. Test tạo schema biệt lập trong transaction rồi rollback toàn bộ, và sẽ bỏ qua nếu chưa có `TEST_DATABASE_URL`.

#### Kiểm tra thao tác CRUD

Chạy từ thư mục `backend/` và dùng cơ sở dữ liệu phát triển hoặc kiểm thử riêng:

```bash
node test-crud.js
```

Tập lệnh CRUD thực hiện các thao tác ghi trong một transaction rồi hoàn tác dữ liệu thử nghiệm. Không chạy tập lệnh này trên môi trường production.

### API upload ảnh và audio

Backend nhận file bằng `multipart/form-data`, upload từ Express tới Cloudinary rồi lưu metadata vào Neon. Đây là luồng upload qua backend; luồng client upload trực tiếp bằng URL ký và upload intent vẫn là kế hoạch.

| Method / endpoint | Nội dung | Giới hạn |
|---|---|---|
| `POST /api/v1/uploads/artwork` | JPG/JPEG, PNG hoặc WebP | 5 MB (5 × 1024 × 1024 byte) |
| `POST /api/v1/uploads/audio` | MP3 (`audio/mpeg`) | 20 MB (20 × 1024 × 1024 byte) |
| `GET /api/v1/uploads/{assetId}/access` | URL đọc mới cho asset của chính người dùng | URL hết hạn sau 5 phút |
| `DELETE /api/v1/uploads/{assetId}` | Xóa file Cloudinary và metadata của chính người dùng | UUID lấy từ response upload; không body/query |

Mọi endpoint trên yêu cầu `Authorization: Bearer <Clerk session token>`. Owner lấy từ `sub` đã xác minh; request upload chỉ nhận đúng một trường file tên `file`, không nhận text field hoặc query parameter. Backend kiểm tra phần mở rộng, MIME và magic bytes; Cloudinary phải đọc được file và trả metadata khớp trước khi Neon được ghi.

Trước khi gọi API, trong Clerk Dashboard của instance tương ứng, mở **Sessions → Customize session token** và thêm claim `"aud": "soundshare-api"` vào các claim hiện có. Backend yêu cầu audience này theo mặc định (hoặc giá trị `CLERK_AUDIENCE` đã cấu hình), kiểm tra issuer từ publishable key của instance, chữ ký và hạn token. Dùng session token mới sau khi lưu cấu hình; không dùng Clerk secret key làm Bearer token. Nếu có web client, cấu hình `CLERK_AUTHORIZED_PARTIES` bằng danh sách origin tin cậy, phân cách bởi dấu phẩy. Xem [hướng dẫn Clerk](https://clerk.com/docs/guides/sessions/customize-session-tokens).

Từ thư mục `backend/`, chạy `npm run dev`. Ví dụ PowerShell (đặt session token trong biến môi trường của terminal, không ghi token vào mã nguồn):

```powershell
curl.exe -X POST http://localhost:3000/api/v1/uploads/artwork -H "Authorization: Bearer $env:CLERK_SESSION_TOKEN" -F "file=@C:\path\cover.png"
curl.exe -X POST http://localhost:3000/api/v1/uploads/audio -H "Authorization: Bearer $env:CLERK_SESSION_TOKEN" -F "file=@C:\path\track.mp3"
```

Response thành công có dạng `{ "success": true, "data": { "id": "...", "mediaType": "artwork", "resourceType": "image", "format": "png", "bytes": 1234, "originalFilename": "cover.png", "mimeType": "image/png", "createdAt": "...", "access": { "url": "...", "expiresAt": "..." } } }`. Trả `201` khi tạo mới, `200` khi cùng owner gửi lại cùng nội dung và loại media. Hai người upload cùng file có object key và bản ghi riêng. Retry cùng file không ghi đè object hoặc tạo metadata trùng; tên file lưu theo lần tạo đầu tiên.

Cloudinary lưu asset với `type: authenticated`. Neon lưu `public_id`, URL metadata HTTPS không có chữ ký và thuộc tính file; URL đọc có chữ ký chỉ được tạo trong response với `Cache-Control: no-store`. Chủ sở hữu có thể lấy lại URL qua endpoint `/access`; asset không tồn tại hoặc thuộc người khác đều trả `404` để không lộ dữ liệu riêng tư. Sau upload, `POST /api/v1/songs` tạo bài hát riêng từ asset ID; không công khai nội dung. Xóa asset đang được bài hát sử dụng trả `409 MEDIA_IN_USE` trước khi gọi Cloudinary.

Lỗi có dạng `{ "success": false, "error": { "code": "...", "message": "...", "requestId": "..." } }`, kèm header `X-Request-Id`. Các mã chính: `400 FILE_REQUIRED/INVALID_FILE/INVALID_MULTIPART/VALIDATION_ERROR`, `401 UNAUTHORIZED`, `404 MEDIA_NOT_FOUND`, `409 UPLOAD_IN_PROGRESS`, `413 FILE_TOO_LARGE`, `415 INVALID_FILE_TYPE`, `429 RATE_LIMITED`, `502 STORAGE_UNAVAILABLE/STORAGE_VERIFICATION_FAILED`, `503 DATABASE_UNAVAILABLE/UPLOAD_BUSY`. Với `409`, đợi một chút rồi gửi lại cùng file.

Giới hạn hiện tại trong một process: 10 upload/15 phút/user, 20 lần xóa/15 phút/user, 60 request/15 phút/user cho nhóm upload/access/delete, 120 request/15 phút/IP cho API riêng tư, và tối đa 4 upload đang xử lý. Khi triển khai nhiều instance cần limiter dùng kho chung; cấu hình proxy tin cậy theo môi trường triển khai, không tin `X-Forwarded-For` tùy ý.

Nếu ghi metadata thất bại và xác nhận chưa có bản ghi, backend thử xóa object vừa tạo. Khi trạng thái Neon không xác định hoặc cleanup thất bại, object được giữ private và phát sự kiện an toàn `UPLOAD_RECONCILIATION_REQUIRED`/`UPLOAD_CLEANUP_REQUIRED`; retry cùng file có thể đối soát lại. Chưa có worker dọn object mồ côi định kỳ. Lỗi hoặc mất kết nối sau khi upload không được hiểu là đã tạo bài hát thành công.

Chạy `npm test` để kiểm thử HTTP, Clerk signature/claims, validation, quyền đọc, retry, SQL tham số hóa và lỗi phụ thuộc. Test API dùng khóa RSA giả lập với middleware Clerk thật, đồng thời giả lập Cloudinary và Neon; test PostgreSQL riêng chỉ chạy khi có `TEST_DATABASE_URL`. Các test này không chứng minh phiên Clerk thật hoặc upload Cloudinary thật đã được kiểm tra trong môi trường triển khai.

### API xóa file Cloudinary

Gọi `DELETE /api/v1/uploads/{assetId}` với Clerk Bearer session token có audience như phần upload. `assetId` là UUID `data.id` trong response upload, không phải `public_id` Cloudinary. Request không nhận body hoặc query parameter:

```powershell
curl.exe -i -X DELETE http://localhost:3000/api/v1/uploads/UUID_CUA_ASSET -H "Authorization: Bearer $env:CLERK_SESSION_TOKEN"
```

Backend tìm asset trong phạm vi owner đã xác minh, dùng chung khóa transaction với upload và kiểm tra lại UUID sau khi lấy khóa. Backend gọi Cloudinary `destroy` bằng `public_id` và `resource_type` từ Neon, với `type: authenticated`, `invalidate: true`; chỉ sau khi Cloudinary xác nhận `ok` hoặc `not found` mới xóa metadata. Thành công trả `204 No Content`, không có JSON body. Không cần migration mới.

Các lỗi chính: `400 VALIDATION_ERROR` khi UUID/body/query không hợp lệ, `401 UNAUTHORIZED` khi thiếu/sai token, `404 MEDIA_NOT_FOUND` khi asset không còn hoặc không thuộc owner, `409 MEDIA_BUSY` khi cùng asset đang upload/xóa, `409 MEDIA_IN_USE` nếu bài hát đang dùng asset, `429 RATE_LIMITED`, `502 STORAGE_DELETE_FAILED` khi Cloudinary chưa xác nhận xóa, `503 DATABASE_UNAVAILABLE` khi Neon hoặc commit lỗi. Lỗi vẫn dùng JSON có `error.requestId`. Xóa lại UUID đã xóa hoàn tất trả `404` và không gọi Cloudinary, kể cả cùng nội dung vừa được upload lại thành asset mới.

Cloudinary lỗi thì metadata được giữ để retry. Nếu Cloudinary đã xóa nhưng Neon chưa hoàn tất, backend phát sự kiện `MEDIA_DELETE_RECONCILIATION_REQUIRED`; gửi lại DELETE cùng UUID sẽ chấp nhận file đã mất trên Cloudinary và hoàn tất metadata. Nếu commit trước đó đã thành công nhưng mất phản hồi, retry trả `404`. Không có transaction phân tán giữa Cloudinary và Neon, nên lỗi một phần có thể tạm để lại metadata trỏ tới file đã xóa; cần hoàn tất DELETE trước khi dùng lại asset đó.

`invalidate: true` yêu cầu Cloudinary xóa cache CDN; việc lan truyền cache không được đảm bảo tức thời. Xem [Cloudinary destroy API](https://cloudinary.com/documentation/image_upload_api_reference#destroy_by_public_id). Kiểm thử DELETE dùng Clerk middleware thật với khóa test và Cloudinary/Neon giả lập, không xóa dữ liệu thật để thử nghiệm.

### Kiểm tra tình trạng dịch vụ

```http
GET /api/v1/health
```

### Kiểm thử API backend

Chạy từ thư mục `backend/`:

```powershell
npm ci
npm test
npm run test:smoke
```

`npm test` chạy HTTP API với middleware Clerk thật và khóa RSA test; Cloudinary/Neon được giả lập để không upload hoặc xóa dữ liệu thật. Các trường hợp đã bao phủ:

| Nhóm | Kiểm tra |
|---|---|
| Authentication | Thiếu token, sai chữ ký, hết hạn, chưa có hiệu lực, sai issuer/audience, thiếu audience/session, session pending. |
| Upload | Ảnh và MP3 hợp lệ, file giả MIME/magic bytes, thiếu file, sai phần mở rộng, body/query thừa, vượt giới hạn 5 MB/20 MB, rate limit. |
| Quyền sở hữu | Chủ sở hữu lấy URL đọc/xóa; asset của người khác trả `404` và không gọi Storage để xóa. |
| Retry và đồng thời | Upload cùng nội dung không trùng bản ghi; upload/xóa dùng chung khóa; UUID cũ không xóa asset vừa upload lại. |
| Lỗi phụ thuộc | Lỗi Cloudinary/Neon, xóa dở dang, mất phản hồi commit, cleanup thất bại và đối soát khi retry. |
| Bảo mật dữ liệu | SQL tham số hóa, error/request ID nhất quán, không rò rỉ secret trong response/log; URL ký không lưu trong Neon. |

`npm run test:smoke` dùng cấu hình `.env` backend ở `development` hoặc `test`, mở server tạm trên cổng loopback ngẫu nhiên rồi tự đóng. Lệnh kiểm tra health, các endpoint riêng tư trả `401` khi không có token, Clerk JWKS, Cloudinary ping và sự tồn tại của bảng/migration media trên Neon. Các thao tác kiểm tra là chỉ đọc; không tạo/xóa asset hoặc bản ghi ứng dụng. Cần cấu hình provider hợp lệ và chạy migration trước; lỗi chỉ in tên kiểm tra, không in credential hay response provider.

Test PostgreSQL thực chỉ chạy khi `TEST_DATABASE_URL` trỏ tới database test riêng, khác `DATABASE_URL`; nếu chưa có thì test migration sẽ báo `SKIP`. Test này áp dụng migration từ schema rỗng trong transaction, kiểm tra default/ràng buộc và chạy lại migration `002` không mất metadata, sau đó rollback toàn bộ.

Kiểm tra Mystic Aurora ngày **06/11/2026**: **89 Flutter test đạt**, **3 kiểm thử tiến trình đạt trên Chrome**, **9 test Web bridge đạt** và analyzer sạch. Đã sửa lỗi giới hạn số nguyên làm đồng hồ/thanh tua bằng 0 khi biên dịch Web và lỗi Clerk chuyển hash khiến đăng nhập phải F5. Đã kiểm tra keyboard ở màn hình hẹp/ngang, Reduce Motion, ảnh đến muộn/lỗi và cập nhật tên không khởi tạo lại phiên. Release Web cho chế độ tài khoản thật và demo đều build thành công. Backend chạy lại có **56 test đạt, 1 integration test bỏ qua**. Xem [báo cáo và ảnh](docs/ui/mystic-aurora-review.md), gồm kiểm tra đăng nhập giả lập trên Chrome và cách xử lý CanvasKit của runner Chrome trên Windows; máy chưa có Android SDK nên chưa nghiệm thu APK/emulator.

Các lệnh kiểm thử client từ thư mục gốc:

```powershell
flutter test
flutter test --platform chrome test/music_progress_test.dart
node --test test/web/*.cjs
```

Kết quả tích hợp trước redesign ngày **05/11/2026**: `npm run test:smoke` có **15 kiểm tra đạt, 0 lỗi** với cấu hình development, gồm auth gate catalog và schema migration 003. Phiên người dùng thật đã nhận `200 /auth/me`, upload audio/artwork và tạo track trả `201`; truy vấn chỉ đọc Neon xác nhận hồ sơ, hai media asset và bài đã lưu. Playback, yêu thích, xóa file và phiên hết hạn bằng tài khoản thật chưa được nghiệm thu. Các lệnh `curl` ở phần upload/xóa dùng cho bước kiểm tra có xác thực trên môi trường development với file do bạn có quyền sử dụng; giữ session token trong biến môi trường terminal.

### API thư viện riêng

Mọi endpoint yêu cầu Clerk Bearer session token. `GET /api/v1/songs` lấy thư viện owner, hỗ trợ `query`, `genre`, `collection`, `limit` 1–50 và `cursor`; `POST /api/v1/songs` lưu bài từ asset ID đã upload. `GET /api/v1/songs/{id}/playback` cấp URL phát có hạn; `PUT`/`DELETE /api/v1/songs/{id}/favorite` lưu/bỏ yêu thích idempotent. Track/favorite được lưu trong migration 003, owner lấy từ token. Xem schema, status và error code tại [PRD mục 8.5](PRD.md) và [hướng dẫn nghiệm thu](docs/auth-real-data.md).

### Các bảng dữ liệu

- users
- artists
- albums
- songs
- playlists
- playlist_songs
- favorites
- listening_history
- media_assets (metadata Cloudinary; không lưu nội dung file hoặc URL ký tạm thời)
- private_tracks (MP3 và metadata của từng tài khoản)
- private_track_favorites (lượt thích của owner trong thư viện riêng)
