# Gợi ý âm nhạc cá nhân hóa — taste-v1

Mục **Dành riêng cho bạn** sử dụng dữ liệu của tài khoản đang đăng nhập: lượt nghe hợp lệ, bài yêu thích, bài đã lưu, thể loại và người đang theo dõi. Backend lấy ứng viên, chấm điểm và trả tối đa tám bài công khai; Flutter chỉ trình bày kết quả và lý do. Đây là baseline gợi ý theo nội dung có trọng số, chưa phải mô hình ML được huấn luyện hay phân tích âm thanh bằng AI. Không có nhà cung cấp AI, API key hoặc dữ liệu gửi sang dịch vụ mới.

Hướng tiếp cận dựa trên [content-based filtering của Google](https://developers.google.com/machine-learning/recommendation/content-based/basics): đặc điểm nội dung và hành vi của chính người nghe cung cấp tín hiệu. Trong SoundShare, đặc điểm hiện có là thể loại và người đăng; không suy diễn tâm trạng, nhịp độ hay độ “nhẹ” từ tên bài hát.

## Dữ liệu và cách tính

- Lịch sử: tối đa 1.000 `valid_play_events` gần nhất trong 90 ngày, có playback session đạt ngưỡng nghe server. Mở player hoặc tạo ticket chưa nghe đủ không đóng góp. Bỏ nội dung đã hidden/deleted hoặc bài riêng của người khác mà người nghe không còn quyền đọc.
- Một bài chỉ đóng góp một lần/ngày địa phương cho sở thích chung. Trọng số giảm theo thời gian, chu kỳ bán rã 30 ngày: `exp(-ln(2) × tuổi sự kiện / 30 ngày)`.
- Thích/lưu: tối đa 500 quan hệ hiện có mỗi loại; không lấy quan hệ đã bỏ thích/bỏ lưu. Thể loại so sánh sau khi trim và lowercase.
- Theo dõi: tối đa 100 creator được theo dõi gần nhất, còn hồ sơ công khai hoạt động. Bỏ theo dõi loại tín hiệu tương ứng.
- Khung giờ: đêm 22:00–04:59, sáng 05:00–11:59, chiều 12:00–17:59, tối 18:00–21:59. Dùng thời điểm bắt đầu session, không dùng thời điểm mở Trang chủ làm lịch sử.
- Thói quen theo giờ cần ít nhất hai quan sát hợp lệ trong khung giờ đó. Dữ liệu khung giờ được dedupe riêng theo bài/ngày/khung giờ, để nghe cùng bài buổi sáng và ban đêm vẫn ghi nhận cả hai thói quen; lượt lặp trong cùng khung giờ không tăng thêm bằng chứng.

Chuẩn hóa từng nhóm thể loại theo tín hiệu mạnh nhất của chính người nghe. Điểm baseline:

| Tín hiệu | Trọng số |
| --- | ---: |
| Thể loại từ lịch sử nghe hợp lệ | 0,30 |
| Thể loại từ bài yêu thích | 0,25 |
| Thể loại từ bài đã lưu | 0,10 |
| Creator đang theo dõi | 0,15 |
| Thể loại thường nghe cùng khung giờ | 0,20 |

Thêm tối đa 0,01 cho độ mới; giảm điểm còn 65% nếu bài vừa được nghe hợp lệ trong 24 giờ. Chọn lần lượt với hệ số đa dạng creator `điểm / (1 + 0,35 × số bài đã chọn của creator)`. Đây là điều chỉnh mềm: thư viện ít creator vẫn có thể trả đủ bài thực tế. Khi không có tín hiệu phù hợp, dùng bài mới nhất và tie-break `created_at/id` ổn định, không gọi đó là cá nhân hóa.

Trọng số/version nằm trong `backend/src/services/recommendation.service.js`; thứ tự lấy seed thể loại cùng baseline nằm trong `backend/src/repositories/recommendation-query.js`. Khi điều chỉnh phải đánh giá cả hai và cập nhật version/test. Chưa có A/B test hoặc đánh giá chất lượng gợi ý từ người dùng thực.

Ví dụ đã kiểm thử: cùng tài khoản có lịch sử Lo-fi vào 23:00 và Pop vào 12:00 trong nhiều ngày; Lo-fi đứng trước vào ban đêm, Pop đứng trước vào buổi chiều. Không tự tăng Lo-fi cho tài khoản chưa có thói quen này.

## Giới hạn công việc mỗi yêu cầu

SQL chỉ lấy ứng viên từ tối đa tám thể loại sở thích × 24 bài, 100 creator đang theo dõi × ba bài và 40 bài mới. Sau UNION loại trùng có tối đa 532 ứng viên ở backend; không tải toàn bộ catalog về Flutter. Migration `005_recommendation_indexes.sql` thêm index cho lịch sử/thích/lưu/follow theo người dùng và thời gian, cùng index thể loại chuẩn hóa trên bài public/active. Index public/new và owner/new hiện có được tái sử dụng.

Client cache Home tối đa một phút trong container của từng tài khoản. Các đường invalidation hiện có sau thích/lưu/follow và lượt nghe đạt ngưỡng tiếp tục làm mới Home. Backend trả `Cache-Control: no-store`; endpoint dùng giới hạn discovery 60 yêu cầu/phút/người dùng, chung với các route discovery/search hiện có. Không cache kết quả cá nhân hóa dùng chung giữa các tài khoản.

## API

`GET /api/v1/discover/home?utcOffsetMinutes=420` cần Bearer Clerk hợp lệ. Query strict, chỉ nhận `utcOffsetMinutes` là số nguyên −720…840, mặc định 420. Flutter gửi UTC offset hiện tại của thiết bị; server tự lấy thời điểm hiện tại, không nhận `userId`, timestamp hay daypart từ client. Offset chỉ là ngữ cảnh xếp hạng, không cấp quyền truy cập.

Các nhóm `newReleases`, `following`, `recommended`, `recent`, `popular` giữ cấu trúc cũ. Thêm:

```json
{
  "recommendation": {
    "version": "taste-v1",
    "strategy": "personalized",
    "daypart": "night",
    "utcOffsetMinutes": 420,
    "experimental": true
  },
  "recommendationReason": "listening-preferences-v1"
}
```

`strategy` có thể là `new-releases`; khi đó `recommendationReason` tương ứng là `new-releases`. Mỗi item trong `recommended` thêm `recommendationReason`:

```json
{"code":"listening-time","genre":"Lo-fi","daypart":"night"}
```

Code hỗ trợ: `listening-time`, `liked-genre`, `listening-history`, `following`, `saved-genre`, `new-release`. Chỉ trả thể loại của chính bài được gợi ý và daypart nếu cần, không trả tên bài nguồn, lịch sử, Clerk ID hoặc hồ sơ riêng của người khác. Lý do thời gian chỉ được chọn nếu đóng góp ít nhất một nửa tín hiệu có trọng số mạnh nhất; còn lại chọn tín hiệu mạnh nhất.

Lỗi giữ contract hiện có: `400 VALIDATION_ERROR`, `401 UNAUTHORIZED`, `429 RATE_LIMITED`, `503 COMMUNITY_UNAVAILABLE`, kèm `requestId`, không lộ lỗi driver. Home không phân trang riêng; vẫn trả tối đa tám bài gợi ý. Các danh sách khám phá khác giữ phân trang hiện có.

## Triển khai và kiểm tra

Chạy migration bằng runner hiện có trong môi trường development/test đã được xác định, rồi khởi động lại backend trước khi phát hành Flutter mới. Client mới gửi query offset mà backend cũ chưa chấp nhận; parser vẫn xử lý được response thiếu metadata bằng mô tả chung. Không có biến môi trường hay dependency mới. Migration chỉ thêm index, không sửa hoặc công khai dữ liệu. Việc tạo index dùng transaction của runner; cần đánh giá thời gian khóa trước khi áp dụng lên catalog production lớn.

Kiểm thử liên quan: `backend/test/recommendations.test.js`, `backend/test/recommendation-ranking.test.js`, `test/recommendations_test.dart`. Integration dùng PostgreSQL trong PGlite, migration từ schema rỗng, JWT RSA test được middleware Clerk xác minh và asset fixture. Không dùng Neon production hoặc nội dung có bản quyền.

### Kết quả ngày 06/11/2026

- `flutter gen-l10n` và Dart format đạt; `flutter analyze --no-pub` không có issue.
- Toàn bộ `flutter test --no-pub --reporter expanded`: **182/182 đạt**, gồm tám test gợi ý mới và các test hồi quy player/navigation/upload/profile.
- `npm test` trong backend: **73 đạt, một bỏ qua**. Test bỏ qua cần `TEST_DATABASE_URL` cho TCP PostgreSQL biệt lập; migration/query thật của tính năng đã chạy trên PGlite. Sau lượt chạy đầy đủ, thêm và chạy riêng test decay lịch sử: **một đạt**. Tổng cộng 11 integration tests gợi ý và bốn pure ranking/context tests đã được kiểm tra.
- Web release build thành công trong `build/recommendation-web`; bản `build/web` của ứng dụng đang phục vụ được giữ nguyên.
- **4/4 phiên Chrome mới đạt:** cá nhân hóa/tài khoản mới × 390/1280 px. Browser gửi offset 420, API thật trong server test trả đúng metadata, lý do tiếng Việt hiển thị được. Bấm artwork trong rail mở player hiện có; audio HTML tổng hợp tiến từ khoảng 2,9 lên 4,8 giây và dùng cùng audio element khi sang hồ sơ creator. Không có API thất bại, runtime exception hoặc console error. Đã xem bốn ảnh, không thấy nội dung chồng hoặc bị cắt trong vùng kiểm tra.

Ảnh dùng dữ liệu kiểm thử được đánh dấu; đồng hồ gợi ý cố định tại 23:30 Việt Nam, đồng hồ tiến trình audio chạy thật. [Browser report đã lược bỏ payload dư thừa](https://github.com/TieuBao-IT89/SoundShare/blob/cadc3222f13d5d84bbec59c611bc6382ea8196e3/docs/ui/recommendations/browser-report.json) ghi SHA-256 bundle và kết quả từng phiên.

| Trạng thái | Mobile 390 px | Desktop 1280 px |
| --- | --- | --- |
| Cá nhân hóa | [Ảnh](https://github.com/TieuBao-IT89/SoundShare/blob/cadc3222f13d5d84bbec59c611bc6382ea8196e3/docs/ui/recommendations/for-you-personalized-390.png) | [Ảnh](https://github.com/TieuBao-IT89/SoundShare/blob/cadc3222f13d5d84bbec59c611bc6382ea8196e3/docs/ui/recommendations/for-you-personalized-1280.png) |
| Tài khoản mới | [Ảnh](https://github.com/TieuBao-IT89/SoundShare/blob/cadc3222f13d5d84bbec59c611bc6382ea8196e3/docs/ui/recommendations/for-you-cold-390.png) | [Ảnh](https://github.com/TieuBao-IT89/SoundShare/blob/cadc3222f13d5d84bbec59c611bc6382ea8196e3/docs/ui/recommendations/for-you-cold-1280.png) |

Generator Chrome và ảnh/báo cáo của lần kiểm tra trên đã chuyển vào [kho lịch sử](archive.md). Các test hồi quy hiện tại vẫn kiểm tra thuật toán, quyền truy cập, cold start, dữ liệu phân trang và UI; có thể chạy từ root:

```powershell
flutter test test/recommendations_test.dart
node --test backend/test/recommendations.test.js backend/test/recommendation-ranking.test.js
```

Các test dùng player/provider giả lập và database PGlite biệt lập; không đọc dotenv hoặc kết nối Neon/Cloudinary thật.

Giới hạn: offset hiện tại được áp dụng cả cho lịch sử, nên lịch sử khi đi du lịch/đổi giờ mùa hè có thể được quy về khung giờ khác; chưa lưu timezone từng session. Lấy 1.000 sự kiện trước khi dedupe giúp truy vấn có giới hạn nhưng tài khoản nghe lặp nhiều có thể có cửa sổ hiệu dụng ngắn hơn 90 ngày. Chưa benchmark tải catalog lớn, nghiệm thu mobile thật hoặc chạy lại tài khoản Clerk/Neon/Cloudinary thật cho thay đổi này. Không tự chạy migration trên môi trường thật trong đợt triển khai mã này.
