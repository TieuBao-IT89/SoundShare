# V11 — Synced Lyrics & Music Experience

V11 bổ sung source cho lời LRC do người đăng cung cấp: chọn file hoặc dán khi tạo bài, thêm/sửa/xóa trong **Thư viện → Quản lý bài hát**, xem lời từ player, chạm dòng để tua và mở toàn màn hình. Không tải lời từ nguồn bên ngoài, không tự sinh lời hoặc giả lập timestamp. Thiết kế lấy hướng đọc chữ lớn và tập trung dòng hiện tại, giữ font Be Vietnam Pro và palette/ambient SoundShare.

## Luồng dữ liệu

FilePicker đọc `.lrc` UTF-8 có giới hạn; Flutter kiểm tra để báo lỗi sớm. Client gửi **văn bản LRC** trong JSON tới Express, backend tự kiểm tra lại và suy ra owner từ Clerk đã xác minh. Không tin cue, user ID hoặc quyền do client tự khai báo.

`POST /api/v1/songs` nhận thêm `lyricsLrc` không bắt buộc. Sau khi audio/artwork đã xác minh, repository lưu bài và lời trong cùng transaction. Lỗi lyrics rollback việc tạo bài; retry cùng audio asset và cùng metadata/lời không tạo bài trùng, payload khác trả 409. Audio/artwork tiếp tục nằm ở Cloudinary authenticated; không thêm dependency hoặc provider.

Migration **007_synced_lyrics.sql** thêm `track_lyrics`: track ID PK/FK cascade, văn bản LRC chuẩn hóa có giới hạn 64 KB, revision và updated_at. Đây là dữ liệu văn bản ứng dụng ngắn cùng mốc thời gian, không lưu file nhị phân/audio/artwork, connection string hoặc signed URL. Không nhúng lời vào catalog/feed; chỉ tải khi mở viewer/editor. Không cache lyrics vào storage thiết bị hoặc dùng database trực tiếp từ Flutter.

## API contract

Mọi endpoint yêu cầu Bearer token Clerk hợp lệ; response chuẩn `{success:true,data:...}`, lỗi `{success:false,error:{code,message,requestId}}`. Lyrics trả `Cache-Control: no-store`. Router lyrics được mount trước router songs vì router cũ từ chối body trên subresource.

| Method / endpoint | Request | Response / quyền |
|---|---|---|
| POST `/api/v1/songs` | Contract cũ, thêm `lyricsLrc?: string` | 201 mới / 200 retry; chỉ tạo bài của subject đã xác minh, lời được kiểm tra và lưu nguyên tử |
| GET `/api/v1/songs/:songId/lyrics` | UUID; không query/body | 200 `{format:'lrc',lrc:string|null,cues:[{atMs:int,text:string}],revision:int,updatedAt:string|null,canEdit:bool}` |
| PUT `/api/v1/songs/:songId/lyrics` | JSON strict `{lrc:string,revision:int}` | 200 document mới; chỉ uploader của bài active; revision phải khớp |
| DELETE `/api/v1/songs/:songId/lyrics` | JSON strict `{revision:int}` | 200 document với `lrc:null,cues:[]`; revision tiếp tục tăng |

GET cho owner bài active, hoặc người dùng đã đăng nhập đọc bài public/active của hồ sơ active có username. Bài private của người khác, bài deleted/hidden hoặc tài nguyên không tồn tại trả **404 SONG_NOT_FOUND**; người khác sửa bài public nhìn thấy được trả **403 FORBIDDEN**. Thiếu/sai/hết hạn token, issuer hoặc audience sai trả **401 UNAUTHORIZED**. Không public lyrics để vượt quyền bài hát.

Chưa từng có lời: `lrc:null,cues:[],revision:0`. Sau xóa giữ tombstone revision để bản editor cũ không ghi đè; hai phiên sửa cùng revision chỉ một phiên thành công. **409 LYRICS_CHANGED** yêu cầu tải bản mới; client giữ nội dung đang sửa và chỉ thay khi người dùng chọn tải lại. Không tự retry ghi đè. **400 INVALID_LRC** cho nội dung LRC sai; **400 VALIDATION_ERROR** cho schema/path/query sai; **503 LYRICS_UNAVAILABLE** cho lỗi database, thông điệp an toàn. Giới hạn router 120 request / 15 phút / subject, PUT và DELETE mỗi loại 20 / 15 phút; vượt trả **429 RATE_LIMITED** và Retry-After. Giới hạn IP chung tiếp tục áp dụng.

## Định dạng được hỗ trợ

- UTF-8 có/không BOM, LF/CRLF; tối đa **65.536 byte**, 2.000 dòng sau chuẩn hóa, 1.000 mốc sau mở rộng nhiều timestamp. Một dòng lời tối đa 500 code unit, dòng gộp tối đa 2.000.
- `[mm:ss]`, `[mm:ss.f]`, `[mm:ss.ff]`, `[mm:ss.fff]`; phút 1–3 chữ số, giây 00–59, mốc gốc tối đa 6 giờ. Fraction được chuyển về millisecond.
- Nhiều tag cùng dòng: `[00:10][00:30]Điệp khúc`. Sắp xếp ổn định theo thời gian. Các dòng cùng timestamp gộp bằng newline, bỏ bản sao giống hệt; giữ văn bản như text, không thực thi HTML.
- Metadata dạng `[ti:...]`, `[ar:...]` được bỏ qua khi hiển thị. Một `[offset:N]` toàn tài liệu, đơn vị ms trong ±30.000; offset dương đưa lời sớm hơn (`max(0,timestamp-offset)`). Mốc âm sau offset gộp về 0.
- Dòng timestamp trống đánh dấu khoảng nhạc, hiển thị `♪`; tài liệu phải có ít nhất một dòng lời không rỗng. Từ chối plain text không timestamp, control/NUL, Unicode lỗi, timestamp sai và enhanced LRC theo từng từ. Đây là đồng bộ **từng dòng**, không word karaoke.

Node và Dart chạy cùng fixture `test/fixtures/lrc_cases.json`. Tham khảo cách xử lý LRC/multi-timestamp và hướng offset từ [FFmpeg LRC demuxer](https://github.com/FFmpeg/FFmpeg/blob/master/libavformat/lrcdec.c); chính sách giới hạn trên là contract riêng của SoundShare.

## Trải nghiệm nghe và chỉnh sửa

Nút Lời bài hát mở sheet; nút toàn màn hình mở `/lyrics`. Viewer theo bài đang chọn, không tạo AudioPlayer hoặc queue mới. `VisiblePlaybackPosition` dùng tiến trình player hiện tại, dừng subscription khi UI ẩn/nền; binary search xác định dòng hiện tại, tự cuộn khi đổi dòng. Chiều cao mỗi dòng được đo theo font/chiều rộng/text scale, không đo lại mỗi position tick. Không tự phát khi mở/đóng lyrics.

Chạm dòng gọi `PlaybackActions.seek`, giữ trạng thái pause/play và clamp theo duration hiện có; trước khi chọn/tải xong audio, dòng chưa cho tua. Khi kéo đọc lời cũ, tự cuộn tạm dừng; nút **Theo lời đang phát** hoặc chạm dòng bật lại. Reduce Motion bỏ chuyển màu và dùng jump thay vì animate scroll. Chuyển bài bỏ kết quả lời đến muộn của bài trước; loading/error/retry/nội dung rỗng là các trạng thái riêng, không dùng lời giả.

Uploader có thể thêm/sửa từ viewer hoặc Quản lý bài hát. Editor có preview số mốc hợp lệ, picker/paste, save, xóa có xác nhận; lỗi mạng hoặc conflict giữ văn bản để sao chép/sửa. File lỗi không được đính kèm hoặc đồng bộ. Quyền cuối cùng luôn do backend kiểm tra.

## Migration và triển khai

Kiểm thử chỉ dùng PGlite/PostgreSQL biệt lập và Clerk/storage giả lập. **Chưa chạy migration 007 trên Neon đang phục vụ Render.** Trước deploy source này, kiểm tra migration trên staging rồi áp dụng theo quy trình môi trường đích đã được cấp quyền:

```text
npm --prefix backend run migrate
npm --prefix backend run db:check
```

Chạy trong terminal có environment của đúng backend, không đưa credential vào lệnh, tài liệu hoặc chat. Server kiểm tra migration 001–007 và bảng `track_lyrics` trước khi mở cổng; startup không tự migrate. Free Render không có pre-deploy command/shell nên chuẩn bị schema bằng máy đã được cấp quyền như hướng dẫn deploy hiện có. Không deploy source mới trước migration.

Sau khi merge và build lại Render, nghiệm thu hai tài khoản: upload MP3 kèm LRC; refresh, mở player/sheet/fullscreen; pause, seek và chuyển bài; sửa/xóa chỉ owner; đổi visibility private làm người khác mất quyền lyrics. Thử Safari iPhone thật, chữ lớn, keyboard editor, xoay màn hình, Reduce Motion và quay lại từ nền. Chưa coi fixture/widget test là nghiệm thu dịch vụ hoặc thiết bị thật.

## Kiểm tra bản thay đổi

- `flutter analyze`: không có lỗi.
- `flutter test --no-pub`: **337/337** bài kiểm thử đạt. Bộ V11 kiểm tra parser chung với Node, tiến trình/seek khi pause, đổi bài và response đến muộn, lỗi/retry, conflict/reload/save/delete, file sai UTF-8/kích thước/phần mở rộng, và payload upload.
- `node --test --test-reporter=dot backend/test/*.test.js test/web/*.cjs`: đạt; integration lyrics dùng PostgreSQL/PGlite biệt lập, áp dụng migration từ schema rỗng, Clerk giả lập có chữ ký, kiểm tra quyền, revision, transaction rollback và lỗi an toàn.
- Flutter Web release build đạt với cấu hình public cùng nguồn API; không dùng secret backend trong bundle.
- Đã xem ảnh widget với font thật ở 390×844 sáng, 320×640 tối với chữ 200%, và 844×390 ngang với chữ 200%; editor được kiểm tra khi bàn phím chiếm 250 px. Đây là fixture kiểm thử, chưa phải ảnh từ Safari hoặc backend triển khai.

Ảnh tham khảo: [điện thoại sáng](ui/v11-lyrics-light-390.png), [điện thoại nhỏ, chữ lớn](ui/v11-lyrics-dark-320.png), [màn hình ngang](ui/v11-lyrics-landscape.png).
