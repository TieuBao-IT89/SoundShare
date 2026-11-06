# OBSIDIAN WAVE V5 — triển khai và kiểm tra

Ngày 06/11/2026. [Audit trước thay đổi và nguồn nghiên cứu](obsidian-wave-v5-audit.md). Giữ toàn bộ thay đổi recommendation đang có trong working tree; V5 không commit/push, không thay backend/API/schema, provider hoặc chính sách token.

## Kết quả theo sprint

| Sprint | File chính | Kết quả / bằng chứng |
| --- | --- | --- |
| 1 — Audit | `obsidian-wave-v5-audit.md` | Đọc source/tài liệu được yêu cầu, mở ba ảnh Clerk V3; ghi vấn đề và chọn cách tách document/hash trước triển khai |
| 2 — Auth design system | `app_theme.dart`, `authentication_header.dart`, `soundshare.css`, `obsidian-wave.svg` | Một palette NOCTURNE cập nhật theo brief; Be Vietnam Pro giữ nguyên; bìa đĩa/sóng âm SVG và CustomPainter tự viết, không dùng ảnh stock/package mới |
| 3 — Welcome | `auth.html`, `native_auth_screen.dart`, `app.dart`, ARB/generated | Editorial headline, ambient tĩnh, desktop 58/42%, mobile một cột; Web có CTA đăng nhập/tạo tài khoản; native có entry vào bộ form SDK hiện có |
| 4 — Login/Signup | `auth-page.js`, `clerk-bridge.js`, `web_auth.dart` | Embedded mount/unmount tại document riêng; mode query và hash Clerk tách khỏi GoRouter. Real Clerk SignIn/SignUp render được, chuyển qua lại/back/forward/F5 đạt; giữ Development mode và provider từ Dashboard. Ẩn tên/họ tùy chọn, không thêm public @username |
| 5 — Verification/Recovery | `auth-page.js`, `clerk-vi.js`, `soundshare.css` | Giữ nguyên component khi hash bước thay đổi; copy xác minh/khôi phục/MFA và style dùng chung. Lifecycle được unit-test. Chưa có ảnh hoặc nghiệm thu OTP/recovery/MFA thật vì chưa nhập tài khoản/mã xác minh |
| 6 — Responsive/Motion | shared AuthScaffold, scoped CSS, `auth_layout_test.dart` | Native layout 7 viewport × chữ 1×/2× đạt; form giữ state khi đổi breakpoint và tiếp cận được khi có keyboard. Chrome 21 tổ hợp form/viewport không tràn ngang, không modal. Focus 48 px, skip không chiếm hash, reduced motion được kiểm tra |
| 7 — QA/Polish | `test/web/auth_page_test.cjs`, navigation/backend bridge tests, `review-auth-v5.mjs`, tài liệu/ảnh | 197 Flutter tests, 20 Web JS tests, analyze sạch, release build đạt. Lỗi teardown DOM tìm thấy bằng Clerk thật đã sửa; ảnh Before/After là capture browser, không phải mockup |

## Cách tích hợp

1. Flutter signed-out gate nạp Clerk hiện có và chuyển sang `auth.html?mode=welcome&return=...` bằng document navigation. Signed-in gate giữ nguyên `SessionScope` và `/api/v1/auth/me` với timeout 25 giây, retry và sign-out.
2. Auth document không mount Flutter. Clerk dùng `routing:'hash'` chính thức cho verification, recovery, MFA và callback; query chọn welcome/sign-in/sign-up. Chuyển mode không reload document; thay riêng hash không remount form.
3. Chỉ khi SDK công bố session **active** mới quay về URL Flutter đã kiểm tra. Chặn return URL khác origin, auth-document loop, path ngoài app và hash không thuộc Flutter. Backend vẫn xác minh audience/issuer/signature như cũ.
4. SessionStorage chỉ chứa publishable key công khai từ build và UI intent dùng một lần (`mode`, return URL). Không nhận key từ query, không tự lưu password/OTP/token. Bookmark auth lần đầu sẽ bootstrap qua Flutter để lấy cấu hình tin cậy, rồi trở lại đúng mode/deep link; storage bị chặn hiển thị lỗi thay vì lặp redirect.
5. Clerk tự quản lý descendant DOM của mỗi container. Khi đổi mode, gọi API unmount đúng node, rồi tháo container ngoài do SoundShare tạo; không xóa children trong cây React đang teardown. Bảo toàn form khi document vào back/forward cache.

Không có nút social tự dựng; Google xuất hiện vì instance hiện bật. Không thêm Apple/Facebook, username Clerk, legal link giả hoặc CSS ẩn Development mode. Account management vẫn mở UI Clerk hiện có với màu/font chung. Profile, player và thư viện không đổi luồng nghiệp vụ.

## Kiểm tra đã chạy

| Kiểm tra | Kết quả |
| --- | --- |
| `dart format .` | 91 file; chỉ hai file QA Dart trong `build/` cần format ở lượt tổng; các file nguồn đã format riêng trước đó |
| `flutter gen-l10n` | Thành công, giữ toàn bộ chuỗi recommendation đã có |
| `flutter analyze --no-pub` | **No issues found**, gồm lượt cuối sau khi thêm tests |
| `flutter test --no-pub --reporter expanded` | **197/197 đạt**; 15 test auth layout mới và hồi quy session/profile/player/upload/recommendation |
| `node --test test/web/*.cjs` | **20/20 đạt**: mount/unmount, hash/mode, return safety, config/storage failure, bootstrap, session event và các bridge cũ |
| `node --test backend/test/web-auth.test.js` | **3/3 đạt**, gồm CSP Protect và token/session bridge không lộ identity riêng tư |
| Release Web build | Thành công trong `build/auth-v5-web`, dùng cấu hình client hiện có; không ghi đè `build/web` đang phục vụ |
| Chrome thật, SDK 6.42.2/UI 1.42.3 | **21/21** Welcome/SignIn/SignUp × 320/390/430/768/1024/1280/1440; input thật được render, Google theo Dashboard, không modal/tràn ngang/CSP violation/runtime exception trong các case này |
| Tương tác Chrome thật | SignUp → SignIn không reload document; back/forward, F5, skip focus không đổi hash, input ≥48 px, prefers-reduced-motion đạt |
| Bản Flutter release thực | Signed-out ở `/#/profile` đi vào Welcome mới và giữ return. Xóa cấu hình công khai trong **profile Chrome QA riêng**, mở bookmark Signup: Flutter nạp cấu hình rồi quay đúng Signup/deep link. Không redirect loop trong luồng kiểm tra |

Kiểm tra live Clerk chỉ tải form/cấu hình, **không nhập credential, không submit signup, không bắt đầu Google OAuth, không gửi OTP**. Không dùng browser profile của người dùng, không kết nối Neon/Cloudinary hoặc sửa tài khoản thật. Các test Node/Flutter khác dùng fixture rõ ràng; không coi fixture là nghiệm thu provider thật.

Lỗi phát hiện trong QA: unmount form rồi xóa children ngay gây `removeChild` của Clerk/React khi đổi Signup → Signin. Đã chuyển sang node mount riêng và để SDK dọn descendant; chạy lại tương tác với Clerk thật đạt. Skip anchor cũng được thay bằng focus button để không làm thay đổi hash verification.

## Before / After

[Browser report](obsidian-wave-v5/browser-report.json) gồm SHA-256 của bundle/assets cuối, 21 case, ba nhóm tương tác và các phần chưa nghiệm thu. **30 PNG thật**: 21 ảnh V5 và chín ảnh bản trước được chụp lại từ `build/web` giữ nguyên, cùng kích thước 390×844, 430×932, 1280×960. Đã xem ảnh mobile/desktop và trường hợp Signup 320 px. Form dài cuộn dọc tự nhiên; 320 px có heading xuống dòng, không che hay cắt field.

| Màn hình | Before mobile | After mobile | Before desktop | After desktop |
| --- | --- | --- | --- | --- |
| Welcome | [430 px](obsidian-wave-v5/before-welcome-430.png) | [430 px](obsidian-wave-v5/welcome-430.png) | [1280 px](obsidian-wave-v5/before-welcome-1280.png) | [1280 px](obsidian-wave-v5/welcome-1280.png) |
| Đăng nhập | [390 px](obsidian-wave-v5/before-sign-in-390.png) | [390 px](obsidian-wave-v5/sign-in-390.png) | [1280 px](obsidian-wave-v5/before-sign-in-1280.png) | [1280 px](obsidian-wave-v5/sign-in-1280.png) |
| Đăng ký | [390 px](obsidian-wave-v5/before-sign-up-390.png) | [390 px](obsidian-wave-v5/sign-up-390.png) | [1280 px](obsidian-wave-v5/before-sign-up-1280.png) | [1280 px](obsidian-wave-v5/sign-up-1280.png) |

Ảnh xác minh email chưa có: cần người dùng hoàn tất bước đăng ký bằng email do họ sở hữu để Clerk chuyển tới bước đó. Không dựng ảnh OTP giả để lấp mục nghiệm thu.

## Tái lập và chạy ứng dụng

`scripts/run-web.ps1` hiện có sẽ build toàn bộ asset mới và chạy backend như trước; không cần endpoint hoặc migration riêng cho V5. Migration 005 trong working tree thuộc tính năng recommendation trước đó, không thuộc thay đổi authentication này. Kiểm tra môi trường trước khi chạy migration; V5 không chạy migration thật.

QA opt-in dùng Node.js 22+, Chrome và `.local/web-config.json` hiện có, chỉ chứa public client configuration. Từ root:

```powershell
flutter build web --release --no-web-resources-cdn --no-wasm-dry-run --dart-define-from-file=.local/web-config.json --output=build/auth-v5-web
$env:QA_BUILT='1'
node scripts/review-auth-v5.mjs
$env:QA_INTERACTIONS='1'
$env:QA_WIDTH='390'
node scripts/review-auth-v5.mjs
Remove-Item Env:QA_BUILT,Env:QA_INTERACTIONS,Env:QA_WIDTH
```

Harness dùng Express static/CSP thật tại server cổng tạm, intercept request localhost của Chrome QA vào server đó; không gọi app/backend đang chạy ở port 3000. Clerk CDN/FAPI là thật. Raw capture và profile thuộc harness nằm trong `build/auth-v5-*`; browser/server được đóng sau mỗi lượt. `QA_BEFORE=1` chỉ dùng khi còn bản trước trong `build/web`, để chụp baseline mà không thay mã hoặc dữ liệu ứng dụng.

## Phần chưa nghiệm thu — không đánh dấu hoàn thành toàn bộ Definition of Done

- Cần người dùng chủ động nhập tài khoản/mã xác minh **trực tiếp trong UI Clerk** để kiểm tra email/password hoàn tất, OTP/resend/hết hạn, recovery, Google OAuth/cancel/error, MFA nếu instance yêu cầu, và token `/auth/me` sau redirect V5. Không cần cung cấp password/OTP trong chat. V3 từng có xác nhận tài khoản thật, nhưng không thay thế nghiệm thu mới sau thay đổi document navigation V5.
- Chưa có ảnh verification thật. Không khẳng định các bước trên đã hoạt động chỉ vì component được nhúng thành công hoặc test fixture đạt.
- Native `clerk_flutter 0.0.18-beta` chỉ export `ClerkAuthentication` có mode nội bộ; welcome dùng một CTA vào form SDK, chuyển Signup trong SDK. Không dùng private panel API, không thay bằng WebView. Đã kiểm thử wrapper/theme/layout bằng Flutter tests; chưa chạy Android/iOS, TalkBack/VoiceOver hoặc Google native thật.
- Chưa đo FPS/DevTools trên thiết bị tầm trung. Visual tĩnh, không particle/shader hoặc background animation liên tục.
- Các artifact build/QA biệt lập không tự thay bản ứng dụng đang phục vụ. Không commit, push hoặc publish trong V5.
