# SoundShare

**Chia sẻ âm nhạc của bạn. Tận hưởng từng khoảnh khắc.**

SoundShare là ứng dụng Flutter mã nguồn mở giúp khám phá, phát và chia sẻ âm nhạc độc lập. Phiên bản hiện tại tập trung vào giao diện MVP và sử dụng dữ liệu mẫu trong khi các dịch vụ backend đang được chuẩn bị.

## Tính năng

- Giao diện nghe nhạc nền tối, thích ứng với màn hình, có màn hình khởi động và thanh điều hướng dưới.
- Trang chủ với gợi ý mẫu và danh sách bài hát có thể tìm kiếm.
- Trình phát nhạc hỗ trợ phát trực tuyến, tua bài, yêu thích, phát ngẫu nhiên, lặp lại và chuyển bài.
- Chọn tệp MP3 và kiểm tra giới hạn dung lượng 20 MB trên màn hình tải nhạc lên.
- Thư viện lưu lượt thích trong phiên; Profile dùng danh tính Clerk khi có phiên hoặc hiển thị trạng thái khách.

## Công nghệ

Ứng dụng hiện tại: Flutter và Dart · Riverpod · GoRouter · just_audio. Backend: Node.js + Express REST API · Neon PostgreSQL · Clerk · Cloudinary. Mã backend đã có API upload, cấp URL đọc và xóa media; Flutter chưa nối vào các API media này. Kiểm thử tự động và kiểm tra kết nối được mô tả bên dưới; chưa xác minh toàn bộ luồng media bằng phiên Clerk thật.

## Ảnh chụp màn hình

Xem [ảnh sáu màn hình và báo cáo rà soát issue #5](docs/ui/issue-5-review.md). Ảnh chụp từ Flutter Web ở kích thước điện thoại; chưa thay thế kiểm tra Android/iOS thật.

## Yêu cầu

- Flutter SDK tương thích với Dart `^3.13.3`.
- Android Studio cùng Android SDK và trình giả lập, hoặc thiết bị Android thật.
- Visual Studio Code cùng các tiện ích mở rộng Flutter và Dart.

## Chạy trên Windows

1. Cài Flutter và Android Studio, sau đó tạo và khởi động Android Emulator trong Device Manager của Android Studio.
2. Mở thư mục dự án bằng VS Code và chọn trình giả lập đang chạy trong danh sách thiết bị.
3. Mở terminal tích hợp và chạy:

   ```powershell
   flutter pub get
   flutter run
   ```

Bạn cũng có thể chạy `flutter run -d <device-id>` sau khi xem các thiết bị khả dụng bằng `flutter devices`.

## Phát triển

Ứng dụng được tổ chức theo từng tính năng trong `lib/features`; theme, dịch vụ và widget dùng chung nằm trong `lib/app` và `lib/core`. Hãy chạy các lệnh sau trước khi mở pull request:

```powershell
dart format .
flutter analyze
flutter test
```

Backend mục tiêu giao tiếp với Neon qua Express REST API; ứng dụng Flutter không kết nối trực tiếp Neon. Khi triển khai, giữ connection string và secret ở backend thông qua biến môi trường/secret manager. Không commit thông tin bí mật.

### Giao diện mobile — issue #5

Hướng thiết kế và mục tiêu cho Home, Explore, Player, Upload, Library, Profile nằm trong [DESIGN.md](DESIGN.md). Dự án dùng [Taste Skill bản Flutter](.agents/skills/design-taste-frontend/SKILL.md).

Chọn bài từ Home/Explore/Library cập nhật đúng Player; mini-player giữ bài đang chọn khi tạm dừng hoặc đổi tab. Tìm kiếm khớp tên bài, nghệ sĩ và thể loại, không phân biệt chữ hoa/thường. Nút yêu thích cập nhật Library và Profile trong phiên hiện tại; khởi động lại sẽ mất các lượt thích này.

Catalog, tên nghệ sĩ và artwork hiện dùng mẫu có sẵn; bốn bài dùng chung một URL audio demo. Upload kiểm tra MP3 tối đa 20 MB, artwork JPG/PNG/WebP tối đa 5 MB và trường bắt buộc, sau đó chỉ tạo bản xem trước trên thiết bị. File và lượt thích chưa gửi tới backend. Validation client không thay thế kiểm tra MIME/magic bytes phía server.

Kiểm thử tương tác và bố cục nằm trong `test/mobile_experience_test.dart`, giả lập audio player, catalog và file picker; không dùng tài khoản, Neon hay Cloudinary thật. Xem kết quả kiểm tra và giới hạn rà soát giao diện trong [DESIGN.md](DESIGN.md).

### Khám phá thể loại và bộ sưu tập — issue #7

Home có hai lối vào **Sample collections**: Softer corners (Dream pop/Indie folk) và After hours (Alternative/Electronic), kèm số bài trong catalog mẫu. Explore có chip thể loại lấy từ catalog và chip bộ sưu tập. Từ khóa, thể loại và bộ sưu tập kết hợp với nhau; kết quả cần khớp mọi lựa chọn.

**Clear search** chỉ xóa từ khóa; **All genres** và **All collections** bỏ nhóm tương ứng; chạm lại chip đang chọn cũng bỏ lựa chọn đó. **Clear all** xóa toàn bộ và đưa trang về đầu. Link như `/explore?collection=after-hours&genre=Electronic&q=Blue` mở đúng bộ lọc; quay lại từ Player giữ nguyên lựa chọn. Nhấn tab Explore từ tab khác mở chế độ duyệt mặc định.

Đây là cách nhóm nội dung mẫu theo thể loại, chưa có cá nhân hóa hoặc API catalog mới. Kiểm thử domain/điều hướng/trạng thái nằm trong `test/discovery_test.dart`; xem [báo cáo và ảnh rà soát](docs/ui/issue-7-review.md).

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

Cloudinary lưu asset với `type: authenticated`. Neon lưu `public_id`, URL metadata HTTPS không có chữ ký và thuộc tính file; URL đọc có chữ ký chỉ được tạo trong response với `Cache-Control: no-store`. Chủ sở hữu có thể lấy lại URL qua endpoint `/access`; asset không tồn tại hoặc thuộc người khác đều trả `404` để không lộ dữ liệu riêng tư. API này chưa tạo bài hát catalog hoặc công khai nội dung.

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

Các lỗi chính: `400 VALIDATION_ERROR` khi UUID/body/query không hợp lệ, `401 UNAUTHORIZED` khi thiếu/sai token, `404 MEDIA_NOT_FOUND` khi asset không còn hoặc không thuộc owner, `409 MEDIA_BUSY` khi cùng asset đang upload/xóa, `429 RATE_LIMITED`, `502 STORAGE_DELETE_FAILED` khi Cloudinary chưa xác nhận xóa, `503 DATABASE_UNAVAILABLE` khi Neon hoặc commit lỗi. Lỗi vẫn dùng JSON có `error.requestId`. Xóa lại UUID đã xóa hoàn tất trả `404` và không gọi Cloudinary, kể cả cùng nội dung vừa được upload lại thành asset mới.

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

Kết quả xác minh ngày **05/11/2026**: `npm test` có **47 kiểm tra đạt, 0 lỗi, 1 bỏ qua** do chưa có `TEST_DATABASE_URL`; `npm run test:smoke` có **9 kiểm tra đạt, 0 lỗi** với cấu hình development. Kết quả smoke và các giới hạn xác minh phải được đọc riêng: kết nối provider thành công hoặc HTTP `401` không chứng minh upload/xóa bằng session Clerk thật đã hoạt động. Các lệnh `curl` ở phần upload/xóa dùng cho bước kiểm tra có xác thực trên môi trường development với file do bạn có quyền sử dụng; giữ session token trong biến môi trường terminal.

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
