# Định hướng thiết kế SoundShare

Luồng tài khoản/dữ liệu thật: trên Web, màn hình vào ứng dụng là cửa vào thư viện riêng, với đăng nhập và đăng ký Clerk rõ ràng; form xác minh/khôi phục do Clerk xử lý. Không tự chuyển sang dữ liệu mẫu khi cấu hình hoặc backend lỗi. Home/Explore/Library hiển thị bài của tài khoản, Upload xác nhận đã lưu sau khi Storage và Neon hoàn tất, Profile có đăng xuất. Trạng thái chưa có bài dẫn tới Upload; các bộ sưu tập chỉ là nhóm theo thể loại, không phải gợi ý cá nhân hóa. Chế độ demo phục vụ review/test phải được bật rõ ràng.

## Mục tiêu

SoundShare là nơi nghệ sĩ độc lập chia sẻ âm nhạc và người nghe khám phá những giai điệu mới. Giao diện cần hiện đại, dễ dùng trên điện thoại và có bản sắc riêng, không sao chép trực tiếp dịch vụ nghe nhạc nào khác.

## Nhận diện trực quan

- **Phong cách:** tối giản, ấm áp và giàu cảm xúc; ưu tiên bìa album và nội dung âm nhạc.
- **Nền chính:** than đen `#0D0D12`.
- **Bề mặt:** `#17171F`; bề mặt nâng `#22222D`.
- **Màu nhấn:** tím điện `#9B7BFF` cho hành động chính và trạng thái đang chọn.
- **Màu bổ trợ:** xanh bạc hà `#B8F28B` dùng có chọn lọc để tạo điểm nhấn.
- **Văn bản phụ:** xám dịu `#92919E`; văn bản chính có độ tương phản cao trên nền tối.
- **Chữ:** dùng Roboto hiện có trong hệ thống; tiêu đề có trọng lượng rõ ràng, nội dung dễ đọc.
- **Hình ảnh:** bìa album bo góc; ảnh mẫu hiện tại chỉ dùng để dựng giao diện và cần được thay bằng ảnh có quyền sử dụng phù hợp khi phát hành.

## Bố cục và thành phần

- Dùng lề ngang nhất quán, nhóm nội dung theo khoảng cách rõ ràng và bo góc mềm cho thẻ, ô nhập liệu, nút.
- Các thành phần dùng lại như bìa nhạc, thanh điều hướng, mini player và màu sắc cần được đặt trong thư mục dùng chung hoặc design system.
- Hỗ trợ nhiều kích thước màn hình điện thoại; nội dung dài cần cuộn được và không tràn khỏi màn hình.
- Thanh điều hướng dưới gồm Trang chủ, Khám phá, Thư viện và Hồ sơ. Màn hình phát nhạc và tải nhạc lên được mở theo luồng riêng.
- Trạng thái tải, rỗng, lỗi và thành công cần có thông báo dễ hiểu; điều khiển quan trọng phải có vùng chạm đủ lớn.

## Màn hình

- **Khởi động:** biểu tượng sóng âm, tên SoundShare, khẩu hiệu và hiệu ứng xuất hiện nhẹ.
- **Trang chủ:** một bài mẫu nổi bật, các bài mẫu khác và lối vào Upload.
- **Khám phá:** ô tìm kiếm theo tên bài hát hoặc nghệ sĩ, kết quả và trạng thái không có kết quả.
- **Trình phát:** bìa lớn, thông tin bài hát, tiến trình, thời gian, phát/tạm dừng, chuyển bài, yêu thích, phát ngẫu nhiên và lặp lại.
- **Tải nhạc lên:** chọn MP3, kiểm tra dung lượng, điền thông tin bài hát và chọn ảnh bìa.
- **Thư viện:** chế độ thật mặc định All uploads và có Liked tracks lưu theo tài khoản; chế độ demo giữ catalog mẫu và lượt thích trong phiên. Playlist chưa được triển khai.
- **Hồ sơ:** danh tính Clerk khi có phiên hoặc trạng thái khách; tính năng chỉnh sửa và thống kê xã hội chưa được triển khai.

## Chuyển động và khả năng tiếp cận

- Chỉ dùng chuyển động ngắn, mượt để phản hồi thao tác hoặc chuyển màn hình; tránh hiệu ứng gây xao nhãng.
- Duy trì độ tương phản đủ rõ, không chỉ dùng màu sắc để biểu thị trạng thái và cung cấp nhãn cho các nút biểu tượng.
- Tôn trọng cài đặt giảm chuyển động của hệ điều hành khi bổ sung các hoạt ảnh phức tạp.

## Nguyên tắc triển khai

- Tổ chức mã theo tính năng trong `lib/features`; tách giao diện, nghiệp vụ, dữ liệu và repository.
- Dùng Riverpod cho trạng thái, GoRouter cho điều hướng và widget dùng chung cho các mẫu giao diện lặp lại.
- Chế độ thật dùng Clerk và Express/Neon/Cloudinary, chỉ hiển thị dữ liệu riêng của tài khoản. Dữ liệu mẫu và audio demo chỉ tồn tại trong `DEMO_MODE=true`. Upload chỉ báo Saved sau khi backend xác nhận file và metadata; không hiển thị như đã xuất bản công khai.
- Không đưa khóa API, thông tin đăng nhập hoặc dữ liệu nhạy cảm vào mã nguồn.

## Hướng thiết kế cho issue #5

Giữ bảng màu và Roboto hiện có. Ý tưởng chung là một phòng nghe cho nhạc độc lập: artwork mở đầu câu chuyện, tên bài/nghệ sĩ rõ ràng và mỗi màn hình có một hành động chính. Không thêm gradient trang trí, số liệu xã hội giả hoặc dependency phục vụ riêng việc làm đẹp.

| Màn hình | Mục tiêu người dùng | Ý tưởng và thứ bậc nội dung |
|---|---|---|
| Home | Tìm một bài để nghe và mở Player | Một lựa chọn nổi bật như trang giới thiệu nghệ sĩ trong phòng nghe, tiếp theo là các bài mẫu khác; lối vào Upload gọn trong header. |
| Explore | Tìm đúng bài/nghệ sĩ/thể loại | Kệ đĩa có ô tìm kiếm rõ ràng và danh sách dễ quét; kết quả rỗng có hành động xóa bộ lọc. |
| Player | Nghe liên tục và điều khiển bài đã chọn | Một bìa nhạc làm tâm điểm; play/pause và chuyển bài ở hàng chính, shuffle/repeat/like ở hàng phụ để vừa điện thoại hẹp. |
| Upload | Chuẩn bị MP3, thông tin và ảnh bìa | Quy trình ngắn theo ba phần file, thông tin, artwork; validation ngay cạnh nội dung, kết quả chỉ xác nhận bản xem trước trên thiết bị. |
| Library | Quay lại những bài vừa thích | Kệ nghe cá nhân với lượt thích lưu trong phiên; phân biệt rõ phần mẫu và trạng thái thư viện chưa có bài. |
| Profile | Hiểu trạng thái tài khoản và không gian cá nhân | Danh tính có thật khi Clerk cung cấp, trạng thái khách khi chưa cấu hình; không dùng tên, follower hay upload count giả để mô phỏng tài khoản. |

Quy tắc mobile: nội dung cuộn được khi mở bàn phím hoặc tăng cỡ chữ; vùng chạm tối thiểu 48 logical pixels; trạng thái chọn có nhãn và semantics; ảnh lỗi có fallback. Chỉ thêm trạng thái loading/error ở nơi thực sự lấy dữ liệu bất đồng bộ, không tạo trạng thái upload server giả. Mini-player tiếp tục hiện khi tạm dừng và các màn hình dùng chung lựa chọn bài/lượt thích trong phiên. Các thành phần mới không dùng animation trang trí; chỉ báo tiến trình cần tôn trọng reduced motion.

Kết quả kiểm tra 05/11/2026: 30 widget test đạt, analyzer sạch và build Flutter Web thành công. Đã xem ảnh cả sáu màn hình ở 320×640, 390×844 và 430×932; bố cục ở cỡ chữ gấp đôi được kiểm tra bằng widget test. Xem [báo cáo, ảnh và giới hạn xác minh](docs/ui/issue-5-review.md). Chưa kiểm tra bằng Android/iOS emulator hoặc thiết bị thật; catalog, audio demo, lượt thích trong phiên và Upload local preview vẫn tách rõ khỏi năng lực backend thực tế.

## Khám phá theo thể loại và bộ sưu tập — issue #7

- Home giúp người nghe bắt đầu mà chưa cần từ khóa: giữ bài nổi bật, rồi giới thiệu hai bộ sưu tập mẫu như hai lối đi trong phòng nghe. Mỗi lối có artwork hiện có, mô tả và số bài thực tế trong catalog mẫu.
- Explore là kệ đĩa có nhãn: tìm kiếm, thể loại và bộ sưu tập kết hợp để thu hẹp kết quả. Chip có dấu chọn và semantics; nút Clear all đưa cả từ khóa và bộ lọc về trạng thái duyệt mặc định. Clear search chỉ xóa từ khóa; All genres/All collections chỉ bỏ nhóm tương ứng.
- Hai chủ đề mẫu là Softer corners (Dream pop/Indie folk) và After hours (Alternative/Electronic). Nhãn Sample collections giải thích đây là cách nhóm mẫu theo thể loại, không phải đề xuất cá nhân hóa hay kết quả từ lịch sử nghe.
- Bộ lọc nằm trong query của route Explore để mở từ Home/link và quay lại từ Player giữ đúng lựa chọn. Kết quả dùng index của catalog gốc để tiếp tục phát đúng bài. Mỗi trạng thái tải, lỗi, catalog trống, bộ sưu tập không có bài và không khớp bộ lọc có thông báo riêng; luôn có cách bỏ lựa chọn đang dùng.
- Giữ palette, Roboto và artwork hiện tại; chip được Wrap, thẻ nội dung cao linh hoạt và toàn màn hình cuộn khi dùng điện thoại hẹp/cỡ chữ lớn.

Kiểm tra issue #7: 49 test đạt, analyzer sạch và build web release thành công. Đã rà soát Home/Explore ở 320×640, 390×844, 430×932 bằng ảnh Flutter Web; widget test bao phủ cỡ chữ 2× và thể loại dài. Heading có action tự xuống dòng ở màn hình hẹp/chữ lớn; Clear all đưa trang về đầu, còn sửa từ khóa không tự đóng bàn phím. Xem [báo cáo, ảnh và giới hạn xác minh](docs/ui/issue-7-review.md).

## Web dùng tài khoản và dữ liệu thật

Màn hình vào ứng dụng dùng thông điệp “Your sound. Your space.” với hai hành động Đăng nhập/Tạo tài khoản, nối tới form Clerk cùng palette charcoal/tím. ClerkJS Core 3 dùng biến màu foreground/input hiện hành; input và nút chính có chiều cao tối thiểu 48 px. Form cuộn ở màn hình hẹp. Đã xem entry, sign-up và sign-in tại 430×932 trên Chrome, xác nhận ClerkJS 6.42.2 tải Device Intelligence và không có CSP violation trong lượt mở form.

Sau backend session gate, Home/Explore/Library hiển thị thư viện riêng; tài khoản mới có lời mời Upload thay vì bài giả. Library mặc định All uploads. Upload phân biệt đang gửi, lỗi/retry và Saved; Profile dùng tên từ Clerk và có Đăng xuất. Mỗi tài khoản có provider container riêng để dọn player, catalog và cache khi đổi phiên. Demo giữ nhãn nội dung mẫu và hành vi preview cũ.

Luồng mở thư viện chờ session Clerk active, nhận cả sự kiện thay session của cùng người dùng và giới hạn xác minh backend ở 25 giây. Trong lúc chờ có nhãn tiến trình và Sign out; khi timeout/lỗi có Try again và Sign out. Các trạng thái này cuộn được trên màn hình hẹp hoặc chữ lớn. Phản hồi muộn không tự thay trạng thái lỗi thành thư viện đã mở.

Kiểm tra tự động: 57 Flutter test đạt, analyzer sạch, Web release build thành công. Widget test bao phủ loading/timeout/retry ở 320×640 và chữ 2×. Tài khoản thật đã đăng nhập, upload MP3/artwork và lưu bài vào Neon development; playback, yêu thích, đăng ký mới và native vẫn cần nghiệm thu. Xem [checklist và giới hạn](docs/auth-real-data.md).
