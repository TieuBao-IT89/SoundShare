# Web: tài khoản và thư viện riêng

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

Sau đăng nhập, `/api/v1/auth/me` xác minh Bearer session token rồi tạo hồ sơ tối thiểu trong Neon theo subject. Ứng dụng chỉ mở thư viện khi backend chấp nhận phiên. Token được xin từ SDK cho từng request; gặp 401 sẽ refresh bỏ cache và retry một lần.

Upload gửi MP3 và artwork tùy chọn tới API multipart hiện có. Backend kiểm tra dung lượng, MIME, magic bytes và object Cloudinary; file dùng `type: authenticated`. Sau đó client gửi asset ID cùng title/artist/genre/description tới `POST /api/v1/songs`. UI chỉ báo Saved sau khi track commit. Các bước lỗi có thể retry; backend nhận lại cùng nội dung/metadata mà không tạo bài trùng. File đã upload nhưng chưa tạo track vẫn private; chưa có worker dọn tự động.

Library mặc định **All uploads**, có **Liked tracks**. Tìm kiếm và các filter chạy ở Express, chỉ trong thư viện của owner. Lượt thích lưu trong Neon. Playback xin URL ký mới trước khi phát; URL không được lưu vào Neon. Khi đăng xuất/đổi tài khoản, ứng dụng dừng và giải phóng player, provider container, catalog và cache ảnh.

Không có catalog công khai, playlist lưu server, chỉnh sửa/xóa track hoặc đồng bộ Clerk webhook trong phạm vi này. API xóa media từ bước trước vẫn có; trả `409 MEDIA_IN_USE` nếu file đang được track sử dụng. Upload trực tiếp bằng signed upload intent và worker đối soát là kế hoạch.

Contract đầy đủ và error code nằm trong [PRD mục 8.5](../PRD.md). Dữ liệu demo chỉ bật bằng `flutter run -d chrome --dart-define=DEMO_MODE=true`; upload demo chỉ preview và likes chỉ trong phiên.

## Xử lý lỗi đăng ký/đăng nhập

- **Action blocked / suspicious trong form Clerk:** kiểm tra Application Logs → `protect.sign_up.blocked`, tham chiếu hiển thị trên form và phiên bản `window.Clerk.version`. Clerk Protect yêu cầu ClerkJS từ 6.39. CSP phải cho phép `*.protect.clerk.com` cho script/frame và `https://*.protect.clerk.com:*` cho connect (gồm các port khác 443). Code hiện đáp ứng các yêu cầu này; proxy bên ngoài phải giữ policy tương ứng. Không dùng testing token hoặc tắt protection trong luồng thật để che lỗi. Xem [yêu cầu Protect](https://clerk.com/docs/guides/protect/getting-started) và [CSP chính thức](https://clerk.com/docs/guides/secure/best-practices/csp-headers).
- **Your session could not be verified ngoài form:** xem mã `AUTH_REJECTED` trong server log. `token-audience-missing`/`token-audience-mismatch` yêu cầu sửa claim session trong đúng instance. Kiểm tra `CLERK_AUDIENCE` và đăng nhập lại. Không giảm kiểm tra chữ ký/issuer/audience. Log chỉ chứa reason code và request ID, không chứa token hoặc claim người dùng.
- **Không tải được form:** kiểm tra CDN/Clerk bị chặn, cấu hình publishable key và kết nối mạng. Nhấn Try again. Thiếu key không tự mở demo.
- **Library trống sau đăng nhập:** đây là trạng thái tài khoản mới; tải MP3 của bạn tại Upload.
- **TRACK_ALREADY_EXISTS:** cùng MP3 đã lưu với metadata khác; phiên bản này chưa hỗ trợ sửa bài đã lưu.

Không đưa mật khẩu, OTP, token hay ảnh có credentials vào issue/PR/log.

## Kiểm tra và giới hạn nghiệm thu

```powershell
flutter analyze
flutter test
cd backend
npm test
npm run test:smoke
```

Backend tests dùng RSA fixture cho middleware Clerk, fake Neon/Cloudinary cho service và route; bao phủ token sai/hết hạn/khác owner, query injection, giới hạn trang/cursor, idempotency, khóa media và lỗi an toàn. Web regression kiểm tra bundle UI/Core 3, token refresh và CSP cho Protect. Flutter tests kiểm tra refresh một lần, phân trang, multipart, backend session gate, đổi tài khoản, lỗi upload và retry.

Integration migration/constraint test chỉ chạy nếu `TEST_DATABASE_URL` trỏ tới database test riêng, khác `DATABASE_URL`; nếu chưa có sẽ skip. Không chạy fixture/destructive test trên Neon ứng dụng hoặc production.

Trong môi trường development đã áp dụng migration 003 và kiểm tra schema bằng truy vấn chỉ đọc; smoke check kết nối Neon, Clerk JWKS và Cloudinary đã đạt. Chrome đã tải form sign-up/sign-in với ClerkJS 6.42.2, script Device Intelligence và không ghi nhận CSP violation trong lượt rà soát form. Đây chưa chứng minh đăng ký, upload, range playback hoặc expiry URL bằng tài khoản thật đã đạt. Cần hoàn tất checklist thủ công:

- [ ] Đăng ký tài khoản, xác minh email và vào được Library.
- [ ] Đăng xuất, đăng nhập lại và refresh trang giữ đúng phiên.
- [ ] Upload MP3 và artwork có quyền sử dụng; thấy bài trong All uploads.
- [ ] Phát/tua, đổi tab, tạm dừng/phát lại sau hơn 5 phút.
- [ ] Thích bài, refresh trang và thấy Liked tracks còn lưu.
- [ ] Đổi tài khoản; không thấy/nghe dữ liệu của tài khoản trước.
- [ ] Thử file sai loại/quá giới hạn; không báo lưu thành công.

Xóa fixture/tài nguyên nghiệm thu bằng công cụ quản trị phù hợp sau kiểm tra. Không công khai nội dung chỉ để thử playback.
