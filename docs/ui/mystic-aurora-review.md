# Mystic Aurora — báo cáo tích hợp

## Phạm vi

Thiết kế đã được tích hợp trực tiếp vào Flutter: design system Aurora, Be Vietnam Pro, tiếng Việt qua ARB, navigation thích ứng và toàn bộ màn hình hiện có. Xem [kiểm kê và các giai đoạn](mystic-aurora-inventory.md), [đối chiếu brief và việc còn cần nghiệm thu](mystic-aurora-checklist.md), [design system](../../DESIGN.md).

Trang chủ chỉ dùng bài/nhóm thể loại/yêu thích có dữ liệu. Thư viện, tìm kiếm, upload và player giữ provider/repository đang hoạt động. Không thêm playlist, thông báo, lịch sử nghe hay cài đặt giả; không sửa REST API, schema hoặc file môi trường thật. Thay đổi trong API client chỉ là copy lỗi tiếng Việt.

## Kiểm tra đã chạy

| Kiểm tra | Kết quả |
|---|---|
| `dart format lib test` | Đã chạy, không còn file cần format |
| `flutter gen-l10n` | Sinh tài nguyên tiếng Việt thành công |
| `flutter analyze` | Sạch |
| `flutter test` | 89/89 đạt, gồm 14 kiểm thử bổ sung cho lượt tiếp tục |
| `flutter test --platform chrome test/music_progress_test.dart` | 3/3 đạt với renderer SDK local được phục vụ vào trình duyệt test; xem ghi chú Windows bên dưới |
| `node --test test/web/*.cjs` | 9/9 đạt; gồm quản lý tài khoản và 6 hồi quy điều hướng Clerk/hash router |
| `npm test` trong backend | 56 đạt, 0 lỗi; 1 integration test bỏ qua do chưa có database test riêng |
| Release Web demo | Build bản cuối thành công với `DEMO_MODE=true`, tách khỏi bản tài khoản thật |
| Release Web tài khoản thật | Build bản cuối thành công, giữ cấu hình công khai hiện có; Express phục vụ tại `http://localhost:3000` |
| Chrome với dữ liệu demo | Lượt đầu 33 ảnh ở 320×640, 390×844, 1280×900; lượt tiếp tục thêm 22 ảnh ở 390/1280 và 7 ảnh kiểm tra player cuối; không có JavaScript exception |
| Playback trên Web release | Âm thanh tổng hợp 20 giây trong trình duyệt QA: media thực sự phát, tạm dừng, tua bằng pointer tới 14,53 giây, đồng hồ/progress đồng bộ; thích và thu nhỏ thành công; 0 exception/CSP violation |
| Clerk Web qua Express | Mở form đăng nhập/đăng ký tiếng Việt tại 430×932; ClerkJS 6.42.2 ready, Protect tải được, không có lỗi trình duyệt hoặc CSP violation |

Các kiểm thử bao phủ chọn bài đúng index, phát/tạm dừng qua tab không tải lại nguồn, tiến trình/seek dùng chung giữa mini và full player, shuffle/repeat, yêu thích, tìm kiếm và filter kết hợp/đường dẫn, retry, lỗi mạng và ảnh lỗi, MP3 sai loại/quá giới hạn, upload không báo thành công trước callback API, session timeout/refresh/đổi tài khoản, semantic tap và keyboard.

Bố cục được kiểm tra ở 320/390/430 px với cỡ chữ 2× và desktop 1280 px. Test Reduce Motion xác nhận bỏ animation của Hero/loading thích hợp. Adapter Clerk native được kiểm tra chọn tiếng Việt dù thiết bị dùng locale khác, giữ thông tin người nhận và không hiển thị JWT hoặc dữ liệu lỗi thô.

Lượt tiếp tục bổ sung: thẻ nhấn 0,98 giữ tap/keyboard và hủy khi cuộn; Mini Player đổi icon 180 ms; shimmer tắt khi Reduce Motion. Glow lấy màu từ mẫu 32×32 của ảnh cache, có fallback, timeout và giải phóng listener/bitmap; bỏ ảnh của bài cũ đến muộn. Keyboard test bao phủ 320×640, 390×844 và ngang 844×390 với chữ 2× trong khi player vẫn giữ nguồn; form tải nhạc hỗ trợ kéo để đóng bàn phím.

Nút quản lý tài khoản dùng [Clerk UserProfile trên Web](https://clerk.com/docs/js-frontend/reference/components/user/user-profile) và ClerkUserButton công khai của SDK native. Test kiểm tra mở một lần, lỗi an toàn, và cập nhật tên cùng phiên giữ nguyên provider container, API client và dữ liệu thích. Người dùng đã xác nhận mở được hồ sơ Clerk trên bản Web mới ngày 06/11/2026; chưa tuyên bố đã chỉnh sửa thông tin tài khoản thật.

Sửa lỗi đăng nhập còn ở màn hình chào mừng đến khi F5: bridge Web bổ sung `routerPush`/`routerReplace` cho hash route, để Clerk không đánh dấu nhầm cùng document là đang tải lại và bỏ sự kiện active. Chrome release trong profile QA riêng tái hiện bản cũ với 0 request `/auth/me`; bản sửa đăng nhập → thư viện → đăng xuất → đăng ký/đăng nhập lại có 2 request xác minh và 2 request catalog, chỉ 1 document load, 0 exception. Phiên Clerk và các GET API trong phép kiểm tra này được giả lập theo hợp đồng navigation Core 3; không dùng tài khoản thật hoặc ghi Neon. Ngày 06/11/2026, người dùng đã xác nhận đăng xuất rồi đăng nhập lại bằng tài khoản thật và vào thư viện ngay, không F5 sau đăng nhập.

Rà soát Chrome phát hiện `1 << 53` thành `0` khi biên dịch JavaScript: slider bị vô hiệu hóa và đồng hồ luôn `0:00` dù audio đang chạy. Đã thay cả hai giới hạn trong `music_progress_slider.dart` bằng số nguyên thập phân an toàn. Ba test chạy trên VM và Chrome kiểm tra thời lượng 20 giây, đồng hồ, nhấn để tua, thời lượng âm và thời lượng dài hơn 32 bit. Audio service giữ nguyên.

Runner `flutter test --platform chrome` trên Windows hiện trả `404` cho URL CanvasKit do xử lý đường dẫn. Lượt test Chrome được chạy bằng cách cấp đúng file CanvasKit có sẵn trong Flutter SDK vào **trình duyệt test riêng** qua CDP, rồi tải lại iframe test. Cả ba test sau đó đạt; không sửa Flutter SDK. Đây là workaround cho runner, không cần cho bản Web release được Express phục vụ.

## Ảnh giao diện

Ảnh dùng **chế độ demo được bật rõ ràng**, không phải dữ liệu riêng của tài khoản. Tên bài/nghệ sĩ mẫu được giữ nguyên. Các thao tác phát, tạm dừng, thích và thu nhỏ được thử qua nút giao diện trên Chrome; phép kiểm tra nguồn phát dùng chung được xác nhận thêm bằng fake player trong widget test.

Ảnh Player/Mini Player điện thoại dùng âm thanh tổng hợp 20 giây do QA tạo, thay response audio chỉ trong trình duyệt thử riêng qua CDP. Metadata và artwork vẫn là demo. Media element xác nhận phát tới hơn 2 giây; sau nhấn thanh tua, vị trí đạt 14,53 giây và UI hiển thị `0:14 / 0:20`. Fixture không được thêm vào ứng dụng, Cloudinary hoặc Neon. Nguồn MP3 demo bên ngoài đã lỗi tải ở một lượt trên điện thoại; [ảnh Mini Player khi lỗi mạng](mystic-aurora/mini-player-network-error-mobile.png) lưu trạng thái phục hồi này. Việc dùng fixture không xác minh độ sẵn sàng của nguồn nhạc bên ngoài hay playback tài khoản thật.

| Màn hình | Điện thoại | Desktop |
|---|---|---|
| Trang chủ | [Ảnh](mystic-aurora/home-mobile.png) | [Ảnh](mystic-aurora/home-desktop.png) |
| Khám phá | [Ảnh](mystic-aurora/explore-mobile.png) | [Ảnh](mystic-aurora/explore-desktop.png) |
| Đang phát | [Ảnh](mystic-aurora/player-mobile.png) | [Ảnh](mystic-aurora/player-desktop.png) |
| Mini player | [Ảnh](mystic-aurora/mini-player-mobile.png) | — |
| Thư viện | [Ảnh](mystic-aurora/library-mobile.png) | — |
| Tải nhạc lên | [Ảnh](mystic-aurora/upload-mobile.png) | [Ảnh](mystic-aurora/upload-desktop.png) |
| Cá nhân | [Ảnh](mystic-aurora/profile-mobile.png) | — |

Xác thực thật trên bản Web: [màn hình vào](mystic-aurora/auth-entry.png), [form đăng nhập](mystic-aurora/sign-in.png), [form đăng ký](mystic-aurora/sign-up.png). Chỉ mở form bằng trình duyệt sạch, không nhập mật khẩu/OTP hoặc chụp dữ liệu tài khoản.

Sau lượt ảnh đầu, đã sửa tiêu đề AppBar tải nhạc bị tối, sidebar desktop thiếu chiều cao và tăng tương phản của nhãn/counter; chụp lại 12 khung hình bị ảnh hưởng. Lượt tiếp tục thêm glow/chuyển động, quản lý tài khoản và sửa đồng hồ/thanh tua Web; ảnh player cuối đã được xem lại sau thao tác tua thật. Có 15 ảnh đại diện được lưu trong thư mục báo cáo; cả hai bản build cuối đã hoàn tất sau sửa lỗi.

## Giới hạn xác minh

- `flutter doctor` cho biết máy chưa có Android SDK. Chưa build APK, chạy emulator Android/iOS hoặc đo FPS trên điện thoại thật; kết quả bố cục ở trên là widget test và Chrome.
- Clerk giữ toàn bộ credential/session/OTP/OAuth; bản dịch Web và native không thay đổi cơ chế xác minh. Nội dung email và trang OAuth bên ngoài thuộc cấu hình dịch vụ. Kiểm tra form trên Chrome không thay thế nghiệm thu lại email/MFA và mọi nhà cung cấp OAuth bằng tài khoản thật.
- Hai nhãn footer “Secured by Clerk” và “Development mode” của thành phần Clerk hiện vẫn do SDK hiển thị bằng tiếng Anh; không dùng CSS/DOM hack để che branding hoặc giả trạng thái production. Các trường, nút và thông báo xác thực đã dùng bản dịch tiếng Việt.
- Backend tests dùng phụ thuộc giả lập; không chạy fixture lên Neon ứng dụng hoặc production. Đợt UI này không tạo/xóa dữ liệu thật để thử upload/playback/expiry.
- Glow đã lấy màu ảnh bằng bitmap nhỏ; ảnh trung tính, lỗi, URL hết hạn hoặc không cho đọc pixel dùng fallback Aurora. Upload hiển thị xử lý không xác định phần trăm vì service hiện tại không cung cấp byte progress.

Toàn bộ thay đổi đang ở workspace trên nhánh `feature/ui-mystic-aurora`. Không commit hoặc push theo yêu cầu.
