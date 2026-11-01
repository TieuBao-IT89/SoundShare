# SoundShare

**Chia sẻ âm nhạc của bạn. Tận hưởng từng khoảnh khắc.**

SoundShare là ứng dụng Flutter mã nguồn mở giúp khám phá, phát và chia sẻ âm nhạc độc lập. Phiên bản hiện tại tập trung vào giao diện MVP và sử dụng dữ liệu mẫu trong khi các dịch vụ backend đang được chuẩn bị.

## Tính năng

- Giao diện nghe nhạc nền tối, thích ứng với màn hình, có màn hình khởi động và thanh điều hướng dưới.
- Trang chủ với gợi ý mẫu và danh sách bài hát có thể tìm kiếm.
- Trình phát nhạc hỗ trợ phát trực tuyến, tua bài, yêu thích, phát ngẫu nhiên, lặp lại và chuyển bài.
- Chọn tệp MP3 và kiểm tra giới hạn dung lượng 20 MB trên màn hình tải nhạc lên.
- Thư viện và hồ sơ cá nhân sử dụng dữ liệu mẫu.

## Công nghệ

Ứng dụng hiện tại: Flutter và Dart · Riverpod · GoRouter · just_audio. Backend mục tiêu: Node.js + Express REST API · Neon PostgreSQL. Authentication và Cloud Storage sẽ dùng các provider độc lập, hiện chưa được chọn hoặc tích hợp.

## Ảnh chụp màn hình

Ảnh chụp sẽ được bổ sung sau khi hoàn tất các bản xem trước trên thiết bị.

## Yêu cầu

- Flutter SDK tương thích với Dart `^3.13.3`.
- Android Studio cùng Android SDK và trình giả lập, hoặc thiết bị Android thật.
- Visual Studio Code cùng các tiện ích mở rộng Flutter và Dart.

## Chạy trên Windows

1. Cài Flutter và Android Studio, sau đó tạo và khởi động Android Emulator trong Device Manager của Android Studio.
2. Mở thư mục dự án bằng VS Code và chọn trình giả lập đang chạy trong danh sách thiết bị.
3. Mở terminal tích hợp và chạy:

   ```powershell
   flutter pub get
   flutter run
   ```

Bạn cũng có thể chạy `flutter run -d <device-id>` sau khi xem các thiết bị khả dụng bằng `flutter devices`.

## Phát triển

Ứng dụng được tổ chức theo từng tính năng trong `lib/features`; theme, dịch vụ và widget dùng chung nằm trong `lib/app` và `lib/core`. Hãy chạy các lệnh sau trước khi mở pull request:

```powershell
dart format .
flutter analyze
flutter test
```

Backend mục tiêu giao tiếp với Neon qua Express REST API; ứng dụng Flutter không kết nối trực tiếp Neon. Khi triển khai, giữ connection string và secret ở backend thông qua biến môi trường/secret manager. Không commit thông tin bí mật.

## Đóng góp

Xem [CONTRIBUTING.md](CONTRIBUTING.md) để biết quy trình làm việc và hướng dẫn tạo pull request. Tất cả người đóng góp cần tuân thủ [Quy tắc ứng xử](CODE_OF_CONDUCT.md).

## Bảo mật

Vui lòng báo cáo lỗ hổng riêng tư theo hướng dẫn trong [SECURITY.md](SECURITY.md).

## Giấy phép

SoundShare được phát hành theo giấy phép MIT. Xem [LICENSE](LICENSE).
