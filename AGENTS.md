# Hướng dẫn cho tác nhân làm việc trong SoundShare

Các quy tắc trong file này áp dụng cho toàn bộ repository. Trước khi sửa mã nguồn hoặc kiến trúc, hãy đọc `README.md`, `DESIGN.md` và `PRD.md`.

## Kiến trúc sản phẩm

- Ứng dụng client dùng Flutter/Dart. Backend mục tiêu dùng Node.js + Express và cung cấp REST API có version tại `/api/v1`.
- Cơ sở dữ liệu quan hệ là Neon PostgreSQL. Luồng dữ liệu bắt buộc: **Flutter → Express REST API → Neon**. Flutter tuyệt đối không kết nối trực tiếp Neon.
- Authentication và Cloud Storage là các dịch vụ độc lập với Neon và với nhau. Provider cụ thể chỉ được thêm sau khi có quyết định cấu hình; không tự suy đoán rằng một provider đã được chọn.
- Client có thể dùng SDK của Authentication provider để đăng nhập và nhận token. Client gọi Express với Bearer token; Express phải xác minh token phía server.
- Audio và artwork được lưu trong Cloud Storage. Neon chỉ lưu metadata và object key; không lưu byte của file hoặc URL ký tạm thời.
- Backend và các tích hợp trên là kiến trúc mục tiêu. Chỉ mô tả tính năng là đã hoạt động khi mã nguồn và môi trường chạy chứng minh điều đó.

## Ranh giới bảo mật Neon

- Neon connection string, gồm `DATABASE_URL`, chỉ được đọc trong backend từ secret manager hoặc biến môi trường của môi trường chạy.
- Không đặt connection string, password, host riêng tư hay thông tin kết nối trong Flutter, file cấu hình client, tài liệu công khai, log, thông báo lỗi hoặc phản hồi API.
- Không commit `.env`, secret, token, bản dump dữ liệu, log chứa thông tin nhạy cảm hoặc file cấu hình môi trường thật. Chỉ dùng placeholder trong `.env.example`.
- Bật TLS khi kết nối, ưu tiên pooled connection phù hợp môi trường serverless của Neon và dùng role có quyền tối thiểu cần thiết.
- Tách cấu hình development, test và production. Không dùng database production cho test hoặc thử migration.
- Không in toàn bộ cấu hình hoặc lỗi driver ra log nếu chúng có thể chứa connection string hay dữ liệu người dùng.

## Quy tắc API Node.js/Express

- Đặt endpoint dưới `/api/v1`; dùng HTTP method và status code theo ngữ nghĩa REST. JSON request/response phải có cấu trúc nhất quán.
- Tách route, controller, service, repository, middleware và schema validation; không đặt SQL hay nghiệp vụ phức tạp trực tiếp trong route hoặc UI Flutter.
- Validation mọi input ở server: body, query, path parameter, header và metadata file. Dùng schema rõ ràng, giới hạn độ dài, kích thước, page size và giá trị enum.
- Xác thực token trước khi xử lý endpoint riêng tư. Mặc định từ chối truy cập; chỉ endpoint được đánh dấu công khai mới bỏ qua authentication.
- Tính owner từ identity đã xác minh ở server. Không tin `userId`, role, owner hoặc object key do client khai báo để quyết định quyền.
- Kiểm tra authorization trên từng tài nguyên và từng hành động. Trả `401` khi thiếu/sai identity; `403` khi identity hợp lệ nhưng không có quyền; không tiết lộ tài nguyên riêng của người khác.
- Dùng middleware xử lý lỗi tập trung. Trả error code ổn định, thông điệp an toàn và `requestId`; không trả stack trace, SQL, secret hoặc thông tin nội bộ.
- Thêm rate limit và giới hạn payload cho endpoint nhạy cảm, đặc biệt là đăng nhập, tìm kiếm và upload intent. Không ghi token hoặc dữ liệu cá nhân vào log.
- Cập nhật API contract trong `PRD.md` khi thay đổi endpoint, schema, mã lỗi, phân quyền hoặc luồng dữ liệu.

## Authentication và authorization

- Authentication provider độc lập chịu trách nhiệm đăng ký, đăng nhập, làm mới và thu hồi phiên theo cấu hình đã chọn.
- Express phải xác minh chữ ký và các claim bắt buộc như issuer, audience và thời hạn bằng cấu hình tin cậy/JWKS của provider. Không chỉ decode JWT rồi coi token là hợp lệ.
- Dùng `sub` từ token đã xác minh làm subject; ánh xạ subject sang hồ sơ ứng dụng bằng backend.
- Không lưu mật khẩu trong Neon, không tự chế thuật toán xác thực và không tin role/permission từ payload chưa được xác minh.
- Không trả access token, refresh token hoặc provider secret trong log/API response ngoài giao thức Authentication tương ứng.

## SQL, schema và migration

- Mọi truy vấn SQL phải tham số hóa. Không nối chuỗi input người dùng vào SQL; không nhận table/column/order expression tùy ý từ client.
- Truy cập Neon qua repository/backend. Dùng transaction khi một thao tác cập nhật nhiều bản ghi cần tính nguyên tử.
- Schema cần khóa chính, khóa ngoại, unique/check constraint và index phù hợp; kiểm tra truy vấn tìm kiếm và phân trang với dữ liệu có kích thước thực tế.
- Mọi thay đổi schema phải có migration được version hóa, có thứ tự chạy rõ ràng và được rà soát. Cập nhật schema, repository, API contract và test liên quan cùng nhau.
- Migration không được âm thầm xóa dữ liệu hoặc phá tương thích production. Với thay đổi phá hủy, cần kế hoạch chuyển đổi và phê duyệt trước khi thực thi.
- Không đưa audio, artwork, binary lớn, signed URL hoặc dữ liệu phiên vào bảng Neon. Lưu object key và metadata cần thiết.

## Upload audio và Cloud Storage

- Dùng bucket private theo mặc định. Client chỉ upload trực tiếp bằng URL ký ngắn hạn do backend cấp cho đúng user, object và thao tác.
- Backend tự sinh object key; không dùng nguyên văn path do client gửi và không cho client ghi đè object của user khác.
- Kiểm tra quyền sở hữu upload intent, trạng thái upload, dung lượng, phần mở rộng, MIME type và chữ ký nội dung file (magic bytes) ở server. Không chỉ tin `Content-Type` từ client.
- Theo phạm vi MVP hiện tại, chỉ nhận MP3 tối đa 20 MB; server phải kiểm tra giới hạn cuối cùng dù Flutter đã kiểm tra trước.
- Khi hoàn tất, backend xác minh object thật sự tồn tại và khớp upload intent trước khi ghi song metadata vào Neon. Dùng thao tác idempotent để retry không tạo dữ liệu trùng.
- Chỉ phát hành URL đọc có thời hạn sau khi kiểm tra visibility và quyền. Không lưu URL ký làm URL cố định hoặc công khai bucket để né authorization.
- Xử lý upload thất bại/hủy bằng trạng thái rõ ràng và dọn object tạm theo chính sách. Không báo thành công trước khi Storage và Neon hoàn tất theo luồng đã định.
- Kiểm tra quyền sử dụng nội dung theo chính sách sản phẩm trước khi công khai bài hát.

## Kiểm thử backend

- Viết unit test cho service, validation và xử lý trạng thái; giả lập Authentication provider, Cloud Storage và các phụ thuộc ngoài khi phù hợp.
- Integration test dùng database biệt lập/test branch hoặc PostgreSQL test riêng, không kết nối production. Xác nhận migration chạy được từ schema rỗng.
- Bao phủ các trường hợp: thiếu/sai/hết hạn token, truy cập chéo user, validation và giới hạn phân trang, SQL injection input, lỗi Neon, lỗi Storage, upload sai loại/quá dung lượng, retry và hoàn tất upload lặp lại.
- Kiểm tra status code, error code, không rò rỉ secret và dữ liệu của user khác trong mọi lỗi.
- Dùng fixture nhỏ, không chứa nhạc có bản quyền hoặc dữ liệu thật. Dọn tài nguyên test sau khi chạy.
- Không yêu cầu hay dùng thông tin đăng nhập production trong test. Không chạy migration hoặc test phá hủy trên database production.

## Quy trình thay đổi

- Giữ thay đổi tập trung theo tính năng; không xóa hoặc ghi đè tài liệu/dữ liệu người dùng không liên quan.
- Không thêm dependency hoặc provider mới nếu chưa cần; cập nhật lockfile theo công cụ quản lý package khi có thay đổi dependency.
- Với thay đổi backend, cập nhật test và API contract. Với thay đổi luồng UI, cập nhật `DESIGN.md` hoặc `PRD.md` khi nội dung sản phẩm thay đổi.
- Trước khi hoàn tất, tóm tắt file đã sửa, kiểm tra đã chạy và các phần vẫn còn là kế hoạch/mock. Không tuyên bố backend đã kết nối nếu chưa được triển khai và xác minh.
