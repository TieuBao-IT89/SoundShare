import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('vi')];

  /// No description provided for @appName.
  ///
  /// In vi, this message translates to:
  /// **'SoundShare'**
  String get appName;

  /// No description provided for @brandTagline.
  ///
  /// In vi, this message translates to:
  /// **'Âm nhạc kết nối cảm xúc'**
  String get brandTagline;

  /// No description provided for @home.
  ///
  /// In vi, this message translates to:
  /// **'Trang chủ'**
  String get home;

  /// No description provided for @explore.
  ///
  /// In vi, this message translates to:
  /// **'Khám phá'**
  String get explore;

  /// No description provided for @library.
  ///
  /// In vi, this message translates to:
  /// **'Thư viện'**
  String get library;

  /// No description provided for @profile.
  ///
  /// In vi, this message translates to:
  /// **'Cá nhân'**
  String get profile;

  /// No description provided for @manageAccount.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý tài khoản'**
  String get manageAccount;

  /// No description provided for @accountOpenFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể mở quản lý tài khoản. Hãy thử lại hoặc đăng nhập lại.'**
  String get accountOpenFailed;

  /// No description provided for @back.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get back;

  /// No description provided for @cancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get cancel;

  /// No description provided for @tryAgain.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get tryAgain;

  /// No description provided for @browseAll.
  ///
  /// In vi, this message translates to:
  /// **'Xem tất cả'**
  String get browseAll;

  /// No description provided for @uploadMusic.
  ///
  /// In vi, this message translates to:
  /// **'Tải nhạc lên'**
  String get uploadMusic;

  /// No description provided for @uploadTrack.
  ///
  /// In vi, this message translates to:
  /// **'Tải bài hát lên'**
  String get uploadTrack;

  /// No description provided for @exploreMusic.
  ///
  /// In vi, this message translates to:
  /// **'Khám phá âm nhạc'**
  String get exploreMusic;

  /// No description provided for @exploreTracks.
  ///
  /// In vi, this message translates to:
  /// **'Khám phá bài hát'**
  String get exploreTracks;

  /// No description provided for @yourTracks.
  ///
  /// In vi, this message translates to:
  /// **'Nhạc của bạn'**
  String get yourTracks;

  /// No description provided for @privateBadge.
  ///
  /// In vi, this message translates to:
  /// **'THƯ VIỆN RIÊNG'**
  String get privateBadge;

  /// No description provided for @demoBadge.
  ///
  /// In vi, this message translates to:
  /// **'CHẾ ĐỘ NGHE THỬ'**
  String get demoBadge;

  /// No description provided for @demo.
  ///
  /// In vi, this message translates to:
  /// **'Nghe thử'**
  String get demo;

  /// No description provided for @demoNotice.
  ///
  /// In vi, this message translates to:
  /// **'Nhạc mẫu · Chỉ dùng để trải nghiệm giao diện'**
  String get demoNotice;

  /// No description provided for @trackCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} bài hát'**
  String trackCount(int count);

  /// No description provided for @countSongs.
  ///
  /// In vi, this message translates to:
  /// **'{count} bài hát'**
  String countSongs(int count);

  /// No description provided for @likedCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} bài hát yêu thích'**
  String likedCount(int count);

  /// No description provided for @sampleCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} bài hát mẫu'**
  String sampleCount(int count);

  /// No description provided for @artworkFor.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh bìa của {title}'**
  String artworkFor(String title);

  /// No description provided for @albumArtwork.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh bìa bài hát'**
  String get albumArtwork;

  /// No description provided for @playSong.
  ///
  /// In vi, this message translates to:
  /// **'Phát {title}'**
  String playSong(String title);

  /// No description provided for @homeGreeting.
  ///
  /// In vi, this message translates to:
  /// **'Chào bạn,'**
  String get homeGreeting;

  /// No description provided for @homeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Khám phá thế giới\nâm nhạc của bạn'**
  String get homeTitle;

  /// No description provided for @homeSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Một khoảng riêng. Những giai điệu ở lại.'**
  String get homeSubtitle;

  /// No description provided for @listenNow.
  ///
  /// In vi, this message translates to:
  /// **'Nghe ngay'**
  String get listenNow;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Giai điệu đầu tiên đang chờ bạn'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyDemo.
  ///
  /// In vi, this message translates to:
  /// **'Nhạc mẫu sẽ xuất hiện tại đây khi sẵn sàng.'**
  String get homeEmptyDemo;

  /// No description provided for @homeEmptyReal.
  ///
  /// In vi, this message translates to:
  /// **'Tải MP3 đầu tiên để bắt đầu thư viện âm nhạc riêng.'**
  String get homeEmptyReal;

  /// No description provided for @genreCollections.
  ///
  /// In vi, this message translates to:
  /// **'Một sắc màu, một cảm xúc'**
  String get genreCollections;

  /// No description provided for @collectionsDemoSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Bộ sưu tập mẫu · Nhóm theo thể loại'**
  String get collectionsDemoSubtitle;

  /// No description provided for @collectionsRealSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm nhạc của bạn theo thể loại'**
  String get collectionsRealSubtitle;

  /// No description provided for @newUploads.
  ///
  /// In vi, this message translates to:
  /// **'Bài hát mới'**
  String get newUploads;

  /// No description provided for @songsDemoCaption.
  ///
  /// In vi, this message translates to:
  /// **'Nhạc mẫu · Các bài sử dụng audio nghe thử.'**
  String get songsDemoCaption;

  /// No description provided for @songsPrivateCaption.
  ///
  /// In vi, this message translates to:
  /// **'Nhạc đã tải lên · Chỉ tài khoản của bạn truy cập được'**
  String get songsPrivateCaption;

  /// No description provided for @exploreTitle.
  ///
  /// In vi, this message translates to:
  /// **'Khám phá'**
  String get exploreTitle;

  /// No description provided for @exploreSubtitleDemo.
  ///
  /// In vi, this message translates to:
  /// **'Tìm giai điệu qua thể loại, bộ sưu tập hay tên bài. Đây là nhạc mẫu.'**
  String get exploreSubtitleDemo;

  /// No description provided for @exploreSubtitleReal.
  ///
  /// In vi, this message translates to:
  /// **'Tìm lại những giai điệu trong thư viện riêng của bạn.'**
  String get exploreSubtitleReal;

  /// No description provided for @searchLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm âm nhạc'**
  String get searchLabel;

  /// No description provided for @searchHint.
  ///
  /// In vi, this message translates to:
  /// **'Bạn muốn nghe gì hôm nay?'**
  String get searchHint;

  /// No description provided for @clearSearch.
  ///
  /// In vi, this message translates to:
  /// **'Xóa tìm kiếm'**
  String get clearSearch;

  /// No description provided for @combinedFilters.
  ///
  /// In vi, this message translates to:
  /// **'Các lựa chọn được kết hợp với nhau'**
  String get combinedFilters;

  /// No description provided for @clearAll.
  ///
  /// In vi, this message translates to:
  /// **'Xóa bộ lọc'**
  String get clearAll;

  /// No description provided for @searchFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể tìm kiếm'**
  String get searchFailed;

  /// No description provided for @searchFailureMessage.
  ///
  /// In vi, this message translates to:
  /// **'Bộ lọc của bạn được giữ lại. Hãy thử lại khi có kết nối.'**
  String get searchFailureMessage;

  /// No description provided for @browseGenres.
  ///
  /// In vi, this message translates to:
  /// **'Khám phá thể loại'**
  String get browseGenres;

  /// No description provided for @allGenres.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả thể loại'**
  String get allGenres;

  /// No description provided for @removeUnknownGenre.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ thể loại không còn sẵn có'**
  String get removeUnknownGenre;

  /// No description provided for @collectionsDemo.
  ///
  /// In vi, this message translates to:
  /// **'Bộ sưu tập mẫu'**
  String get collectionsDemo;

  /// No description provided for @collectionsReal.
  ///
  /// In vi, this message translates to:
  /// **'Bộ sưu tập của bạn'**
  String get collectionsReal;

  /// No description provided for @collectionsHint.
  ///
  /// In vi, this message translates to:
  /// **'Một lối nghe khác, qua những nhóm thể loại.'**
  String get collectionsHint;

  /// No description provided for @allCollections.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả bộ sưu tập'**
  String get allCollections;

  /// No description provided for @unknownCollection.
  ///
  /// In vi, this message translates to:
  /// **'Bộ sưu tập không còn sẵn có'**
  String get unknownCollection;

  /// No description provided for @removeUnknownCollection.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ bộ sưu tập không còn sẵn có'**
  String get removeUnknownCollection;

  /// No description provided for @resultsCount.
  ///
  /// In vi, this message translates to:
  /// **'Tìm thấy {count} bài hát'**
  String resultsCount(int count);

  /// No description provided for @catalogDemo.
  ///
  /// In vi, this message translates to:
  /// **'Kho nhạc mẫu'**
  String get catalogDemo;

  /// No description provided for @collectionUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Bộ sưu tập này không còn sẵn có'**
  String get collectionUnavailable;

  /// No description provided for @collectionQuiet.
  ///
  /// In vi, this message translates to:
  /// **'Bộ sưu tập đang chờ giai điệu mới'**
  String get collectionQuiet;

  /// No description provided for @noResults.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy kết quả'**
  String get noResults;

  /// No description provided for @collectionEmptyDemo.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có nhạc mẫu trong nhóm này. Thử bộ sưu tập khác hoặc xem tất cả bài hát.'**
  String get collectionEmptyDemo;

  /// No description provided for @collectionEmptyReal.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có bản nhạc tải lên trong nhóm này. Thử bộ sưu tập khác hoặc xem tất cả bài hát.'**
  String get collectionEmptyReal;

  /// No description provided for @noResultsHint.
  ///
  /// In vi, this message translates to:
  /// **'Thử thể loại khác, đổi bộ sưu tập hoặc xóa từ khóa.'**
  String get noResultsHint;

  /// No description provided for @browseAllTracks.
  ///
  /// In vi, this message translates to:
  /// **'Xem tất cả bài hát'**
  String get browseAllTracks;

  /// No description provided for @sampleEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Kho nhạc mẫu đang trống'**
  String get sampleEmpty;

  /// No description provided for @libraryEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Thư viện của bạn đang trống'**
  String get libraryEmpty;

  /// No description provided for @uploadToDiscover.
  ///
  /// In vi, this message translates to:
  /// **'Tải MP3 đầu tiên để khám phá bộ sưu tập của chính bạn.'**
  String get uploadToDiscover;

  /// No description provided for @softFocusTitle.
  ///
  /// In vi, this message translates to:
  /// **'Góc dịu êm'**
  String get softFocusTitle;

  /// No description provided for @softFocusDescription.
  ///
  /// In vi, this message translates to:
  /// **'Dream pop và Indie folk, dành cho những phút chậm lại.'**
  String get softFocusDescription;

  /// No description provided for @afterHoursTitle.
  ///
  /// In vi, this message translates to:
  /// **'Khi đêm về'**
  String get afterHoursTitle;

  /// No description provided for @afterHoursDescription.
  ///
  /// In vi, this message translates to:
  /// **'Alternative và Electronic, những âm sắc của đêm.'**
  String get afterHoursDescription;

  /// No description provided for @loadingLibrary.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải thư viện nhạc'**
  String get loadingLibrary;

  /// No description provided for @catalogLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Âm nhạc đang chờ kết nối'**
  String get catalogLoadFailed;

  /// No description provided for @catalogLoadFailedMessage.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tải được thư viện. Kiểm tra kết nối và thử lại.'**
  String get catalogLoadFailedMessage;

  /// No description provided for @nowPlaying.
  ///
  /// In vi, this message translates to:
  /// **'Đang phát'**
  String get nowPlaying;

  /// No description provided for @backToBrowsing.
  ///
  /// In vi, this message translates to:
  /// **'Thu nhỏ trình phát'**
  String get backToBrowsing;

  /// No description provided for @nothingToPlay.
  ///
  /// In vi, this message translates to:
  /// **'Chọn một giai điệu để bắt đầu'**
  String get nothingToPlay;

  /// No description provided for @nothingToPlayDescription.
  ///
  /// In vi, this message translates to:
  /// **'Mở một bài hát trong thư viện để bắt đầu nghe nhạc.'**
  String get nothingToPlayDescription;

  /// No description provided for @unlikeSong.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ yêu thích bài hát'**
  String get unlikeSong;

  /// No description provided for @likeSong.
  ///
  /// In vi, this message translates to:
  /// **'Yêu thích bài hát'**
  String get likeSong;

  /// No description provided for @likeSaveFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa lưu được lượt thích. Hãy thử lại.'**
  String get likeSaveFailed;

  /// No description provided for @playbackPosition.
  ///
  /// In vi, this message translates to:
  /// **'Tiến trình phát nhạc'**
  String get playbackPosition;

  /// No description provided for @playbackPositionValue.
  ///
  /// In vi, this message translates to:
  /// **'{elapsed} trên {total}'**
  String playbackPositionValue(String elapsed, String total);

  /// No description provided for @previousTrack.
  ///
  /// In vi, this message translates to:
  /// **'Bài trước'**
  String get previousTrack;

  /// No description provided for @nextTrack.
  ///
  /// In vi, this message translates to:
  /// **'Bài tiếp theo'**
  String get nextTrack;

  /// No description provided for @loadingAudio.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải âm thanh'**
  String get loadingAudio;

  /// No description provided for @pauseTrack.
  ///
  /// In vi, this message translates to:
  /// **'Tạm dừng'**
  String get pauseTrack;

  /// No description provided for @playTrack.
  ///
  /// In vi, this message translates to:
  /// **'Phát nhạc'**
  String get playTrack;

  /// No description provided for @resumeTrack.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục phát'**
  String get resumeTrack;

  /// No description provided for @shuffle.
  ///
  /// In vi, this message translates to:
  /// **'Phát ngẫu nhiên'**
  String get shuffle;

  /// No description provided for @shuffleOn.
  ///
  /// In vi, this message translates to:
  /// **'Đang phát ngẫu nhiên'**
  String get shuffleOn;

  /// No description provided for @repeat.
  ///
  /// In vi, this message translates to:
  /// **'Lặp lại'**
  String get repeat;

  /// No description provided for @repeatOn.
  ///
  /// In vi, this message translates to:
  /// **'Đang lặp lại bài hát'**
  String get repeatOn;

  /// No description provided for @sampleAudioNotice.
  ///
  /// In vi, this message translates to:
  /// **'Nhạc mẫu · Audio dùng để nghe thử'**
  String get sampleAudioNotice;

  /// No description provided for @privateLibraryNotice.
  ///
  /// In vi, this message translates to:
  /// **'Nhạc riêng của bạn'**
  String get privateLibraryNotice;

  /// No description provided for @playbackUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể phát nhạc'**
  String get playbackUnavailable;

  /// No description provided for @audioLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa phát được bài hát. Kiểm tra kết nối và thử lại.'**
  String get audioLoadFailed;

  /// No description provided for @openPlayer.
  ///
  /// In vi, this message translates to:
  /// **'Mở trình phát'**
  String get openPlayer;

  /// No description provided for @libraryTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thư viện của bạn'**
  String get libraryTitle;

  /// No description provided for @librarySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Không gian riêng cho những giai điệu bạn muốn nghe lại.'**
  String get librarySubtitle;

  /// No description provided for @libraryEyebrow.
  ///
  /// In vi, this message translates to:
  /// **'BỘ SƯU TẬP CÁ NHÂN'**
  String get libraryEyebrow;

  /// No description provided for @likedTracks.
  ///
  /// In vi, this message translates to:
  /// **'Yêu thích'**
  String get likedTracks;

  /// No description provided for @allUploads.
  ///
  /// In vi, this message translates to:
  /// **'Nhạc đã tải lên'**
  String get allUploads;

  /// No description provided for @sampleCatalog.
  ///
  /// In vi, this message translates to:
  /// **'Nhạc mẫu'**
  String get sampleCatalog;

  /// No description provided for @librarySavedPrivate.
  ///
  /// In vi, this message translates to:
  /// **'Được lưu riêng trong tài khoản của bạn'**
  String get librarySavedPrivate;

  /// No description provided for @librarySavedSession.
  ///
  /// In vi, this message translates to:
  /// **'Lượt thích chỉ được lưu trong phiên nghe thử'**
  String get librarySavedSession;

  /// No description provided for @libraryEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thư viện của bạn đang trống'**
  String get libraryEmptyTitle;

  /// No description provided for @libraryEmptyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Tải lên bản nhạc đầu tiên để bắt đầu không gian âm nhạc của bạn.'**
  String get libraryEmptyMessage;

  /// No description provided for @favoritesEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tìm giai điệu bạn yêu thích'**
  String get favoritesEmptyTitle;

  /// No description provided for @favoritesEmptyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Chạm biểu tượng trái tim khi nghe để lưu bài hát tại đây.'**
  String get favoritesEmptyMessage;

  /// No description provided for @libraryPrivacyNote.
  ///
  /// In vi, this message translates to:
  /// **'Nhạc và lượt thích thuộc riêng tài khoản của bạn.'**
  String get libraryPrivacyNote;

  /// No description provided for @demoLibraryNote.
  ///
  /// In vi, this message translates to:
  /// **'Đây là nhạc mẫu. Lượt thích chỉ tồn tại trong phiên này.'**
  String get demoLibraryNote;

  /// No description provided for @uploadTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ âm nhạc'**
  String get uploadTitle;

  /// No description provided for @uploadEyebrow.
  ///
  /// In vi, this message translates to:
  /// **'ÂM THANH CỦA BẠN'**
  String get uploadEyebrow;

  /// No description provided for @uploadSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Lưu bản nhạc của bạn vào thư viện riêng.'**
  String get uploadSubtitle;

  /// No description provided for @uploadDemoSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo bản xem trước trên thiết bị. Không gửi file lên máy chủ.'**
  String get uploadDemoSubtitle;

  /// No description provided for @uploadAudioStep.
  ///
  /// In vi, this message translates to:
  /// **'Chọn bản nhạc'**
  String get uploadAudioStep;

  /// No description provided for @chooseMp3.
  ///
  /// In vi, this message translates to:
  /// **'Chọn file MP3'**
  String get chooseMp3;

  /// No description provided for @mp3Limit.
  ///
  /// In vi, this message translates to:
  /// **'MP3 · Tối đa 20 MB'**
  String get mp3Limit;

  /// No description provided for @changeFile.
  ///
  /// In vi, this message translates to:
  /// **'Đổi file'**
  String get changeFile;

  /// No description provided for @uploadDetailsStep.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin bài hát'**
  String get uploadDetailsStep;

  /// No description provided for @songTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tên bài hát'**
  String get songTitle;

  /// No description provided for @titleHint.
  ///
  /// In vi, this message translates to:
  /// **'Đặt tên cho giai điệu của bạn'**
  String get titleHint;

  /// No description provided for @artistName.
  ///
  /// In vi, this message translates to:
  /// **'Tên nghệ sĩ'**
  String get artistName;

  /// No description provided for @artistHint.
  ///
  /// In vi, this message translates to:
  /// **'Ai tạo nên bản nhạc này?'**
  String get artistHint;

  /// No description provided for @genre.
  ///
  /// In vi, this message translates to:
  /// **'Thể loại'**
  String get genre;

  /// No description provided for @otherGenre.
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get otherGenre;

  /// No description provided for @descriptionOptional.
  ///
  /// In vi, this message translates to:
  /// **'Mô tả (không bắt buộc)'**
  String get descriptionOptional;

  /// No description provided for @descriptionHint.
  ///
  /// In vi, this message translates to:
  /// **'Câu chuyện phía sau bản nhạc'**
  String get descriptionHint;

  /// No description provided for @uploadArtworkStep.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh bìa'**
  String get uploadArtworkStep;

  /// No description provided for @artworkHint.
  ///
  /// In vi, this message translates to:
  /// **'JPG, PNG hoặc WebP · Tối đa 5 MB'**
  String get artworkHint;

  /// No description provided for @addArtwork.
  ///
  /// In vi, this message translates to:
  /// **'Thêm ảnh bìa'**
  String get addArtwork;

  /// No description provided for @artworkOptional.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh bìa không bắt buộc'**
  String get artworkOptional;

  /// No description provided for @uploadButton.
  ///
  /// In vi, this message translates to:
  /// **'Tải bài hát lên'**
  String get uploadButton;

  /// No description provided for @uploadBusy.
  ///
  /// In vi, this message translates to:
  /// **'Đang xử lý bản nhạc. Vui lòng giữ trang này mở…'**
  String get uploadBusy;

  /// No description provided for @openingFile.
  ///
  /// In vi, this message translates to:
  /// **'Đang mở file…'**
  String get openingFile;

  /// No description provided for @uploadSaved.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu vào thư viện riêng'**
  String get uploadSaved;

  /// No description provided for @openLibrary.
  ///
  /// In vi, this message translates to:
  /// **'Mở thư viện'**
  String get openLibrary;

  /// No description provided for @previewButton.
  ///
  /// In vi, this message translates to:
  /// **'Xem trước thông tin'**
  String get previewButton;

  /// No description provided for @previewReady.
  ///
  /// In vi, this message translates to:
  /// **'Bản xem trước đã sẵn sàng'**
  String get previewReady;

  /// No description provided for @previewNotice.
  ///
  /// In vi, this message translates to:
  /// **'File chỉ có trên thiết bị và chưa được tải lên.'**
  String get previewNotice;

  /// No description provided for @mp3Invalid.
  ///
  /// In vi, this message translates to:
  /// **'Chọn file MP3 không rỗng, tối đa 20 MB.'**
  String get mp3Invalid;

  /// No description provided for @artworkInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ảnh JPG, PNG hoặc WebP tối đa 5 MB.'**
  String get artworkInvalid;

  /// No description provided for @fileOpenError.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được file. Vui lòng chọn lại.'**
  String get fileOpenError;

  /// No description provided for @mp3Required.
  ///
  /// In vi, this message translates to:
  /// **'Hãy chọn file MP3 trước.'**
  String get mp3Required;

  /// No description provided for @titleRequired.
  ///
  /// In vi, this message translates to:
  /// **'Hãy nhập tên bài hát.'**
  String get titleRequired;

  /// No description provided for @artistRequired.
  ///
  /// In vi, this message translates to:
  /// **'Hãy nhập tên nghệ sĩ.'**
  String get artistRequired;

  /// No description provided for @uploadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa lưu được bản nhạc. Hãy thử lại với file đã chọn.'**
  String get uploadFailed;

  /// No description provided for @uploadPrivateTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ dành cho bạn'**
  String get uploadPrivateTitle;

  /// No description provided for @uploadPrivateMessage.
  ///
  /// In vi, this message translates to:
  /// **'Nhạc được lưu trong thư viện riêng. Bạn chỉ nên tải nội dung mình có quyền sử dụng.'**
  String get uploadPrivateMessage;

  /// No description provided for @profileTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cá nhân'**
  String get profileTitle;

  /// No description provided for @profileEyebrow.
  ///
  /// In vi, this message translates to:
  /// **'KHÔNG GIAN CỦA BẠN'**
  String get profileEyebrow;

  /// No description provided for @profileSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Âm nhạc riêng, cảm xúc riêng.'**
  String get profileSubtitle;

  /// No description provided for @guestName.
  ///
  /// In vi, this message translates to:
  /// **'Khách nghe thử'**
  String get guestName;

  /// No description provided for @accountName.
  ///
  /// In vi, this message translates to:
  /// **'Người yêu nhạc'**
  String get accountName;

  /// No description provided for @profilePrivateNote.
  ///
  /// In vi, this message translates to:
  /// **'Nhạc tải lên và lượt thích được lưu trong tài khoản riêng của bạn.'**
  String get profilePrivateNote;

  /// No description provided for @profileDemoNote.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đang khám phá nhạc mẫu. Lượt thích chỉ được lưu trong phiên này.'**
  String get profileDemoNote;

  /// No description provided for @yourMusic.
  ///
  /// In vi, this message translates to:
  /// **'Âm nhạc của bạn'**
  String get yourMusic;

  /// No description provided for @yourUploads.
  ///
  /// In vi, this message translates to:
  /// **'Nhạc đã tải lên'**
  String get yourUploads;

  /// No description provided for @yourFavorites.
  ///
  /// In vi, this message translates to:
  /// **'Bài hát yêu thích'**
  String get yourFavorites;

  /// No description provided for @profileLibraryHint.
  ///
  /// In vi, this message translates to:
  /// **'Trở lại những giai điệu bạn đã lưu'**
  String get profileLibraryHint;

  /// No description provided for @profileUploadHint.
  ///
  /// In vi, this message translates to:
  /// **'Thêm MP3 và ảnh bìa vào thư viện'**
  String get profileUploadHint;

  /// No description provided for @accountSection.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản'**
  String get accountSection;

  /// No description provided for @accountProvider.
  ///
  /// In vi, this message translates to:
  /// **'Được bảo vệ bởi Clerk'**
  String get accountProvider;

  /// No description provided for @accountProviderNote.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập và phiên tài khoản do Clerk quản lý.'**
  String get accountProviderNote;

  /// No description provided for @profilePrivacyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Khoảng riêng cho âm nhạc'**
  String get profilePrivacyTitle;

  /// No description provided for @profilePrivacyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Bài hát của bạn chưa được công khai. Hồ sơ nghệ sĩ và người theo dõi chưa được hỗ trợ.'**
  String get profilePrivacyMessage;

  /// No description provided for @signIn.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In vi, this message translates to:
  /// **'Tạo tài khoản'**
  String get signUp;

  /// No description provided for @signOut.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất'**
  String get signOut;

  /// No description provided for @signingOut.
  ///
  /// In vi, this message translates to:
  /// **'Đang đăng xuất…'**
  String get signingOut;

  /// No description provided for @signOutFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa đăng xuất được. Hãy thử lại.'**
  String get signOutFailed;

  /// No description provided for @welcomeBack.
  ///
  /// In vi, this message translates to:
  /// **'Chào mừng trở lại'**
  String get welcomeBack;

  /// No description provided for @signInSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập để tiếp tục hành trình âm nhạc'**
  String get signInSubtitle;

  /// No description provided for @signInPrivateNote.
  ///
  /// In vi, this message translates to:
  /// **'Một khoảng riêng cho MP3, ảnh bìa và những bài hát bạn yêu thích.'**
  String get signInPrivateNote;

  /// No description provided for @secureAccountNote.
  ///
  /// In vi, this message translates to:
  /// **'Clerk bảo vệ tài khoản, xác minh email và khôi phục mật khẩu cho bạn.'**
  String get secureAccountNote;

  /// No description provided for @loadingSignIn.
  ///
  /// In vi, this message translates to:
  /// **'Đang mở đăng nhập'**
  String get loadingSignIn;

  /// No description provided for @signInLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa mở được đăng nhập. Kiểm tra kết nối và thử lại.'**
  String get signInLoadFailed;

  /// No description provided for @openingLibrary.
  ///
  /// In vi, this message translates to:
  /// **'Đang mở thư viện'**
  String get openingLibrary;

  /// No description provided for @verifyingSession.
  ///
  /// In vi, this message translates to:
  /// **'Đang xác minh tài khoản và mở thư viện của bạn…'**
  String get verifyingSession;

  /// No description provided for @libraryOpenFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa mở được thư viện. Hãy thử lại.'**
  String get libraryOpenFailed;

  /// No description provided for @signInNotConfigured.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập chưa được cấu hình cho bản ứng dụng này.'**
  String get signInNotConfigured;

  /// No description provided for @sessionInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xác minh được phiên tài khoản. Vui lòng đăng nhập lại.'**
  String get sessionInvalid;

  /// No description provided for @sessionTimeout.
  ///
  /// In vi, this message translates to:
  /// **'Mở thư viện mất quá lâu. Kiểm tra kết nối và thử lại.'**
  String get sessionTimeout;

  /// No description provided for @errorAlreadySaved.
  ///
  /// In vi, this message translates to:
  /// **'MP3 này đã được lưu với thông tin khác. Hãy chọn file khác.'**
  String get errorAlreadySaved;

  /// No description provided for @errorFileTooLarge.
  ///
  /// In vi, this message translates to:
  /// **'File vượt quá dung lượng cho phép.'**
  String get errorFileTooLarge;

  /// No description provided for @errorFileType.
  ///
  /// In vi, this message translates to:
  /// **'Định dạng hoặc nội dung file chưa được hỗ trợ.'**
  String get errorFileType;

  /// No description provided for @errorRateLimit.
  ///
  /// In vi, this message translates to:
  /// **'Bạn thao tác quá nhanh. Hãy đợi một lát rồi thử lại.'**
  String get errorRateLimit;

  /// No description provided for @errorInvalidDetails.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra lại file và thông tin bài hát.'**
  String get errorInvalidDetails;

  /// No description provided for @errorNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Bài hát hoặc file này không còn sẵn có.'**
  String get errorNotFound;

  /// No description provided for @errorBusy.
  ///
  /// In vi, this message translates to:
  /// **'File đang được xử lý. Hãy đợi một lát rồi thử lại.'**
  String get errorBusy;

  /// No description provided for @errorConnection.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thực hiện được yêu cầu. Kiểm tra kết nối và thử lại.'**
  String get errorConnection;

  /// No description provided for @backendVerifying.
  ///
  /// In vi, this message translates to:
  /// **'Đang xác minh tài khoản'**
  String get backendVerifying;

  /// No description provided for @backendNotVerified.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản chưa được xác minh'**
  String get backendNotVerified;

  /// No description provided for @backendVerified.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản đã được xác minh'**
  String get backendVerified;

  /// No description provided for @languageVietnamese.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Việt'**
  String get languageVietnamese;

  /// No description provided for @privateListening.
  ///
  /// In vi, this message translates to:
  /// **'KHÔNG GIAN ÂM NHẠC'**
  String get privateListening;

  /// No description provided for @clerkALengthOfBetweenMINAndMAX.
  ///
  /// In vi, this message translates to:
  /// **'độ dài từ {min} đến {max} ký tự'**
  String clerkALengthOfBetweenMINAndMAX(int min, int max);

  /// No description provided for @clerkALengthOfMINOrGreater.
  ///
  /// In vi, this message translates to:
  /// **'ít nhất {min} ký tự'**
  String clerkALengthOfMINOrGreater(int min);

  /// No description provided for @clerkALowercaseLetter.
  ///
  /// In vi, this message translates to:
  /// **'một chữ thường'**
  String get clerkALowercaseLetter;

  /// No description provided for @clerkANumber.
  ///
  /// In vi, this message translates to:
  /// **'một chữ số'**
  String get clerkANumber;

  /// No description provided for @clerkASpecialCharacter.
  ///
  /// In vi, this message translates to:
  /// **'một ký tự đặc biệt ({chars})'**
  String clerkASpecialCharacter(String chars);

  /// No description provided for @clerkAbandoned.
  ///
  /// In vi, this message translates to:
  /// **'đã hủy'**
  String get clerkAbandoned;

  /// No description provided for @clerkAcceptTerms.
  ///
  /// In vi, this message translates to:
  /// **'Tôi đồng ý với Điều khoản dịch vụ và Chính sách quyền riêng tư'**
  String get clerkAcceptTerms;

  /// No description provided for @clerkActive.
  ///
  /// In vi, this message translates to:
  /// **'đang hoạt động'**
  String get clerkActive;

  /// No description provided for @clerkAddAccount.
  ///
  /// In vi, this message translates to:
  /// **'Thêm tài khoản'**
  String get clerkAddAccount;

  /// No description provided for @clerkAddDomain.
  ///
  /// In vi, this message translates to:
  /// **'Thêm tên miền'**
  String get clerkAddDomain;

  /// No description provided for @clerkAddEmailAddress.
  ///
  /// In vi, this message translates to:
  /// **'Thêm địa chỉ email'**
  String get clerkAddEmailAddress;

  /// No description provided for @clerkAddPasskey.
  ///
  /// In vi, this message translates to:
  /// **'Thêm khóa truy cập'**
  String get clerkAddPasskey;

  /// No description provided for @clerkAddPhoneNumber.
  ///
  /// In vi, this message translates to:
  /// **'Thêm số điện thoại'**
  String get clerkAddPhoneNumber;

  /// No description provided for @clerkAlreadyHaveAnAccount.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã có tài khoản?'**
  String get clerkAlreadyHaveAnAccount;

  /// No description provided for @clerkAnUppercaseLetter.
  ///
  /// In vi, this message translates to:
  /// **'một chữ hoa'**
  String get clerkAnUppercaseLetter;

  /// No description provided for @clerkAnd.
  ///
  /// In vi, this message translates to:
  /// **'và'**
  String get clerkAnd;

  /// No description provided for @clerkAreYouSure.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc chắn?'**
  String get clerkAreYouSure;

  /// No description provided for @clerkAuthenticationServiceError.
  ///
  /// In vi, this message translates to:
  /// **'Chưa kết nối được dịch vụ xác thực. Vui lòng thử lại.'**
  String get clerkAuthenticationServiceError;

  /// No description provided for @clerkAuthenticatorApp.
  ///
  /// In vi, this message translates to:
  /// **'ứng dụng xác thực'**
  String get clerkAuthenticatorApp;

  /// No description provided for @clerkAutomaticInvitation.
  ///
  /// In vi, this message translates to:
  /// **'Lời mời tự động'**
  String get clerkAutomaticInvitation;

  /// No description provided for @clerkAutomaticSuggestion.
  ///
  /// In vi, this message translates to:
  /// **'Đề xuất tự động'**
  String get clerkAutomaticSuggestion;

  /// No description provided for @clerkBack.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get clerkBack;

  /// No description provided for @clerkBackupCode.
  ///
  /// In vi, this message translates to:
  /// **'mã dự phòng'**
  String get clerkBackupCode;

  /// No description provided for @clerkCancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get clerkCancel;

  /// No description provided for @clerkCannotDeleteSelf.
  ///
  /// In vi, this message translates to:
  /// **'Bạn không có quyền xóa tài khoản này'**
  String get clerkCannotDeleteSelf;

  /// No description provided for @clerkClickOnTheLinkThatsBeenSentTo.
  ///
  /// In vi, this message translates to:
  /// **'Mở liên kết đã gửi đến {identifier}, sau đó quay lại đây'**
  String clerkClickOnTheLinkThatsBeenSentTo(String identifier);

  /// No description provided for @clerkClickOnTheLinkThatsBeenSentToYou.
  ///
  /// In vi, this message translates to:
  /// **'Mở liên kết đã gửi cho bạn, sau đó quay lại đây'**
  String get clerkClickOnTheLinkThatsBeenSentToYou;

  /// No description provided for @clerkComplete.
  ///
  /// In vi, this message translates to:
  /// **'đã hoàn tất'**
  String get clerkComplete;

  /// No description provided for @clerkConnectAccount.
  ///
  /// In vi, this message translates to:
  /// **'Liên kết tài khoản'**
  String get clerkConnectAccount;

  /// No description provided for @clerkConnectedAccounts.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản đã liên kết'**
  String get clerkConnectedAccounts;

  /// No description provided for @clerkCont.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get clerkCont;

  /// No description provided for @clerkCreateOrganization.
  ///
  /// In vi, this message translates to:
  /// **'Tạo tổ chức'**
  String get clerkCreateOrganization;

  /// No description provided for @clerkCreated.
  ///
  /// In vi, this message translates to:
  /// **'Đã tạo'**
  String get clerkCreated;

  /// No description provided for @clerkDevelopmentMode.
  ///
  /// In vi, this message translates to:
  /// **'Chế độ phát triển'**
  String get clerkDevelopmentMode;

  /// No description provided for @clerkDidntReceiveCode.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa nhận được mã?'**
  String get clerkDidntReceiveCode;

  /// No description provided for @clerkDomainName.
  ///
  /// In vi, this message translates to:
  /// **'Tên miền'**
  String get clerkDomainName;

  /// No description provided for @clerkDontHaveAnAccount.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa có tài khoản?'**
  String get clerkDontHaveAnAccount;

  /// No description provided for @clerkEdit.
  ///
  /// In vi, this message translates to:
  /// **'chỉnh sửa'**
  String get clerkEdit;

  /// No description provided for @clerkEmailAddress.
  ///
  /// In vi, this message translates to:
  /// **'địa chỉ email'**
  String get clerkEmailAddress;

  /// No description provided for @clerkEmailAddressConcise.
  ///
  /// In vi, this message translates to:
  /// **'email'**
  String get clerkEmailAddressConcise;

  /// No description provided for @clerkEmailAddresses.
  ///
  /// In vi, this message translates to:
  /// **'Địa chỉ email'**
  String get clerkEmailAddresses;

  /// No description provided for @clerkEnrollment.
  ///
  /// In vi, this message translates to:
  /// **'Tham gia'**
  String get clerkEnrollment;

  /// No description provided for @clerkEnrollmentMode.
  ///
  /// In vi, this message translates to:
  /// **'Phương thức tham gia:'**
  String get clerkEnrollmentMode;

  /// No description provided for @clerkEnterOneOfYourBackupCodes.
  ///
  /// In vi, this message translates to:
  /// **'Nhập một trong các mã dự phòng của bạn'**
  String get clerkEnterOneOfYourBackupCodes;

  /// No description provided for @clerkEnterTheCodeFromYourAuthenticatorApp.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã từ ứng dụng xác thực của bạn'**
  String get clerkEnterTheCodeFromYourAuthenticatorApp;

  /// No description provided for @clerkEnterTheCodeSentTo.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã đã gửi đến {identifier}'**
  String clerkEnterTheCodeSentTo(String identifier);

  /// No description provided for @clerkEnterTheCodeSentToYou.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã đã gửi cho bạn'**
  String get clerkEnterTheCodeSentToYou;

  /// No description provided for @clerkEnterTheCodeSentToYouByEmail.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã đã gửi qua email'**
  String get clerkEnterTheCodeSentToYouByEmail;

  /// No description provided for @clerkEnterTheCodeSentToYouByTextMessage.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã đã gửi qua tin nhắn'**
  String get clerkEnterTheCodeSentToYouByTextMessage;

  /// No description provided for @clerkEnterYourOrganizationDetailsToContinue.
  ///
  /// In vi, this message translates to:
  /// **'Nhập thông tin tổ chức để tiếp tục'**
  String get clerkEnterYourOrganizationDetailsToContinue;

  /// No description provided for @clerkEnterYourPassword.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mật khẩu của bạn'**
  String get clerkEnterYourPassword;

  /// No description provided for @clerkExpired.
  ///
  /// In vi, this message translates to:
  /// **'đã hết hạn'**
  String get clerkExpired;

  /// No description provided for @clerkExternalError.
  ///
  /// In vi, this message translates to:
  /// **'Chưa hoàn tất được xác thực. Vui lòng thử lại.'**
  String get clerkExternalError;

  /// No description provided for @clerkFailed.
  ///
  /// In vi, this message translates to:
  /// **'không thành công'**
  String get clerkFailed;

  /// No description provided for @clerkFirstName.
  ///
  /// In vi, this message translates to:
  /// **'tên'**
  String get clerkFirstName;

  /// No description provided for @clerkForgottenPassword.
  ///
  /// In vi, this message translates to:
  /// **'Bạn quên mật khẩu?'**
  String get clerkForgottenPassword;

  /// No description provided for @clerkGeneralDetails.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin chung'**
  String get clerkGeneralDetails;

  /// No description provided for @clerkInvalidEmailAddress.
  ///
  /// In vi, this message translates to:
  /// **'Địa chỉ email không hợp lệ: {address}'**
  String clerkInvalidEmailAddress(String address);

  /// No description provided for @clerkInvalidPhoneNumber.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại không hợp lệ: {number}'**
  String clerkInvalidPhoneNumber(String number);

  /// No description provided for @clerkJoin.
  ///
  /// In vi, this message translates to:
  /// **'THAM GIA'**
  String get clerkJoin;

  /// No description provided for @clerkJwtPoorlyFormatted.
  ///
  /// In vi, this message translates to:
  /// **'Phiên xác thực không hợp lệ. Vui lòng đăng nhập lại.'**
  String get clerkJwtPoorlyFormatted;

  /// No description provided for @clerkLastName.
  ///
  /// In vi, this message translates to:
  /// **'họ'**
  String get clerkLastName;

  /// No description provided for @clerkLastUsed.
  ///
  /// In vi, this message translates to:
  /// **'Lần sử dụng gần nhất'**
  String get clerkLastUsed;

  /// No description provided for @clerkLeave.
  ///
  /// In vi, this message translates to:
  /// **'Rời khỏi'**
  String get clerkLeave;

  /// No description provided for @clerkLeaveOrg.
  ///
  /// In vi, this message translates to:
  /// **'Rời khỏi {organization}'**
  String clerkLeaveOrg(String organization);

  /// No description provided for @clerkLeaveOrganization.
  ///
  /// In vi, this message translates to:
  /// **'Rời khỏi tổ chức'**
  String get clerkLeaveOrganization;

  /// No description provided for @clerkLegalAcceptanceRequired.
  ///
  /// In vi, this message translates to:
  /// **'Bạn cần đồng ý với các điều khoản để tiếp tục đăng ký'**
  String get clerkLegalAcceptanceRequired;

  /// No description provided for @clerkLoading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải…'**
  String get clerkLoading;

  /// No description provided for @clerkLogo.
  ///
  /// In vi, this message translates to:
  /// **'Biểu tượng'**
  String get clerkLogo;

  /// No description provided for @clerkLongDateFormat.
  ///
  /// In vi, this message translates to:
  /// **'HH:mm, dd/MM/yyyy'**
  String get clerkLongDateFormat;

  /// No description provided for @clerkManualInvitation.
  ///
  /// In vi, this message translates to:
  /// **'Lời mời trực tiếp'**
  String get clerkManualInvitation;

  /// No description provided for @clerkMissingRequirements.
  ///
  /// In vi, this message translates to:
  /// **'cần bổ sung thông tin'**
  String get clerkMissingRequirements;

  /// No description provided for @clerkMyOrganization.
  ///
  /// In vi, this message translates to:
  /// **'Tổ chức của tôi'**
  String get clerkMyOrganization;

  /// No description provided for @clerkName.
  ///
  /// In vi, this message translates to:
  /// **'Tên'**
  String get clerkName;

  /// No description provided for @clerkNeedsFirstFactor.
  ///
  /// In vi, this message translates to:
  /// **'cần xác minh bước đầu'**
  String get clerkNeedsFirstFactor;

  /// No description provided for @clerkNeedsIdentifier.
  ///
  /// In vi, this message translates to:
  /// **'cần thông tin đăng nhập'**
  String get clerkNeedsIdentifier;

  /// No description provided for @clerkNeedsSecondFactor.
  ///
  /// In vi, this message translates to:
  /// **'cần xác minh bước hai'**
  String get clerkNeedsSecondFactor;

  /// No description provided for @clerkNewPassword.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu mới'**
  String get clerkNewPassword;

  /// No description provided for @clerkNewPasswordConfirmation.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận mật khẩu mới'**
  String get clerkNewPasswordConfirmation;

  /// No description provided for @clerkNoAssociatedCodeRetrievalMethod.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy phương thức nhận mã cho {arg}'**
  String clerkNoAssociatedCodeRetrievalMethod(String arg);

  /// No description provided for @clerkNoAssociatedStrategy.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy phương thức xác thực cho {arg}'**
  String clerkNoAssociatedStrategy(String arg);

  /// No description provided for @clerkNoInitialCodeHasBeenSetUpToResend.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có mã xác minh để gửi lại'**
  String get clerkNoInitialCodeHasBeenSetUpToResend;

  /// No description provided for @clerkNoSessionFoundForUser.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy phiên đăng nhập của {arg}'**
  String clerkNoSessionFoundForUser(String arg);

  /// No description provided for @clerkNoSessionTokenRetrieved.
  ///
  /// In vi, this message translates to:
  /// **'Chưa nhận được phiên xác thực'**
  String get clerkNoSessionTokenRetrieved;

  /// No description provided for @clerkNoStageForStatus.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy bước xác thực cho trạng thái {arg}'**
  String clerkNoStageForStatus(String arg);

  /// No description provided for @clerkNoSuchFirstFactorStrategy.
  ///
  /// In vi, this message translates to:
  /// **'Phương thức {arg} không hỗ trợ xác minh bước đầu'**
  String clerkNoSuchFirstFactorStrategy(String arg);

  /// No description provided for @clerkNoSuchSecondFactorStrategy.
  ///
  /// In vi, this message translates to:
  /// **'Phương thức {arg} không hỗ trợ xác minh bước hai'**
  String clerkNoSuchSecondFactorStrategy(String arg);

  /// No description provided for @clerkNoUserAttributeForField.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy thông tin tài khoản cho trường {arg}'**
  String clerkNoUserAttributeForField(String arg);

  /// No description provided for @clerkOk.
  ///
  /// In vi, this message translates to:
  /// **'Đồng ý'**
  String get clerkOk;

  /// No description provided for @clerkOptional.
  ///
  /// In vi, this message translates to:
  /// **'(không bắt buộc)'**
  String get clerkOptional;

  /// No description provided for @clerkOr.
  ///
  /// In vi, this message translates to:
  /// **'hoặc'**
  String get clerkOr;

  /// No description provided for @clerkOrganizationProfile.
  ///
  /// In vi, this message translates to:
  /// **'Hồ sơ tổ chức'**
  String get clerkOrganizationProfile;

  /// No description provided for @clerkOrganizations.
  ///
  /// In vi, this message translates to:
  /// **'Tổ chức'**
  String get clerkOrganizations;

  /// No description provided for @clerkPasskey.
  ///
  /// In vi, this message translates to:
  /// **'khóa truy cập'**
  String get clerkPasskey;

  /// No description provided for @clerkPasskeys.
  ///
  /// In vi, this message translates to:
  /// **'Khóa truy cập'**
  String get clerkPasskeys;

  /// No description provided for @clerkPassword.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu'**
  String get clerkPassword;

  /// No description provided for @clerkPasswordConfirmation.
  ///
  /// In vi, this message translates to:
  /// **'xác nhận mật khẩu'**
  String get clerkPasswordConfirmation;

  /// No description provided for @clerkPasswordMatchError.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu xác nhận phải trùng với mật khẩu'**
  String get clerkPasswordMatchError;

  /// No description provided for @clerkPasswordMustBeSupplied.
  ///
  /// In vi, this message translates to:
  /// **'Hãy nhập mật khẩu'**
  String get clerkPasswordMustBeSupplied;

  /// No description provided for @clerkPasswordRequires.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu cần có:'**
  String get clerkPasswordRequires;

  /// No description provided for @clerkPending.
  ///
  /// In vi, this message translates to:
  /// **'đang chờ'**
  String get clerkPending;

  /// No description provided for @clerkPersonalAccount.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản cá nhân'**
  String get clerkPersonalAccount;

  /// No description provided for @clerkPhoneNumber.
  ///
  /// In vi, this message translates to:
  /// **'số điện thoại'**
  String get clerkPhoneNumber;

  /// No description provided for @clerkPhoneNumberConcise.
  ///
  /// In vi, this message translates to:
  /// **'điện thoại'**
  String get clerkPhoneNumberConcise;

  /// No description provided for @clerkPhoneNumbers.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại'**
  String get clerkPhoneNumbers;

  /// No description provided for @clerkPleaseAddRequiredInformation.
  ///
  /// In vi, this message translates to:
  /// **'Hãy bổ sung các thông tin bắt buộc còn thiếu'**
  String get clerkPleaseAddRequiredInformation;

  /// No description provided for @clerkPleaseChooseAnAccountToConnect.
  ///
  /// In vi, this message translates to:
  /// **'Chọn tài khoản bạn muốn liên kết'**
  String get clerkPleaseChooseAnAccountToConnect;

  /// No description provided for @clerkPleaseEnterYourIdentifier.
  ///
  /// In vi, this message translates to:
  /// **'Nhập thông tin đăng nhập của bạn'**
  String get clerkPleaseEnterYourIdentifier;

  /// No description provided for @clerkPrimary.
  ///
  /// In vi, this message translates to:
  /// **'CHÍNH'**
  String get clerkPrimary;

  /// No description provided for @clerkPrivacyPolicy.
  ///
  /// In vi, this message translates to:
  /// **'Chính sách quyền riêng tư'**
  String get clerkPrivacyPolicy;

  /// No description provided for @clerkProfile.
  ///
  /// In vi, this message translates to:
  /// **'Cá nhân'**
  String get clerkProfile;

  /// No description provided for @clerkProfileDetails.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin cá nhân'**
  String get clerkProfileDetails;

  /// No description provided for @clerkRecommendSize.
  ///
  /// In vi, this message translates to:
  /// **'Nên dùng ảnh vuông, dung lượng tối đa 5 MB.'**
  String get clerkRecommendSize;

  /// No description provided for @clerkRequiredField.
  ///
  /// In vi, this message translates to:
  /// **'(bắt buộc)'**
  String get clerkRequiredField;

  /// No description provided for @clerkRequiredFieldsAreMissing.
  ///
  /// In vi, this message translates to:
  /// **'Cần điền các trường bắt buộc'**
  String get clerkRequiredFieldsAreMissing;

  /// No description provided for @clerkResend.
  ///
  /// In vi, this message translates to:
  /// **'Gửi lại'**
  String get clerkResend;

  /// No description provided for @clerkResetFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa đặt lại được mật khẩu. Một mã mới đã được gửi.'**
  String get clerkResetFailed;

  /// No description provided for @clerkResetPassword.
  ///
  /// In vi, this message translates to:
  /// **'Đặt lại mật khẩu và đăng nhập'**
  String get clerkResetPassword;

  /// No description provided for @clerkSelectAccount.
  ///
  /// In vi, this message translates to:
  /// **'Chọn tài khoản để tiếp tục'**
  String get clerkSelectAccount;

  /// No description provided for @clerkSendMeTheCode.
  ///
  /// In vi, this message translates to:
  /// **'Gửi mã đặt lại mật khẩu'**
  String get clerkSendMeTheCode;

  /// No description provided for @clerkServerErrorResponse.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ trả về lỗi: {arg}'**
  String clerkServerErrorResponse(String arg);

  /// No description provided for @clerkSetUpYourOrganization.
  ///
  /// In vi, this message translates to:
  /// **'Thiết lập tổ chức của bạn'**
  String get clerkSetUpYourOrganization;

  /// No description provided for @clerkSignIn.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get clerkSignIn;

  /// No description provided for @clerkSignInByCodeSentToYourEmail.
  ///
  /// In vi, this message translates to:
  /// **'Gửi mã đến email của bạn'**
  String get clerkSignInByCodeSentToYourEmail;

  /// No description provided for @clerkSignInByEmailCode.
  ///
  /// In vi, this message translates to:
  /// **'Gửi mã đến email {arg}'**
  String clerkSignInByEmailCode(String arg);

  /// No description provided for @clerkSignInByEmailLink.
  ///
  /// In vi, this message translates to:
  /// **'Gửi liên kết đến email {arg}'**
  String clerkSignInByEmailLink(String arg);

  /// No description provided for @clerkSignInByEnteringOneOfYourBackupCodes.
  ///
  /// In vi, this message translates to:
  /// **'Dùng mã dự phòng'**
  String get clerkSignInByEnteringOneOfYourBackupCodes;

  /// No description provided for @clerkSignInByLinkSentToYourEmail.
  ///
  /// In vi, this message translates to:
  /// **'Gửi liên kết đến email của bạn'**
  String get clerkSignInByLinkSentToYourEmail;

  /// No description provided for @clerkSignInBySMSCode.
  ///
  /// In vi, this message translates to:
  /// **'Gửi mã SMS đến {arg}'**
  String clerkSignInBySMSCode(String arg);

  /// No description provided for @clerkSignInBySMSCodeToYourPhone.
  ///
  /// In vi, this message translates to:
  /// **'Gửi mã đến điện thoại của bạn'**
  String get clerkSignInBySMSCodeToYourPhone;

  /// No description provided for @clerkSignInTo.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập vào {name}'**
  String clerkSignInTo(String name);

  /// No description provided for @clerkSignInUsingEnterpriseSSO.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập qua SSO của doanh nghiệp'**
  String get clerkSignInUsingEnterpriseSSO;

  /// No description provided for @clerkSignInUsingYourAuthenticatorApp.
  ///
  /// In vi, this message translates to:
  /// **'Dùng ứng dụng xác thực'**
  String get clerkSignInUsingYourAuthenticatorApp;

  /// No description provided for @clerkSignInWithOneOfYourBackupCodes.
  ///
  /// In vi, this message translates to:
  /// **'Dùng một trong các mã dự phòng'**
  String get clerkSignInWithOneOfYourBackupCodes;

  /// No description provided for @clerkSignOut.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất'**
  String get clerkSignOut;

  /// No description provided for @clerkSignOutIdentifier.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất {identifier}'**
  String clerkSignOutIdentifier(String identifier);

  /// No description provided for @clerkSignOutOfAllAccounts.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất tất cả tài khoản'**
  String get clerkSignOutOfAllAccounts;

  /// No description provided for @clerkSignUp.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký'**
  String get clerkSignUp;

  /// No description provided for @clerkSignUpTo.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký vào {name}'**
  String clerkSignUpTo(String name);

  /// No description provided for @clerkSlug.
  ///
  /// In vi, this message translates to:
  /// **'Tên định danh'**
  String get clerkSlug;

  /// No description provided for @clerkSlugUrl.
  ///
  /// In vi, this message translates to:
  /// **'Đường dẫn định danh'**
  String get clerkSlugUrl;

  /// No description provided for @clerkSwitchTo.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển sang'**
  String get clerkSwitchTo;

  /// No description provided for @clerkTermsOfService.
  ///
  /// In vi, this message translates to:
  /// **'Điều khoản dịch vụ'**
  String get clerkTermsOfService;

  /// No description provided for @clerkTooManyRetries.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ đang bận. Vui lòng thử lại sau.'**
  String get clerkTooManyRetries;

  /// No description provided for @clerkTransferable.
  ///
  /// In vi, this message translates to:
  /// **'có thể chuyển tiếp'**
  String get clerkTransferable;

  /// No description provided for @clerkTwoStepVerification.
  ///
  /// In vi, this message translates to:
  /// **'Xác minh hai bước'**
  String get clerkTwoStepVerification;

  /// No description provided for @clerkTypeTypeInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Loại {type} không hợp lệ'**
  String clerkTypeTypeInvalid(String type);

  /// No description provided for @clerkUnknownError.
  ///
  /// In vi, this message translates to:
  /// **'Đã xảy ra lỗi khi xác thực. Vui lòng thử lại.'**
  String get clerkUnknownError;

  /// No description provided for @clerkUnsupportedPasswordResetStrategy.
  ///
  /// In vi, this message translates to:
  /// **'Chưa hỗ trợ phương thức đặt lại mật khẩu: {arg}'**
  String clerkUnsupportedPasswordResetStrategy(String arg);

  /// No description provided for @clerkUnverified.
  ///
  /// In vi, this message translates to:
  /// **'chưa xác minh'**
  String get clerkUnverified;

  /// No description provided for @clerkUsePasskeyInstead.
  ///
  /// In vi, this message translates to:
  /// **'Dùng khóa truy cập'**
  String get clerkUsePasskeyInstead;

  /// No description provided for @clerkUsername.
  ///
  /// In vi, this message translates to:
  /// **'tên đăng nhập'**
  String get clerkUsername;

  /// No description provided for @clerkVerificationEmailAddress.
  ///
  /// In vi, this message translates to:
  /// **'Xác minh địa chỉ email'**
  String get clerkVerificationEmailAddress;

  /// No description provided for @clerkVerificationPhoneNumber.
  ///
  /// In vi, this message translates to:
  /// **'Xác minh số điện thoại'**
  String get clerkVerificationPhoneNumber;

  /// No description provided for @clerkVerified.
  ///
  /// In vi, this message translates to:
  /// **'đã xác minh'**
  String get clerkVerified;

  /// No description provided for @clerkVerifiedDomains.
  ///
  /// In vi, this message translates to:
  /// **'Tên miền đã xác minh'**
  String get clerkVerifiedDomains;

  /// No description provided for @clerkVerifyThisDevice.
  ///
  /// In vi, this message translates to:
  /// **'Xác minh thiết bị này'**
  String get clerkVerifyThisDevice;

  /// No description provided for @clerkVerifyYourEmailAddress.
  ///
  /// In vi, this message translates to:
  /// **'Xác minh địa chỉ email của bạn'**
  String get clerkVerifyYourEmailAddress;

  /// No description provided for @clerkVerifyYourPhoneNumber.
  ///
  /// In vi, this message translates to:
  /// **'Xác minh số điện thoại của bạn'**
  String get clerkVerifyYourPhoneNumber;

  /// No description provided for @clerkViaAutomaticInvitation.
  ///
  /// In vi, this message translates to:
  /// **'qua lời mời tự động'**
  String get clerkViaAutomaticInvitation;

  /// No description provided for @clerkViaAutomaticSuggestion.
  ///
  /// In vi, this message translates to:
  /// **'qua đề xuất tự động'**
  String get clerkViaAutomaticSuggestion;

  /// No description provided for @clerkViaManualInvitation.
  ///
  /// In vi, this message translates to:
  /// **'qua lời mời trực tiếp'**
  String get clerkViaManualInvitation;

  /// No description provided for @clerkWeb3Wallet.
  ///
  /// In vi, this message translates to:
  /// **'ví Web3'**
  String get clerkWeb3Wallet;

  /// No description provided for @clerkWelcomeBackPleaseSignInToContinue.
  ///
  /// In vi, this message translates to:
  /// **'Chào mừng trở lại! Đăng nhập để tiếp tục'**
  String get clerkWelcomeBackPleaseSignInToContinue;

  /// No description provided for @clerkWelcomePleaseFillInTheDetailsToGetStarted.
  ///
  /// In vi, this message translates to:
  /// **'Chào bạn! Điền thông tin để bắt đầu'**
  String get clerkWelcomePleaseFillInTheDetailsToGetStarted;

  /// No description provided for @v3UploadCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Đã ngừng gửi. Tệp máy chủ đã nhận trước đó có thể vẫn được giữ riêng tư; chưa xác nhận lưu bài hát.'**
  String get v3UploadCancelled;

  /// No description provided for @v3LibrarySearch.
  ///
  /// In vi, this message translates to:
  /// **'Tìm trong thư viện của bạn'**
  String get v3LibrarySearch;

  /// No description provided for @v3ImageReady.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh mới đã sẵn sàng'**
  String get v3ImageReady;

  /// No description provided for @v3Working.
  ///
  /// In vi, this message translates to:
  /// **'Đang xử lý…'**
  String get v3Working;

  /// No description provided for @v3Sending.
  ///
  /// In vi, this message translates to:
  /// **'Đang gửi dữ liệu'**
  String get v3Sending;

  /// No description provided for @v3Confirming.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ máy chủ xác nhận lưu bài hát…'**
  String get v3Confirming;

  /// No description provided for @search.
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm'**
  String get search;

  /// No description provided for @v3Recent.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục nghe'**
  String get v3Recent;

  /// No description provided for @v3Genres.
  ///
  /// In vi, this message translates to:
  /// **'Khám phá thể loại'**
  String get v3Genres;

  /// No description provided for @v3Editorial.
  ///
  /// In vi, this message translates to:
  /// **'NHỮNG THANH ÂM CÓ CÂU CHUYỆN'**
  String get v3Editorial;

  /// No description provided for @v3HomeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Mở một thế giới nghe mới.'**
  String get v3HomeTitle;

  /// No description provided for @v3HomeSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Bản thu độc lập. Những người sáng tạo. Một nơi để tìm thấy nhau.'**
  String get v3HomeSubtitle;

  /// No description provided for @v3DiscoverTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đi tìm thanh âm của bạn.'**
  String get v3DiscoverTitle;

  /// No description provided for @v3DiscoverSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Khám phá những bản thu được chia sẻ công khai trên SoundShare.'**
  String get v3DiscoverSubtitle;

  /// No description provided for @v3Trending.
  ///
  /// In vi, this message translates to:
  /// **'Đang được lắng nghe'**
  String get v3Trending;

  /// No description provided for @v3TrendingNote.
  ///
  /// In vi, this message translates to:
  /// **'Xếp hạng thử nghiệm từ lượt nghe hợp lệ, người nghe, lượt thích và lưu trong cùng khoảng thời gian. Ngày tính theo giờ Việt Nam.'**
  String get v3TrendingNote;

  /// No description provided for @v3Creators.
  ///
  /// In vi, this message translates to:
  /// **'Những gương mặt nổi bật'**
  String get v3Creators;

  /// No description provided for @v3NewCreators.
  ///
  /// In vi, this message translates to:
  /// **'Nghệ sĩ mới đáng nghe'**
  String get v3NewCreators;

  /// No description provided for @v3NewReleases.
  ///
  /// In vi, this message translates to:
  /// **'Mới được chia sẻ'**
  String get v3NewReleases;

  /// No description provided for @v3FollowingFeed.
  ///
  /// In vi, this message translates to:
  /// **'Từ người bạn theo dõi'**
  String get v3FollowingFeed;

  /// No description provided for @v3ForYou.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý để bắt đầu'**
  String get v3ForYou;

  /// No description provided for @v3RecommendationNote.
  ///
  /// In vi, this message translates to:
  /// **'Ưu tiên thể loại bạn đã thích, sau đó là bản thu mới. Chưa có lượt thích? Bắt đầu với những bài mới nhất.'**
  String get v3RecommendationNote;

  /// No description provided for @v3SearchHint.
  ///
  /// In vi, this message translates to:
  /// **'Bài hát, nghệ sĩ hoặc @username'**
  String get v3SearchHint;

  /// No description provided for @v3SearchIntro.
  ///
  /// In vi, this message translates to:
  /// **'Một cái tên. Một thanh âm mới.'**
  String get v3SearchIntro;

  /// No description provided for @v3SearchDescription.
  ///
  /// In vi, this message translates to:
  /// **'Nhập @username để tìm người sáng tạo, hoặc tìm tên bài hát và nghệ sĩ.'**
  String get v3SearchDescription;

  /// No description provided for @v3All.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get v3All;

  /// No description provided for @v3Songs.
  ///
  /// In vi, this message translates to:
  /// **'Bài hát'**
  String get v3Songs;

  /// No description provided for @v3Accounts.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản'**
  String get v3Accounts;

  /// No description provided for @v3Playlists.
  ///
  /// In vi, this message translates to:
  /// **'Playlist'**
  String get v3Playlists;

  /// No description provided for @v3RecentSearches.
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm gần đây'**
  String get v3RecentSearches;

  /// No description provided for @v3SearchPrivacy.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ lưu trong phiên này; đăng xuất sẽ xóa lịch sử tìm kiếm.'**
  String get v3SearchPrivacy;

  /// No description provided for @v3NoContent.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có nội dung ở đây'**
  String get v3NoContent;

  /// No description provided for @v3NoContentDescription.
  ///
  /// In vi, this message translates to:
  /// **'Hãy thử tìm một người sáng tạo hoặc chia sẻ bản thu đầu tiên của bạn.'**
  String get v3NoContentDescription;

  /// No description provided for @v3Follow.
  ///
  /// In vi, this message translates to:
  /// **'Theo dõi'**
  String get v3Follow;

  /// No description provided for @v3Unfollow.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ theo dõi'**
  String get v3Unfollow;

  /// No description provided for @v3Following.
  ///
  /// In vi, this message translates to:
  /// **'Đang theo dõi'**
  String get v3Following;

  /// No description provided for @v3Followers.
  ///
  /// In vi, this message translates to:
  /// **'Người theo dõi'**
  String get v3Followers;

  /// No description provided for @v3ShareProfile.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép liên kết hồ sơ'**
  String get v3ShareProfile;

  /// No description provided for @v3Copied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép liên kết hồ sơ'**
  String get v3Copied;

  /// No description provided for @v3About.
  ///
  /// In vi, this message translates to:
  /// **'Giới thiệu'**
  String get v3About;

  /// No description provided for @v3EditProfile.
  ///
  /// In vi, this message translates to:
  /// **'Chỉnh sửa hồ sơ'**
  String get v3EditProfile;

  /// No description provided for @v3CreateProfile.
  ///
  /// In vi, this message translates to:
  /// **'Tạo hồ sơ SoundShare'**
  String get v3CreateProfile;

  /// No description provided for @v3ProfileIntro.
  ///
  /// In vi, this message translates to:
  /// **'Chọn tên công khai để người nghe có thể tìm thấy bạn. Hồ sơ này tách biệt với thông tin đăng nhập Clerk.'**
  String get v3ProfileIntro;

  /// No description provided for @v3Username.
  ///
  /// In vi, this message translates to:
  /// **'Username công khai'**
  String get v3Username;

  /// No description provided for @v3UsernamePolicy.
  ///
  /// In vi, this message translates to:
  /// **'3–24 ký tự: a–z, số, dấu chấm và gạch dưới; không có dấu chấm ở đầu/cuối. Không dùng tên dành riêng.'**
  String get v3UsernamePolicy;

  /// No description provided for @v3DisplayName.
  ///
  /// In vi, this message translates to:
  /// **'Tên hiển thị'**
  String get v3DisplayName;

  /// No description provided for @v3Bio.
  ///
  /// In vi, this message translates to:
  /// **'Đôi dòng về bạn'**
  String get v3Bio;

  /// No description provided for @v3Avatar.
  ///
  /// In vi, this message translates to:
  /// **'Đổi ảnh đại diện'**
  String get v3Avatar;

  /// No description provided for @v3Cover.
  ///
  /// In vi, this message translates to:
  /// **'Đổi ảnh bìa'**
  String get v3Cover;

  /// No description provided for @v3Save.
  ///
  /// In vi, this message translates to:
  /// **'Lưu thay đổi'**
  String get v3Save;

  /// No description provided for @v3Saved.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu'**
  String get v3Saved;

  /// No description provided for @v3Public.
  ///
  /// In vi, this message translates to:
  /// **'Công khai'**
  String get v3Public;

  /// No description provided for @v3Private.
  ///
  /// In vi, this message translates to:
  /// **'Riêng tư'**
  String get v3Private;

  /// No description provided for @v3Visibility.
  ///
  /// In vi, this message translates to:
  /// **'Ai có thể nghe?'**
  String get v3Visibility;

  /// No description provided for @v3Rights.
  ///
  /// In vi, this message translates to:
  /// **'Tôi có quyền chia sẻ công khai bản thu và ảnh bìa này.'**
  String get v3Rights;

  /// No description provided for @v3RightsRequired.
  ///
  /// In vi, this message translates to:
  /// **'Cần xác nhận quyền sử dụng nội dung trước khi chia sẻ công khai.'**
  String get v3RightsRequired;

  /// No description provided for @v3PublicHint.
  ///
  /// In vi, this message translates to:
  /// **'Bài công khai xuất hiện trong Khám phá và hồ sơ của bạn. Bài riêng tư chỉ bạn có thể nghe.'**
  String get v3PublicHint;

  /// No description provided for @v3ManageSongs.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý bài hát'**
  String get v3ManageSongs;

  /// No description provided for @v3EditSong.
  ///
  /// In vi, this message translates to:
  /// **'Sửa thông tin bài hát'**
  String get v3EditSong;

  /// No description provided for @v3DeleteSong.
  ///
  /// In vi, this message translates to:
  /// **'Xóa bài hát'**
  String get v3DeleteSong;

  /// No description provided for @v3DeleteConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Bài hát sẽ được gỡ khỏi thư viện và các trang khám phá. Bạn muốn tiếp tục?'**
  String get v3DeleteConfirm;

  /// No description provided for @v3Cancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get v3Cancel;

  /// No description provided for @v3Delete.
  ///
  /// In vi, this message translates to:
  /// **'Xóa'**
  String get v3Delete;

  /// No description provided for @v3SaveTrack.
  ///
  /// In vi, this message translates to:
  /// **'Lưu vào bộ sưu tập'**
  String get v3SaveTrack;

  /// No description provided for @v3RemoveSaved.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ lưu bài hát'**
  String get v3RemoveSaved;

  /// No description provided for @v3SavedTracks.
  ///
  /// In vi, this message translates to:
  /// **'Bài hát đã lưu'**
  String get v3SavedTracks;

  /// No description provided for @v3AddToPlaylist.
  ///
  /// In vi, this message translates to:
  /// **'Thêm vào playlist'**
  String get v3AddToPlaylist;

  /// No description provided for @v3CreatePlaylist.
  ///
  /// In vi, this message translates to:
  /// **'Tạo playlist'**
  String get v3CreatePlaylist;

  /// No description provided for @v3PlaylistTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tên playlist'**
  String get v3PlaylistTitle;

  /// No description provided for @v3RemoveFromPlaylist.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ khỏi playlist'**
  String get v3RemoveFromPlaylist;

  /// No description provided for @v3DeletePlaylist.
  ///
  /// In vi, this message translates to:
  /// **'Xóa playlist'**
  String get v3DeletePlaylist;

  /// No description provided for @v3More.
  ///
  /// In vi, this message translates to:
  /// **'Tải thêm'**
  String get v3More;

  /// No description provided for @v3PreviousPage.
  ///
  /// In vi, this message translates to:
  /// **'Trang trước'**
  String get v3PreviousPage;

  /// No description provided for @v3Today.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get v3Today;

  /// No description provided for @v3Week.
  ///
  /// In vi, this message translates to:
  /// **'7 ngày'**
  String get v3Week;

  /// No description provided for @v3Month.
  ///
  /// In vi, this message translates to:
  /// **'30 ngày'**
  String get v3Month;

  /// No description provided for @v3AllTime.
  ///
  /// In vi, this message translates to:
  /// **'Mọi thời điểm'**
  String get v3AllTime;

  /// No description provided for @v3Featured.
  ///
  /// In vi, this message translates to:
  /// **'Nổi bật'**
  String get v3Featured;

  /// No description provided for @v3Newest.
  ///
  /// In vi, this message translates to:
  /// **'Mới tham gia'**
  String get v3Newest;

  /// No description provided for @v3Popular.
  ///
  /// In vi, this message translates to:
  /// **'Nhiều người theo dõi'**
  String get v3Popular;

  /// No description provided for @v3Growing.
  ///
  /// In vi, this message translates to:
  /// **'Đang phát triển'**
  String get v3Growing;

  /// No description provided for @v3Report.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo nội dung'**
  String get v3Report;

  /// No description provided for @v3ReportReceived.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi nhận báo cáo để xem xét. Nội dung chưa tự động bị gỡ.'**
  String get v3ReportReceived;

  /// No description provided for @v3Copyright.
  ///
  /// In vi, this message translates to:
  /// **'Quyền sử dụng nội dung'**
  String get v3Copyright;

  /// No description provided for @v3Abuse.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung không phù hợp'**
  String get v3Abuse;

  /// No description provided for @v3Spam.
  ///
  /// In vi, this message translates to:
  /// **'Spam'**
  String get v3Spam;

  /// No description provided for @v3Other.
  ///
  /// In vi, this message translates to:
  /// **'Lý do khác'**
  String get v3Other;

  /// No description provided for @v3Queue.
  ///
  /// In vi, this message translates to:
  /// **'Danh sách phát'**
  String get v3Queue;

  /// No description provided for @v3AddToQueue.
  ///
  /// In vi, this message translates to:
  /// **'Thêm vào danh sách phát'**
  String get v3AddToQueue;

  /// No description provided for @v3RemoveFromQueue.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ khỏi danh sách phát'**
  String get v3RemoveFromQueue;

  /// No description provided for @v3QueueEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chọn một bài hát để bắt đầu danh sách phát.'**
  String get v3QueueEmpty;

  /// No description provided for @v3UsernameTaken.
  ///
  /// In vi, this message translates to:
  /// **'Username này đã có người sử dụng. Hãy chọn tên khác.'**
  String get v3UsernameTaken;

  /// No description provided for @v3ProfileRequired.
  ///
  /// In vi, this message translates to:
  /// **'Hãy tạo hồ sơ SoundShare và chọn username trước khi đăng bài công khai.'**
  String get v3ProfileRequired;

  /// No description provided for @v3InvalidProfile.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra username và các thông tin đã nhập.'**
  String get v3InvalidProfile;

  /// No description provided for @v3Unavailable.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tải được nội dung. Kiểm tra kết nối và thử lại.'**
  String get v3Unavailable;

  /// No description provided for @v3Views.
  ///
  /// In vi, this message translates to:
  /// **'lượt nghe hợp lệ'**
  String get v3Views;

  /// No description provided for @v3Likes.
  ///
  /// In vi, this message translates to:
  /// **'lượt thích'**
  String get v3Likes;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
