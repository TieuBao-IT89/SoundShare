# NOCTURNE V3 — kết quả triển khai và kiểm tra

Ngày kiểm tra: **06/11/2026**. Nhánh: `feature/ui-mystic-aurora`, đích Pull Request: `develop`. Phạm vi gồm công việc Mystic Aurora, NOCTURNE V3 và bản sửa đăng nhập đã nghiệm thu; không sửa file secret. Các ghi chú “chưa commit/push” trong báo cáo Mystic Aurora là trạng thái tại checkpoint lịch sử trước khi người dùng yêu cầu xuất bản PR.

V3 đã được tích hợp vào Flutter và Express, không phải mockup độc lập. Bản development chạy tại `http://localhost:3000`. Dữ liệu cộng đồng được đọc từ API; fixture chỉ xuất hiện trong các bài kiểm thử và ảnh được ghi rõ bên dưới. Người dùng đã nghiệm thu trên hai tài khoản Clerk thật: lưu hồ sơ qua reload, tìm @username/follow, phát bài công khai khi chuyển tab và lượt nghe tăng. Kết quả đọc Neon/ranking xác nhận có valid play event thật; các giới hạn còn lại ghi ở cuối báo cáo.

## Kết quả theo phase

| Phase | File chính đã thay đổi | Kết quả và kiểm tra |
|---|---|---|
| 1 — Audit | `nocturne-v3-audit.md`, README/PRD/DESIGN/ARCHITECTURE/TASKS | Kiểm kê màn hình, state/router/player, schema legacy và đang dùng; nghiên cứu nguồn và giới hạn giấy phép. Không đổi framework/provider hoặc công khai bài cũ |
| 2 — Design system | `lib/app/theme/app_theme.dart`, `core/widgets/aurora_widgets.dart`, `app_scaffold.dart`, `app/app.dart`, `web/clerk-bridge.js`, `web/soundshare.css`, `lib/l10n/` | Palette NOCTURNE, nền trung tính, typography Be Vietnam Pro, navigation năm tab có state riêng. Giảm gradient/card/glow; giữ accessibility/reduced motion. Bố cục 320/390/1280 và text 2× qua widget tests |
| 3 — Home/Discovery | `community_home_screen.dart`, `discover_screen.dart`, `community_widgets.dart`; backend `community.repository.js`, `community.service.js`, `community.routes.js`, `community.controller.js` | Hero từ artwork thật; recent/resume, following, gợi ý có nhãn, bài mới và ranking 7 ngày. Discovery có period/genre/creator modes, pagination, loading/error/empty. SQL/HTTP test kiểm tra quyền đọc và cửa sổ ranking |
| 4 — Identity/Search | `community_search_screen.dart`, `public_profile_screen.dart`, `profile_editor_screen.dart`, `data/community_repository.dart`, `application/community_providers.dart`; backend `community.schema.js`, migration `004_social_music.sql` | Username lowercase/unique/reserved ở server và DB; tìm exact/prefix/contains/display name Unicode, @ ưu tiên tài khoản. Hồ sơ có route theo username và sửa avatar/cover/bio; liên kết Clerk sub không do client sửa |
| 5 — Social | `community_widgets.dart`, `public_profile_screen.dart`; repository/routes/schema ở trên | Follow/unfollow idempotent, chống self-follow và quan hệ trùng; follower/following phân trang, count/relationship lưu PostgreSQL và feed đúng người theo dõi. Chrome xác minh tìm tài khoản → mở hồ sơ → follow → reload vẫn đúng |
| 6 — Player/Library | `core/services/audio_service.dart`, `home/domain/song.dart`, `home/data/api_song_repository.dart`, `player_screen.dart`, `library_screen.dart`, `queue_screen.dart`, `playlists_screen.dart`, `explore_screen.dart` | Cùng AudioPlayer, queue thêm/bỏ/phát ngay/auto-next, progress/resume, thích/lưu/playlist lưu server. Tìm thư viện riêng giữ tại `/library/search`. Widget và Chrome kiểm tra điều hướng không dựng player thứ hai |
| 7 — Upload/Management | `upload_screen.dart`, `track_draft.dart`, `core/services/api_client.dart`, `upload_control.dart`, `upload_transport*.dart`, `web/upload-transport.js`, `manage_songs_screen.dart`; backend track schema/repository/service, `media.repository.js`, `cloudinary-storage.service.js`, `media-cleanup.service.js`, `moderation.service.js`, `scripts/moderate-report.mjs`, `server.js` | Public/private, quyền sử dụng, byte progress/hủy Web, retry metadata giữ asset ID, owner edit/delete, cleanup jobs có retry; report thật và CLI moderation. Xác minh duration thật của hai MP3 cũ bằng Cloudinary media metadata |
| 8 — QA | `test/community_test.dart`, `test/upload_control_test.dart`, `test/live_data_test.dart`, `test/web/*`, `backend/test/community*.test.js`, `test/helpers/community-fixture.js`, `cloudinary-storage.test.js`, `test-api-smoke.js`, `scripts/review-nocturne.mjs`, `scripts/v3-preflight.mjs` | Kết quả tự động bên dưới và nghiệm thu hai tài khoản thật ở cuối báo cáo; chưa thay thế nghiệm thu native hoặc tải lớn |

Migration 004 bổ sung schema thay vì tạo mô hình trùng: mở rộng `users`/`private_tracks`, tận dụng `playlists` và thêm quan hệ tới catalog hiện dùng. Đã kiểm tra từ schema rỗng bằng PostgreSQL PGlite, sau đó chạy migration runner thành công trên **Neon development**. Tại checkpoint sau migration: **3 user, 2 track, cả hai private; 0 public profile/follow**, không có dữ liệu mẫu được ghi vào Neon. Không thay đổi migration sau khi áp dụng.

## Các lệnh thực sự đã chạy

| Kiểm tra | Kết quả |
|---|---|
| `dart format` và kiểm tra format cuối | 63 file kiểm tra, không còn thay đổi format |
| `flutter analyze` | Không có issue |
| `flutter test --reporter expanded` | **122 passed** |
| `node --test test/web/*.cjs` | **12 passed** — auth navigation/account bridge và upload progress/abort/response |
| `npm test` trong backend | **59 passed, 1 skipped**; bài TCP PostgreSQL cần `TEST_DATABASE_URL` biệt lập |
| `npm run test:smoke` | **30 passed**, chỉ đọc dịch vụ development; Clerk JWKS, Cloudinary ping/duration, Neon schema/truy vấn và các route từ chối thiếu token |
| `node scripts/v3-preflight.mjs` | Development, username cũ tương thích, đủ migration 001–004, dữ liệu cũ giữ private |
| `npm run migrate` | 001–003 skipped; **004_social_music.sql success** |
| `flutter build web --release --no-web-resources-cdn --no-wasm-dry-run --dart-define-from-file=.local/web-config.json` | Build thành công; Express development đã khởi động lại với module V3 |
| `node scripts/review-nocturne.mjs` | **16 ảnh**, search/profile/follow/reload, tạo playlist bằng dialog thật, audio thật + heartbeat/valid event, không API lỗi/exception chưa xử lý trong luồng kiểm tra |
| Mở Clerk thật bằng Chrome sạch | SDK 6.42.2 ready; form đăng nhập/đăng ký mở được; không CSP failure/browser error; không nhập credential |

Các trường hợp backend được bao phủ gồm validation/username trùng, thiếu token, truy cập chéo tài khoản, không lộ private track, tìm SQL injection như literal, pagination, concurrent duplicate follow, thích/lưu, playlist ownership, ngưỡng nghe/dedupe, cửa sổ ranking, report/hide/restore, đổi visibility, delete retry và Storage cleanup failure/recovery. Dùng migrations/repository/Express thật với JWT RSA fixture và Storage giả lập; không kết nối Neon production.

Các lỗi đã tìm và sửa trong đợt QA: timer cache chưa được test harness giải phóng; callback upload gọi setState trong dispose; JS interop abort cần closure khi build Web; số bài playlist phải dùng visibility của người đăng bài; retry metadata không được upload lại asset đã xác nhận. Kiểm tra dữ liệu thật còn phát hiện duration không có trong Cloudinary response mặc định; adapter đã yêu cầu `media_metadata:true` theo [Admin API](https://cloudinary.com/documentation/admin_api), smoke xác nhận cả hai MP3 cũ có duration đọc được.

## Ảnh kiểm tra

**Nội dung có chữ “kiểm thử”, @qa.listener/@qa.creator, artwork procedural và audio tổng hợp dưới đây chỉ tồn tại trong PostgreSQL/Chrome biệt lập. Không phải dữ liệu cộng đồng thật hoặc tài khoản người dùng.** Toàn bộ request localhost của Chrome kiểm thử được chuyển đến Express test; database ứng dụng không nhận các thao tác này. [JSON kết quả](nocturne-v3/browser-report.json).

| Luồng | Điện thoại | Desktop |
|---|---|---|
| Home | [390 px](nocturne-v3/home-390.png), [320 px](nocturne-v3/home-320.png) | [1280 px](nocturne-v3/home-1280.png) |
| Discovery | [390 px](nocturne-v3/discover-390.png), [320 px](nocturne-v3/discover-320.png) | [1280 px](nocturne-v3/discover-1280.png) |
| Tìm @username | [Kết quả](nocturne-v3/username-search-390.png) | — |
| Public profile | [Hồ sơ](nocturne-v3/public-profile-390.png), [mini player](nocturne-v3/profile-mini-player-390.png) | — |
| Cá nhân | [320 px](nocturne-v3/profile-320.png) | [1280 px](nocturne-v3/profile-1280.png) |
| Player | [Đang phát](nocturne-v3/player-390.png) | — |
| Playlist | [Dialog](nocturne-v3/playlist-dialog-390.png), [đã lưu](nocturne-v3/playlist-created-390.png) | — |
| Upload | [320 px](nocturne-v3/upload-320.png) | [1280 px](nocturne-v3/upload-1280.png) |

Clerk thật, chưa đăng nhập và không nhập dữ liệu: [màn hình vào](nocturne-v3/clerk-entry.png), [đăng nhập](nocturne-v3/clerk-sign-in.png), [đăng ký](nocturne-v3/clerk-sign-up.png).

Chrome headless dùng SwiftShader để chụp. Ở lượt thay liên tục kích thước 390 → 320 → 1280 có ảnh cache bị đen; tải lại document tại mỗi viewport đã cho ảnh đúng. Chưa xác định đây là giới hạn renderer headless hay tái hiện trên GPU thật; cần kiểm tra resize Chrome có giao diện. Không coi ảnh tĩnh là bằng chứng FPS hoặc mọi chuyển động đều đạt yêu cầu.

## Nghiệm thu bằng tài khoản thật

- Người dùng đã xác nhận trên Web thật: đăng nhập, mở **Cá nhân → Tạo hồ sơ công khai**, lưu username/tên hiển thị thành công và **F5 vẫn giữ đúng hồ sơ**. Đã nghiệm thu luồng tạo/lưu hồ sơ qua reload bằng tài khoản thật.
- Người dùng đã xác nhận bằng hai tài khoản thật: tìm @username mở đúng hồ sơ, theo dõi thành công và **F5 vẫn ở trạng thái Đang theo dõi**. Sau đó **đăng xuất/đăng nhập lại thành công và vẫn Đang theo dõi**. Đã nghiệm thu tìm tài khoản/public profile và follow qua reload lẫn phiên đăng nhập mới.
- Người dùng đã xác nhận tài khoản thứ hai thấy bài công khai, phát được và **chuyển tab nhạc vẫn chạy**. Đã nghiệm thu playback xuyên tài khoản và chuyển tab trên Web thật; bài công khai do owner chủ động chọn.
- Sau khi nghe liên tục, người dùng xác nhận **lượt nghe đã tăng**. Checkpoint chỉ đọc Neon development: 1 bài public/active, 6 playback sessions, 3 phiên có tiến trình, **1 valid play event**, 1 phiên đạt ngưỡng 30.000 ms. Truy vấn ranking today/week/month/all đều trả đúng 1 bài public/active với **1 valid play**; score có thứ tự. Đã xác minh đường đi nghe thật → heartbeat → Neon → ranking → giao diện. Không sửa dữ liệu để tạo lượt nghe. Với chỉ 1 bài/event, chưa thể nghiệm thu khác biệt thứ hạng giữa nhiều bài hoặc cửa sổ thời gian bằng dữ liệu thật; các trường hợp này đã có test PostgreSQL biệt lập.

## Phần còn cần nghiệm thu / giới hạn

- Chưa chạy Android/iOS thật; máy chưa có Android SDK. Native upload có abort nhưng progress chưa xác định phần trăm. Chưa đo Flutter DevTools/FPS/large catalog trên thiết bị tầm trung.
- PGlite kiểm tra SQL/migrations thực nhưng dùng một connection được tuần tự hóa; chưa chứng minh Neon pooler/TLS, deadlock/đa kết nối hoặc nhiều Express instance. Limiter hiện nằm trong một process, cần shared store khi triển khai nhiều instance.
- Toàn bộ nội dung public trong V3 vẫn yêu cầu Clerk đã xác minh để đọc; chưa mở anonymous access hoặc anonymous plays. Username/hồ sơ cộng đồng do SoundShare quản lý, không có webhook đồng bộ hai chiều Clerk.
- Cache khám phá 1 phút ở client; ranking baseline thử nghiệm, chưa có chống bot phân tán. Ticket mở player được tách khỏi lượt nghe hợp lệ. Recent search chỉ giữ tối đa 8 mục trong phiên tài khoản.
- Upload tiếp tục service multipart qua Express hiện có, chưa chuyển sang upload intent/direct signed upload. Hủy hoặc mất response upload file có thể để lại asset private chưa gắn bài; chưa có TTL worker dọn loại orphan này. Retry asset đã xác nhận chỉ giữ trong phiên, không qua reload. Xóa track đã có receipt/outbox cleanup bền vững.
- URL media ký 5 phút có thể tiếp tục đọc đến hết hạn sau unpublish/moderation; không bảo đảm CDN thu hồi tức thời.
- Moderation hiện có report và CLI tin cậy, chưa có dashboard moderator, block account hoặc kháng nghị. Không dựng nút notification/settings/block không có hành vi.

Hướng dẫn chạy, identity/ranking và cleanup: [NOCTURNE V3](../nocturne-v3.md). API chi tiết: [PRD](../../PRD.md). Nguồn nghiên cứu và kiểm kê trước thay đổi: [audit](nocturne-v3-audit.md).
