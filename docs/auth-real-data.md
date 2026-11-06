# Web: tài khoản và thư viện riêng

**Cập nhật V5:** Web dùng trang `auth.html` và Clerk embedded thay modal; Flutter giữ gate `/auth/me`. [Hướng dẫn và QA OBSIDIAN WAVE](ui/obsidian-wave-v5-review.md) mô tả hash routing, public config bootstrap, các form thật đã kiểm tra và những bước OTP/OAuth/MFA còn cần tài khoản. Các mục nghiệm thu cũ bên dưới là lịch sử, không tự xác nhận luồng mới.

Phạm vi là Chrome, đăng ký/đăng nhập Clerk và MP3/artwork do chính chủ tài khoản tải lên. Mặc định không seed bài mẫu. Đăng ký, xác minh email, quên mật khẩu, OAuth và duy trì phiên do UI/SDK Clerk xử lý. Express không nhận mật khẩu.

## Cấu hình và chạy

1. Chạy `flutter pub get` tại gốc và `npm ci` tại `backend/`.
2. Tạo `backend/.env` từ file example. Dùng Neon, Cloudinary và Clerk development; không đưa database URL/secret vào Flutter.
3. Trong **đúng instance Development** của Clerk, mở **Sessions → Customize session token**. Thêm claim ở cấp ngoài cùng, giữ các claim hiện có:

   ```json
   { "aud": "soundshare-api" }
   ```

   Đây là session token mặc định, không phải user metadata hay JWT template riêng. Backend `CLERK_AUDIENCE` phải khớp chính xác giá trị này. Sau khi lưu, đăng xuất/đăng nhập để nhận token mới. Xem [hướng dẫn Clerk](https://clerk.com/docs/guides/sessions/customize-session-tokens).
4. Đặt `CLERK_AUTHORIZED_PARTIES=http://localhost:3000` tại backend cho bản web cùng origin. Production cấu hình origin HTTPS tương ứng và dùng instance/secret riêng.
5. Tại `backend/`, chạy `npm run migrate`. Migration 003 thêm track/favorite riêng, giữ các bảng cũ. Nếu lỗi, kiểm tra runner; không tạo bảng thủ công.
6. Tại gốc, chạy `.\scripts\run-web.ps1`. Có thể truyền `-FlutterExecutable 'C:\path\flutter\bin\flutter.bat'`. Mở `http://localhost:3000`.

Script tạo `.local/web-config.json` chỉ có `CLERK_PUBLISHABLE_KEY`, `API_BASE_URL`, `DEMO_MODE=false`; file đã gitignore. Backend phục vụ duy nhất `build/web` khi `SERVE_FLUTTER_WEB=true`. Khi chạy API riêng, bỏ cờ này. Không phục vụ thư mục gốc hoặc `backend/.env` qua web server.

Web dùng `@clerk/clerk-js@6.42.2` cùng `@clerk/ui@1.42.3`, tải từ CDN. Cập nhật hai bundle cùng nhau và kiểm tra lại form/Protect sau nâng cấp. Native giữ SDK Flutter hiện có; chưa nghiệm thu native với dữ liệu thật.

## Luồng dữ liệu

Client chờ Clerk có session `active` trước khi gọi `/api/v1/auth/me`. Endpoint này xác minh Bearer session token rồi tạo hồ sơ tối thiểu trong Neon theo subject. Ứng dụng chỉ mở thư viện khi backend chấp nhận phiên. Token được xin từ SDK cho từng request; gặp 401 sẽ refresh bỏ cache và retry một lần. Sự kiện thay session của cùng một tài khoản cũng tạo lại vùng dữ liệu phiên để xác minh lại.

Clerk Web được nối với hash router Flutter qua `routerPush` và `routerReplace`. Chuyển trong cùng document dùng điều hướng hash của trình duyệt, kể cả khi đích đang là URL hiện tại; không đánh dấu tải lại trang. Các URL khác vẫn chuyển qua `windowNavigate` của Clerk, giữ luồng OAuth/callback. Xem [cấu hình điều hướng Clerk](https://clerk.com/docs/js-frontend/reference/objects/clerk).

Bước mở thư viện chờ tối đa 25 giây, tính cả lấy token và retry. Khi quá hạn, UI hiển thị lỗi cùng Try again/Sign out; Sign out cũng có trong lúc chờ. Phản hồi đến muộn không tự mở thư viện sau khi UI đã báo timeout.

Hồ sơ Neon chỉ gồm `id` và `clerk_user_id` ở bước này; email, username và display name chưa được đồng bộ từ Clerk. Đăng ký thành công ở Clerk chưa tạo hồ sơ Neon cho tới khi `/auth/me` trả `200`. Không có webhook đồng bộ nền. Upload tạo metadata ở `media_assets`, lưu bài tạo bản ghi ở `private_tracks`; bảng `songs` cũ không được dùng cho thư viện riêng.

Upload gửi MP3 và artwork tùy chọn tới API multipart hiện có. Backend kiểm tra dung lượng, MIME, magic bytes và object Cloudinary; file dùng `type: authenticated`. Sau đó client gửi asset ID cùng title/artist/genre/description tới `POST /api/v1/songs`. UI chỉ báo Saved sau khi track commit. Các bước lỗi có thể retry; backend nhận lại cùng nội dung/metadata mà không tạo bài trùng. File đã upload nhưng chưa tạo track vẫn private; chưa có worker dọn tự động.

Library mặc định **All uploads**, có **Liked tracks**. Tìm kiếm và các filter chạy ở Express, chỉ trong thư viện của owner. Lượt thích lưu trong Neon. Playback xin URL ký mới trước khi phát; URL không được lưu vào Neon. Khi đăng xuất/đổi tài khoản, ứng dụng dừng và giải phóng player, provider container, catalog và cache ảnh.

Trong giao diện Mystic Aurora, các nhãn tương ứng là **Thư viện → Nhạc đã tải lên**, **Yêu thích**, **Tải nhạc lên**, **Thử lại** và **Đăng xuất**. UI mặc định tiếng Việt qua ARB; Clerk Web và native cũng có bản dịch, giữ nguyên phiên và các quy trình xác thực. Những thông báo tiếng Anh bên dưới mô tả các lượt chẩn đoán trước redesign; mã lỗi HTTP vẫn giữ nguyên.

Không có catalog công khai, playlist lưu server, chỉnh sửa/xóa track hoặc đồng bộ Clerk webhook trong phạm vi này. API xóa media từ bước trước vẫn có; trả `409 MEDIA_IN_USE` nếu file đang được track sử dụng. Upload trực tiếp bằng signed upload intent và worker đối soát là kế hoạch.

Contract đầy đủ và error code nằm trong [PRD mục 8.5](../PRD.md). Dữ liệu demo chỉ bật bằng `flutter run -d chrome --dart-define=DEMO_MODE=true`; upload demo chỉ preview và likes chỉ trong phiên.

## Xử lý lỗi đăng ký/đăng nhập

- **Action blocked / suspicious trong form Clerk:** kiểm tra Application Logs → `protect.sign_up.blocked`, tham chiếu hiển thị trên form và phiên bản `window.Clerk.version`. Clerk Protect yêu cầu ClerkJS từ 6.39. CSP phải cho phép `*.protect.clerk.com` cho script/frame và `https://*.protect.clerk.com:*` cho connect (gồm các port khác 443). Code hiện đáp ứng các yêu cầu này; proxy bên ngoài phải giữ policy tương ứng. Không dùng testing token hoặc tắt protection trong luồng thật để che lỗi. Xem [yêu cầu Protect](https://clerk.com/docs/guides/protect/getting-started) và [CSP chính thức](https://clerk.com/docs/guides/secure/best-practices/csp-headers).
- **Your session could not be verified ngoài form:** xem mã `AUTH_REJECTED` trong server log. `token-audience-missing`/`token-audience-mismatch` yêu cầu sửa claim session trong đúng instance. Kiểm tra `CLERK_AUDIENCE` và đăng nhập lại. Không giảm kiểm tra chữ ký/issuer/audience. Log chỉ chứa reason code và request ID, không chứa token hoặc claim người dùng.
- **Đăng nhập đóng form nhưng vẫn hiện chào mừng, F5 mới vào được:** bản cũ dùng điều hướng mặc định Clerk về `/#/`. ClerkJS 6.42.2 đánh dấu navigation này là unloading trước khi biết đó chỉ là đổi hash, nên bỏ lần công bố session active. Bản sửa đăng ký cả hai router callback để hoàn tất kích hoạt phiên trong trang Flutter. Tải lại một lần để nhận bundle mới, sau đó kiểm tra đăng xuất/đăng nhập mà không F5; không thay claim hoặc chạy migration để xử lý lỗi điều hướng này.
- **Không thấy cập nhật trên Neon:** nếu `/api/v1/auth/me` trả `401`, backend chưa thực hiện lệnh tạo hồ sơ. Kiểm tra claim trước; chạy lại migration không sửa được lỗi này. Nếu trả `503 DATABASE_UNAVAILABLE`, kiểm tra kết nối và quyền ghi của backend. Sau khi `/auth/me` trả `200`, kiểm tra `users`; sau upload kiểm tra `media_assets` và `private_tracks`. Không kỳ vọng email/mật khẩu xuất hiện trong Neon.
- **Opening your library took too long:** kiểm tra Express đang chạy tại đúng API URL rồi Try again. Client chờ session active và tự cập nhật nếu session sẵn sàng sau sự kiện user; không cần refresh liên tục để vượt bước khởi tạo.
- **Không tải được form:** kiểm tra CDN/Clerk bị chặn, cấu hình publishable key và kết nối mạng. Nhấn Try again. Thiếu key không tự mở demo.
- **Library trống sau đăng nhập:** đây là trạng thái tài khoản mới; tải MP3 của bạn tại Upload.
- **TRACK_ALREADY_EXISTS:** cùng MP3 đã lưu với metadata khác; phiên bản này chưa hỗ trợ sửa bài đã lưu.

Không đưa mật khẩu, OTP, token hay ảnh có credentials vào issue/PR/log.

## Kiểm tra và giới hạn nghiệm thu

```powershell
flutter analyze
flutter test
node --test test/web/*.cjs
cd backend
npm test
npm run test:smoke
```

Backend tests dùng RSA fixture cho middleware Clerk, fake Neon/Cloudinary cho service và route; bao phủ token sai/hết hạn/khác owner, query injection, giới hạn trang/cursor, idempotency, khóa media và lỗi an toàn. Test đăng nhập kiểm tra token thiếu audience không gọi ghi hồ sơ, token hợp lệ tạo hồ sơ và retry giữ cùng ID. Web regression kiểm tra bundle UI/Core 3, session active/thay session, sự kiện trước lúc subscribe, token refresh và CSP cho Protect. Flutter tests kiểm tra refresh một lần, phân trang, multipart, backend session gate, timeout/đăng xuất/thử lại và phản hồi muộn, đổi tài khoản, lỗi upload và retry.

Integration migration/constraint test chỉ chạy nếu `TEST_DATABASE_URL` trỏ tới database test riêng, khác `DATABASE_URL`; nếu chưa có sẽ skip. Không chạy fixture/destructive test trên Neon ứng dụng hoặc production.

Trong môi trường development đã áp dụng migration 003 và kiểm tra schema bằng truy vấn chỉ đọc; smoke check kết nối Neon, Clerk JWKS và Cloudinary đã đạt. Chrome đã tải form sign-up/sign-in với ClerkJS 6.42.2, script Device Intelligence và không ghi nhận CSP violation trong lượt rà soát form.

Chẩn đoán ngày 05/11/2026: `/auth/me` ban đầu trả `401 token-audience-missing` vì ô Claims trên Clerk vẫn là `{}`. Sau khi người dùng lưu `{"aud":"soundshare-api"}` và thử lại, endpoint trả `200` và người dùng xác nhận vào trang chính. Upload audio/artwork và tạo bài trả `201`; truy vấn chỉ đọc Neon xác nhận `users=1`, `media_assets=2`, `private_tracks=1`. Đây là dữ liệu do người dùng tự tải, không phải fixture test. Chưa nghiệm thu playback, range/expiry, favorite, xóa hoặc tài khoản thứ hai.

Checklist thủ công:

- [x] Đăng nhập bằng tài khoản thật và vào trang chính sau khi cấu hình đúng audience.
- [x] Ngày 06/11/2026: người dùng xác nhận đăng xuất/đăng nhập lại vào thư viện ngay, không cần F5 sau đăng nhập, sau bản sửa điều hướng Clerk/hash router.
- [x] Backend tạo hồ sơ Neon và lưu MP3/artwork cùng metadata bài hát; đối chiếu bằng truy vấn chỉ đọc.
- [ ] Đăng ký tài khoản, xác minh email và vào được Thư viện.
- [ ] Đăng xuất, đăng nhập lại và refresh trang giữ đúng phiên.
- [ ] Vào Cá nhân → Quản lý tài khoản, mở/đóng giao diện Clerk; đổi tên và kiểm tra nguồn phát/thư viện được giữ nguyên.
- [ ] Upload MP3 và artwork có quyền sử dụng; thấy bài trong Nhạc đã tải lên.
- [ ] Phát/tua, đổi tab, tạm dừng/phát lại sau hơn 5 phút.
- [ ] Thích bài, refresh trang và thấy Yêu thích còn lưu.
- [ ] Đổi tài khoản; không thấy/nghe dữ liệu của tài khoản trước.
- [ ] Thử file sai loại/quá giới hạn; không báo lưu thành công.

Xóa fixture/tài nguyên nghiệm thu bằng công cụ quản trị phù hợp sau kiểm tra. Không công khai nội dung chỉ để thử playback.
