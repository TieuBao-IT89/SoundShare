# Điều chỉnh thao tác hồ sơ

Ngày 06/11/2026, tiếp nối bản OBSIDIAN PULSE V4.

- Bỏ nút **Tải nhạc lên** khỏi nội dung hồ sơ live và demo. Sidebar/topbar/Thư viện vẫn là các điểm đăng nhạc của ứng dụng.
- Menu **⋯ — Tài khoản** ở góc phải ảnh bìa, chỉ có trên hồ sơ của chính mình. Menu chứa **Quản lý tài khoản** và **Đăng xuất**, với Đăng xuất dùng màu cảnh báo.
- Hàng thao tác hồ sơ giữ Chỉnh sửa hồ sơ, Quản lý bài hát và Chia sẻ. Hồ sơ người khác giữ Theo dõi/Chia sẻ/Báo cáo.
- Menu và nút tài khoản cũ dùng chung launcher `openAccountManagement`; vẫn mở Clerk UserProfile trên Web hoặc giao diện Clerk native, không thay quy trình xác thực. Đăng xuất tiếp tục gọi `signOutProvider`, chặn thao tác lặp khi đang xử lý và báo lỗi tiếng Việt an toàn.

File chính: `profile_header.dart`, `profile_account_menu.dart`, `account_management.dart`, `profile_screen.dart`, `DESIGN.md`; kiểm thử menu tại `test/profile_account_menu_test.dart`.

Đã format; **34 kiểm thử Flutter liên quan đạt**, bao gồm menu 320 px/chữ 2×, desktop, loading/retry, tài khoản và luồng cộng đồng. **3 kiểm thử JavaScript Clerk account đạt**, `flutter analyze` sạch, Web release build thành công. Đã đối chiếu bundle với bản đang phục vụ tại localhost:3000.

Chrome ở 390/1280 px xác nhận menu gọi bridge quản lý tài khoản đúng một lần và đăng xuất quay về màn hình đăng nhập; không có API thất bại hoặc exception browser không bắt được. Đây là môi trường PostgreSQL/Clerk SDK fixture biệt lập, không thao tác tài khoản thật; không chạy nghiệm thu native.

| Kích thước | Hồ sơ mới | Menu tài khoản | Sau đăng xuất |
|---|---|---|---|
| 390 px | [Hồ sơ](profile-account-menu/profile-390.png) | [Menu](profile-account-menu/account-menu-390.png) | [Đăng nhập](profile-account-menu/signed-out-390.png) |
| 1280 px | [Hồ sơ](profile-account-menu/profile-1280.png) | [Menu](profile-account-menu/account-menu-1280.png) | [Đăng nhập](profile-account-menu/signed-out-1280.png) |

Nội dung và tài khoản trong ảnh là dữ liệu kiểm thử được đánh dấu rõ. Không đổi backend/API/schema/secret; không commit/push.
