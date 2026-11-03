PRD — SoundShare
Product Requirements Document
Phiên bản: 1.0
Trạng thái: Draft
Sản phẩm: SoundShare
Nền tảng ứng dụng: Flutter (mobile)
Backend: Node.js + Express, cung cấp REST API
Cơ sở dữ liệu: Neon PostgreSQL
Authentication: dịch vụ xác thực độc lập, provider sẽ được chọn riêng
Cloud Storage: dịch vụ lưu trữ object độc lập, provider sẽ được chọn riêng

1. Tổng quan sản phẩm
   SoundShare là ứng dụng âm nhạc hướng đến trải nghiệm khám phá, nghe và chia sẻ âm nhạc. Ứng dụng tập trung đưa việc nghe nhạc từ một hoạt động cá nhân thành trải nghiệm có thể khám phá và chia sẻ với người khác.

Người dùng có thể khám phá các bài hát, tìm kiếm nội dung âm nhạc, nghe nhạc qua trình phát, quản lý thư viện cá nhân, tải nội dung lên (theo phạm vi tính năng được hỗ trợ) và quản lý hồ sơ cá nhân.

PRD này mô tả mục tiêu sản phẩm, người dùng, phạm vi chức năng và tiêu chí nghiệm thu để đội ngũ phát triển hoặc AI contributor hiểu SoundShare giải quyết vấn đề gì, phục vụ ai và cần xây dựng những hành vi nào.
1.3 Kiến trúc mục tiêu

- Ứng dụng Flutter chỉ giao tiếp với backend Node.js/Express qua REST API HTTPS; Flutter không kết nối trực tiếp đến Neon PostgreSQL.
- Backend Express xác thực access token từ dịch vụ Authentication độc lập, áp dụng nghiệp vụ và phân quyền, rồi mới truy cập Neon.
- Audio và artwork được lưu tại Cloud Storage độc lập. Neon chỉ lưu metadata, trạng thái và object key; không lưu nội dung nhị phân của file.
- Provider cụ thể cho Authentication và Cloud Storage cần được quyết định trước khi triển khai tích hợp. Hiện tại ứng dụng vẫn dùng dữ liệu mẫu; các tích hợp này chưa được xem là đã hoàn thành.
- Chuỗi kết nối Neon chỉ tồn tại trong môi trường backend dưới dạng secret, không được gửi tới ứng dụng Flutter, repository, log hay phản hồi API.
1.1 Tuyên bố sản phẩm
Giúp người yêu âm nhạc dễ dàng khám phá, nghe, lưu trữ và chia sẻ trải nghiệm âm nhạc trong một ứng dụng có giao diện trực quan, nhất quán và thuận tiện trên thiết bị di động.
1.2 Vấn đề cần giải quyết
Trải nghiệm âm nhạc thường bị chia nhỏ giữa nhiều thao tác và khu vực: tìm bài hát, xem nội dung được đề xuất, phát nhạc, quay lại bài đang nghe và quản lý danh sách yêu thích. Điều này có thể khiến người dùng mất thời gian và khó duy trì một không gian âm nhạc cá nhân thống nhất.

SoundShare hướng đến giải quyết các vấn đề sau:

- Khó khám phá nội dung phù hợp: người dùng cần một nơi để duyệt và tìm bài hát một cách thuận tiện.
- Gián đoạn trải nghiệm nghe: người dùng cần truy cập nhanh trình phát và bài hát hiện tại khi chuyển giữa các màn hình.
- Khó quản lý nội dung cá nhân: người dùng cần một khu vực tập trung để truy cập thư viện âm nhạc của mình.
- Thiếu một luồng chia sẻ/tải nội dung rõ ràng: người dùng cần một quy trình dễ hiểu để đưa nội dung âm nhạc vào trải nghiệm SoundShare và chia sẻ nội dung khi tính năng được hỗ trợ.
  Các vấn đề trên là định hướng sản phẩm dựa trên cấu trúc ứng dụng hiện tại. Mức độ ưu tiên và các giả định về hành vi chia sẻ cần được xác thực thêm với người dùng thực tế.

2. Mục tiêu sản phẩm
   2.1 Mục tiêu chính
1. Cung cấp trải nghiệm khám phá và tìm kiếm âm nhạc đơn giản.
1. Cho phép người dùng phát nhạc và điều khiển việc nghe một cách thuận tiện.
1. Cung cấp thư viện cá nhân để người dùng truy cập lại nội dung đã lưu.
1. Tạo nền tảng cho việc tải lên và chia sẻ nội dung âm nhạc.
1. Duy trì trải nghiệm nhất quán giữa các màn hình, với trình phát mini có thể truy cập nhanh.
   2.2 Kết quả mong đợi

- Người dùng có thể tìm thấy một bài hát và bắt đầu phát với ít thao tác.
- Người dùng có thể chuyển giữa Home, Explore, Library và Profile mà không mất ngữ cảnh bài hát đang phát.
- Người dùng nhận biết rõ trạng thái phát nhạc, tải nội dung và các thao tác chính.
- Giao diện có trạng thái tải, rỗng, lỗi và thành công rõ ràng.
- Kiến trúc cho phép bổ sung backend, xác thực và lưu trữ nội dung mà không phải thay đổi toàn bộ trải nghiệm.
  2.3 Ngoài mục tiêu
  SoundShare không mặc định đặt mục tiêu trở thành:
- Một nền tảng phân phối nhạc thương mại quy mô lớn.
- Một mạng xã hội tổng quát ngoài phạm vi nội dung âm nhạc.
- Một công cụ chỉnh sửa, phối khí hoặc sản xuất âm thanh chuyên nghiệp.
- Một dịch vụ cung cấp quyền sử dụng mọi bản ghi âm có bản quyền.

3. Người dùng mục tiêu
   Các nhóm dưới đây là persona giả định ban đầu, cần được kiểm chứng bằng nghiên cứu người dùng.
   3.1 Người nghe nhạc thường xuyên

- Nghe nhạc trong thời gian rảnh, học tập, làm việc hoặc di chuyển.
- Muốn mở ứng dụng và tiếp tục nghe nhanh chóng.
- Cần tìm kiếm, khám phá và lưu lại bài hát yêu thích.
  Nhu cầu chính: tìm nhạc nhanh, phát ổn định và dễ quay lại nội dung đang nghe.
  3.2 Người thích khám phá âm nhạc
- Thường xuyên tìm kiếm bài hát hoặc nghệ sĩ mới.
- Muốn duyệt nội dung theo các khu vực khám phá.
- Cần thông tin và artwork đủ rõ để nhận diện nội dung.
  Nhu cầu chính: tìm kiếm thuận tiện và khám phá nội dung dễ dàng.
  3.3 Người đóng góp nội dung
- Muốn đưa nội dung âm nhạc của mình vào ứng dụng nếu được phép.
- Cần biết định dạng, thông tin bắt buộc và trạng thái xử lý khi tải lên.
  Nhu cầu chính: quy trình tải lên rõ ràng, có phản hồi lỗi và xác nhận kết quả.

4. Phạm vi sản phẩm
   4.1 Phạm vi chức năng hiện tại
   Dựa trên cấu trúc màn hình và mã nguồn hiện có, sản phẩm có các khu vực sau:
   Khu vực Mục đích
   Splash Hiển thị màn hình khởi động và chuyển vào ứng dụng
   Home Hiển thị nội dung âm nhạc để người dùng khám phá
   Explore Tìm kiếm và khám phá nội dung
   Player Phát nhạc và cung cấp điều khiển playback
   Upload Cung cấp luồng tải nội dung lên
   Library Truy cập nội dung âm nhạc cá nhân
   Profile Hiển thị và quản lý thông tin hồ sơ

Ứng dụng hiện sử dụng dữ liệu bài hát mẫu trong source code. Không được mặc định rằng backend, đăng nhập, đồng bộ dữ liệu hoặc tải file lên máy chủ đã hoàn thiện chỉ vì chúng xuất hiện trong định hướng kiến trúc hoặc README.
4.2 MVP — phiên bản khả dụng tối thiểu
MVP nên ưu tiên các luồng cốt lõi:

1. Mở ứng dụng và truy cập màn hình chính.
2. Duyệt danh sách bài hát.
3. Tìm kiếm bài hát.
4. Chọn bài hát và phát nhạc.
5. Điều khiển phát/tạm dừng và truy cập màn hình Player.
6. Duy trì mini-player khi điều hướng giữa các tab.
7. Xem thư viện cá nhân và hồ sơ.
8. Hiển thị trạng thái phù hợp khi chưa có dữ liệu hoặc xảy ra lỗi.
   4.3 Phạm vi cần xác nhận trước khi triển khai đầy đủ
   Các mục dưới đây là định hướng hoặc phụ thuộc backend, không được coi là tính năng đã hoàn tất:

- Đăng ký, đăng nhập, đăng xuất và khôi phục tài khoản.
- Đồng bộ thư viện giữa nhiều thiết bị.
- Upload file âm thanh thực tế lên cloud storage.
- Chia sẻ bài hát qua liên kết hoặc nền tảng bên ngoài.
- Theo dõi người dùng, hồ sơ công khai hoặc tương tác xã hội.
- Bình luận, lượt thích, playlist cộng tác.
- Đề xuất nhạc cá nhân hóa.
- Phân quyền, kiểm duyệt và xử lý báo cáo bản quyền.

5. Yêu cầu chức năng
   Mức ưu tiên:

- P0: bắt buộc cho trải nghiệm cốt lõi/MVP.
- P1: quan trọng, nên có trong phiên bản đầu.
- P2: có thể triển khai ở giai đoạn sau.
  FR-01 — Khởi động ứng dụng
  Ưu tiên: P0
- Ứng dụng hiển thị Splash khi khởi động.
- Sau khi khởi tạo, ứng dụng điều hướng đến khu vực chính.
- Không để người dùng mắc kẹt vô thời hạn trên màn hình khởi động.
- Nếu khởi tạo dữ liệu thất bại, cần có trạng thái lỗi hoặc cơ chế thử lại phù hợp.
  Tiêu chí nghiệm thu
- Khi mở ứng dụng thành công, người dùng có thể vào Home.
- Không xuất hiện màn hình trắng hoặc lỗi điều hướng không có thông báo.
  FR-02 — Khám phá trên Home
  Ưu tiên: P0
- Hiển thị nội dung âm nhạc có thể chọn.
- Mỗi mục nội dung cần thể hiện thông tin nhận diện tối thiểu, chẳng hạn tên bài hát, nghệ sĩ và artwork nếu có.
- Người dùng có thể chọn một bài hát để bắt đầu phát hoặc mở màn hình Player.
- Giao diện hỗ trợ trạng thái đang tải, không có dữ liệu và lỗi tải dữ liệu.
  Tiêu chí nghiệm thu
- Danh sách nội dung hiển thị rõ ràng.
- Chạm vào một bài hát thực hiện đúng hành động được thiết kế.
- Artwork lỗi hoặc thiếu không làm vỡ bố cục.
  FR-03 — Tìm kiếm và Explore
  Ưu tiên: P0
- Người dùng có thể nhập từ khóa tìm kiếm.
- Kết quả cần phản ánh từ khóa theo các trường dữ liệu được hỗ trợ, tối thiểu là tên bài hát; nghệ sĩ có thể được bổ sung.
- Người dùng có thể chọn kết quả để phát nhạc.
- Có trạng thái trước khi tìm kiếm, đang tìm kiếm, có kết quả, không có kết quả và lỗi.
  Tiêu chí nghiệm thu
- Có thể nhập, sửa và xóa từ khóa.
- Kết quả phù hợp với từ khóa theo quy tắc tìm kiếm đã triển khai.
- Trường hợp không có kết quả phải có thông báo dễ hiểu.
  FR-04 — Phát nhạc
  Ưu tiên: P0
- Người dùng có thể bắt đầu phát một bài hát được hỗ trợ.
- Player thể hiện tối thiểu tên bài hát, nghệ sĩ, artwork và trạng thái phát.
- Người dùng có thể phát/tạm dừng.
- Trạng thái giao diện phải đồng bộ với trạng thái playback thực tế.
- Lỗi phát nhạc cần được thông báo và không làm ứng dụng bị treo.
  Tiêu chí nghiệm thu
- Chọn bài hát hợp lệ sẽ khởi chạy playback.
- Nút phát/tạm dừng phản ánh đúng trạng thái.
- Khi phát lỗi, người dùng nhận được phản hồi phù hợp.
  FR-05 — Mini-player và điều hướng
  Ưu tiên: P0
- Mini-player hiển thị bài hát hiện tại khi có nội dung đang được chọn/phát theo thiết kế.
- Người dùng có thể mở Player từ mini-player.
- Mini-player được duy trì khi chuyển giữa các tab chính.
- Điều hướng không tự ý tạo nhiều phiên playback cho cùng một thao tác.
  Tiêu chí nghiệm thu
- Chuyển Home → Explore → Library không làm mất bài hát hiện tại.
- Chạm mini-player mở đúng Player.
- Trạng thái mini-player nhất quán với Player.
  FR-06 — Library
  Ưu tiên: P1
- Cung cấp khu vực truy cập nội dung âm nhạc cá nhân.
- Khi có dữ liệu, hiển thị danh sách hoặc các nhóm nội dung theo thiết kế.
- Khi chưa có dữ liệu, hiển thị empty state và hướng dẫn hành động tiếp theo.
- Không hiển thị dữ liệu cá nhân của người dùng khác.
  Tiêu chí nghiệm thu
- Library có trạng thái rỗng rõ ràng.
- Nội dung hiển thị đúng với nguồn dữ liệu của tài khoản/ngữ cảnh hiện tại.
  FR-07 — Upload
  Ưu tiên: P1
- Cung cấp điểm truy cập vào quy trình tải nội dung.
- Hướng dẫn người dùng cung cấp file và metadata cần thiết.
- Kiểm tra các trường bắt buộc và định dạng file được hỗ trợ.
- Ở kiến trúc mục tiêu, client chỉ tải file lên Cloud Storage bằng thông tin tạm thời do Express cấp; client không nhận thông tin xác thực dài hạn của Storage.
- Backend kiểm tra lại file và quyền sở hữu sau khi nhận thông báo hoàn tất; kiểm tra phía client không thay thế validation phía server.
- Hiển thị trạng thái đang xử lý, thành công hoặc thất bại.
- Không báo tải lên thành công nếu file chưa được lưu thành công ở nơi lưu trữ đích.
  Tiêu chí nghiệm thu
- Dữ liệu thiếu hoặc file không hợp lệ phải được giải thích.
- Người dùng có thể sửa thông tin và thử lại khi phù hợp.
- Trạng thái thành công chỉ xuất hiện sau khi thao tác được xác nhận.
  FR-08 — Profile
  Ưu tiên: P1
- Hiển thị thông tin hồ sơ sẵn có.
- Cung cấp các mục cài đặt hoặc hành động tài khoản nếu được hỗ trợ.
- Nếu chưa có xác thực, không giả lập trạng thái tài khoản đã đăng nhập.
- Các hành động chưa được triển khai phải được ẩn hoặc thể hiện rõ là chưa khả dụng.
  Tiêu chí nghiệm thu
- Profile không hiển thị thông tin tài khoản giả như dữ liệu thật.
- Trạng thái chưa đăng nhập/không có dữ liệu được xử lý rõ ràng.
  FR-09 — Chia sẻ nội dung
  Ưu tiên: P2 — cần xác nhận phạm vi
- Cho phép người dùng chia sẻ một bài hát hoặc nội dung âm nhạc bằng phương thức được sản phẩm hỗ trợ.
- Nội dung chia sẻ cần nhận diện được bài hát.
- Nếu sử dụng liên kết sâu, liên kết cần mở đúng nội dung hoặc có fallback hợp lý.
  Tiêu chí nghiệm thu
- Chỉ hiển thị hành động chia sẻ khi có phương thức chia sẻ thực sự hoạt động.
- Không tạo liên kết giả hoặc báo chia sẻ thành công khi hệ điều hành/dịch vụ chia sẻ trả về lỗi.

  FR-10 — Authentication và phiên người dùng
  Ưu tiên: P1
- Đăng ký, đăng nhập, đăng xuất và làm mới phiên được xử lý bởi dịch vụ Authentication độc lập, không lưu mật khẩu trong Neon.
- Ứng dụng gửi access token dạng Bearer tới REST API khi gọi chức năng cần đăng nhập.
- Express xác minh chữ ký, issuer, audience và thời hạn của token bằng cấu hình tin cậy phía server.
- Backend lấy định danh người dùng từ token đã xác minh; không tin `userId`, role hay owner do client tự gửi.
- Khi token hết hạn hoặc không hợp lệ, API trả lỗi xác thực có cấu trúc và ứng dụng yêu cầu đăng nhập lại phù hợp.
  Tiêu chí nghiệm thu
- API công khai không yêu cầu token; API riêng tư từ chối request thiếu token hoặc token sai.
- Người dùng chỉ đọc hoặc sửa hồ sơ, thư viện và upload thuộc tài khoản của mình.
- Không có mật khẩu, token hoặc secret trong log và mã nguồn client.

  FR-11 — REST API và dữ liệu catalog
  Ưu tiên: P1
- Flutter gọi API có version tại `/api/v1` qua HTTPS; API dùng JSON với tên trường thống nhất.
- API catalog hỗ trợ danh sách, tìm kiếm theo tiêu đề/nghệ sĩ, lấy chi tiết bài hát và phân trang có giới hạn.
- API chỉ trả trường cần thiết cho UI; URL playback là URL truy cập có thời hạn do backend/Storage cấp khi được phép.
- API trả status code và error code ổn định để client phân biệt lỗi xác thực, quyền truy cập, validation, không tìm thấy, giới hạn tốc độ và lỗi server.
  Tiêu chí nghiệm thu
- Kết quả tìm kiếm và phân trang ổn định, giới hạn page size ở phía server.
- Không có endpoint cho Flutter gửi SQL hoặc truy cập Neon trực tiếp.
- Dữ liệu cá nhân được lọc theo chủ sở hữu đã xác thực ở backend.

  FR-12 — Upload qua API và Cloud Storage
  Ưu tiên: P1
- Client tạo yêu cầu upload với metadata và thông tin file; Express xác thực người dùng và kiểm tra dữ liệu.
- Express cấp thông tin upload tạm thời có giới hạn cho Cloud Storage độc lập; file không đi vào Neon.
- Sau khi gửi file, client gọi API hoàn tất upload. Backend xác minh object, chủ sở hữu, loại và dung lượng file trước khi lưu metadata bài hát vào Neon.
- Upload có trạng thái rõ ràng như `pending`, `uploaded`, `processing`, `completed` hoặc `failed`; chỉ báo thành công sau khi backend xác nhận.
- MVP hỗ trợ MP3 tối đa 20 MB theo giao diện hiện tại; backend là nơi kiểm tra cuối cùng.
  Tiêu chí nghiệm thu
- URL upload hết hạn và chỉ dùng được cho object đã cấp cho upload đó.
- File không hợp lệ hoặc vượt giới hạn không tạo bài hát khả dụng.
- Request hoàn tất lặp lại không tạo bản ghi trùng hoặc trạng thái không nhất quán.

6. Luồng người dùng chính
   6.1 Luồng nghe nhạc
1. Người dùng mở SoundShare.
1. Ứng dụng hiển thị Home.
1. Người dùng chọn một bài hát.
1. Ứng dụng bắt đầu phát nhạc.
1. Mini-player xuất hiện hoặc cập nhật.
1. Người dùng có thể mở Player để điều khiển chi tiết.
1. Người dùng chuyển sang tab khác; trạng thái bài hát hiện tại vẫn được duy trì.
   6.2 Luồng tìm kiếm
1. Người dùng mở Explore.
1. Nhập tên bài hát hoặc từ khóa được hỗ trợ.
1. Ứng dụng hiển thị kết quả.
1. Người dùng chọn một kết quả.
1. Ứng dụng phát bài hát và cập nhật Player/mini-player.
   6.3 Luồng thư viện
1. Người dùng mở Library.
1. Ứng dụng tải nội dung thuộc thư viện hiện tại.
1. Nếu có nội dung, người dùng chọn để phát.
1. Nếu chưa có nội dung, ứng dụng hiển thị hướng dẫn để bắt đầu xây dựng thư viện.
   6.4 Luồng tải lên
1. Người dùng mở Upload.
1. Chọn file âm thanh được hỗ trợ.
1. Nhập hoặc xác nhận metadata bắt buộc.
1. Ứng dụng gửi metadata và thuộc tính file tới `POST /api/v1/uploads` cùng access token.
1. Express xác thực token, kiểm tra quyền và validation, tạo upload intent rồi trả URL ký có thời hạn.
1. Ứng dụng tải file trực tiếp lên Cloud Storage bằng URL ký và hiển thị tiến trình.
1. Ứng dụng gọi `POST /api/v1/uploads/{uploadId}/complete`; backend kiểm tra object thực tế, owner, loại và kích thước.
1. Backend ghi metadata vào Neon và trả trạng thái hoàn tất; chỉ lúc này ứng dụng mới báo thành công.
1. Nếu bước nào thất bại, ứng dụng hiển thị lỗi phù hợp và cho phép thử lại an toàn; không tạo song khả dụng từ upload chưa xác minh.
   6.5 Luồng xác thực và gọi API riêng tư
1. Người dùng đăng nhập hoặc đăng ký qua Authentication provider độc lập.
1. Provider trả access token và refresh token theo chính sách của provider.
1. Flutter giữ token theo cơ chế lưu trữ an toàn của nền tảng; không ghi token vào log.
1. Flutter gọi endpoint riêng tư qua HTTPS với `Authorization: Bearer <access-token>`.
1. Express xác minh chữ ký, issuer, audience, thời hạn và trạng thái token; lấy subject từ token đã xác minh.
1. Backend kiểm tra quyền trên tài nguyên, truy cập Neon qua repository/service phía server và trả dữ liệu tối thiểu cần thiết.
1. Khi token hết hạn, client refresh qua Authentication provider; nếu refresh thất bại, xóa phiên cục bộ và yêu cầu đăng nhập lại.
   6.6 Luồng catalog và tìm kiếm qua REST API
1. Flutter gọi `GET /api/v1/songs` với từ khóa, bộ lọc và `limit` hợp lệ.
1. Express kiểm tra query parameters, chuẩn hóa từ khóa và giới hạn phân trang.
1. Repository truy vấn Neon bằng câu lệnh tham số hóa, áp dụng điều kiện visibility và sort ổn định.
1. API trả danh sách metadata cùng `nextCursor`; không trả secret hoặc URL lưu trữ nội bộ.
1. Khi người dùng chọn bài, client lấy URL playback ngắn hạn theo quyền truy cập rồi truyền cho trình phát.
1. API lỗi được chuyển thành trạng thái loading/error/empty phù hợp trên giao diện.
7. Yêu cầu phi chức năng
   7.1 Hiệu năng

- Các màn hình chính cần hiển thị phản hồi nhanh, tránh thao tác bị treo.
- Tác vụ mạng hoặc xử lý file dài cần có loading/progress state.
- Artwork cần có placeholder và cơ chế cache phù hợp.
- Không tải hoặc giải mã đồng thời quá nhiều tài nguyên lớn nếu không cần thiết.
  7.2 Độ tin cậy
- Lỗi mạng, lỗi file và lỗi playback phải được xử lý có kiểm soát.
- Không làm mất trạng thái playback chỉ vì người dùng chuyển tab.
- Các thao tác bất đồng bộ cần tránh cập nhật UI sau khi màn hình/widget đã bị hủy.
  7.3 Khả năng sử dụng
- Các nút chính cần có nhãn hoặc biểu tượng dễ hiểu.
- Khu vực chạm phù hợp với thao tác trên thiết bị di động.
- Trạng thái loading, empty, error và success phải phân biệt được.
- Giao diện tuân thủ hệ thống thiết kế trong DESIGN.md.
  7.4 Khả năng bảo trì
- Tách biệt presentation, domain và data layer theo cấu trúc dự án.
- Tái sử dụng widget và theme thay vì tạo các biến thể không cần thiết.
- Không đặt logic nghiệp vụ phức tạp trực tiếp trong widget UI.
- State dùng chung cho playback cần có một nguồn sự thật nhất quán.
  7.5 Bảo mật và quyền riêng tư
- Không lưu secret/API key trong mã nguồn client.
- Flutter không được chứa Neon connection string, driver truy cập PostgreSQL hoặc logic SQL; mọi truy vấn Neon chỉ chạy trong backend.
- Neon connection string lấy từ secret/environment của backend, không commit, không log và không trả về trong API.
- Express phải xác minh token từ Authentication provider và kiểm tra quyền theo chủ sở hữu tài nguyên ở server.
- Dùng câu lệnh SQL tham số hóa; không ghép input người dùng trực tiếp vào SQL.
- URL ký của Cloud Storage phải giới hạn object, thao tác, content type khi khả thi và thời hạn; không lưu URL ký làm định danh lâu dài.
- Dữ liệu cá nhân cần được giới hạn theo tài khoản và quyền truy cập.
- Upload cần kiểm tra loại file, kích thước và quyền sử dụng nội dung theo chính sách sản phẩm.
- Không giả định client-side validation thay thế được kiểm tra phía server.
  7.6 Khả năng tiếp cận
- Đảm bảo độ tương phản văn bản và trạng thái đủ rõ.
- Các nút chỉ có icon cần semantic label.
- Không dùng màu sắc làm tín hiệu duy nhất cho trạng thái.
- Nội dung cần thích ứng với kích thước màn hình và cỡ chữ hệ thống trong phạm vi hỗ trợ.

8. Dữ liệu và tích hợp
   8.1 Thực thể dữ liệu cốt lõi đề xuất
   Các thực thể dưới đây là mô hình logic ban đầu. Tên bảng/cột vật lý sẽ được chốt trong schema PostgreSQL và migration.

| Thực thể | Trường chính đề xuất | Ghi chú |
|---|---|---|
| `user_profiles` | `id`, `auth_subject`, `display_name`, `avatar_object_key`, `bio`, `created_at`, `updated_at` | `auth_subject` ánh xạ tới định danh từ Authentication provider; không lưu mật khẩu. |
| `songs` | `id`, `owner_id`, `title`, `artist`, `description`, `genre`, `audio_object_key`, `artwork_object_key`, `duration_ms`, `status`, `visibility`, `created_at`, `updated_at` | Chỉ lưu metadata và object key, không lưu file hoặc signed URL. |
| `library_items` | `user_id`, `song_id`, `created_at` | Khóa duy nhất trên (`user_id`, `song_id`) để tránh lưu trùng yêu thích. |
| `uploads` | `id`, `user_id`, `object_key`, `original_file_name`, `content_type`, `size_bytes`, `status`, `error_code`, `created_at`, `updated_at` | Theo dõi tiến trình; object key được sinh ở backend, không nhận path tùy ý từ client. |
| `playlists` (giai đoạn sau) | `id`, `owner_id`, `title`, `description`, `visibility`, `created_at`, `updated_at` | Quan hệ bài hát nên được lưu bằng bảng liên kết riêng nếu triển khai. |
| `playlist_items` (giai đoạn sau) | `playlist_id`, `song_id`, `position`, `added_at` | Thứ tự bài hát có ràng buộc và khóa ngoại. |

Đây là mô hình khái niệm. Mọi thay đổi schema phải đi kèm migration có phiên bản và cập nhật API contract.

   8.2 Nguồn dữ liệu và ranh giới dịch vụ

- Flutter dùng mock repository cho tới khi backend REST API được triển khai; UI không kết nối trực tiếp Neon.
- Node.js + Express cung cấp REST API có version tại `/api/v1`, xác thực request, áp dụng nghiệp vụ và truy cập Neon PostgreSQL.
- Neon là nguồn dữ liệu quan hệ cho hồ sơ ứng dụng, catalog, thư viện và trạng thái upload. Chuỗi kết nối chỉ nằm ở backend.
- Authentication là dịch vụ riêng. Backend xác minh token ở mỗi request được bảo vệ và ánh xạ subject đã xác minh tới hồ sơ ứng dụng.
- Cloud Storage là dịch vụ riêng để lưu audio/artwork. API cấp quyền upload/download ngắn hạn; Neon chỉ lưu object key và metadata.
- Không xem tính năng nào là đã tích hợp cho tới khi code và môi trường chạy xác nhận hoạt động thực tế.

   8.3 Quy tắc dữ liệu

- Dùng UUID hoặc định danh ổn định do backend tạo; thời gian lưu dưới dạng UTC và truyền qua API theo ISO 8601.
- Ràng buộc khóa ngoại, unique và check phải bảo vệ tính toàn vẹn dữ liệu ở PostgreSQL.
- Lưu thời lượng bằng mili giây khi đã biết; cho phép chưa có thời lượng nếu metadata chưa được xử lý.
- Không lưu URL ký tạm trong Neon. Khi cần phát audio, API tạo URL mới theo quyền truy cập và thời hạn phù hợp.
- Tìm kiếm và phân trang phải được thực thi phía server; `limit` có giá trị mặc định và tối đa do backend quy định.
- Dữ liệu mẫu phải được phân biệt với dữ liệu thật; không dùng tài khoản hoặc bài hát giả để mô phỏng trạng thái đã xác thực.

   8.4 REST API đề xuất

Base URL: `/api/v1`. Tất cả endpoint dùng HTTPS và JSON, trừ thao tác truyền file trực tiếp tới URL ký của Cloud Storage. API trả lỗi theo cấu trúc ổn định:

The current Clerk integration also exposes `GET /api/v1/auth/me`. It requires a verified Clerk session token in the `Authorization: Bearer <session-token>` header and returns the authenticated Clerk user ID; it does not query or synchronize a user profile in Neon.

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Thông tin gửi lên chưa hợp lệ.",
    "details": [],
    "requestId": "..."
  }
}
```

Các endpoint cho giai đoạn backend:

| Method và endpoint | Xác thực | Mục đích |
|---|---|---|
| `GET /songs?query=&genre=&cursor=&limit=` | Không | Tìm kiếm/list catalog, phân trang cursor, giới hạn page size ở server. |
| `GET /songs/{songId}` | Theo visibility | Lấy metadata chi tiết bài hát. |
| `GET /songs/{songId}/playback` | Theo visibility/quyền | Nhận URL phát ngắn hạn hoặc thông tin playback được phép. |
| `GET /me` | Có | Lấy hồ sơ gắn với subject của token. |
| `PATCH /me` | Có | Cập nhật các trường hồ sơ được phép. |
| `GET /me/library?cursor=&limit=` | Có | Liệt kê thư viện của người dùng hiện tại. |
| `PUT /me/library/{songId}` | Có | Thêm bài hát vào thư viện; thao tác idempotent. |
| `DELETE /me/library/{songId}` | Có | Xóa bài hát khỏi thư viện của chính người dùng. |
| `GET /me/uploads?cursor=&limit=` | Có | Xem trạng thái các upload của người dùng hiện tại. |
| `POST /uploads` | Có | Validate metadata và tạo upload intent; trả `uploadId`, URL ký, method/header cần thiết và thời điểm hết hạn. |
| `POST /uploads/{uploadId}/complete` | Có | Xác minh object đã nhận rồi hoàn tất upload và tạo song metadata. |
| `DELETE /uploads/{uploadId}` | Có, owner | Hủy upload đang chờ và dọn object tạm nếu có. |

Đăng ký, đăng nhập, refresh và logout thuộc Authentication provider độc lập, không phải endpoint xử lý mật khẩu của Express. API có thể bổ sung endpoint sau khi thống nhất provider, schema và chính sách quyền.

9. Điều hướng và cấu trúc màn hình
   Các khu vực điều hướng chính hiện có:

- Home: /
- Explore: /explore
- Library: /library
- Profile: /profile
  Các màn hình/route chức năng khác:
- Splash: /splash
- Player: /player
- Upload: /upload
  Quy tắc trải nghiệm:
- Bốn tab chính là các điểm điều hướng cấp cao.
- Player và Upload là các luồng chức năng riêng, không thay thế tab chính.
- Mini-player là lối tắt tới nội dung đang nghe.
- Điều hướng phải giữ trạng thái phù hợp và tránh tạo back stack khó hiểu.

10. Chỉ số đánh giá thành công
    Các chỉ số dưới đây là đề xuất; cần có analytics và định nghĩa sự kiện trước khi đo.
    Mục tiêu Chỉ số
    Khám phá nhạc hiệu quả Tỷ lệ phiên có ít nhất một lượt chọn bài hát
    Tìm kiếm hữu ích Tỷ lệ tìm kiếm dẫn đến chọn kết quả
    Trải nghiệm nghe Số lượt phát thành công / số lượt bắt đầu phát
    Duy trì nghe nhạc Thời lượng nghe trung bình mỗi phiên
    Sử dụng thư viện Tỷ lệ người dùng quay lại Library
    Upload dễ sử dụng Tỷ lệ upload thành công / số lượt bắt đầu upload
    Ổn định ứng dụng Tỷ lệ phiên không crash và số lỗi playback

Không đặt mục tiêu số học cụ thể cho đến khi có baseline hoặc dữ liệu thử nghiệm. 11. Rủi ro và phụ thuộc

- Nguồn audio: URL mẫu có thể hết hạn, không truy cập được hoặc không phù hợp để phát hành.
- Bản quyền: cần xác định quyền lưu trữ, phát và chia sẻ nội dung âm nhạc.
- Backend: cần chốt Authentication provider và Cloud Storage provider; cần thiết kế Express REST API, schema Neon, migration, secret và chính sách quyền trước khi tích hợp production.
- Upload: URL ký, xác minh MIME/magic bytes, giới hạn kích thước, trạng thái retry và dọn object mồ côi cần được kiểm thử.
- Playback nền: phát nhạc khi ứng dụng ở background có thể cần cấu hình native và xử lý lifecycle riêng.
- Chất lượng mạng: tải audio/artwork phụ thuộc kết nối; cần cache và lỗi dự phòng.
- Phạm vi chia sẻ: cần quyết định SoundShare chia sẻ liên kết, file, playlist hay hồ sơ người dùng.
- Định nghĩa thư viện: cần chốt nội dung nào được xem là thuộc Library (bài đã lưu, bài upload, playlist hay lịch sử nghe).

12. Câu hỏi sản phẩm cần quyết định
    Các câu hỏi này cần được trả lời trước khi mở rộng phạm vi MVP:
1. SoundShare là ứng dụng nghe nhạc cá nhân có tính năng chia sẻ, hay là mạng xã hội âm nhạc nơi người dùng đăng tải và tương tác?
1. Người dùng có cần đăng nhập để nghe nhạc hay chỉ cần đăng nhập để lưu thư viện/upload?
1. Người dùng được upload file âm thanh của chính họ hay chỉ thêm liên kết đến nguồn nhạc?
1. Chia sẻ nghĩa là chia sẻ link bài hát, playlist, file audio hay hoạt động nghe nhạc?
1. Library bao gồm bài hát yêu thích, bài đã upload, playlist hay toàn bộ các loại trên?
1. Ứng dụng có cần hỗ trợ phát nhạc nền, điều khiển từ notification/lock screen và queue/playlist playback trong MVP không?
1. Nguồn nội dung âm nhạc và quy trình xử lý bản quyền được quản lý như thế nào?
1. Chọn dịch vụ Authentication nào và cách Express xác minh issuer/audience/JWKS ra sao?
1. Chọn Cloud Storage provider nào, bucket nào là private và thời hạn URL ký là bao lâu?
1. Backend chạy ở đâu, quản lý secret/migration theo môi trường như thế nào và API cần rate limit nào?
1. Hướng dẫn cho AI contributor
   Khi thực hiện yêu cầu liên quan đến SoundShare:
1. Đọc README.md, DESIGN.md và PRD này trước khi thay đổi kiến trúc hoặc UI.
1. Ưu tiên hành vi và phạm vi đã được xác nhận trong source code; không tự suy diễn rằng tính năng backend đã hoạt động.
1. Không tự thêm tính năng xã hội, thanh toán, subscription hoặc recommendation phức tạp nếu chưa có yêu cầu.
1. Giữ nhất quán với Flutter, Riverpod, GoRouter và các package hiện có; chỉ thay đổi khi có lý do kỹ thuật rõ ràng.
1. Kiến trúc backend mục tiêu là Node.js + Express REST API và Neon PostgreSQL; Flutter chỉ gọi API HTTPS, tuyệt đối không kết nối trực tiếp Neon.
1. Authentication và Cloud Storage là dịch vụ riêng; Express xác minh token và cấp quyền Storage tạm thời, không tự lưu mật khẩu hoặc file audio nhị phân trong Neon.
1. Mọi thay đổi schema phải có migration; mọi SQL phải tham số hóa; mọi API phải validation input và kiểm tra authorization phía server.
1. Không đưa Neon connection string, token, khóa Storage hoặc URL ký vào mã nguồn, phản hồi không cần thiết hay log.
1. Luồng upload phải kiểm tra file ở client lẫn server, xác minh object trước khi hoàn tất và chỉ báo thành công sau khi metadata được lưu.
1. Playback cần có nguồn trạng thái nhất quán giữa Player, mini-player và các màn hình khác.
1. Mọi trạng thái loading, empty, error và success đều cần được thiết kế.
1. Không hiển thị thông báo thành công trước khi thao tác thực sự hoàn tất.
1. Khi yêu cầu mơ hồ hoặc ảnh hưởng đến định nghĩa sản phẩm, nêu giả định và hỏi lại thay vì tự mở rộng scope.
1. Cập nhật tài liệu khi thay đổi luồng người dùng, phạm vi MVP hoặc quyết định sản phẩm.
1. Tóm tắt định hướng
   SoundShare cần trước hết làm tốt vòng lặp cốt lõi:

Khám phá nhạc → Chọn bài hát → Phát nhạc → Tiếp tục nghe khi điều hướng → Lưu và quay lại nội dung.

Home, Explore, Player, mini-player và Library là các thành phần quan trọng nhất của trải nghiệm MVP. Upload và chia sẻ là hướng mở rộng có giá trị, nhưng cần chốt rõ quy tắc nội dung, backend và bản quyền trước khi coi là năng lực hoàn chỉnh của sản phẩm.

PRD này là bản định hướng ban đầu dựa trên cấu trúc ứng dụng hiện tại; các giả định về đối tượng người dùng, mô hình chia sẻ và backend cần được xác thực trước khi phát triển production.
