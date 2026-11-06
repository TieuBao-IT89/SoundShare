# OBSIDIAN PULSE V4 — audit và hướng triển khai

Nhánh local `feature/ui-obsidian-pulse-v4`, bắt đầu từ mã V3 `2d372c5` đã nghiệm thu. PR V3 #17 đã merge. V4 chỉ nâng cấp presentation, giữ Flutter 3.47.4/Dart 3.13.3, Riverpod 2, GoRouter 14, Be Vietnam Pro, một AudioPlayer, Clerk và toàn bộ contract Express/Neon/Cloudinary. Không commit/push, migration hoặc sửa secret trong đợt này.

Đã mở toàn bộ 19 PNG trong `docs/ui/nocturne-v3/`, đọc browser-report và tài liệu V3. Các ảnh cộng đồng là fixture biệt lập, không phải nội dung thật. Những chỗ ảnh đen trên 320 px đã được ghi nhận ở V3, chưa coi là lỗi dữ liệu.

## Before / After dự kiến, trước khi sửa mã

| Vùng | Vấn đề quan sát được ở V3 | Thay đổi V4 cần đạt |
|---|---|---|
| Shell desktop | Sidebar có sẵn nhưng chưa có topbar; mini player giới hạn 860 px, thiếu controls desktop | Sidebar 224 px, topbar search/avatar/upload gọn; dock xuyên chiều rộng; queue panel đóng/mở khi có bài |
| Home | Heading 42 px + mô tả và hero xếp dọc đẩy CTA/nội dung khỏi viewport mobile; desktop lặp danh sách một cột | Chào ngắn, featured tối đa 3 bản thu thật, quick access, artwork rail và các nhóm bài 2–3 cột; chart có rank |
| Discover | Filter/text trước âm nhạc; mỗi bài tốn nhiều hàng; creator nằm rất sâu | Featured gọn, chart Top 3 nổi bật, row compact, creator rail, releases/genre visual/emerging từ API cũ |
| Song row | Username + like/save/menu dùng Wrap; menu đứng riêng ở 390 px | Metadata và thao tác có cột ổn định; menu luôn cùng hàng, công cụ phụ vào menu khi hẹp; giữ mọi hành vi |
| Search | Heading lớn, tab Wrap thành 2 hàng, follow nằm dưới identity | Heading gọn, tab cuộn ngang; avatar/name/@handle và follow cạnh nhau ở kích thước chữ thường; gợi ý thật khi trống |
| Profile | Không cover khi chưa upload; avatar lẻ bên trái, header/actions cao và thưa | Header có cover hoặc fallback đồ họa code-native minh bạch, avatar/identity cạnh nhau khi đủ rộng; nhóm actions và stats gọn |
| Player | Cột 520 px cả desktop; Shuffle/Repeat thành hai card lớn | Mobile controls icon; desktop artwork trái/metadata-controls phải; queue contextual, cùng player/progress |
| Library/playlist | Nhiều list cùng cấu trúc, playlist chỉ có tên và add/delete | Summary/navigation gọn, playlist có visual riêng, play all/shuffle trên dữ liệu có quyền đọc |
| Upload | Đã có 2 cột, validation/rights/progress/hủy thật | Giữ nghiệp vụ, phân cấp preview/metadata rõ, thông tin privacy và action gọn hơn |
| Empty | Minh họa lớn + văn bản chung nằm giữa vùng rất rộng | Inline empty có hướng dẫn và CTA đúng ngữ cảnh, giới hạn chiều rộng |

Concept: **Không gian nghe của những người tạo bản thu độc lập: artwork dẫn nội dung, nhịp lưới dày vừa đủ, danh tính người đăng luôn trong tầm chạm, âm nhạc nối liền mọi khu vực.** Không tăng mật độ bằng dữ liệu giả hoặc nhân đôi bài để lấp chỗ trống.

## Nghiên cứu và giới hạn nguồn

- [Zing MP3](https://zingmp3.vn/): trang công khai chuyển `restrict.html`/yêu cầu JavaScript trong công cụ đọc. Dùng định hướng IA của brief (sidebar, featured, chart, dock); không tuyên bố đã quan sát layout live hoặc gọi API/lấy nội dung Zing.
- [Spotify Play Queue](https://support.spotify.com/bb/article/play-queue/), [Now Playing](https://support.spotify.com/pt-en/article/now-playing/): phân biệt vùng đang phát và hàng đợi; áp dụng dock + panel điều khiển cùng state. Web Player live không trả nội dung đọc được.
- [TikTok For You](https://newsroom.tiktok.com/how-tiktok-recommends-videos-for-you?lang=en), [Friends/Following](https://support.tiktok.com/en/using-tiktok/exploring-videos/friends-tab): tách khám phá và quan hệ, @handle rõ; không sao chép feed video, không phát tự động nhiều audio. Trang chủ live bị giới hạn truy cập.
- [SoundCloud](https://soundcloud.com/): trang yêu cầu JavaScript; creator/track-first dùng API và public profile SoundShare đã có, không lấy artwork/nhạc bên ngoài.
- [Wonderous](https://github.com/gskinnerTeam/flutter-wonderous-app) (MIT): hierarchy ảnh và responsive composition, không sao chép source/assets.
- [Vignettes](https://github.com/gskinnerTeam/flutter_vignettes): tương tác ngắn/gesture có mục đích; license riêng chưa xác minh đầy đủ từ audit V3, không sao chép mã.
- [Flutter Shadcn](https://github.com/nank1ro/flutter-shadcn-ui) (MIT): input/tab/dialog gọn, selected/focus/disabled rõ; dùng Material hiện có.
- [Flutter Animate](https://github.com/gskinner/flutter_animate) (BSD-3-Clause): motion hierarchy, SDK AnimatedSwitcher/Container/Hero đủ; không thêm dependency.

## Các sprint

1. Audit này và ảnh baseline V3.
2. Token OBSIDIAN, typography/spacing, reusable media/creator/genre/empty components và ARB.
3. Desktop/tablet/mobile shell, topbar, player dock, queue panel.
4. Home/Discover dựa vào home/trending/creators/genres V3.
5. Search/public profile, giữ @username/follow/profile routes.
6. Now Playing/mobile mini/queue, giữ player instance và valid-play logic.
7. Library/playlist/upload, không sửa API/privacy/rights.
8. Format/analyze/tests, viewport 320/390/430/768/1024/1280/1440, ảnh before/after và báo cáo thực tế. Native/DevTools chỉ báo đã chạy khi có bằng chứng.

API không thiếu cho layout chính, nên không thay backend/schema. Chế độ lướt audio là tùy chọn và không thuộc phần bắt buộc của sprint này.
