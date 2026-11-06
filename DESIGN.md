# SoundShare — NOCTURNE · Mystic Aurora 2.0

Một tạp chí âm nhạc về những người đang sáng tạo: artwork mở đầu câu chuyện, typography dẫn đường, danh sách và hồ sơ nối người nghe với người đăng. NOCTURNE mở rộng thư viện riêng thành cộng đồng có chủ đích chia sẻ. Giữ Flutter, Riverpod, GoRouter, Clerk → Express → Neon/Cloudinary và cùng AudioPlayer. [Kiểm kê và nguồn nghiên cứu V3](docs/ui/nocturne-v3-audit.md).

## Nhận diện

| Token | Màu | Vai trò |
|---|---|---|
| Nền chính / phụ | `#090A10` / `#11131D` | Nền gần đen trung tính |
| Bề mặt / nâng | `#161823` / `#1B1D29` | Input và vùng chọn |
| Electric Violet / Lavender | `#8957F7` / `#B9A6F8` | Nhận diện và điểm nhấn |
| Aurora Blue / Cyan | `#3D8BEB` / `#57D6DE` | Progress, màu phụ |
| Chữ chính / phụ | `#F7F7FA` / `#9B9EAE` | Nội dung và mô tả |
| Muted | `#737A98` | Trang trí, không dùng làm chữ nhỏ trên surface |
| Thành công / cảnh báo / lỗi | `#40CF9A` / `#F5BA6A` / `#F47187` | Phản hồi có nhãn |

Nền trung tính không có glow mặc định. Nút chính dùng tím đậm `#6742BF` để giữ tương phản chữ trắng; gradient dành cho logo, nút phát và ambient artwork. Home có một hero ảnh lớn, các danh sách có divider, creator là hàng thông tin và tương tác, không bọc mọi nội dung trong card. Tên component Aurora/Glass được giữ để tương thích mã cũ; card mặc định nay là surface đặc không viền. Không thêm blur hoặc package animation.

Be Vietnam Pro được đóng gói tại `assets/fonts`, kèm giấy phép OFL; không cần tải font khi chạy. Các mức chữ: display 32, tiêu đề 24–28, section 20, bài hát 15–16, body 14–16, caption 12. Font native và Clerk Web dùng cùng họ chữ. Tên SoundShare không được dịch; tên bài, nghệ sĩ, thể loại và tên file do người dùng tạo được giữ nguyên.

## Bố cục và dùng chung

- Hệ khoảng cách 4/8 px; padding trang 20–24, khoảng giữa section 32; radius 12–24.
- Điện thoại dùng năm tab **Trang chủ · Khám phá · Tìm kiếm · Thư viện · Cá nhân**. `StatefulShellRoute.indexedStack` giữ nội dung và vị trí cuộn; session và player ở ngoài shell. Khi chữ lớn, nhãn có thêm chiều cao.
- Từ 900 px dùng thanh bên 240 px và nội dung giới hạn 1180 px; form, banner và nhóm nội dung chia cột theo chiều rộng có sẵn. Không kéo giãn bố cục điện thoại ra toàn desktop.
- Mini player nằm trong vùng layout riêng phía trên navigation, hoặc cuối vùng nội dung desktop. Không đè lên danh sách. Upload và Đang phát là luồng riêng.
- Các thành phần chung: AuroraBackground, AuroraLogo, GlassCard, GradientButton, GradientIconButton, MysticSearchBar, LoadingSkeleton, ScreenHeading/SectionHeading, EmptyState, SongTile, SoundShareBottomNavigation, FloatingMiniPlayer, MusicProgressSlider và AuthenticationHeader.
- Không tạo Album/Playlist/Artist card không có nguồn dữ liệu. V3 có playlist lưu server và gợi ý theo thể loại đã thích rồi bài mới nhất, kèm nhãn giải thích. Bộ sưu tập demo cũ vẫn được đánh dấu mẫu.

## Màn hình

| Màn hình | Hướng thiết kế và hành vi |
|---|---|
| Khởi động | Sóng âm gradient, SoundShare, “Âm nhạc kết nối cảm xúc”; fade/scale ngắn, timer 900 ms, không chờ animation để khôi phục Clerk |
| Xác thực | Header thương hiệu và thẻ Aurora, “Chào mừng trở lại”, nút đăng nhập/tạo tài khoản; Clerk giữ form, OAuth, email/MFA và khôi phục mật khẩu |
| Trang chủ | Typography editorial, một hero artwork, tiếp tục nghe từ tiến trình thật, gợi ý minh bạch, bài mới, feed theo dõi và ranking 7 ngày; chỉ hiển thị nhóm có dữ liệu |
| Khám phá / Tìm kiếm | Discovery hub có thể loại, ranking theo ngày/7/30 ngày/tất cả và các chế độ creator. Tìm cộng đồng debounce 300 ms, ưu tiên @username, tab và phân trang. Tìm thư viện riêng vẫn tại /library/search |
| Đang phát | Glow lấy sắc màu từ ảnh bìa, fallback Aurora khi ảnh lỗi/trung tính; tên bài/nghệ sĩ, yêu thích, tiến trình và thời gian từ audio thật; nút phát gradient, shuffle/repeat có trạng thái |
| Mini player | Artwork, tên bài/nghệ sĩ, phát/tạm dừng/bài tiếp và progress thật; chạm mở trình phát, giữ cùng provider/audio instance |
| Thư viện | Upload riêng, thích/lưu và playlist có lưu server; tìm thư viện riêng được giữ; không chèn mẫu vào tài khoản thật |
| Tải nhạc | MP3 20 MB/artwork 5 MB; public/private mặc định private, xác nhận quyền khi public; Web đo byte bằng XHR, hủy transport thật; khi xác nhận metadata thì chờ server, không mô phỏng thành công |
| Cá nhân | Hồ sơ SoundShare do người dùng chọn username; tên/bio/avatar/cover, follow, bài công khai và playlist; quản lý credential bằng Clerk; demo giữ nhãn dữ liệu mẫu |

V3 bổ sung Home editorial, discovery/trending có cửa sổ thời gian, tìm cộng đồng, public profile, follower/following, sửa hồ sơ, playlist, queue, thích/lưu và quản lý bài. Thư viện riêng vẫn có tìm kiếm tại `/library/search`. Không thêm Cài đặt/thông báo hoặc block không có nghiệp vụ thật. Luồng chi tiết và giới hạn nghiệm thu nằm trong PRD mục V3 và báo cáo V3.

## Ngôn ngữ và authentication

Giao diện mặc định `vi`, dùng Flutter localization và `lib/l10n/app_vi.arb`; generated Dart được tạo bằng `flutter gen-l10n`. `context.l10n` cung cấp copy cho widget, cùng tài nguyên cung cấp thông báo API an toàn. Không dịch metadata người dùng.

Clerk Web giữ SDK/UI hiện có, dùng bản dịch `@clerk/localizations` 4.24.6 được lưu cục bộ và bổ sung các chuỗi bảo vệ còn thiếu. Clerk native dùng adapter 165 thành viên của SDK đã cài; fallback tiếng Việt cả khi thiết bị dùng ngôn ngữ khác. Nội dung email gửi từ dịch vụ và trang OAuth bên ngoài thuộc cấu hình của nhà cung cấp.

Chỉ bắt đầu mở thư viện khi session Clerk active; Express vẫn kiểm tra đầy đủ token và quyền. Bước mở thư viện chờ tối đa 25 giây, có Đăng xuất trong lúc chờ và Thử lại khi lỗi; phản hồi muộn không tự mở thư viện. Đổi phiên giải phóng player, catalog và cache như trước. Upload chỉ báo đã lưu sau khi callback backend hoàn tất.

Trên Web, điều hướng Clerk về hash route dùng `routerPush`/`routerReplace` để giữ trang Flutter và phát sự kiện phiên active ngay sau đăng nhập. Không cần F5 để mở thư viện. URL bên ngoài, callback hoặc thay đổi document vẫn dùng điều hướng đầy đủ của Clerk.

Quản lý tài khoản mở Clerk UserProfile trên Web hoặc ClerkUserButton trên native. Hồ sơ công khai SoundShare dùng `/users/me`, do người dùng tự chỉnh và liên kết bằng `sub` server đã xác minh. Không đồng bộ email, mật khẩu hay tên Clerk đè lên hồ sơ SoundShare. Đổi tên trong cùng phiên không khởi tạo lại nguồn phát/thư viện.

## Chuyển động, tiếp cận và kiểm tra

Chuyển động phản hồi ngắn 150–280 ms: nội dung xuất hiện nhẹ, trạng thái chọn, đổi icon, chuyển vào Player và Hero artwork. Reduce Motion bỏ Hero/chuyển cảnh, bỏ shimmer/spinner tại các giao diện mới khi phù hợp. Glow không chuyển động liên tục.

SongTile thu nhỏ 0,98 khi nhấn, nhả khi hủy hoặc bắt đầu cuộn, giữ keyboard/semantics của control bên trong. Mini Player chuyển icon trong 180 ms. Skeleton có một lớp shimmer cho cả cụm và dừng khi Reduce Motion được bật. Màu glow chỉ lấy mẫu bitmap 32×32 một lần mỗi ảnh, chuyển màu 320 ms, có timeout và giải phóng listener/tài nguyên khi đổi bài/rời màn hình; không dùng blur ảnh hay lấy mẫu mỗi frame.

Vùng chạm tối thiểu 48×48; icon có nhãn, tab có selected/tap semantics; text có thể xuống dòng, form cuộn khi có bàn phím, artwork lỗi có fallback. Kiểm thử bao phủ 320/390/430 px với chữ 2×, desktop 1280 px, loading/error/empty, tìm kiếm/bộ lọc, player/mini dùng chung tiến trình, upload lỗi/retry và session gate.

Kết quả chạy và giới hạn thiết bị được ghi riêng trong [báo cáo Mystic Aurora](docs/ui/mystic-aurora-review.md). Các báo cáo [issue #5](docs/ui/issue-5-review.md), [issue #7](docs/ui/issue-7-review.md) là lịch sử giao diện trước redesign; ảnh và palette trong các báo cáo đó không mô tả giao diện hiện tại.
