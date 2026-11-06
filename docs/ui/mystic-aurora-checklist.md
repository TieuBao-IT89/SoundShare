# Mystic Aurora — đối chiếu yêu cầu

Đối chiếu với brief “SOUNDSHARE — COMPLETE UI/UX REDESIGN”. Đây là trạng thái mã nguồn và kiểm tra thực tế; các mục có điều kiện không được xem là tính năng backend đã có.

| Phần trong brief | Trạng thái trong source | Bằng chứng / giới hạn |
|---|---|---|
| 1. Phân tích | Đã kiểm kê Flutter/Dart, dependency, theme, routes, Riverpod, Clerk, catalog/upload/audio và màn hình | [Kiểm kê ban đầu](mystic-aurora-inventory.md) |
| 2. Design language | Màu/gradient/spacing/typography Aurora, Be Vietnam Pro local, thành phần dùng chung | `app_theme.dart`, `aurora_widgets.dart`, `assets/fonts`; tên component phù hợp kiến trúc hiện có |
| 3.1–3.4 | Splash, xác thực, Trang chủ, Khám phá đã tích hợp | Dữ liệu thật theo tài khoản; demo phải bật rõ ràng; search giữ debounce và bộ lọc URL |
| 3.5–3.6 | Full/Mini Player, glow theo ảnh, seek/progress, like, previous/next/shuffle/repeat | Dùng chung player/provider cũ; không thêm queue không hoạt động |
| 3.7–3.9 | Thư viện, Upload, Cá nhân và quản lý tài khoản Clerk | Upload chỉ thành công sau callback API; người dùng đã xác nhận mở được hồ sơ Clerk trên Web; thao tác sửa thông tin thật còn chờ nghiệm thu |
| 3.10 | Có điều kiện: chưa có màn hình Cài đặt trong ứng dụng cũ | Không tạo công tắc ngôn ngữ/theme/thông báo không có tác dụng; tiếng Việt và dark là mặc định |
| 4. Việt hóa | ARB/delegates, copy lỗi API, bản dịch Clerk Web/native | Hai nhãn branding/development của Clerk còn tiếng Anh; email và OAuth bên ngoài theo dịch vụ |
| 5. Chuyển động | Reveal, nhấn thẻ 0,98, like 180 ms, mini icon, Hero, navigation, shimmer, search results, Player transition; Reduce Motion | Glow đổi theo ảnh một lần, không animate liên tục; không thêm dependency animation |
| 6. Responsive/accessibility | Mobile/desktop, SafeArea, chữ 2×, semantic tap, keyboard, ảnh lỗi | Widget test thêm màn hình ngang 844×390 và keyboard; chưa chạy Android/iOS thật hoặc đo FPS thiết bị |
| 7. Cấu trúc | Theme/tokens/localization/shared widget tách biệt nghiệp vụ | Không đưa API/SQL vào UI, không tạo player state khác |
| 8. QA | Format/analyzer/tests và hai build Web; visual review Chrome | [Kết quả chạy và ảnh](mystic-aurora-review.md); test phụ thuộc ngoài không thay thế nghiệm thu tài khoản thật |
| 9. Quy trình | Kiểm kê và bảng thay đổi theo tám giai đoạn | [File và kết quả từng giai đoạn](mystic-aurora-inventory.md#tiến-độ-theo-giai-đoạn) |
| 10. Hoàn thành | Giao diện mới nằm trong ứng dụng đang chạy | Không commit/push; backend, dữ liệu và `.env` được giữ nguyên |

## Bổ sung trong lượt tiếp tục

- `aurora_widgets.dart`, `catalog_widgets.dart`: phản hồi nhấn không chặn tap/keyboard; hủy khi cuộn; shimmer tắt theo Reduce Motion.
- `artwork_glow.dart`, `player_screen.dart`: lấy màu từ bitmap nhỏ trong image cache; bỏ kết quả bài cũ; fallback ảnh lỗi; giải phóng timer/listener/bitmap.
- `floating_mini_player.dart`: chuyển biểu tượng theo stream phát thực tế.
- `music_progress_slider.dart`: sửa cả giới hạn thời lượng và định dạng thời gian bị bằng 0 trên JavaScript; bổ sung test VM/Chrome cho clock, thao tác tua và thời lượng dài.
- `upload_screen.dart`: kéo để đóng bàn phím, đóng bàn phím khi xem trước/gửi form.
- `account_management.dart`, Web bridge, Profile và ARB: nút quản lý tài khoản dùng SDK [Clerk UserProfile](https://clerk.com/docs/js-frontend/reference/components/user/user-profile), không tự xử lý mật khẩu.
- `session_scope.dart`: tên hiển thị được cập nhật trong cùng phiên, giữ container/client/player/catalog hiện tại.
- Test bổ sung kiểm tra gesture/keyboard, Reduce Motion, ảnh đến muộn/lỗi, tìm kiếm khi mở bàn phím, thao tác quản lý tài khoản và giữ dữ liệu khi đổi tên.

## Các việc vẫn cần môi trường hoặc nghiệm thu thực tế

- [ ] Chạy Android emulator/điện thoại sau khi có Android SDK; kiểm tra bàn phím, TalkBack, background và FPS trên thiết bị. Không dùng kết quả Chrome để đánh dấu hoàn thành mục này.
- [x] Người dùng xác nhận mở được hồ sơ Clerk từ Cá nhân → Quản lý tài khoản trên Web mới ngày 06/11/2026.
- [x] Người dùng xác nhận đăng xuất/đăng nhập lại vào thư viện ngay, không cần F5 sau đăng nhập, ngày 06/11/2026.
- [ ] Đóng cửa sổ quản lý tài khoản sau khi chỉnh sửa → kiểm tra tên mới, phát qua tab → đăng xuất bằng tài khoản development. Không gửi mật khẩu/OTP/token.
- [ ] Upload MP3/ảnh có quyền sử dụng và xác minh playback, favorite sau tải lại trang, URL hết hạn bằng tài khoản thật trên môi trường phù hợp. Đợt UI không tự tạo/xóa fixture trong Neon ứng dụng.
- [ ] Nghiệm thu các phương thức email/MFA/OAuth được bật trong Clerk; hai nhãn footer SDK và nội dung email vẫn thuộc giới hạn dịch vụ.

Playlist, lịch sử nghe, nghệ sĩ độc lập, thông báo, đề xuất cá nhân hóa và cài đặt chưa có nguồn dữ liệu/hành vi trong MVP. Brief yêu cầu chỉ dựng các phần được hỗ trợ, nên không thêm các mục này thành nội dung giả hoặc thay API để đáp ứng bố cục.
