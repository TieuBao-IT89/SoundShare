# TASKS.md — SoundShare

> **Project Task Tracker**  
> Version: 1.0  
> Status: In Progress  
> Purpose: Theo dõi tiến độ, công việc còn lại và thứ tự triển khai SoundShare.

---

## NOCTURNE V3 — cập nhật 06/11/2026

Phần theo dõi bên dưới là backlog lịch sử. Trạng thái V3 căn cứ vào [audit](docs/ui/nocturne-v3-audit.md), [hướng dẫn vận hành](docs/nocturne-v3.md) và [báo cáo kiểm tra](docs/ui/nocturne-v3-review.md).

- [x] Audit repository, nghiên cứu nguồn, design system NOCTURNE và navigation năm tab.
- [x] Migration 004 additive; đã chạy Neon development, giữ 3 user/2 bài cũ, hai bài vẫn private.
- [x] API và UI username/profile, tìm cộng đồng, follow, follower/following, feed.
- [x] Discovery, trending cùng cửa sổ thống kê, valid play threshold/dedupe và thể loại thực.
- [x] Cùng AudioPlayer, queue, resume, mini player; playlist, thích/lưu có lưu server.
- [x] Public/private upload, byte progress/hủy Web, retry giữ asset ID, sửa/xóa owned song và cleanup bền vững.
- [x] Báo cáo nội dung và CLI moderation; không có nút cấp quyền admin từ client.
- [x] Kiểm thử PostgreSQL biệt lập, regression Flutter/JS, smoke chỉ đọc dịch vụ development, build Web và Chrome fixture.
- [x] Người dùng xác nhận Web thật đăng nhập và mở được Cá nhân → Tạo hồ sơ công khai.
- [x] Người dùng xác nhận lưu username/tên hiển thị và F5 vẫn giữ đúng hồ sơ trên Web thật.
- [x] Người dùng xác nhận hai tài khoản thật: tìm @username mở đúng hồ sơ, follow thành công và F5 vẫn Đang theo dõi.
- [x] Người dùng xác nhận tài khoản thứ hai thấy/phát được bài công khai và chuyển tab nhạc vẫn chạy.
- [x] Người dùng xác nhận lượt nghe tăng; đọc Neon có 1 valid play event và truy vấn ranking cả bốn khoảng thời gian trả 1 valid play cho bài công khai.
- [x] Người dùng xác nhận đăng xuất/đăng nhập lại thành công và vẫn giữ trạng thái Đang theo dõi.
- [ ] Android/iOS thật, profile performance/large catalog, TCP PostgreSQL test branch và nhiều server instance.
- [ ] Worker TTL cho upload dở, dashboard moderation và quy trình kháng nghị (chưa triển khai).

## 1. Tổng quan tiến độ

SoundShare là ứng dụng nghe và chia sẻ âm nhạc được xây dựng bằng Flutter.

**Kiến trúc mục tiêu:**

- Frontend: Flutter + Dart
- State management: Riverpod
- Navigation: GoRouter
- Audio playback: just_audio
- Backend: Node.js + Express
- Database: Neon PostgreSQL
- Authentication: Chưa lựa chọn
- File Storage: Chưa lựa chọn

### Trạng thái dự án

| Hạng mục       | Trạng thái                 |
| -------------- | -------------------------- |
| README.md      | Có tài liệu hiện tại       |
| DESIGN.md      | Đã soạn bản đầu            |
| PRD.md         | Đã soạn, cần cập nhật Neon |
| AGENTS.md      | Đã soạn, cần cập nhật Neon |
| TASKS.md       | Đang xây dựng              |
| Flutter UI     | Đã có cấu trúc màn hình    |
| Backend API    | Chưa xác nhận hoàn thành   |
| Neon Database  | Chưa xác nhận tích hợp     |
| Authentication | Chưa lựa chọn              |
| Cloud Storage  | Chưa lựa chọn              |

> Trạng thái tài liệu ở đây phản ánh tiến độ soạn thảo trong quá trình làm việc, không xác nhận các file đã được commit lên GitHub.

---

## 2. Quy ước trạng thái

- `[ ] TODO`: Chưa thực hiện.
- `[~] IN PROGRESS`: Đang thực hiện.
- `[x] DONE`: Đã hoàn thành và kiểm chứng.
- `[!] BLOCKED`: Đang bị chặn bởi phụ thuộc hoặc quyết định chưa được xác nhận.

Không đánh dấu DONE chỉ vì đã tạo UI hoặc viết code. Cần có kiểm thử hoặc bằng chứng phù hợp.

---

## 3. Phase 1 — Project Documentation

Mục tiêu: Hoàn thiện tài liệu để AI hiểu sản phẩm và quy tắc phát triển.

### DOC-01 — DESIGN.md

- [x] Xác định hệ thống màu sắc.
- [x] Xác định typography và spacing.
- [x] Mô tả các màn hình chính.
- [x] Xác định quy tắc UI/UX.

### DOC-02 — PRD.md

- [x] Mô tả mục tiêu sản phẩm.
- [x] Xác định người dùng mục tiêu.
- [x] Xác định các chức năng chính.
- [ ] Cập nhật kiến trúc Neon PostgreSQL.
- [ ] Bổ sung Node.js + Express backend.
- [ ] Xác định authentication và storage là các dịch vụ riêng.

### DOC-03 — AGENTS.md

- [x] Xác định quy tắc Flutter/Dart.
- [x] Xác định quy tắc Riverpod và GoRouter.
- [ ] Thay các hướng dẫn Supabase bằng Neon.
- [ ] Bổ sung quy tắc Express API.
- [ ] Bổ sung bảo mật database credentials.
- [ ] Bổ sung quy tắc migration và SQL.
- [ ] Bổ sung quy tắc kiểm thử backend.

### DOC-04 — TASKS.md

- [x] Xây dựng bảng theo dõi công việc.
- [x] Xác định các phase triển khai.
- [x] Xác định trạng thái và tiêu chí hoàn thành.

### DOC-05 — README.md

- [ ] Cập nhật kiến trúc tổng thể.
- [ ] Bổ sung hướng dẫn chạy Flutter.
- [ ] Bổ sung hướng dẫn chạy backend.
- [ ] Bổ sung cấu hình Neon.
- [ ] Bổ sung `.env.example`.

---

## 4. Phase 2 — Flutter Frontend

Mục tiêu: Hoàn thiện trải nghiệm người dùng và kết nối API.

### FE-01 — Project Structure

- [ ] Kiểm tra cấu trúc thư mục Flutter.
- [ ] Kiểm tra dependency trong pubspec.yaml.
- [ ] Chuẩn hóa cấu trúc feature.
- [ ] Kiểm tra Riverpod providers.
- [ ] Kiểm tra GoRouter routes.

### FE-02 — Home

- [ ] Hoàn thiện danh sách bài hát.
- [ ] Kết nối API lấy danh sách bài hát.
- [ ] Xử lý loading state.
- [ ] Xử lý empty state.
- [ ] Xử lý error state.

### FE-03 — Explore

- [ ] Hoàn thiện giao diện tìm kiếm.
- [ ] Kết nối Search API.
- [ ] Xử lý kết quả tìm kiếm.
- [ ] Xử lý trường hợp không có kết quả.

### FE-04 — Player

- [ ] Hoàn thiện playback controller.
- [ ] Đồng bộ trạng thái play/pause.
- [ ] Hiển thị metadata bài hát.
- [ ] Xử lý lỗi audio URL.
- [ ] Kiểm tra chuyển bài và trạng thái phát.

### FE-05 — Mini-player

- [ ] Đồng bộ với Player.
- [ ] Duy trì playback khi chuyển tab.
- [ ] Mở Player khi nhấn mini-player.

### FE-06 — Library

- [ ] Hoàn thiện giao diện Library.
- [ ] Kết nối API lấy thư viện.
- [ ] Thêm chức năng lưu bài hát.
- [ ] Thêm chức năng xóa bài hát đã lưu.
- [ ] Xử lý empty state.

### FE-07 — Profile

- [ ] Hoàn thiện giao diện Profile.
- [ ] Kết nối thông tin tài khoản.
- [ ] Xử lý trạng thái chưa đăng nhập.

### FE-08 — Upload

- [ ] Xây dựng quy trình chọn file.
- [ ] Kiểm tra định dạng và kích thước.
- [ ] Nhập metadata.
- [ ] Kết nối Upload API.
- [ ] Hiển thị tiến trình upload.

---

## 5. Phase 3 — Backend Development

Mục tiêu: Xây dựng backend trung gian giữa Flutter và Neon.

### BE-01 — Khởi tạo Backend

- [ ] Tạo thư mục backend.
- [ ] Khởi tạo Node.js project.
- [ ] Cài đặt Express.
- [ ] Thiết lập cấu trúc routes/controllers/services.
- [ ] Thiết lập middleware xử lý lỗi.
- [ ] Tạo health check endpoint.
- [ ] Thiết lập `.env.example`.

### BE-02 — Neon Database

- [ ] Tạo Neon project.
- [ ] Tạo PostgreSQL database.
- [ ] Cấu hình connection string phía backend.
- [ ] Thiết lập connection pooling.
- [ ] Xây dựng database connection module.
- [ ] Thiết lập migration.
- [ ] Kiểm tra kết nối database.

### BE-03 — Database Schema

- [ ] Thiết kế bảng users.
- [ ] Thiết kế bảng songs.
- [ ] Thiết kế bảng library_items.
- [ ] Thiết kế bảng uploads.
- [ ] Thiết lập khóa chính và khóa ngoại.
- [ ] Thiết lập index.
- [ ] Kiểm tra quan hệ dữ liệu.

### BE-04 — Song API

- [ ] GET `/api/v1/songs`
- [ ] GET `/api/v1/songs/:id`
- [ ] GET `/api/v1/search`
- [ ] Validate query parameters.
- [ ] Kiểm tra response format.
- [ ] Kiểm thử API.

### BE-05 — Authentication

- [ ] Chọn authentication provider.
- [ ] Thiết kế authentication flow.
- [ ] Xác minh access token phía backend.
- [ ] Xây dựng middleware authorization.
- [ ] Xử lý session hết hạn.
- [ ] Kiểm thử quyền truy cập.

### BE-06 — Library API

- [ ] GET `/api/v1/me/library`
- [ ] POST `/api/v1/me/library`
- [ ] DELETE `/api/v1/me/library/:songId`
- [ ] Kiểm tra quyền truy cập theo user.
- [ ] Kiểm thử dữ liệu thư viện.

### BE-07 — Upload API

- [ ] Chọn Cloud Storage provider.
- [ ] Thiết kế quy trình upload.
- [ ] Validate file phía server.
- [ ] Lưu file vào object storage.
- [ ] Lưu metadata vào Neon.
- [ ] Xử lý lỗi và cleanup.
- [ ] Kiểm thử upload.

---

## 6. Phase 4 — Integration

Mục tiêu: Kết nối Flutter, Backend và Database thành hệ thống hoàn chỉnh.

### INT-01 — Flutter ↔ Backend

- [ ] Thiết lập API client.
- [ ] Cấu hình base URL theo môi trường.
- [ ] Chuẩn hóa xử lý HTTP errors.
- [ ] Kiểm tra timeout và network errors.
- [ ] Kiểm thử các endpoint chính.

### INT-02 — Backend ↔ Neon

- [ ] Kiểm tra database connection.
- [ ] Kiểm thử CRUD.
- [ ] Kiểm thử transaction.
- [ ] Kiểm thử lỗi kết nối.
- [ ] Kiểm tra migration.

### INT-03 — End-to-End

- [ ] Home tải danh sách bài hát từ API.
- [ ] Explore tìm kiếm bài hát.
- [ ] Player phát bài hát từ media URL.
- [ ] Mini-player đồng bộ với Player.
- [ ] Library tải dữ liệu đúng tài khoản.
- [ ] Upload hoạt động với storage provider đã chọn.

---

## 7. Phase 5 — Testing & Quality Assurance

- [ ] Chạy `flutter analyze`.
- [ ] Chạy `flutter test`.
- [ ] Chạy backend tests.
- [ ] Kiểm thử API bằng công cụ phù hợp.
- [ ] Kiểm thử database queries.
- [ ] Kiểm thử authentication và authorization.
- [ ] Kiểm thử playback.
- [ ] Kiểm thử upload.
- [ ] Kiểm thử UI trên nhiều kích thước màn hình.
- [ ] Kiểm tra không có secret trong repository.
- [ ] Kiểm tra lỗi và performance.

---

## 8. Phase 6 — Deployment

- [ ] Chọn nền tảng deploy backend.
- [ ] Cấu hình production environment variables.
- [ ] Cấu hình Neon production database.
- [ ] Chạy database migrations.
- [ ] Thiết lập HTTPS.
- [ ] Thiết lập logging và health checks.
- [ ] Kiểm thử production API.
- [ ] Build Flutter release.
- [ ] Kiểm thử ứng dụng release.

---

## 9. Thứ tự ưu tiên thực hiện

| Priority | Task                     | Mục tiêu              |
| -------- | ------------------------ | --------------------- |
| P0       | Hoàn thiện PRD và AGENTS | Đồng bộ tài liệu Neon |
| P0       | Khởi tạo Express backend | Có backend hoạt động  |
| P0       | Kết nối Neon             | Có database           |
| P0       | Song API                 | Cung cấp catalog      |
| P0       | Flutter API integration  | Hiển thị dữ liệu thật |
| P0       | Playback integration     | Nghe nhạc ổn định     |
| P1       | Authentication           | Quản lý tài khoản     |
| P1       | Library API              | Lưu nội dung cá nhân  |
| P1       | Cloud Storage            | Lưu audio/artwork     |
| P1       | Upload API               | Tải nội dung lên      |
| P2       | Sharing                  | Chia sẻ nội dung      |
| P2       | Advanced features        | Mở rộng sản phẩm      |

---

## 10. Quy tắc cập nhật TASKS.md

AI contributor phải cập nhật file này khi:

1. Bắt đầu một task: chuyển trạng thái sang IN PROGRESS.
2. Hoàn thành và kiểm chứng: chuyển sang DONE.
3. Gặp phụ thuộc chưa giải quyết: chuyển sang BLOCKED và ghi lý do.
4. Phát hiện task mới: thêm task vào phase phù hợp.
5. Thay đổi kiến trúc hoặc phạm vi: cập nhật task liên quan.

Mỗi task nên có:

- ID duy nhất.
- Mô tả rõ ràng.
- Trạng thái.
- Tiêu chí hoàn thành khi cần.
- Phụ thuộc nếu có.

Không tự động đánh dấu DONE chỉ vì code đã được viết. Cần kiểm thử hoặc xác minh kết quả.

---

## 11. Next Actions — Công việc tiếp theo

Thứ tự đề xuất:

1. [ ] Cập nhật `PRD.md` theo Neon + Node.js + Express.
2. [ ] Cập nhật `AGENTS.md` theo kiến trúc mới.
3. [ ] Hoàn thiện `README.md` và hướng dẫn cấu hình.
4. [ ] Tạo backend Node.js + Express.
5. [ ] Tạo Neon PostgreSQL project và kết nối backend.
6. [ ] Thiết kế schema và migration.
7. [ ] Xây dựng Song API.
8. [ ] Kết nối Flutter với Song API.

**Nguyên tắc:** Hoàn thành từng task, kiểm thử và cập nhật trạng thái trước khi chuyển sang task tiếp theo.

---

## 12. Definition of Done

Một task chỉ được xem là DONE khi:

- Code hoặc tài liệu đã được cập nhật.
- Không làm hỏng chức năng liên quan.
- Đã chạy kiểm tra phù hợp.
- Không có lỗi đã biết chưa được ghi nhận.
- Đã cập nhật tài liệu liên quan.
- Đã cập nhật trạng thái trong `TASKS.md`.
