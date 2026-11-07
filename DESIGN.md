# SoundShare — OBSIDIAN PULSE V4

V4 giữ nền tảng NOCTURNE và toàn bộ logic V3, nâng bố cục thay vì tạo lại chức năng. [Audit và Before/After dự kiến](docs/ui/obsidian-pulse-v4-audit.md). Nền #080A12/#10121D, surface #171A29/#23283B, brand #8957F7/#6D4DD7, blue/cyan #3D8BEB/#57D6DE; chữ #F7F7FA/#AAB1C4. Primary action giữ tím đậm để chữ trắng đủ tương phản. Be Vietnam Pro và ARB giữ nguyên.

Mobile dưới 768 px dùng bottom navigation/mini player; tablet 768–1099 px dùng rail 80 px; desktop từ 1100 px dùng sidebar 224 px, topbar search/avatar/upload và playback dock. Queue mở drawer khi hẹp hoặc panel 310 px từ 1360 px. Dock/player/queue cùng AudioPlayer và progress, không tạo state phát riêng. Drawer chỉ phản ứng ở route/tab đang hiển thị và giữ trạng thái khi đổi breakpoint. Các quy tắc và chức năng V3 bên dưới tiếp tục được áp dụng trong V4.

Một tạp chí âm nhạc về những người đang sáng tạo: artwork mở đầu câu chuyện, typography dẫn đường, danh sách và hồ sơ nối người nghe với người đăng. NOCTURNE mở rộng thư viện riêng thành cộng đồng có chủ đích chia sẻ. Giữ Flutter, Riverpod, GoRouter, Clerk → Express → Neon/Cloudinary và cùng AudioPlayer. [Kiểm kê và nguồn nghiên cứu V3](docs/ui/nocturne-v3-audit.md).

## Nhận diện

| Token | Màu | Vai trò |
|---|---|---|
| Nền chính / phụ | `#080A12` / `#10121D` | Nền gần đen trung tính |
| Bề mặt / nâng | `#171A29` / `#23283B` | Input và vùng chọn |
| Electric Violet / Lavender | `#8957F7` / `#B9A6F8` | Nhận diện và điểm nhấn |
| Aurora Blue / Cyan | `#3D8BEB` / `#57D6DE` | Progress, màu phụ |
| Chữ chính / phụ | `#F7F7FA` / `#AAB1C4` | Nội dung và mô tả |
| Muted | `#8089A3` | Trang trí, không dùng làm chữ nhỏ trên surface |
| Thành công / cảnh báo / lỗi | `#40CF9A` / `#F5BA6A` / `#F47187` | Phản hồi có nhãn |

Nền trung tính không có glow mặc định. Nút chính dùng tím đậm `#6742BF` để giữ tương phản chữ trắng; gradient dành cho logo, nút phát và ambient artwork. Home có một hero ảnh lớn, các danh sách có divider, creator là hàng thông tin và tương tác, không bọc mọi nội dung trong card. Tên component Aurora/Glass được giữ để tương thích mã cũ; card mặc định nay là surface đặc không viền. Không thêm blur hoặc package animation.

Be Vietnam Pro được đóng gói tại `assets/fonts`, kèm giấy phép OFL; không cần tải font khi chạy. Các mức chữ: display 32, tiêu đề 24–28, section 20, bài hát 15–16, body 14–16, caption 12. Font native và Clerk Web dùng cùng họ chữ. Tên SoundShare không được dịch; tên bài, nghệ sĩ, thể loại và tên file do người dùng tạo được giữ nguyên.

## Bố cục và dùng chung

- Hệ khoảng cách 4/8 px; padding trang 20–24, khoảng giữa section 32; radius 12–24.
- Điện thoại dùng năm tab **Trang chủ · Khám phá · Tìm kiếm · Thư viện · Cá nhân**. `StatefulShellRoute.indexedStack` giữ nội dung và vị trí cuộn; session và player ở ngoài shell. Khi chữ lớn, nhãn có thêm chiều cao.
- Từ 768 px dùng rail 80 px, từ 1100 px sidebar 224 px; nội dung giới hạn 1560 px. Topbar có tìm kiếm, avatar và đăng nhạc. Các nhóm bài chia cột theo chiều rộng vùng nội dung, thu về một cột khi chữ lớn.
- Mini player nằm trên navigation mobile. Desktop/tablet có dock riêng; volume được giới hạn chiều cao 48 px để không giãn dock. Đang phát desktop dùng shell nhưng không lặp dock; queue dùng cùng danh sách/state, không tạo player khác. Upload là luồng riêng.
- Các thành phần chung: AuroraBackground, AuroraLogo, GlassCard, GradientButton, GradientIconButton, MysticSearchBar, LoadingSkeleton, ScreenHeading/SectionHeading, EmptyState, SongTile, SoundShareBottomNavigation, FloatingMiniPlayer, MusicProgressSlider và AuthenticationHeader.
- Không tạo Album/Playlist/Artist card không có nguồn dữ liệu. V3 có playlist lưu server và gợi ý theo thể loại đã thích rồi bài mới nhất, kèm nhãn giải thích. Bộ sưu tập demo cũ vẫn được đánh dấu mẫu.

## Màn hình

| Màn hình | Hướng thiết kế và hành vi |
|---|---|
| Khởi động | Sóng âm gradient, SoundShare, “Âm nhạc kết nối cảm xúc”; fade/scale ngắn, timer 900 ms, không chờ animation để khôi phục Clerk |
| Xác thực | Header thương hiệu và thẻ Aurora, “Chào mừng trở lại”, nút đăng nhập/tạo tài khoản; Clerk giữ form, OAuth, email/MFA và khôi phục mật khẩu |
| Trang chủ | Typography editorial, một hero artwork, tiếp tục nghe từ tiến trình thật, Dành riêng cho bạn dựa trên dữ liệu nghe/thích/lưu/follow và khung giờ, bài mới, feed theo dõi và ranking 7 ngày; chỉ hiển thị nhóm có dữ liệu |
| Khám phá / Tìm kiếm | Discovery hub có thể loại, ranking theo ngày/7/30 ngày/tất cả và các chế độ creator. Tìm cộng đồng debounce 300 ms, ưu tiên @username, tab và phân trang. Tìm thư viện riêng vẫn tại /library/search |
| Đang phát | Glow lấy sắc màu từ ảnh bìa, fallback Aurora khi ảnh lỗi/trung tính; tên bài/nghệ sĩ, yêu thích, tiến trình và thời gian từ audio thật; nút phát gradient, shuffle/repeat có trạng thái |
| Mini player | Artwork, tên bài/nghệ sĩ, phát/tạm dừng/bài tiếp và progress thật; chạm mở trình phát, giữ cùng provider/audio instance |
| Thư viện | Upload riêng, thích/lưu và playlist có lưu server; tìm thư viện riêng được giữ; không chèn mẫu vào tài khoản thật |
| Tải nhạc | MP3 20 MB/artwork 5 MB; public/private mặc định private, xác nhận quyền khi public; Web đo byte bằng XHR, hủy transport thật; khi xác nhận metadata thì chờ server, không mô phỏng thành công |
| Cá nhân | Hồ sơ SoundShare do người dùng chọn username; tên/bio/avatar/cover, follow, bài công khai và playlist. Menu “Tài khoản” ở góc phải cover của chính mình chứa Quản lý tài khoản và Đăng xuất; hàng thao tác giữ Chỉnh sửa hồ sơ, Quản lý bài hát và Chia sẻ. Không đặt nút Tải nhạc lên trong hồ sơ; thao tác này nằm ở sidebar/topbar/Thư viện. Credential vẫn do Clerk quản lý; demo giữ nhãn dữ liệu mẫu |

V3 bổ sung Home editorial, discovery/trending có cửa sổ thời gian, tìm cộng đồng, public profile, follower/following, sửa hồ sơ, playlist, queue, thích/lưu và quản lý bài. Thư viện riêng vẫn có tìm kiếm tại `/library/search`. Không thêm Cài đặt/thông báo hoặc block không có nghiệp vụ thật. Luồng chi tiết và giới hạn nghiệm thu nằm trong PRD mục V3 và báo cáo V3.

**Dành riêng cho bạn:** artwork vẫn dẫn nội dung; một dòng lý do dưới metadata giải thích thể loại đã thích/lưu, lịch sử nghe, khung giờ thường nghe hoặc creator đang theo dõi. Lý do chỉ nằm trong rail gợi ý, không nhân lên ở danh sách bài mới/feed follow. Mô tả phân biệt gợi ý cá nhân hóa và bài mới khi chưa có tín hiệu phù hợp. Không thêm nhãn “AI” hay hiệu ứng trang trí cho baseline chấm điểm. Khoảng cao dành cho lý do có tính font scaling; giữ thao tác phát và AudioPlayer hiện có. [Chi tiết](docs/personalized-recommendations.md).

## Ngôn ngữ và authentication

Giao diện mặc định `vi`, dùng Flutter localization và `lib/l10n/app_vi.arb`; generated Dart được tạo bằng `flutter gen-l10n`. `context.l10n` cung cấp copy cho widget, cùng tài nguyên cung cấp thông báo API an toàn. Không dịch metadata người dùng.

Clerk Web giữ SDK/UI hiện có, dùng bản dịch `@clerk/localizations` 4.24.6 được lưu cục bộ và bổ sung các chuỗi bảo vệ còn thiếu. Clerk native dùng adapter 165 thành viên của SDK đã cài; fallback tiếng Việt cả khi thiết bị dùng ngôn ngữ khác. Nội dung email gửi từ dịch vụ và trang OAuth bên ngoài thuộc cấu hình của nhà cung cấp.

Chỉ bắt đầu mở thư viện khi session Clerk active; Express vẫn kiểm tra đầy đủ token và quyền. Bước mở thư viện chờ tối đa 25 giây, có Đăng xuất trong lúc chờ và Thử lại khi lỗi; phản hồi muộn không tự mở thư viện. Đổi phiên giải phóng player, catalog và cache như trước. Upload chỉ báo đã lưu sau khi callback backend hoàn tất.

Trên Web, điều hướng Clerk về hash route dùng `routerPush`/`routerReplace` để giữ trang Flutter và phát sự kiện phiên active ngay sau đăng nhập. Không cần F5 để mở thư viện. URL bên ngoài, callback hoặc thay đổi document vẫn dùng điều hướng đầy đủ của Clerk.

Quản lý tài khoản mở Clerk UserProfile trên Web hoặc ClerkUserButton trên native. Hồ sơ công khai SoundShare dùng `/users/me`, do người dùng tự chỉnh và liên kết bằng `sub` server đã xác minh. Không đồng bộ email, mật khẩu hay tên Clerk đè lên hồ sơ SoundShare. Đổi tên trong cùng phiên không khởi tạo lại nguồn phát/thư viện.

## Chuyển động, tiếp cận và kiểm tra

Banner nội dung nổi bật ở Trang chủ/Khám phá tự trượt qua tối đa ba bài sau mỗi 5 giây, chuyển trong 250 ms và quay lại bài đầu sau bài cuối. Vuốt hoặc chọn chấm điều hướng bắt đầu lại chu kỳ sau khi chuyển xong. Tạm dừng tự trượt khi giữ chạm, rê chuột hoặc focus bàn phím trong banner, ứng dụng ở nền hay route/tab không hiển thị; khi quay lại chờ đủ chu kỳ mới. Không tự trượt khi chỉ có một bài, bật Reduce Motion hoặc hỗ trợ điều hướng tiếp cận; thao tác chọn thủ công vẫn hoạt động.

Chuyển động phản hồi ngắn 150–280 ms: nội dung xuất hiện nhẹ, trạng thái chọn, đổi icon, chuyển vào Player và Hero artwork. Reduce Motion bỏ Hero/chuyển cảnh, bỏ shimmer/spinner tại các giao diện mới khi phù hợp. Glow không chuyển động liên tục.

SongTile thu nhỏ 0,98 khi nhấn, nhả khi hủy hoặc bắt đầu cuộn, giữ keyboard/semantics của control bên trong. Mini Player chuyển icon trong 180 ms. Skeleton có một lớp shimmer cho cả cụm và dừng khi Reduce Motion được bật. Màu glow chỉ lấy mẫu bitmap 32×32 một lần mỗi ảnh, chuyển màu 320 ms, có timeout và giải phóng listener/tài nguyên khi đổi bài/rời màn hình; không dùng blur ảnh hay lấy mẫu mỗi frame.

Vùng chạm tối thiểu 48×48; icon có nhãn, tab có selected/tap semantics; text có thể xuống dòng, form cuộn khi có bàn phím, artwork lỗi có fallback. Kiểm thử bao phủ 320/390/430 px với chữ 2×, desktop 1280 px, loading/error/empty, tìm kiếm/bộ lọc, player/mini dùng chung tiến trình, upload lỗi/retry và session gate.

Kết quả chạy và giới hạn thiết bị được ghi riêng trong [báo cáo Mystic Aurora](docs/ui/mystic-aurora-review.md). Các báo cáo [issue #5](docs/ui/issue-5-review.md), [issue #7](docs/ui/issue-7-review.md) là lịch sử giao diện trước redesign; ảnh và palette trong các báo cáo đó không mô tả giao diện hiện tại.

## Authentication ? OBSIDIAN WAVE V5

Welcome Web d?ng visual b?a ??a/s?ng ?m SVG t? thi?t k?; headline l?ch tr?i, typography Be Vietnam Pro v? ambient t?nh. Desktop t? 1000 px chia kho?ng 58/42%, form t?i ?a 420 px; tablet/mobile m?t c?t, v?ng form cu?n t? nhi?n. Header mobile c?a form r?t g?n; kh?ng gi? hero Welcome sau form. CTA ch?nh n?i b?t, CTA t?o t?i kho?n th? c?p; kh?ng th?m li?n k?t ph?p l? ch?a c? URL th?t.

Trang static `auth.html` nh?ng Clerk b?ng mount/unmount ch?nh th?c. Mode ch?n b?ng query, hash d?nh ri?ng cho c?c b??c Clerk. M?i l?n mount c? container ri?ng ?? Clerk t? d?n DOM; kh?ng remount khi ch? ??i hash c?a OTP/recovery/MFA. Form ch? hi?n th? provider/tr??ng b?t bu?c trong Dashboard, ?n c?c tr??ng t?n/h? t?y ch?n. T?n c?ng khai SoundShare ti?p t?c ch?n sau ??ng nh?p.

Focus ring lavender, input n?n xanh ?en, l?i t?i tr??ng do Clerk qu?n l?; n?t v? input t?i thi?u 48 px. Motion 240?260 ms, action xu?t hi?n l?ch nh? theo th? t?; t?t delay/animation v?i prefers-reduced-motion. Skip control chuy?n focus b?ng JavaScript, kh?ng chi?m hash c?a Clerk. Flutter d?ng c?ng Header/BrandPanel/AuthenticationScaffold cho welcome native, loading v? l?i/session; GlobalKey gi? form khi ??i breakpoint, timeout/retry/sign-out hi?n c? gi? nguy?n.

[B?o c?o V5 v? Before/After](docs/ui/obsidian-wave-v5-review.md). OTP/OAuth/MFA v? native thi?t b? th?t c?n c?n nghi?m thu b?ng t?i kho?n/thi?t b? do ng??i d?ng ch? ??ng d?ng; kh?ng coi vi?c form render l? b?ng ch?ng ??ng nh?p ho?n t?t.
