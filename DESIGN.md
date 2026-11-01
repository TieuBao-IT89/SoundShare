# Định hướng thiết kế SoundShare

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
- **Trang chủ:** lời chào, bản phối nổi bật, nhạc vừa chia sẻ và gợi ý khám phá.
- **Khám phá:** ô tìm kiếm theo tên bài hát hoặc nghệ sĩ, kết quả và trạng thái không có kết quả.
- **Trình phát:** bìa lớn, thông tin bài hát, tiến trình, thời gian, phát/tạm dừng, chuyển bài, yêu thích, phát ngẫu nhiên và lặp lại.
- **Tải nhạc lên:** chọn MP3, kiểm tra dung lượng, điền thông tin bài hát và chọn ảnh bìa.
- **Thư viện:** bài hát đã tải lên, bài yêu thích và danh sách phát cá nhân.
- **Hồ sơ:** ảnh đại diện, tên, tiểu sử và thống kê người theo dõi.

## Chuyển động và khả năng tiếp cận

- Chỉ dùng chuyển động ngắn, mượt để phản hồi thao tác hoặc chuyển màn hình; tránh hiệu ứng gây xao nhãng.
- Duy trì độ tương phản đủ rõ, không chỉ dùng màu sắc để biểu thị trạng thái và cung cấp nhãn cho các nút biểu tượng.
- Tôn trọng cài đặt giảm chuyển động của hệ điều hành khi bổ sung các hoạt ảnh phức tạp.

## Nguyên tắc triển khai

- Tổ chức mã theo tính năng trong `lib/features`; tách giao diện, nghiệp vụ, dữ liệu và repository.
- Dùng Riverpod cho trạng thái, GoRouter cho điều hướng và widget dùng chung cho các mẫu giao diện lặp lại.
- Bản MVP dùng dữ liệu mẫu và phát một nguồn âm thanh mẫu. Tích hợp Supabase Auth, PostgreSQL và Storage sẽ được thực hiện ở giai đoạn sau.
- Không đưa khóa API, thông tin đăng nhập hoặc dữ liệu nhạy cảm vào mã nguồn.
