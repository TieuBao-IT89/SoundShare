# SoundShare — search refresh

Một lối vào âm nhạc và người sáng tạo: ô tìm kiếm capsule rõ nét, trạng thái focus violet, bộ lọc có icon và lịch sử gọn thành chip. Dùng chung một component cho topbar, tìm cộng đồng và thư viện/demo, theo hai palette AURORA PEARL / OBSIDIAN PULSE.

## Nguồn tham khảo

- [Material 3 Search](https://m3.material.io/components/search/overview): hình dáng capsule và phân cấp thao tác trong ô nhập.
- [shadcn/ui Command](https://ui.shadcn.com/docs/components/command): keycap, thao tác bàn phím và cách tổ chức tìm kiếm gọn.
- [Music App Search — Bhavuk Thakur / Dribbble](https://dribbble.com/shots/14028793-Music-App-Search-screen-UI-UX): liên kết khu vực tìm, nội dung khám phá và lịch sử nghe/tìm. Chỉ tham khảo bố cục; dùng artwork và token sẵn có của SoundShare.

## Hành vi và mã nguồn

- `lib/core/widgets/soundshare_search_field.dart`: focus/hover, xóa, gửi truy vấn, Ctrl+K/⌘K, Esc, hỗ trợ chữ lớn và Reduce Motion. Phím tắt chỉ nhận ở route/tab đang hiển thị, kể cả sau khi cuộn khỏi ô nhập.
- `app_scaffold.dart` và `aurora_widgets.dart`: dùng component chung; topbar nhường ô nhập cho trang tìm kiếm để tránh trùng lặp.
- `community_search_screen.dart`: bộ lọc có icon, lịch sử có thể chọn lại/xóa, Enter gửi ngay truy vấn hiện tại và hủy debounce cũ khi đổi deep link.
- `music_components.dart`, `explore_screen.dart` và ARB/generated localization: style bộ lọc, giữ ô tìm kiếm và nội dung tiếng Việt. Cập nhật contract giao diện trong `DESIGN.md`.

## Ảnh widget

Ảnh do Flutter widget test render với font Be Vietnam Pro đóng gói trong ứng dụng, API và dữ liệu fixture. Đây là kiểm tra bố cục, chưa nghiệm thu thao tác trên trình duyệt hoặc thiết bị native thật.

| Bố cục | Sáng | Tối |
|---|---|---|
| Điện thoại 390 px, chữ 1× | [Ảnh](search-refresh/search-390-light.png) | [Ảnh](search-refresh/search-390-dark.png) |
| Desktop 1280 px, chữ 1× | [Ảnh](search-refresh/search-1280-light.png) | [Ảnh](search-refresh/search-1280-dark.png) |
| Điện thoại 320 px, chữ 2× | [Ảnh](search-refresh/search-320-light.png) | [Ảnh](search-refresh/search-320-dark.png) |

Trạng thái focus: [Sáng](search-refresh/search-1280-light-focused.png) · [Tối](search-refresh/search-1280-dark-focused.png).

## Kiểm tra

- Bộ kiểm thử đầy đủ: `flutter test --dart-define=CAPTURE_SEARCH_REVIEW=true` — 237 kiểm thử đạt.
- Sau rà soát ảnh và điều chỉnh cuối, chạy lại 87 kiểm thử search/accessibility/responsive/community/discovery: đạt. `flutter analyze` sạch, định dạng các file đã sửa và `git diff --check` đạt.
- `test/search_field_test.dart`: 12 kiểm thử cho đồng bộ controller/nút xóa, Enter trước debounce, lịch sử, đổi tab/deep link, shortcut sau cuộn, hai theme, màn hình hẹp và bàn phím. Các kiểm thử accessibility, community, discovery và responsive hiện có kiểm tra thêm tìm kiếm cùng player.
- Tạo lại ảnh bằng `flutter test --dart-define=CAPTURE_SEARCH_REVIEW=true test/search_field_test.dart`; kết quả ở `build/search-review/`.

Lịch sử vẫn chỉ tồn tại trong phiên. Gợi ý và kết quả dùng nguồn API hiện tại; kiểm thử không sử dụng tài khoản, Neon hoặc Cloud Storage thật.
