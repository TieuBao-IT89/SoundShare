# OBSIDIAN WAVE V5 — audit trước triển khai

Đã đọc README/DESIGN/PRD, theme/widgets, các gate/session/native Clerk, bridge/CSS/localization/index, hướng dẫn dữ liệu thật và báo cáo V3; mở ba PNG Clerk V3. Thay đổi recommendation đang chưa commit được giữ nguyên. Không commit/push trong V5.

Concept: **Một bìa đĩa với đường sóng âm dẫn người nghe từ không gian khám phá tới danh tính của chính mình; typography kể câu chuyện, Clerk giữ trọn hành trình xác thực.**

## Vấn đề và thay đổi

| Hiện tại | V5 |
| --- | --- |
| Logo lớn, toàn bộ welcome căn giữa và nhiều khoảng trống | Brand lockup gọn, headline lệch trái, visual sóng âm SVG tự thiết kế |
| Card welcome còn nằm sau modal login/signup | Trang auth HTML riêng, embedded Clerk, không lớp modal hoặc welcome lồng bên dưới |
| Desktop chỉ kéo rộng cột 460 px | Split khoảng 58/42%, form giới hạn 420 px; tablet/mobile một cột |
| Input/CTA cơ bản, thiếu nhận diện chung giữa HTML và Flutter | Cùng palette NOCTURNE, Be Vietnam Pro, focus/disabled/error có tương phản |
| Loading/session gate là card giữa màn hình | Cùng AuthLayout, giữ timeout 25 giây/retry/sign-out và lỗi an toàn |

## Quyết định tích hợp

ClerkJS 6.42.2 và UI 1.42.3 hiện có giữ nguyên. [mount/unmount SignIn](https://clerk.com/docs/js-frontend/reference/components/authentication/sign-in), [SignUp](https://clerk.com/docs/js-frontend/reference/components/authentication/sign-up) và [CSS/appearance](https://clerk.com/docs/js-frontend/guides/customizing-clerk/appearance-prop/bring-your-own-css) là API chính thức. [Clerk hash routing](https://clerk.com/docs/guides/how-clerk-works/routing) dùng hash riêng cho verification/recovery; không cho nó tranh cùng hash GoRouter.

Chọn `/auth.html` được Express static hiện có phục vụ, không cần thêm endpoint/backend fallback. Trang này không khởi động Flutter. `?mode=welcome|sign-in|sign-up` chọn trang, hash dành cho các bước nội bộ Clerk; khi session active quay về URL Flutter cùng origin đã kiểm tra. Chuyển mode bằng history trong trang và unmount đúng component; F5/back/forward giữ URL của bước Clerk. Không tự xử lý OAuth/OTP/mật khẩu.

Publishable key từ build Flutter được chuyển qua sessionStorage như **cấu hình công khai**, không nhận key từ query và không lưu password/OTP/token. Trang auth mở trực tiếp khi chưa có cấu hình sẽ hướng về ứng dụng để nạp cấu hình tin cậy, giữ mode/deep link bằng UI intent dùng một lần; khi storage bị chặn sẽ hiển thị lỗi an toàn. Token, audience, authorized parties và `/auth/me` giữ nguyên. Native SDK được bọc trong layout mới, không thay bằng WebView; SDK beta không cung cấp API tương đương mount Web.

## Nguồn và nguyên tắc chọn

- [LyricAI](https://dribbble.com/shots/26586484-Login-Signup-Page-UI-Design-AI-Music-Mobile-App): nhận diện dark music, hierarchy CTA và ánh sáng violet/blue có chủ đích; không lấy artwork.
- [ultim8sports](https://dribbble.com/shots/27770458-ultim8sports-Dark-Mode-Authentication-Onboarding-Flow): focus rõ, chuyển bước nhất quán, không lặp background animation.
- [Welcome/Login Flutter](https://github.com/abuanwar072/Welcome-Login-Signup-Page-Flutter), MIT đã kiểm tra: shared layout và responsive welcome/form; không sao chép form authentication.
- [Animated Login](https://github.com/bahricanyesil/flutter-animated-login), MIT đã kiểm tra: chuyển đổi khoảng 240 ms, xử lý kích thước trước animation; không thêm package.
- [Wonderous](https://github.com/gskinnerTeam/flutter-wonderous-app), MIT đã kiểm tra: layering ảnh/typography và motion hierarchy, áp dụng vào SVG bìa đĩa và reveal ngắn.
- [Vignettes](https://github.com/gskinnerTeam/flutter_vignettes): phản hồi tương tác ngắn. LICENSE tại đường dẫn master chưa đọc được (404); không sao chép source/assets.
- [Mobbin](https://mobbin.com/) chỉ mở được trang giới thiệu; [Behance](https://www.behance.net/search/projects/music%20authentication) không truy cập được; không tuyên bố đã đọc flow riêng sau đăng nhập.
- [Apple Music](https://www.apple.com/apple-music/): headline chắc và visual âm nhạc dẫn nội dung. Spotify live không trả nội dung đọc được; SoundCloud yêu cầu JS. Chỉ dùng nguyên tắc IA từ brief cho hai nguồn bị giới hạn này.

Toàn bộ vector/style mới tự viết; không thêm dependency hoặc tài sản bên ngoài. Trước khi hoàn tất cần tests bridge/session/native-layout, Chrome viewport 320/390/430/768/1024/1280/1440 và ảnh thật. OTP/OAuth/MFA/account thật chỉ ghi nhận đạt khi được kiểm chứng, không suy ra từ UI hoặc fixture.
