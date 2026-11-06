# SoundShare V3 — NOCTURNE

## Phase 1 — kiểm kê ngày 06/11/2026

Nhánh hiện tại: `feature/ui-mystic-aurora`. Giữ toàn bộ thay đổi Mystic Aurora chưa commit và bản sửa đăng nhập đã được người dùng nghiệm thu. Không checkout đè, commit hoặc push.

Flutter 3.47.4 / Dart 3.13, Riverpod 2, GoRouter 14, just_audio 0.9; font Be Vietnam Pro và ARB đã có. Không thêm thư viện chỉ để trang trí. `ARCHITECTURE.md`/`TASKS.md` còn nội dung kế hoạch cũ; mã và migrations là căn cứ thực tế.

| Màn hình/luồng | Hiện trạng | V3 |
|---|---|---|
| Splash, Clerk Web/native | Có; Web đã nghiệm thu đăng nhập không F5 | Giữ SDK, claim verification, cô lập dữ liệu phiên |
| Home | Catalog riêng, bốn bài mẫu chỉ khi DEMO_MODE | Editorial home, phát hành mới, đang theo dõi, gợi ý minh bạch |
| Explore | Tìm trong thư viện riêng, debounce/filter | Giữ tìm thư viện, thêm discovery hub và tìm cộng đồng riêng |
| Player/mini | Một AudioPlayer, seek/shuffle/repeat, glow ảnh thật | Mở nguồn cộng đồng qua cùng player; queue và tracking có xác minh thời gian |
| Library | Upload và thích của owner | Giữ; thêm playlist có lưu server |
| Upload | MP3 20 MB, artwork 5 MB, metadata private, retry idempotent | Public/private có xác nhận quyền, quản lý metadata/xóa |
| Cá nhân | Danh tính Clerk, quản lý tài khoản | Hồ sơ SoundShare riêng: username, tên, bio, avatar; public profile/follow |
| Backend | Express `/api/v1`, JWT/JWKS/audience, repository/service, rate limit | Bổ sung module community; giữ nguyên API riêng hiện có |
| Neon | 001–003: users và schema legacy; media_assets, private_tracks/favorites đang dùng | Migration 004 mở rộng users/tracks; follow, engagement, playlist_tracks và reports |

Không có bảng xếp hạng, lượt nghe, follow, username công khai hoặc playlist thật trong UI hiện tại. Bảng legacy `songs` khác `private_tracks`; không chuyển dữ liệu âm thầm giữa hai bảng. Các bài hiện có không tự công khai. Database chỉ được kiểm tra bằng truy vấn an toàn; fixture dùng database test biệt lập.

## Nghiên cứu và quyết định trước triển khai

Concept: **Một tạp chí âm nhạc về những người đang sáng tạo — artwork mở đầu câu chuyện, typography dẫn đường, danh sách và hồ sơ nối người nghe với người đăng.**

| Nguồn | Áp dụng / lý do |
|---|---|
| [Wonderous](https://github.com/gskinnerTeam/flutter-wonderous-app) | Composition thiên về ảnh, hierarchy và chuyển cảnh có vai trò; Home có một hero chính, Player dùng Hero đang có. MIT; không chép ảnh/code |
| [Flutter Vignettes](https://github.com/gskinnerTeam/flutter_vignettes) | Navigation/gesture phản hồi ngắn; chỉ dùng SDK animation cho control đang có. Chưa xác minh được file LICENSE riêng qua URL raw; không sử dụng source/assets |
| [Shadcn UI](https://github.com/nank1ro/flutter-shadcn-ui) | Input, tabs và dialog phân cấp rõ, focus/disabled state. MIT; tự triển khai bằng Material hiện có |
| [Flutter Animate](https://github.com/gskinner/flutter_animate) | Stagger nhẹ và motion hierarchy; AnimatedSwitcher/Container hiện có đủ, không thêm package. BSD-3-Clause |
| [Mobbin](https://mobbin.com/) | Tham khảo công khai cách tổ chức flow; thư viện chi tiết cần đăng nhập, không tuyên bố đã xem nội dung trả phí |
| [Dribbble: Dark Music Player](https://dribbble.com/shots/27033925-Music-Player-App-UI-Dark-Neumorphic-Concept) | Artwork làm tiêu điểm, tương phản điều khiển; bỏ neumorphism/shadow nặng, không dùng assets |
| [Behance: Music App](https://www.behance.net/gallery/193601505/Music-App-UI-Design) | Tìm thấy dự án công khai nhưng trang trả 403; không dựa vào hình ảnh chưa truy cập được |
| [SoundCloud feed](https://help.soundcloud.com/hc/en-us/articles/115003568208-Your-Feed-and-how-it-works), [Spotify recents](https://support.spotify.com/tj-en/article/recent-activity/) | Tách feed người theo dõi và lịch sử thực, duy trì queue, không lặp bài theo số follow |
| Apple Music / TikTok | Tham khảo hierarchy artwork và phân biệt display name/handle; không chép layout/branding. Trang hỗ trợ không trả nội dung đọc được trong lượt nghiên cứu |

## Kế hoạch triển khai và ranh giới

1. Token NOCTURNE, nền trung tính, giảm glass/gradient; navigation năm khu vực, giữ route cũ.
2. Migration mở rộng không xóa dữ liệu; API profile/search/follow/discover, visibility mặc định private, URL media ký sau kiểm tra quyền.
3. Public profile chỉ xuất hiện sau khi owner chọn username. SoundShare quản lý handle độc lập Clerk, liên kết bằng sub đã xác minh; không cần webhook hoặc đồng bộ credential.
4. Lượt nghe: ticket do server cấp, heartbeat theo thời gian server, giới hạn credit theo thời gian trôi qua; valid sau min(30 giây, 50% duration đã xác minh Cloudinary), dedupe user/song/30 phút. Không tính mở player là valid play; công thức ranking thử nghiệm có cùng cửa sổ thời gian cho mọi chỉ số.
5. Nối UI với API, pagination, lỗi/rỗng, cùng AudioPlayer; kiểm tra regression cũ và luồng hai tài khoản bằng fixture biệt lập. Chỉ ghi nghiệm thu thật khi có bằng chứng.

Các phase 2–7 đã được tích hợp trực tiếp vào Flutter/Express; migration 004 đã áp dụng Neon development và giữ dữ liệu cũ private. Phase 8 có kiểm thử tự động, build Web và Chrome với database biệt lập. Xem [báo cáo theo phase, file thay đổi, kết quả và giới hạn](nocturne-v3-review.md); nghiệm thu hai tài khoản thật và native vẫn còn mở.
