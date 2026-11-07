// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appName => 'SoundShare';

  @override
  String get brandTagline => 'Âm nhạc kết nối cảm xúc';

  @override
  String get home => 'Trang chủ';

  @override
  String get explore => 'Khám phá';

  @override
  String get library => 'Thư viện';

  @override
  String get profile => 'Cá nhân';

  @override
  String get manageAccount => 'Quản lý tài khoản';

  @override
  String get accountOpenFailed =>
      'Chưa thể mở quản lý tài khoản. Hãy thử lại hoặc đăng nhập lại.';

  @override
  String get back => 'Quay lại';

  @override
  String get cancel => 'Hủy';

  @override
  String get tryAgain => 'Thử lại';

  @override
  String get browseAll => 'Xem tất cả';

  @override
  String get uploadMusic => 'Tải nhạc lên';

  @override
  String get uploadTrack => 'Tải bài hát lên';

  @override
  String get exploreMusic => 'Khám phá âm nhạc';

  @override
  String get exploreTracks => 'Khám phá bài hát';

  @override
  String get yourTracks => 'Nhạc của bạn';

  @override
  String get privateBadge => 'THƯ VIỆN RIÊNG';

  @override
  String get demoBadge => 'CHẾ ĐỘ NGHE THỬ';

  @override
  String get demo => 'Nghe thử';

  @override
  String get demoNotice => 'Nhạc mẫu · Chỉ dùng để trải nghiệm giao diện';

  @override
  String trackCount(int count) {
    return '$count bài hát';
  }

  @override
  String countSongs(int count) {
    return '$count bài hát';
  }

  @override
  String likedCount(int count) {
    return '$count bài hát yêu thích';
  }

  @override
  String sampleCount(int count) {
    return '$count bài hát mẫu';
  }

  @override
  String artworkFor(String title) {
    return 'Ảnh bìa của $title';
  }

  @override
  String get albumArtwork => 'Ảnh bìa bài hát';

  @override
  String playSong(String title) {
    return 'Phát $title';
  }

  @override
  String get homeGreeting => 'Chào bạn,';

  @override
  String get homeTitle => 'Khám phá thế giới\nâm nhạc của bạn';

  @override
  String get homeSubtitle => 'Một khoảng riêng. Những giai điệu ở lại.';

  @override
  String get listenNow => 'Nghe ngay';

  @override
  String get homeEmptyTitle => 'Giai điệu đầu tiên đang chờ bạn';

  @override
  String get homeEmptyDemo => 'Nhạc mẫu sẽ xuất hiện tại đây khi sẵn sàng.';

  @override
  String get homeEmptyReal =>
      'Tải MP3 đầu tiên để bắt đầu thư viện âm nhạc riêng.';

  @override
  String get genreCollections => 'Một sắc màu, một cảm xúc';

  @override
  String get collectionsDemoSubtitle => 'Bộ sưu tập mẫu · Nhóm theo thể loại';

  @override
  String get collectionsRealSubtitle => 'Nhóm nhạc của bạn theo thể loại';

  @override
  String get newUploads => 'Bài hát mới';

  @override
  String get songsDemoCaption => 'Nhạc mẫu · Các bài sử dụng audio nghe thử.';

  @override
  String get songsPrivateCaption =>
      'Nhạc đã tải lên · Chỉ tài khoản của bạn truy cập được';

  @override
  String get exploreTitle => 'Khám phá';

  @override
  String get exploreSubtitleDemo =>
      'Tìm giai điệu qua thể loại, bộ sưu tập hay tên bài. Đây là nhạc mẫu.';

  @override
  String get exploreSubtitleReal =>
      'Tìm lại những giai điệu trong thư viện riêng của bạn.';

  @override
  String get searchLabel => 'Tìm kiếm âm nhạc';

  @override
  String get searchHint => 'Bạn muốn nghe gì hôm nay?';

  @override
  String get clearSearch => 'Xóa tìm kiếm';

  @override
  String get clearSearchHistory => 'Xóa lịch sử';

  @override
  String searchShortcut(String shortcut) {
    return 'Nhấn $shortcut để tìm kiếm';
  }

  @override
  String get combinedFilters => 'Các lựa chọn được kết hợp với nhau';

  @override
  String get clearAll => 'Xóa bộ lọc';

  @override
  String get searchFailed => 'Chưa thể tìm kiếm';

  @override
  String get searchFailureMessage =>
      'Bộ lọc của bạn được giữ lại. Hãy thử lại khi có kết nối.';

  @override
  String get browseGenres => 'Khám phá thể loại';

  @override
  String get allGenres => 'Tất cả thể loại';

  @override
  String get removeUnknownGenre => 'Bỏ thể loại không còn sẵn có';

  @override
  String get collectionsDemo => 'Bộ sưu tập mẫu';

  @override
  String get collectionsReal => 'Bộ sưu tập của bạn';

  @override
  String get collectionsHint => 'Một lối nghe khác, qua những nhóm thể loại.';

  @override
  String get allCollections => 'Tất cả bộ sưu tập';

  @override
  String get unknownCollection => 'Bộ sưu tập không còn sẵn có';

  @override
  String get removeUnknownCollection => 'Bỏ bộ sưu tập không còn sẵn có';

  @override
  String resultsCount(int count) {
    return 'Tìm thấy $count bài hát';
  }

  @override
  String get catalogDemo => 'Kho nhạc mẫu';

  @override
  String get collectionUnavailable => 'Bộ sưu tập này không còn sẵn có';

  @override
  String get collectionQuiet => 'Bộ sưu tập đang chờ giai điệu mới';

  @override
  String get noResults => 'Không tìm thấy kết quả';

  @override
  String get collectionEmptyDemo =>
      'Chưa có nhạc mẫu trong nhóm này. Thử bộ sưu tập khác hoặc xem tất cả bài hát.';

  @override
  String get collectionEmptyReal =>
      'Chưa có bản nhạc tải lên trong nhóm này. Thử bộ sưu tập khác hoặc xem tất cả bài hát.';

  @override
  String get noResultsHint =>
      'Thử thể loại khác, đổi bộ sưu tập hoặc xóa từ khóa.';

  @override
  String get browseAllTracks => 'Xem tất cả bài hát';

  @override
  String get sampleEmpty => 'Kho nhạc mẫu đang trống';

  @override
  String get libraryEmpty => 'Thư viện của bạn đang trống';

  @override
  String get uploadToDiscover =>
      'Tải MP3 đầu tiên để khám phá bộ sưu tập của chính bạn.';

  @override
  String get softFocusTitle => 'Góc dịu êm';

  @override
  String get softFocusDescription =>
      'Dream pop và Indie folk, dành cho những phút chậm lại.';

  @override
  String get afterHoursTitle => 'Khi đêm về';

  @override
  String get afterHoursDescription =>
      'Alternative và Electronic, những âm sắc của đêm.';

  @override
  String get loadingLibrary => 'Đang tải thư viện nhạc';

  @override
  String get catalogLoadFailed => 'Âm nhạc đang chờ kết nối';

  @override
  String get catalogLoadFailedMessage =>
      'Chưa tải được thư viện. Kiểm tra kết nối và thử lại.';

  @override
  String get nowPlaying => 'Đang phát';

  @override
  String get backToBrowsing => 'Thu nhỏ trình phát';

  @override
  String get nothingToPlay => 'Chọn một giai điệu để bắt đầu';

  @override
  String get nothingToPlayDescription =>
      'Mở một bài hát trong thư viện để bắt đầu nghe nhạc.';

  @override
  String get unlikeSong => 'Bỏ yêu thích bài hát';

  @override
  String get likeSong => 'Yêu thích bài hát';

  @override
  String get likeSaveFailed => 'Chưa lưu được lượt thích. Hãy thử lại.';

  @override
  String get playbackPosition => 'Tiến trình phát nhạc';

  @override
  String playbackPositionValue(String elapsed, String total) {
    return '$elapsed trên $total';
  }

  @override
  String get previousTrack => 'Bài trước';

  @override
  String get nextTrack => 'Bài tiếp theo';

  @override
  String get loadingAudio => 'Đang tải âm thanh';

  @override
  String get pauseTrack => 'Tạm dừng';

  @override
  String get playTrack => 'Phát nhạc';

  @override
  String get resumeTrack => 'Tiếp tục phát';

  @override
  String get shuffle => 'Phát ngẫu nhiên';

  @override
  String get shuffleOn => 'Đang phát ngẫu nhiên';

  @override
  String get repeat => 'Lặp lại';

  @override
  String get repeatOn => 'Đang lặp lại bài hát';

  @override
  String get sampleAudioNotice => 'Nhạc mẫu · Audio dùng để nghe thử';

  @override
  String get privateLibraryNotice => 'Nhạc riêng của bạn';

  @override
  String get playbackUnavailable => 'Chưa thể phát nhạc';

  @override
  String get audioLoadFailed =>
      'Chưa phát được bài hát. Kiểm tra kết nối và thử lại.';

  @override
  String get openPlayer => 'Mở trình phát';

  @override
  String get libraryTitle => 'Thư viện của bạn';

  @override
  String get librarySubtitle =>
      'Không gian riêng cho những giai điệu bạn muốn nghe lại.';

  @override
  String get libraryEyebrow => 'BỘ SƯU TẬP CÁ NHÂN';

  @override
  String get likedTracks => 'Yêu thích';

  @override
  String get allUploads => 'Nhạc đã tải lên';

  @override
  String get sampleCatalog => 'Nhạc mẫu';

  @override
  String get librarySavedPrivate => 'Được lưu riêng trong tài khoản của bạn';

  @override
  String get librarySavedSession =>
      'Lượt thích chỉ được lưu trong phiên nghe thử';

  @override
  String get libraryEmptyTitle => 'Thư viện của bạn đang trống';

  @override
  String get libraryEmptyMessage =>
      'Tải lên bản nhạc đầu tiên để bắt đầu không gian âm nhạc của bạn.';

  @override
  String get favoritesEmptyTitle => 'Tìm giai điệu bạn yêu thích';

  @override
  String get favoritesEmptyMessage =>
      'Chạm biểu tượng trái tim khi nghe để lưu bài hát tại đây.';

  @override
  String get libraryPrivacyNote =>
      'Nhạc và lượt thích thuộc riêng tài khoản của bạn.';

  @override
  String get demoLibraryNote =>
      'Đây là nhạc mẫu. Lượt thích chỉ tồn tại trong phiên này.';

  @override
  String get uploadTitle => 'Chia sẻ âm nhạc';

  @override
  String get uploadEyebrow => 'ÂM THANH CỦA BẠN';

  @override
  String get uploadSubtitle => 'Lưu bản nhạc của bạn vào thư viện riêng.';

  @override
  String get uploadDemoSubtitle =>
      'Tạo bản xem trước trên thiết bị. Không gửi file lên máy chủ.';

  @override
  String get uploadAudioStep => 'Chọn bản nhạc';

  @override
  String get chooseMp3 => 'Chọn file MP3';

  @override
  String get mp3Limit => 'MP3 · Tối đa 20 MB';

  @override
  String get changeFile => 'Đổi file';

  @override
  String get uploadDetailsStep => 'Thông tin bài hát';

  @override
  String get songTitle => 'Tên bài hát';

  @override
  String get titleHint => 'Đặt tên cho giai điệu của bạn';

  @override
  String get artistName => 'Tên nghệ sĩ';

  @override
  String get artistHint => 'Ai tạo nên bản nhạc này?';

  @override
  String get genre => 'Thể loại';

  @override
  String get otherGenre => 'Khác';

  @override
  String get descriptionOptional => 'Mô tả (không bắt buộc)';

  @override
  String get descriptionHint => 'Câu chuyện phía sau bản nhạc';

  @override
  String get uploadArtworkStep => 'Ảnh bìa';

  @override
  String get artworkHint => 'JPG, PNG hoặc WebP · Tối đa 5 MB';

  @override
  String get addArtwork => 'Thêm ảnh bìa';

  @override
  String get artworkOptional => 'Ảnh bìa không bắt buộc';

  @override
  String get uploadButton => 'Tải bài hát lên';

  @override
  String get uploadBusy => 'Đang xử lý bản nhạc. Vui lòng giữ trang này mở…';

  @override
  String get openingFile => 'Đang mở file…';

  @override
  String get uploadSaved => 'Đã lưu vào thư viện riêng';

  @override
  String get openLibrary => 'Mở thư viện';

  @override
  String get previewButton => 'Xem trước thông tin';

  @override
  String get previewReady => 'Bản xem trước đã sẵn sàng';

  @override
  String get previewNotice => 'File chỉ có trên thiết bị và chưa được tải lên.';

  @override
  String get mp3Invalid => 'Chọn file MP3 không rỗng, tối đa 20 MB.';

  @override
  String get artworkInvalid => 'Chọn ảnh JPG, PNG hoặc WebP tối đa 5 MB.';

  @override
  String get fileOpenError => 'Không mở được file. Vui lòng chọn lại.';

  @override
  String get mp3Required => 'Hãy chọn file MP3 trước.';

  @override
  String get titleRequired => 'Hãy nhập tên bài hát.';

  @override
  String get artistRequired => 'Hãy nhập tên nghệ sĩ.';

  @override
  String get uploadFailed =>
      'Chưa lưu được bản nhạc. Hãy thử lại với file đã chọn.';

  @override
  String get uploadPrivateTitle => 'Chỉ dành cho bạn';

  @override
  String get uploadPrivateMessage =>
      'Nhạc được lưu trong thư viện riêng. Bạn chỉ nên tải nội dung mình có quyền sử dụng.';

  @override
  String get profileTitle => 'Cá nhân';

  @override
  String get profileEyebrow => 'KHÔNG GIAN CỦA BẠN';

  @override
  String get profileSubtitle => 'Âm nhạc riêng, cảm xúc riêng.';

  @override
  String get guestName => 'Khách nghe thử';

  @override
  String get accountName => 'Người yêu nhạc';

  @override
  String get profilePrivateNote =>
      'Nhạc tải lên và lượt thích được lưu trong tài khoản riêng của bạn.';

  @override
  String get profileDemoNote =>
      'Bạn đang khám phá nhạc mẫu. Lượt thích chỉ được lưu trong phiên này.';

  @override
  String get yourMusic => 'Âm nhạc của bạn';

  @override
  String get yourUploads => 'Nhạc đã tải lên';

  @override
  String get yourFavorites => 'Bài hát yêu thích';

  @override
  String get profileLibraryHint => 'Trở lại những giai điệu bạn đã lưu';

  @override
  String get profileUploadHint => 'Thêm MP3 và ảnh bìa vào thư viện';

  @override
  String get accountSection => 'Tài khoản';

  @override
  String get accountProvider => 'Được bảo vệ bởi Clerk';

  @override
  String get accountProviderNote =>
      'Đăng nhập và phiên tài khoản do Clerk quản lý.';

  @override
  String get profilePrivacyTitle => 'Khoảng riêng cho âm nhạc';

  @override
  String get profilePrivacyMessage =>
      'Bài hát của bạn chưa được công khai. Hồ sơ nghệ sĩ và người theo dõi chưa được hỗ trợ.';

  @override
  String get signIn => 'Đăng nhập';

  @override
  String get authTagline => 'Âm nhạc kết nối cảm xúc.';

  @override
  String get authHeadline => 'Không gian âm nhạc của riêng bạn.';

  @override
  String get authDescription =>
      'Khám phá, chia sẻ và kết nối cùng những người yêu âm nhạc.';

  @override
  String get authContinue => 'Đăng nhập hoặc tạo tài khoản';

  @override
  String get signUp => 'Tạo tài khoản';

  @override
  String get signOut => 'Đăng xuất';

  @override
  String get signingOut => 'Đang đăng xuất…';

  @override
  String get signOutFailed => 'Chưa đăng xuất được. Hãy thử lại.';

  @override
  String get welcomeBack => 'Chào mừng trở lại';

  @override
  String get signInSubtitle => 'Đăng nhập để tiếp tục hành trình âm nhạc';

  @override
  String get signInPrivateNote =>
      'Một khoảng riêng cho MP3, ảnh bìa và những bài hát bạn yêu thích.';

  @override
  String get secureAccountNote =>
      'Clerk bảo vệ tài khoản, xác minh email và khôi phục mật khẩu cho bạn.';

  @override
  String get loadingSignIn => 'Đang mở đăng nhập';

  @override
  String get signInLoadFailed =>
      'Chưa mở được đăng nhập. Kiểm tra kết nối và thử lại.';

  @override
  String get openingLibrary => 'Đang mở thư viện';

  @override
  String get verifyingSession => 'Đang kết nối tài khoản của bạn…';

  @override
  String get libraryOpenFailed => 'Chưa mở được thư viện. Hãy thử lại.';

  @override
  String get signInNotConfigured =>
      'Đăng nhập chưa được cấu hình cho bản ứng dụng này.';

  @override
  String get sessionInvalid =>
      'Chưa xác minh được phiên tài khoản. Vui lòng đăng nhập lại.';

  @override
  String get sessionTimeout =>
      'Mở thư viện mất quá lâu. Kiểm tra kết nối và thử lại.';

  @override
  String get errorAlreadySaved =>
      'MP3 này đã được lưu với thông tin khác. Hãy chọn file khác.';

  @override
  String get errorFileTooLarge => 'File vượt quá dung lượng cho phép.';

  @override
  String get errorFileType => 'Định dạng hoặc nội dung file chưa được hỗ trợ.';

  @override
  String get errorRateLimit =>
      'Bạn thao tác quá nhanh. Hãy đợi một lát rồi thử lại.';

  @override
  String get errorInvalidDetails => 'Kiểm tra lại file và thông tin bài hát.';

  @override
  String get errorNotFound => 'Bài hát hoặc file này không còn sẵn có.';

  @override
  String get errorBusy => 'File đang được xử lý. Hãy đợi một lát rồi thử lại.';

  @override
  String get errorConnection =>
      'Chưa thực hiện được yêu cầu. Kiểm tra kết nối và thử lại.';

  @override
  String get backendVerifying => 'Đang xác minh tài khoản';

  @override
  String get backendNotVerified => 'Tài khoản chưa được xác minh';

  @override
  String get backendVerified => 'Tài khoản đã được xác minh';

  @override
  String get languageVietnamese => 'Tiếng Việt';

  @override
  String get privateListening => 'KHÔNG GIAN ÂM NHẠC';

  @override
  String clerkALengthOfBetweenMINAndMAX(int min, int max) {
    return 'độ dài từ $min đến $max ký tự';
  }

  @override
  String clerkALengthOfMINOrGreater(int min) {
    return 'ít nhất $min ký tự';
  }

  @override
  String get clerkALowercaseLetter => 'một chữ thường';

  @override
  String get clerkANumber => 'một chữ số';

  @override
  String clerkASpecialCharacter(String chars) {
    return 'một ký tự đặc biệt ($chars)';
  }

  @override
  String get clerkAbandoned => 'đã hủy';

  @override
  String get clerkAcceptTerms =>
      'Tôi đồng ý với Điều khoản dịch vụ và Chính sách quyền riêng tư';

  @override
  String get clerkActive => 'đang hoạt động';

  @override
  String get clerkAddAccount => 'Thêm tài khoản';

  @override
  String get clerkAddDomain => 'Thêm tên miền';

  @override
  String get clerkAddEmailAddress => 'Thêm địa chỉ email';

  @override
  String get clerkAddPasskey => 'Thêm khóa truy cập';

  @override
  String get clerkAddPhoneNumber => 'Thêm số điện thoại';

  @override
  String get clerkAlreadyHaveAnAccount => 'Bạn đã có tài khoản?';

  @override
  String get clerkAnUppercaseLetter => 'một chữ hoa';

  @override
  String get clerkAnd => 'và';

  @override
  String get clerkAreYouSure => 'Bạn có chắc chắn?';

  @override
  String get clerkAuthenticationServiceError =>
      'Chưa kết nối được dịch vụ xác thực. Vui lòng thử lại.';

  @override
  String get clerkAuthenticatorApp => 'ứng dụng xác thực';

  @override
  String get clerkAutomaticInvitation => 'Lời mời tự động';

  @override
  String get clerkAutomaticSuggestion => 'Đề xuất tự động';

  @override
  String get clerkBack => 'Quay lại';

  @override
  String get clerkBackupCode => 'mã dự phòng';

  @override
  String get clerkCancel => 'Hủy';

  @override
  String get clerkCannotDeleteSelf => 'Bạn không có quyền xóa tài khoản này';

  @override
  String clerkClickOnTheLinkThatsBeenSentTo(String identifier) {
    return 'Mở liên kết đã gửi đến $identifier, sau đó quay lại đây';
  }

  @override
  String get clerkClickOnTheLinkThatsBeenSentToYou =>
      'Mở liên kết đã gửi cho bạn, sau đó quay lại đây';

  @override
  String get clerkComplete => 'đã hoàn tất';

  @override
  String get clerkConnectAccount => 'Liên kết tài khoản';

  @override
  String get clerkConnectedAccounts => 'Tài khoản đã liên kết';

  @override
  String get clerkCont => 'Tiếp tục';

  @override
  String get clerkCreateOrganization => 'Tạo tổ chức';

  @override
  String get clerkCreated => 'Đã tạo';

  @override
  String get clerkDevelopmentMode => 'Chế độ phát triển';

  @override
  String get clerkDidntReceiveCode => 'Bạn chưa nhận được mã?';

  @override
  String get clerkDomainName => 'Tên miền';

  @override
  String get clerkDontHaveAnAccount => 'Bạn chưa có tài khoản?';

  @override
  String get clerkEdit => 'chỉnh sửa';

  @override
  String get clerkEmailAddress => 'địa chỉ email';

  @override
  String get clerkEmailAddressConcise => 'email';

  @override
  String get clerkEmailAddresses => 'Địa chỉ email';

  @override
  String get clerkEnrollment => 'Tham gia';

  @override
  String get clerkEnrollmentMode => 'Phương thức tham gia:';

  @override
  String get clerkEnterOneOfYourBackupCodes =>
      'Nhập một trong các mã dự phòng của bạn';

  @override
  String get clerkEnterTheCodeFromYourAuthenticatorApp =>
      'Nhập mã từ ứng dụng xác thực của bạn';

  @override
  String clerkEnterTheCodeSentTo(String identifier) {
    return 'Nhập mã đã gửi đến $identifier';
  }

  @override
  String get clerkEnterTheCodeSentToYou => 'Nhập mã đã gửi cho bạn';

  @override
  String get clerkEnterTheCodeSentToYouByEmail => 'Nhập mã đã gửi qua email';

  @override
  String get clerkEnterTheCodeSentToYouByTextMessage =>
      'Nhập mã đã gửi qua tin nhắn';

  @override
  String get clerkEnterYourOrganizationDetailsToContinue =>
      'Nhập thông tin tổ chức để tiếp tục';

  @override
  String get clerkEnterYourPassword => 'Nhập mật khẩu của bạn';

  @override
  String get clerkExpired => 'đã hết hạn';

  @override
  String get clerkExternalError =>
      'Chưa hoàn tất được xác thực. Vui lòng thử lại.';

  @override
  String get clerkFailed => 'không thành công';

  @override
  String get clerkFirstName => 'tên';

  @override
  String get clerkForgottenPassword => 'Bạn quên mật khẩu?';

  @override
  String get clerkGeneralDetails => 'Thông tin chung';

  @override
  String clerkInvalidEmailAddress(String address) {
    return 'Địa chỉ email không hợp lệ: $address';
  }

  @override
  String clerkInvalidPhoneNumber(String number) {
    return 'Số điện thoại không hợp lệ: $number';
  }

  @override
  String get clerkJoin => 'THAM GIA';

  @override
  String get clerkJwtPoorlyFormatted =>
      'Phiên xác thực không hợp lệ. Vui lòng đăng nhập lại.';

  @override
  String get clerkLastName => 'họ';

  @override
  String get clerkLastUsed => 'Lần sử dụng gần nhất';

  @override
  String get clerkLeave => 'Rời khỏi';

  @override
  String clerkLeaveOrg(String organization) {
    return 'Rời khỏi $organization';
  }

  @override
  String get clerkLeaveOrganization => 'Rời khỏi tổ chức';

  @override
  String get clerkLegalAcceptanceRequired =>
      'Bạn cần đồng ý với các điều khoản để tiếp tục đăng ký';

  @override
  String get clerkLoading => 'Đang tải…';

  @override
  String get clerkLogo => 'Biểu tượng';

  @override
  String get clerkLongDateFormat => 'HH:mm, dd/MM/yyyy';

  @override
  String get clerkManualInvitation => 'Lời mời trực tiếp';

  @override
  String get clerkMissingRequirements => 'cần bổ sung thông tin';

  @override
  String get clerkMyOrganization => 'Tổ chức của tôi';

  @override
  String get clerkName => 'Tên';

  @override
  String get clerkNeedsFirstFactor => 'cần xác minh bước đầu';

  @override
  String get clerkNeedsIdentifier => 'cần thông tin đăng nhập';

  @override
  String get clerkNeedsSecondFactor => 'cần xác minh bước hai';

  @override
  String get clerkNewPassword => 'Mật khẩu mới';

  @override
  String get clerkNewPasswordConfirmation => 'Xác nhận mật khẩu mới';

  @override
  String clerkNoAssociatedCodeRetrievalMethod(String arg) {
    return 'Không tìm thấy phương thức nhận mã cho $arg';
  }

  @override
  String clerkNoAssociatedStrategy(String arg) {
    return 'Không tìm thấy phương thức xác thực cho $arg';
  }

  @override
  String get clerkNoInitialCodeHasBeenSetUpToResend =>
      'Chưa có mã xác minh để gửi lại';

  @override
  String clerkNoSessionFoundForUser(String arg) {
    return 'Không tìm thấy phiên đăng nhập của $arg';
  }

  @override
  String get clerkNoSessionTokenRetrieved => 'Chưa nhận được phiên xác thực';

  @override
  String clerkNoStageForStatus(String arg) {
    return 'Không tìm thấy bước xác thực cho trạng thái $arg';
  }

  @override
  String clerkNoSuchFirstFactorStrategy(String arg) {
    return 'Phương thức $arg không hỗ trợ xác minh bước đầu';
  }

  @override
  String clerkNoSuchSecondFactorStrategy(String arg) {
    return 'Phương thức $arg không hỗ trợ xác minh bước hai';
  }

  @override
  String clerkNoUserAttributeForField(String arg) {
    return 'Không tìm thấy thông tin tài khoản cho trường $arg';
  }

  @override
  String get clerkOk => 'Đồng ý';

  @override
  String get clerkOptional => '(không bắt buộc)';

  @override
  String get clerkOr => 'hoặc';

  @override
  String get clerkOrganizationProfile => 'Hồ sơ tổ chức';

  @override
  String get clerkOrganizations => 'Tổ chức';

  @override
  String get clerkPasskey => 'khóa truy cập';

  @override
  String get clerkPasskeys => 'Khóa truy cập';

  @override
  String get clerkPassword => 'Mật khẩu';

  @override
  String get clerkPasswordConfirmation => 'xác nhận mật khẩu';

  @override
  String get clerkPasswordMatchError =>
      'Mật khẩu xác nhận phải trùng với mật khẩu';

  @override
  String get clerkPasswordMustBeSupplied => 'Hãy nhập mật khẩu';

  @override
  String get clerkPasswordRequires => 'Mật khẩu cần có:';

  @override
  String get clerkPending => 'đang chờ';

  @override
  String get clerkPersonalAccount => 'Tài khoản cá nhân';

  @override
  String get clerkPhoneNumber => 'số điện thoại';

  @override
  String get clerkPhoneNumberConcise => 'điện thoại';

  @override
  String get clerkPhoneNumbers => 'Số điện thoại';

  @override
  String get clerkPleaseAddRequiredInformation =>
      'Hãy bổ sung các thông tin bắt buộc còn thiếu';

  @override
  String get clerkPleaseChooseAnAccountToConnect =>
      'Chọn tài khoản bạn muốn liên kết';

  @override
  String get clerkPleaseEnterYourIdentifier =>
      'Nhập thông tin đăng nhập của bạn';

  @override
  String get clerkPrimary => 'CHÍNH';

  @override
  String get clerkPrivacyPolicy => 'Chính sách quyền riêng tư';

  @override
  String get clerkProfile => 'Cá nhân';

  @override
  String get clerkProfileDetails => 'Thông tin cá nhân';

  @override
  String get clerkRecommendSize =>
      'Nên dùng ảnh vuông, dung lượng tối đa 5 MB.';

  @override
  String get clerkRequiredField => '(bắt buộc)';

  @override
  String get clerkRequiredFieldsAreMissing => 'Cần điền các trường bắt buộc';

  @override
  String get clerkResend => 'Gửi lại';

  @override
  String get clerkResetFailed =>
      'Chưa đặt lại được mật khẩu. Một mã mới đã được gửi.';

  @override
  String get clerkResetPassword => 'Đặt lại mật khẩu và đăng nhập';

  @override
  String get clerkSelectAccount => 'Chọn tài khoản để tiếp tục';

  @override
  String get clerkSendMeTheCode => 'Gửi mã đặt lại mật khẩu';

  @override
  String clerkServerErrorResponse(String arg) {
    return 'Máy chủ trả về lỗi: $arg';
  }

  @override
  String get clerkSetUpYourOrganization => 'Thiết lập tổ chức của bạn';

  @override
  String get clerkSignIn => 'Đăng nhập';

  @override
  String get clerkSignInByCodeSentToYourEmail => 'Gửi mã đến email của bạn';

  @override
  String clerkSignInByEmailCode(String arg) {
    return 'Gửi mã đến email $arg';
  }

  @override
  String clerkSignInByEmailLink(String arg) {
    return 'Gửi liên kết đến email $arg';
  }

  @override
  String get clerkSignInByEnteringOneOfYourBackupCodes => 'Dùng mã dự phòng';

  @override
  String get clerkSignInByLinkSentToYourEmail =>
      'Gửi liên kết đến email của bạn';

  @override
  String clerkSignInBySMSCode(String arg) {
    return 'Gửi mã SMS đến $arg';
  }

  @override
  String get clerkSignInBySMSCodeToYourPhone => 'Gửi mã đến điện thoại của bạn';

  @override
  String clerkSignInTo(String name) {
    return 'Đăng nhập vào $name';
  }

  @override
  String get clerkSignInUsingEnterpriseSSO =>
      'Đăng nhập qua SSO của doanh nghiệp';

  @override
  String get clerkSignInUsingYourAuthenticatorApp => 'Dùng ứng dụng xác thực';

  @override
  String get clerkSignInWithOneOfYourBackupCodes =>
      'Dùng một trong các mã dự phòng';

  @override
  String get clerkSignOut => 'Đăng xuất';

  @override
  String clerkSignOutIdentifier(String identifier) {
    return 'Đăng xuất $identifier';
  }

  @override
  String get clerkSignOutOfAllAccounts => 'Đăng xuất tất cả tài khoản';

  @override
  String get clerkSignUp => 'Đăng ký';

  @override
  String clerkSignUpTo(String name) {
    return 'Đăng ký vào $name';
  }

  @override
  String get clerkSlug => 'Tên định danh';

  @override
  String get clerkSlugUrl => 'Đường dẫn định danh';

  @override
  String get clerkSwitchTo => 'Chuyển sang';

  @override
  String get clerkTermsOfService => 'Điều khoản dịch vụ';

  @override
  String get clerkTooManyRetries => 'Máy chủ đang bận. Vui lòng thử lại sau.';

  @override
  String get clerkTransferable => 'có thể chuyển tiếp';

  @override
  String get clerkTwoStepVerification => 'Xác minh hai bước';

  @override
  String clerkTypeTypeInvalid(String type) {
    return 'Loại $type không hợp lệ';
  }

  @override
  String get clerkUnknownError =>
      'Đã xảy ra lỗi khi xác thực. Vui lòng thử lại.';

  @override
  String clerkUnsupportedPasswordResetStrategy(String arg) {
    return 'Chưa hỗ trợ phương thức đặt lại mật khẩu: $arg';
  }

  @override
  String get clerkUnverified => 'chưa xác minh';

  @override
  String get clerkUsePasskeyInstead => 'Dùng khóa truy cập';

  @override
  String get clerkUsername => 'tên đăng nhập';

  @override
  String get clerkVerificationEmailAddress => 'Xác minh địa chỉ email';

  @override
  String get clerkVerificationPhoneNumber => 'Xác minh số điện thoại';

  @override
  String get clerkVerified => 'đã xác minh';

  @override
  String get clerkVerifiedDomains => 'Tên miền đã xác minh';

  @override
  String get clerkVerifyThisDevice => 'Xác minh thiết bị này';

  @override
  String get clerkVerifyYourEmailAddress => 'Xác minh địa chỉ email của bạn';

  @override
  String get clerkVerifyYourPhoneNumber => 'Xác minh số điện thoại của bạn';

  @override
  String get clerkViaAutomaticInvitation => 'qua lời mời tự động';

  @override
  String get clerkViaAutomaticSuggestion => 'qua đề xuất tự động';

  @override
  String get clerkViaManualInvitation => 'qua lời mời trực tiếp';

  @override
  String get clerkWeb3Wallet => 'ví Web3';

  @override
  String get clerkWelcomeBackPleaseSignInToContinue =>
      'Chào mừng trở lại! Đăng nhập để tiếp tục';

  @override
  String get clerkWelcomePleaseFillInTheDetailsToGetStarted =>
      'Chào bạn! Điền thông tin để bắt đầu';

  @override
  String get v3UploadCancelled =>
      'Đã ngừng gửi. Tệp máy chủ đã nhận trước đó có thể vẫn được giữ riêng tư; chưa xác nhận lưu bài hát.';

  @override
  String get v3LibrarySearch => 'Tìm trong thư viện của bạn';

  @override
  String get v3ImageReady => 'Ảnh mới đã sẵn sàng';

  @override
  String get v3Working => 'Đang xử lý…';

  @override
  String get v3Sending => 'Đang gửi dữ liệu';

  @override
  String get v3Confirming => 'Đang chờ máy chủ xác nhận lưu bài hát…';

  @override
  String get search => 'Tìm kiếm';

  @override
  String get v3Recent => 'Tiếp tục nghe';

  @override
  String get v3Genres => 'Khám phá thể loại';

  @override
  String get v3Editorial => 'NHỮNG THANH ÂM CÓ CÂU CHUYỆN';

  @override
  String get v3HomeTitle => 'Mở một thế giới nghe mới.';

  @override
  String get v3HomeSubtitle =>
      'Bản thu độc lập. Những người sáng tạo. Một nơi để tìm thấy nhau.';

  @override
  String get v3DiscoverTitle => 'Đi tìm thanh âm của bạn.';

  @override
  String get v3DiscoverSubtitle =>
      'Khám phá những bản thu được chia sẻ công khai trên SoundShare.';

  @override
  String get v3Trending => 'Đang được lắng nghe';

  @override
  String get v3TrendingNote =>
      'Xếp hạng thử nghiệm từ lượt nghe hợp lệ, người nghe, lượt thích và lưu trong cùng khoảng thời gian. Ngày tính theo giờ Việt Nam.';

  @override
  String get v3Creators => 'Những gương mặt nổi bật';

  @override
  String get v3NewCreators => 'Nghệ sĩ mới đáng nghe';

  @override
  String get v3NewReleases => 'Mới được chia sẻ';

  @override
  String get v3FollowingFeed => 'Từ người bạn theo dõi';

  @override
  String get v3ForYou => 'Dành riêng cho bạn';

  @override
  String get v3RecommendationNote =>
      'Khám phá những bản thu công khai trong cộng đồng SoundShare.';

  @override
  String get recommendationPersonalized =>
      'Gợi ý từ lịch sử nghe, bài đã thích/lưu và tài khoản bạn theo dõi, có xét thói quen nghe theo thời điểm.';

  @override
  String get recommendationNewListener =>
      'Bắt đầu với các bản thu mới. Nghe, thích, lưu và theo dõi để gợi ý dần phù hợp với bạn.';

  @override
  String recommendationListeningTimeGenre(String genre, String daypart) {
    return 'Bạn hay nghe $genre $daypart';
  }

  @override
  String get recommendationListeningTime => 'Từ thói quen nghe theo thời điểm';

  @override
  String get recommendationAtNight => 'ban đêm';

  @override
  String get recommendationInMorning => 'buổi sáng';

  @override
  String get recommendationInAfternoon => 'buổi chiều';

  @override
  String get recommendationInEvening => 'buổi tối';

  @override
  String recommendationLikedGenre(String genre) {
    return '$genre từ những bài bạn thích';
  }

  @override
  String get recommendationLikedGenreFallback => 'Cùng thể loại bài bạn thích';

  @override
  String get recommendationListeningHistory => 'Từ những bài bạn đã nghe';

  @override
  String get recommendationFollowing => 'Từ người bạn theo dõi';

  @override
  String recommendationSavedGenre(String genre) {
    return '$genre từ những bài bạn lưu';
  }

  @override
  String get recommendationSavedGenreFallback => 'Cùng thể loại bài bạn lưu';

  @override
  String get recommendationNewRelease => 'Bản thu mới để bạn khám phá';

  @override
  String get v3SearchHint => 'Bài hát hoặc @username';

  @override
  String get v3SearchIntro => 'Một cái tên. Một thanh âm mới.';

  @override
  String get v3SearchDescription =>
      'Nhập @username để tìm người sáng tạo, hoặc tìm tên bài hát và nghệ sĩ.';

  @override
  String get v3All => 'Tất cả';

  @override
  String get v3Songs => 'Bài hát';

  @override
  String get v3Accounts => 'Tài khoản';

  @override
  String get v3Playlists => 'Playlist';

  @override
  String get v3RecentSearches => 'Tìm kiếm gần đây';

  @override
  String get v3SearchPrivacy =>
      'Chỉ lưu trong phiên này; đăng xuất sẽ xóa lịch sử tìm kiếm.';

  @override
  String get v3NoContent => 'Chưa có nội dung ở đây';

  @override
  String get v3NoContentDescription =>
      'Hãy thử tìm một người sáng tạo hoặc chia sẻ bản thu đầu tiên của bạn.';

  @override
  String get v3Follow => 'Theo dõi';

  @override
  String get v3Unfollow => 'Bỏ theo dõi';

  @override
  String get v3Following => 'Đang theo dõi';

  @override
  String get v3Followers => 'Người theo dõi';

  @override
  String get v3ShareProfile => 'Sao chép liên kết hồ sơ';

  @override
  String get v3Copied => 'Đã sao chép liên kết hồ sơ';

  @override
  String get v3About => 'Giới thiệu';

  @override
  String get v3EditProfile => 'Chỉnh sửa hồ sơ';

  @override
  String get v3CreateProfile => 'Tạo hồ sơ SoundShare';

  @override
  String get v3ProfileIntro =>
      'Chọn tên công khai để người nghe có thể tìm thấy bạn. Hồ sơ này tách biệt với thông tin đăng nhập Clerk.';

  @override
  String get v3Username => 'Username công khai';

  @override
  String get v3UsernamePolicy =>
      '3–24 ký tự: a–z, số, dấu chấm và gạch dưới; không có dấu chấm ở đầu/cuối. Không dùng tên dành riêng.';

  @override
  String get v3DisplayName => 'Tên hiển thị';

  @override
  String get v3Bio => 'Đôi dòng về bạn';

  @override
  String get v3Avatar => 'Đổi ảnh đại diện';

  @override
  String get v3Cover => 'Đổi ảnh bìa';

  @override
  String get v3Save => 'Lưu thay đổi';

  @override
  String get v3Saved => 'Đã lưu';

  @override
  String get v3Public => 'Công khai';

  @override
  String get v3Private => 'Riêng tư';

  @override
  String get v3Visibility => 'Ai có thể nghe?';

  @override
  String get v3Rights =>
      'Tôi có quyền chia sẻ công khai bản thu và ảnh bìa này.';

  @override
  String get v3RightsRequired =>
      'Cần xác nhận quyền sử dụng nội dung trước khi chia sẻ công khai.';

  @override
  String get v3PublicHint =>
      'Bài công khai xuất hiện trong Khám phá và hồ sơ của bạn. Bài riêng tư chỉ bạn có thể nghe.';

  @override
  String get v3ManageSongs => 'Quản lý bài hát';

  @override
  String get v3EditSong => 'Sửa thông tin bài hát';

  @override
  String get v3DeleteSong => 'Xóa bài hát';

  @override
  String get v3DeleteConfirm =>
      'Bài hát sẽ được gỡ khỏi thư viện và các trang khám phá. Bạn muốn tiếp tục?';

  @override
  String get v3Cancel => 'Hủy';

  @override
  String get v3Delete => 'Xóa';

  @override
  String get v3SaveTrack => 'Lưu vào bộ sưu tập';

  @override
  String get v3RemoveSaved => 'Bỏ lưu bài hát';

  @override
  String get v3SavedTracks => 'Bài hát đã lưu';

  @override
  String get v3AddToPlaylist => 'Thêm vào playlist';

  @override
  String get v3CreatePlaylist => 'Tạo playlist';

  @override
  String get v3PlaylistTitle => 'Tên playlist';

  @override
  String get v3RemoveFromPlaylist => 'Bỏ khỏi playlist';

  @override
  String get v3DeletePlaylist => 'Xóa playlist';

  @override
  String get v3More => 'Tải thêm';

  @override
  String get v3PreviousPage => 'Trang trước';

  @override
  String get v3Today => 'Hôm nay';

  @override
  String get v3Week => '7 ngày';

  @override
  String get v3Month => '30 ngày';

  @override
  String get v3AllTime => 'Mọi thời điểm';

  @override
  String get v3Featured => 'Nổi bật';

  @override
  String get v3Newest => 'Mới tham gia';

  @override
  String get v3Popular => 'Nhiều người theo dõi';

  @override
  String get v3Growing => 'Đang phát triển';

  @override
  String get v3Report => 'Báo cáo nội dung';

  @override
  String get v3ReportReceived =>
      'Đã ghi nhận báo cáo để xem xét. Nội dung chưa tự động bị gỡ.';

  @override
  String get v3Copyright => 'Quyền sử dụng nội dung';

  @override
  String get v3Abuse => 'Nội dung không phù hợp';

  @override
  String get v3Spam => 'Spam';

  @override
  String get v3Other => 'Lý do khác';

  @override
  String get v3Queue => 'Danh sách phát';

  @override
  String get v3AddToQueue => 'Thêm vào danh sách phát';

  @override
  String get v3RemoveFromQueue => 'Bỏ khỏi danh sách phát';

  @override
  String get v3QueueEmpty => 'Chọn một bài hát để bắt đầu danh sách phát.';

  @override
  String get v3UsernameTaken =>
      'Username này đã có người sử dụng. Hãy chọn tên khác.';

  @override
  String get v3ProfileRequired =>
      'Hãy tạo hồ sơ SoundShare và chọn username trước khi đăng bài công khai.';

  @override
  String get v3InvalidProfile => 'Kiểm tra username và các thông tin đã nhập.';

  @override
  String get v3Unavailable =>
      'Chưa tải được nội dung. Kiểm tra kết nối và thử lại.';

  @override
  String get v3Views => 'lượt nghe hợp lệ';

  @override
  String get v3Likes => 'lượt thích';

  @override
  String get v4Greeting => 'Hôm nay, nghe gì?';

  @override
  String get v4Featured => 'Tâm điểm hôm nay';

  @override
  String get v4HomeIntro => 'Bản thu độc lập. Kết nối qua âm nhạc.';

  @override
  String get v4QuickAccess => 'Không gian của bạn';

  @override
  String get v4SeeAll => 'Xem tất cả';

  @override
  String get v4Volume => 'Âm lượng';

  @override
  String get v4CloseQueue => 'Đóng danh sách phát';

  @override
  String get v4OpenPlayer => 'Mở trình phát nhạc';

  @override
  String get v4ExploreIntro => 'Âm nhạc và những người tạo nên nó';

  @override
  String get v4Community => 'CỘNG ĐỒNG ÂM NHẠC';

  @override
  String get v4PlayAll => 'Phát tất cả';

  @override
  String get v4ShufflePlay => 'Phát ngẫu nhiên';

  @override
  String get v4PlaylistPage =>
      'Các thao tác phát áp dụng cho trang bài hát đang hiển thị.';

  @override
  String get v4ProfileCover => 'Không gian âm nhạc của người sáng tạo';

  @override
  String get v4SearchIntro => 'Tìm âm nhạc. Gặp người cùng gu.';

  @override
  String get v4Browse => 'Bắt đầu khám phá';

  @override
  String get v4Charts => 'Bảng xếp hạng';

  @override
  String get v4Tracks => 'Bản thu';

  @override
  String get v4ListenNext => 'Tiếp theo trong danh sách';

  @override
  String get v4EmptyTitle => 'Một không gian cho bản thu tiếp theo';

  @override
  String v4FeaturedPosition(int position, int total) {
    return 'Nội dung nổi bật $position/$total';
  }

  @override
  String get playerReorder => 'Kéo để đổi thứ tự phát';

  @override
  String get playerLyrics => 'Lời bài hát';

  @override
  String get playerLyricsUnavailable => 'Chưa có lời bài hát cho bản thu này.';

  @override
  String get playerRecordHint =>
      'Chạm hai lần để thích hoặc bỏ thích. Vuốt ngang để chuyển bài.';

  @override
  String get playerSleepTimer => 'Hẹn giờ dừng nhạc';

  @override
  String get playerSleepDescription =>
      'Nhạc sẽ tạm dừng khi hết thời gian đã chọn.';

  @override
  String playerSleepUntil(String time) {
    return 'Dừng nhạc lúc $time';
  }

  @override
  String playerMinutes(int minutes) {
    return '$minutes phút';
  }

  @override
  String get playerCancelTimer => 'Hủy hẹn giờ';

  @override
  String get playerAddedToQueue => 'Đã thêm vào danh sách phát.';

  @override
  String get themeAppearance => 'Giao diện';

  @override
  String get themeLight => 'Sáng';

  @override
  String get themeDark => 'Tối';

  @override
  String get themeDarkMode => 'Giao diện tối';

  @override
  String get themeSystem => 'Theo hệ thống';

  @override
  String get themeSaveFailed =>
      'Đã đổi giao diện nhưng chưa lưu được lựa chọn trên thiết bị. Hãy thử lại.';
}
