# NOCTURNE V3 — triển khai và nghiệm thu

## Chạy development

Đọc [kiểm kê và nguồn thiết kế](ui/nocturne-v3-audit.md). Dùng Node/Flutter và cấu hình Clerk/Cloudinary/Neon development hiện có; không sửa secret trong client. Chạy từ `backend/`:

```powershell
node scripts/v3-preflight.mjs
npm test
npm run migrate
```

Preflight chỉ đọc: xác nhận môi trường development, số bản ghi và username cũ có tương thích hay không. Nếu migration lỗi, dừng để kiểm tra; không tự tạo bảng bằng SQL Editor. Migration 004 thêm cột/bảng/index và sao chép lượt thích hiện có sang quan hệ mới; không xóa dữ liệu hoặc công khai các bài cũ. Unique/check constraint cố ý từ chối dữ liệu username cũ không tương thích, không âm thầm đổi tên.

Từ thư mục gốc, build bằng `scripts/run-web.ps1` hoặc lệnh build hiện có, rồi khởi động lại Express để nhận module community và worker cleanup. Phiên Clerk, audience, CSP, hash navigation được giữ.

## Danh tính và dữ liệu công khai

Mở Cá nhân → Tạo hồ sơ SoundShare. Chọn username 3–24 ký tự, tên hiển thị và bio; avatar/cover tải lên qua API artwork đã kiểm tra. Handle SoundShare độc lập username/email của Clerk, không cần bật username trong Clerk Dashboard hoặc webhook. Server lấy subject đã xác minh để ánh xạ `users.id`; client không được sửa liên kết này.

Username lưu lowercase, unique trong database; tên dành riêng gồm `admin`, `support`, `soundshare`, `system`, `official`, `search`. Case-insensitive/prefix/partial và tên Unicode được hỗ trợ. Đổi username làm liên kết cũ không còn hiệu lực; chưa có alias/cooldown. Email, Clerk ID và metadata tài khoản không nằm trong public DTO.

“Công khai” nghĩa là các tài khoản SoundShare đã đăng nhập đều có thể khám phá/nghe. Ngoài health, các REST endpoint hiện yêu cầu Clerk Bearer token; liên kết hồ sơ yêu cầu đăng nhập trước khi mở. Chưa có anonymous listening/tracking. Bài cũ và upload mới mặc định riêng tư. Public yêu cầu hồ sơ có username và xác nhận quyền chia sẻ audio/artwork. Không tự lấy nhạc từ dịch vụ ngoài.

## Nghe, xếp hạng và cá nhân hóa

Một AudioPlayer phục vụ mọi tab và hồ sơ. Queue theo phiên có phát ngay/thêm/bỏ, chuyển bài tiếp theo khi kết thúc và hỗ trợ điều khiển shuffle/repeat hiện có. Home tiếp tục nghe dựa trên phiên có tiến trình thật; gợi ý ưu tiên thể loại đã thích rồi mới nhất, có nhãn giải thích. Follow feed chỉ lấy bài công khai từ người đang theo dõi.

Server cấp playback ticket, lấy duration từ metadata Cloudinary đã xác minh, gửi URL ký 5 phút; không lưu URL ký trong Neon. Heartbeat 15 giây chỉ gửi khi audio sẵn sàng/đang phát, có cập nhật khi kết thúc hoặc tạm dừng. Credit không vượt thời gian server đã trôi qua, thay đổi vị trí và 20 giây mỗi heartbeat. Ngưỡng valid là `min(30 giây, duration/2)`; ticket hết hạn sau 2 giờ. Một user/song chỉ có một valid event trong cửa sổ trượt 30 phút, dùng transaction/advisory lock và unique constraint. Mở player, seek hoặc refresh liên tục không tự tạo valid event.

Đây là chống lạm dụng mức MVP, không phải bằng chứng mật mã rằng thiết bị đã phát ra âm thanh. Chưa có phát hiện bot phân tán hoặc phân tích gian lận. `totalPlayCount` đếm ticket khởi tạo, tách khỏi `validPlayCount` và unique listeners; ticket không đồng nghĩa lượt nghe hợp lệ.

Ranking thử nghiệm: 45% valid plays + 25% unique listeners + 20% likes + 10% saves, mỗi đại lượng chia cho max cùng cửa sổ. Hôm nay theo Asia/Ho_Chi_Minh; 7/30 ngày là cửa sổ trượt; mọi thời điểm tính từ epoch. Không có hệ số/lượt nghe giả. 0 tương tác vẫn có thể có bài mới với score 0 và tie-break thời gian/ID. Creator featured dựa trên follow/lượt nghe công khai 7 ngày; emerging ưu tiên follower thấp rồi tương tác mới. Discovery cache 1 phút; hoạt động quan trọng chủ động invalidate.

## Upload, xóa và moderation

Web dùng sự kiện byte thực của XHR; 100% truyền file chưa có nghĩa metadata đã lưu. Giai đoạn xác nhận metadata vô hiệu hóa hủy vì server có thể đã commit. Hủy trước đó abort transport và không bắt đầu tạo bài; các asset đã được server nhận có thể còn private, UI nêu rõ. Native dùng abortable HTTP và trạng thái tiến trình không xác định; chưa nghiệm thu thiết bị thật. Chưa có worker TTL dọn asset upload dở chưa gắn bài.

Trong cùng phiên, retry metadata giữ asset ID đã nhận thay vì tải lại file; server kiểm tra unique audio asset và metadata tương ứng để không tạo bài trùng khi mất response. Cache này không tồn tại qua reload/đăng xuất. Upload public kiểm tra đã chọn username trước khi truyền file và vẫn kiểm tra lại quyền ở server.

Xóa bài tạo receipt và cleanup jobs trong cùng transaction khi gỡ track/quan hệ. Trả 202 với `status=removed, cleanupPending`; thử dọn Storage ngay, worker chạy mỗi phút xử lý tối đa 20 job/batch. Lỗi Storage giữ job để retry qua restart. Media đang được track/hồ sơ khác dùng không bị xóa. Chỉ xóa metadata asset sau Storage xác nhận; retry DELETE cùng track ID của owner được hỗ trợ. Đã phát hành URL ký có thể dùng đến hết hạn, không bảo đảm thu hồi CDN tức thời.

Báo cáo có reason, dedupe và trạng thái pending; không tự gỡ khi có báo cáo. Người vận hành backend có quyền DB có thể review bằng CLI, không có REST cấp quyền moderation từ client:

```powershell
node scripts/moderate-report.mjs --report=<uuid> --action=hide
node scripts/moderate-report.mjs --report=<uuid> --action=restore
node scripts/moderate-report.mjs --report=<uuid> --action=dismiss
```

Hide/restore tác động track hoặc profile đúng target, lưu resolution/reviewed_at. Nội dung hidden bị loại khỏi search/discovery/playback của người khác; owner không thể PATCH để tự unhide. Chưa có dashboard moderator, block account hoặc quy trình kháng nghị.

## Kiểm tra

`backend/test/community*.test.js` dùng PostgreSQL WASM PGlite biệt lập từ schema rỗng, migrations thật, repository thật, HTTP Express và JWT RSA fixture với Clerk middleware. Cloudinary giả lập; không viết fixture vào Neon ứng dụng. Đây không thay thế kiểm tra pooler/TLS, đa kết nối đồng thời và tải thật trên Neon test branch. Test TCP PostgreSQL cũ vẫn cần TEST_DATABASE_URL riêng.

`test/community_test.dart` kiểm tra API DTO, responsive 320/390/1280 ở chữ 2×, debounce, follow thành công/thất bại, mở hồ sơ, chuyển tab và queue dùng chung player. Test upload transport kiểm tra byte progress, cancel và chờ response; không mô phỏng thành công trước server. Kết quả chạy cuối và những bước nghiệm thu thật còn thiếu ghi ở báo cáo UI V3.

Chạy `node scripts/review-nocturne.mjs` tại backend sau khi build Web để rà soát Chrome. Cần Chrome (hoặc CHROME_PATH). Script tự tạo PostgreSQL PGlite trong bộ nhớ và Chrome profile riêng, sinh khóa JWT test, audio tổng hợp và artwork procedural; chuyển mọi request localhost của trình duyệt đó vào Express test. Không import `.env`, không ghi Neon/Cloudinary hoặc dùng phiên trình duyệt cá nhân. Các ảnh/JSON nằm trong `build/nocturne-review/`; đây là dữ liệu kiểm thử, không phải cộng đồng thật.

Adapter Storage yêu cầu `media_metadata:true` cho video/audio để lấy duration từ Admin API. Đã đối chiếu [tài liệu Cloudinary](https://cloudinary.com/documentation/admin_api) và xác minh đọc được duration của hai MP3 cũ trong development. Smoke chỉ đọc metadata; không lưu URL ký hoặc nội dung file vào Neon.
