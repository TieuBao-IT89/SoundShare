# SoundShare V9 — Social music

## Khắc phục môi trường development — 2026-11-08

Bình luận, Shorts và thông báo cùng lỗi vì database đang chạy chỉ có migration 001–004, thiếu toàn bộ bảng V9; unit/integration test biệt lập trước đó không phát hiện trạng thái triển khai này. Đã xác minh `NODE_ENV=development`, đối chiếu schema đang hoạt động và áp dụng migration additive 005–006 bằng runner hiện có. Không thay visibility, identity hay nội dung cũ; không tạo tài khoản/bình luận/thông báo mẫu trên database này.

Backend được khởi động lại; health trả 200 và Web phục vụ đúng bundle mới được build với cấu hình client công khai. Có thể tải lại `http://localhost:3000` bằng Ctrl+F5. Thông báo được sinh từ tương tác mới sau khi outbox được cài đặt.

Các sửa bổ sung:

- `schema-readiness.js`, `check-schema.js`, `npm run db:check`: kiểm tra read-only migration và bảng trước startup. `run-web.ps1` kiểm tra trước build, server từ chối khởi động nếu thiếu schema; không tự migration khi start.
- Shorts nằm trong khu vực Khám phá, shortcut cùng nhóm trên Home và sidebar desktop. Bỏ nút đứng riêng dưới lời chào. Ảnh review fixture có font thật: `.local/v9-shorts-entry-discovery.png`.
- Feed/comments/inbox hiển thị lý do lỗi và retry; badge lỗi không bị trình bày thành 0 thông báo. Comments/inbox ít nội dung vẫn kéo để refresh được.
- Inbox trang đầu tự đọc lại mỗi 30 giây khi đang hiển thị, không nhấp nháy loading. Dừng khi bị route khác che/background/dispose; lỗi backoff tối đa 5 phút, không thay trang cursor người dùng đang xem.
- `test-api-smoke.js` bổ sung schema V9, read queries và kiểm tra Bearer trên các route mới. Smoke không ghi dữ liệu ứng dụng.

Kiểm tra: **316 Flutter passed; 83 backend passed, 1 skipped; 25 Web passed; 39 smoke passed trên cấu hình development Neon/Clerk/Cloudinary; analyze sạch; build Web thành công**. Vẫn chưa nghiệm thu đăng bình luận và nhận thông báo bằng phiên Clerk của người dùng trong browser hoặc trên Android; smoke kiểm tra truy vấn thật và ranh giới auth, các mutation được kiểm tra trong database biệt lập. Không commit/push.

## Audit trước triển khai

Đã đối chiếu `origin/develop` và giữ nguyên thay đổi V7 chưa commit. Không có V8 trong source hiện tại.

| Thành phần | Phân loại | Bằng chứng / hướng xử lý |
| --- | --- | --- |
| Clerk → users, Express `/api/v1`, PostgreSQL | Tái sử dụng | middleware xác minh Clerk; community repository ánh xạ subject phía server |
| Public/private, moderation, playback ticket, valid plays | Tái sử dụng | `community.repository.js`: PUBLIC/ACCESS, playback_sessions, ngưỡng 30 giây hoặc nửa bài, dedupe 30 phút |
| Like/save/follow, public profile, playlist | Mở rộng | API và provider cộng đồng hiện có; cần đồng bộ optimistic state |
| Recommendation | Mở rộng | `taste-v1` xếp hạng affinity, giảm lặp creator; snapshot thứ tự cho Shorts |
| Audio player | Tái sử dụng | một `audioPlayerProvider`, `PlaybackActions`, bridge V7; cần lease khôi phục context preview |
| Session/cache | Tái sử dụng | ProviderContainer riêng theo Clerk user/session, dispose khi đổi tài khoản |
| Shorts / cursor snapshot | Chưa có | cần API metadata, PageView lazy, không tự phát lần đầu |
| Comment/reply/like/report | Chưa có | migration mới; mở rộng hệ thống moderation hiện có |
| Persistent notifications/preferences/outbox | Chưa có | migration mới, delivery theo batch có retry; polling có lifecycle |
| Android MediaSession trên thiết bị | Chưa kiểm chứng | source V7 và test Dart có; máy hiện thiếu Android SDK |
| Neon/Cloudinary/Clerk V9 thực tế | Chưa kiểm chứng | chỉ test database biệt lập; không chạy migration production |

## Hướng thiết kế

Một bản thu độc lập chiếm một trang Shorts: artwork là điểm nhìn chính, tên creator và tương tác đặt quanh ảnh, điều khiển nghe thử ở đáy; giữ Aurora Pearl/Obsidian Pulse và Be Vietnam Pro. Comments và inbox dùng các hàng nội dung rõ ràng, trạng thái tải/rỗng/lỗi, không dựng số liệu giả.

## Chính sách phát

Shorts dùng player V7. Lần vào đầu tiên chờ người dùng nhấn phát. Chuyển trang dừng preview trước; autoplay sau thao tác đầu chỉ khi người dùng bật. Đóng sheet không tự resume. Rời Shorts khôi phục queue/index/position/mode cũ ở trạng thái tạm dừng; chọn “Nghe toàn bộ” nhận queue mới và bỏ quyền khôi phục. Mất foreground hoặc bị route khác che thì pause. Không phát ngầm preview và không tính swipe/impression là lượt nghe.

## Kiến trúc và schema

Flutter → Express REST xác minh Clerk → PostgreSQL. V9 thêm social routes → controller dùng chung → social service → social repository. Recommendation, Storage, profile và các social endpoint cũ được tái sử dụng. Không có kết nối Neon trực tiếp hoặc provider authentication mới trong Flutter.

Migration **006_social_discovery.sql** chạy sau 001–005 bằng migration runner hiện có:

| Bảng / thay đổi | Ràng buộc và index |
| --- | --- |
| `track_comments` | UUID, track/user FK, composite parent/track FK, content 1–1000, active/hidden/deleted, timestamps; index track/parent/user theo thời gian |
| `comment_likes` | PK comment/user, FK cascade |
| `content_reports.comment_id` | Đúng một target track/profile/comment, unique reporter/comment; CLI moderation hiện có hỗ trợ comment |
| `notifications` | Recipient/actor/type/track/comment/event_key/read_at/created_at; unique recipient/event, cấm self notification, index recipient/page và unread |
| `notification_preferences` | PK user, 5 nhóm boolean mặc định bật |
| `social_outbox` | Event key unique, cursor fanout, attempts/available_at/completed_at, index jobs chưa hoàn tất |
| `shorts_snapshots` | Owner/mode/track IDs, tối đa 200 IDs, TTL 30 phút, tối đa 5 snapshot/user trong luồng tạo |
| `track_likes_by_track` | Index tổng hợp lượt thích theo track |

Không sửa migration cũ, không đổi visibility hoặc identity của dữ liệu cũ. Migration được kiểm thử trên PGlite biệt lập và sau đó đã áp dụng 005–006 vào Neon development trong đợt khắc phục nêu trên.

## Shorts và playback

- For You dùng candidate/ranking `taste-v1`: valid history, liked/saved genre, following, freshness, diversity creator. Trending dùng ranking tuần. Following chỉ lấy creator đang theo dõi và kiểm tra lại follow trên từng trang.
- Cursor chứa snapshot/position; server xác minh owner, mode và TTL. Thứ tự ID cố định trong snapshot nên ranking đổi không làm lặp trang. Track private/hidden/deleted bị lọc lại khi đọc. Bài mới xuất hiện khi refresh. Snapshot hết hạn trả `410 FEED_EXPIRED`; thử lại làm mới feed.
- Backend tối đa 30 DTO/request; Flutter lấy 10/lần, giữ cửa sổ tối đa 50 DTO và bỏ 20 trang cũ khi tiến xa. PageView lazy; không tải toàn bộ catalog, không prefetch audio ticket. Có nút chuyển trang hỗ trợ bàn phím/a11y; chữ lớn/chiều cao hạn chế cho phép cuộn nội dung trang.
- Preview từ 0, tối đa 30 giây và cắt theo duration thực nếu ngắn hơn. AudioPlayer và PlaybackActions V7 duy nhất; không transcode/reupload. Lần đầu chờ nhấn phát; menu tùy chọn có autoplay khi vuốt và auto-next, mặc định tắt. Mất focus, noisy event, background, route khác hoặc comments sheet đều pause, không tự resume.
- Lease giữ queue/index/position/mode cũ, khôi phục ở trạng thái pause. Stop/đổi session/chọn bài từ nơi khác thu hồi lease; phản hồi muộn không lấy lại quyền phát. “Nghe toàn bộ” giữ bài mới khi rời Shorts.
- Dùng lại playback ticket và heartbeat server. Swipe/impression/rebuild không ghi valid play. Ngưỡng nghe và dedupe V3 giữ nguyên; preview kết thúc gửi heartbeat qua cùng đường có khóa chống gửi chồng.

## API contract V9

Tất cả dưới `/api/v1`, Bearer Clerk bắt buộc, `Cache-Control: no-store`; validation strict UUID/body/query/enum/cursor. Identity/recipient lấy phía server. Success và lỗi dùng envelope/middleware hiện có, không trả SQL/stack/token/signed audio URL.

| Method / path | Input | Kết quả |
| --- | --- | --- |
| GET `/shorts/feed` | mode=for-you/following/trending, limit 1–30, cursor? | 200 `{items,nextCursor}`; Song + uploader/avatar, liked/saved/following, likeCount/commentCount, previewStartMs=0/previewDurationMs |
| GET `/shorts/songs/:id` | UUID | 200 public/active Song hoặc 404, dùng mở link |
| GET `/community/songs/:id/comments` | limit/cursor/parentId? | 200 `{items,nextCursor,total}`; root hoặc replies, total chỉ tính nội dung khả dụng |
| GET `/community/comments/:id` | UUID | 200 `{trackId,rootId,targetId,content,deleted}`, mở đúng thread từ inbox |
| POST `/community/songs/:id/comments` | `{content}` | 201 `{id,track_id}` |
| POST `/community/comments/:id/replies` | `{content}` | 201, chỉ reply root active, tối đa một cấp |
| DELETE `/community/comments/:id` | Không body | 204 chỉ owner, soft delete và giữ replies |
| PUT / DELETE `/community/comments/:id/like` | Không body | 204 idempotent |
| POST `/community/comments/:id/report` | reason copyright/abuse/spam/other, details? ≤1000 | 202 `{status:pending}`, lưu report thật |
| GET `/notifications` | limit/cursor, unread=true/false | 200 `{items,nextCursor}` với actor/type/content IDs/title/read/createdAt |
| GET `/notifications/unread-count` | Không query | 200 `{count}` đã lọc privacy |
| PATCH `/notifications/:id/read` | Không body | 204 chỉ recipient, account khác 404 |
| PATCH `/notifications/read-all` | Không body | 204 chỉ tài khoản hiện tại |
| GET / PATCH `/notifications/preferences` | PATCH một hoặc nhiều followers/comments/replies/likes/newTracks boolean | 200 cả 5 nhóm, lưu server |

Mã lỗi: 401 `UNAUTHORIZED`; 400 `VALIDATION_ERROR`, `INVALID_CURSOR`, `REPLY_DEPTH`; 404 `RESOURCE_NOT_FOUND`; 410 `FEED_EXPIRED`; 429 `RATE_LIMITED`, `COMMENT_RATE_LIMITED`; 503 `SOCIAL_UNAVAILABLE`.

Comments cộng đồng chỉ mở trên bài public/active, creator active có username, kể cả với owner. Track của reply được suy ra từ parent, client không khai báo được track khác. Deleted root còn replies hiển thị tombstone; hidden root ẩn thread. Author hidden và nội dung hidden/deleted bị loại khỏi counts/notifications. Flutter render text thuần, không parse HTML. Server trim, giới hạn 1–1000/control characters; khóa user khi viết để giới hạn 8 comments/phút và từ chối nội dung trùng trong phút đó. HTTP limiter tái sử dụng MVP một process; nhiều instance cần shared limiter.

## Notifications và worker

Trigger DB ghi outbox **cùng transaction** follow/like/comment/publish, bao gồm endpoint cũ. Không thông báo cho bản thân. Stable event key chống retry, unlike/re-like, unfollow/re-follow và republish spam. Reply gửi sự kiện phù hợp tới chủ bài và chủ comment; một recipient không nhận cả comment lẫn reply cho cùng thao tác. Private upload không phát sự kiện bài mới; edit metadata không phát lại.

Worker dùng `FOR UPDATE SKIP LOCKED`; mỗi transaction lấy tối đa 101 follower IDs, ghi tối đa 100 recipients và lưu cursor. Preferences/follow/visibility hiện tại được kiểm tra lúc delivery. Lỗi rollback batch tới savepoint và lưu backoff từ 5 giây tới 1 giờ. Crash rollback transaction; unique recipient/event chống giao trùng khi chạy lại. Không fanout hàng nghìn follower trong request publish.

Server đánh thức worker mỗi 15 giây, 5 batch, không chạy chồng. **Thiết lập scheduler bền vững** gọi mỗi phút từ `backend/`:

```sh
npm run notifications:deliver
```

CLI xử lý tối đa 50 batch và dọn tối đa 500 snapshot hết hạn/lượt. Timer chỉ là wakeup nhanh; DB outbox + scheduler phục hồi khi restart hoặc scale-to-zero. Giám sát pending/attempts/available_at và cấu hình retention cho job hoàn tất; giữ dedupe key theo chính sách chống spam. Không có FCM/device token/SSE, không có JWT trong URL.

Inbox/read state/preferences nằm trong PostgreSQL, tồn tại qua phiên và thiết bị. Badge poll tuần tự 30 giây, lỗi backoff tối đa 5 phút; dừng khi route/tab bị che, background/dispose. Inbox mở lại/refresh đọc DB. Visibility được kiểm tra lại ở list/unread/deep link; nội dung không còn được xem bị loại. Actor chưa có username vẫn được nhận diện; mở profile chưa tồn tại hiển thị không khả dụng.

## Flutter, chia sẻ và phạm vi file

Feature mới: `shorts/presentation`, `comments/presentation`, `notifications/presentation`; data/actions dùng chung trong `social/data` và `social/application`. Providers thuộc SessionScope hiện có. Like/save/follow dùng chung maps và mutex theo resource, optimistic rollback khi server từ chối. Home/Discover/Profile/Player cập nhật cùng trạng thái; Following refresh sau unfollow hoàn tất. Count comment lấy lại từ API sau mutation. Home có Shorts và chuông; Now Playing/menu bài có comments/share; profile/playlist public có share.

Web dùng Navigator.share, fallback Clipboard; Android ACTION_SEND + chooser qua MethodChannel của Activity V7, không thêm package. Link `/#/shorts/:id`, `/#/u/:username`, `/#/playlists/:id` không chứa signed URL/token. Native deployment cần `--dart-define=PUBLIC_APP_URL=https://<web-app-host>`; fallback API origin chỉ phù hợp development. Chưa cấu hình verified Android App Links khi chưa có domain/assetlinks; web link đi qua auth gate và REST authorization. Tham khảo [Android chooser](https://developer.android.com/training/basics/intents/sending), [Dart JS interop](https://dart.dev/interop/js-interop/start).

| Sprint | File/kết quả chính | Kiểm chứng và giới hạn |
| --- | --- | --- |
| 1 Audit | Bảng đầu tài liệu; đọc README/DESIGN/PRD và develop | Giữ V7 local |
| 2 Shorts | shorts_screen, Song, audio_service, router | Test first entry/bound/restore/full/stop/late response; không có feed giả trong ứng dụng |
| 3 Comments backend | migration 006, social repository/service/routes/schema | PGlite + Clerk HTTP: ownership/privacy/depth/spam/report/cursor |
| 4 Comments UI | comments_sheet, player extras/menu | Keyboard 320px/1.3×, gửi một request, đóng sheet không resume |
| 5 Notifications backend | outbox/worker/server, moderation, package script | Idempotency/rollback/retry/preferences/102 followers qua 2 batch/private→public/cross-account |
| 6 Center | notification_center, Home/topbar/preferences routes | Test unread/read-all, lưu rồi mở lại preferences, reply link đúng thread và không autoplay; chưa nghiệm thu hai account thật trên Neon |
| 7 Near realtime | lifecycle/backoff polling + scheduler CLI | Không push; cần scheduler deployment |
| 8 Social/share | social providers, community widgets/profile/playlist, favorite service, share transports/Activity | Shared-state rollback test; Android chooser chờ SDK/device |
| 9 QA | social_music_test, social-discovery.test và các suite cũ | Kết quả bên dưới; artwork fixture không phải asset production |

## Kết quả kiểm thử và giới hạn

- `flutter pub get`, `flutter gen-l10n`: thành công; V9 không thêm dependency.
- `flutter analyze`: không có issue; formatter toàn repo đã chạy, `git diff --check` sạch.
- `flutter test`: **316 passed**, gồm native bridge V7, các luồng V9 và hồi quy retry/refresh/navigation. Fake engine không thay thế nghiệm thu native.
- `node --test test/web/*.cjs`: **25 passed**.
- `npm test`: **83 passed, 1 skipped** (test cần database test riêng). Migration 001–006 chạy từ schema rỗng trong PGlite riêng; test startup từ chối schema thiếu bảng/migration. Cursor giữ microseconds PostgreSQL để không mất hàng cùng millisecond; có test timestamp trùng.
- `flutter build web --release`: thành công; Wasm dry run thành công, build JS ở `build/web`.
- `flutter build apk --debug`: đã thử, dừng trước compile vì **No Android SDK found**; chưa có APK, chưa kiểm tra native chooser/Bluetooth/lock screen.
- Đã xem ảnh render light/dark với font Be Vietnam Pro/Material Icons thật, artwork trống và nhãn Fixture; không coi đây là nghiệm thu artwork/network/tài khoản production. Ảnh `.local/v9-shorts-*.png` không commit.
- `npm run test:smoke`: **39 passed**, gồm schema/read queries Neon V9, Clerk JWKS và Cloudinary. Chưa nghiệm thu mutation qua phiên người dùng, logout/login/F5/đa thiết bị trên Neon thật; không tuyên bố đã triển khai production.
- Không commit/push hoặc migration production; giữ version release hiện tại và toàn bộ thay đổi V7.
