# SoundShare — Vinyl Now Playing

> Báo cáo lịch sử trước Vinyl Player 2.0. Giao diện và kết quả kiểm tra mới nằm trong [báo cáo 2.0](vinyl-player-v2-review.md).

Artwork của bản thu trở thành nhãn giữa một đĩa vinyl: thân charcoal, rãnh đồng tâm mảnh, viền nhãn, lỗ tâm và reflection nhẹ. Giữ kích thước vùng artwork, bố cục thông tin, tiến trình và nút điều khiển hiện tại; bóng đổ theo hình tròn thay cho glow vuông quanh artwork.

Tham khảo [Vinyl Music Player — Tom.vsx](https://dribbble.com/shots/14611479-Vinyl-Music-Player-App-UI-Concept) và [Vinyl Player — Ana Carolina Magalhães](https://dribbble.com/shots/27364872-Vinyl-Player-Music-Player-UI). Dùng màu và ảnh bìa hiện có của SoundShare, nhãn chiếm 58% đường kính để vẫn nhận diện bài hát. Không thêm package hoặc artwork thương mại.

## Mã nguồn và chuyển động

- `lib/core/widgets/vinyl_record_artwork.dart`: widget tái sử dụng, một `AnimationController` vòng 12 giây và `RotationTransition`. Pause giữ nguyên value; repeat tiếp tục từ góc hiện tại. Bề mặt đĩa/nhãn có `RepaintBoundary`; bóng đổ, reflection và lỗ tâm đứng yên.
- `lib/features/player/presentation/player_screen.dart`: đọc `playerStateStream`/`playerState` của cùng `audioPlayerProvider`. Chỉ chuyển `playing=true` cho đĩa khi audio đang phát và ready, không loading/lỗi. Không tạo player hoặc trạng thái playback khác. Hero giữ tag của bài hiện tại.
- Reduce Motion, route/TickerMode ẩn và lifecycle nền dừng controller mà không reset góc. Artwork thiếu/lỗi giữ fallback của `Artwork`; controller được dispose khi rời widget.
- Trạng thái catalog đang tải được bọc vùng cuộn để vừa màn hình ngang thấp. Nội dung player sau khi tải giữ bố cục cũ.
- `DESIGN.md` cập nhật hành vi. Kiểm thử playback dùng chờ số frame hữu hạn khi đĩa đang quay, vì animation này chủ động không kết thúc.

Các file kiểm thử điều chỉnh cách chờ: `test/support/test_app.dart`, `test/aurora_player_test.dart`, `test/obsidian_experience_test.dart` và `test/recommendations_test.dart`. Kiểm thử rotation/UI mới nằm trong `test/vinyl_record_artwork_test.dart`.

## Ảnh widget

Ảnh được render từ Flutter widget test với font của ứng dụng, bìa tổng hợp trong test và fake AudioPlayer. Bìa mẫu được đưa qua cùng pipeline `Artwork` bằng image cache; các assertion xác nhận ảnh đã decode. Chưa nghiệm thu chuyển động/FPS trên trình duyệt hoặc thiết bị native thật.

| Bố cục | Sáng | Tối |
|---|---|---|
| Điện thoại 390 px, đang phát | [Ảnh](vinyl-player/player-390-light-playing.png) | [Ảnh](vinyl-player/player-390-dark-playing.png) |
| Điện thoại 390 px, dừng | [Ảnh](vinyl-player/player-390-light.png) | [Ảnh](vinyl-player/player-390-dark.png) |
| Điện thoại 320 px, chữ 2× | [Ảnh](vinyl-player/player-320-light.png) | [Ảnh](vinyl-player/player-320-dark.png) |
| Desktop 1280 px | [Ảnh](vinyl-player/player-1280-light.png) | [Ảnh](vinyl-player/player-1280-dark.png) |
| Ngang 844×390 px | [Ảnh](vinyl-player/player-844-light.png) | [Ảnh](vinyl-player/player-844-dark.png) |

## Kiểm thử

`flutter analyze` sạch; `flutter test --dart-define=CAPTURE_VINYL_REVIEW=true` có **253 kiểm thử đạt**. Kiểm tra định dạng các file đã sửa và `git diff --check` đạt.

`test/vinyl_record_artwork_test.dart` có 16 kiểm thử: tốc độ/chiều quay/vòng lặp, pause/resume và rebuild/theme, Reduce Motion, TickerMode, lifecycle/dispose, fallback/semantics, liên kết audio thật trong UI qua fake player (ready/buffering/completed) và bố cục sáng/tối ở 320/390/430/844/1280 px. Các kiểm thử player/mini-player hiện có tiếp tục xác nhận chung tiến trình, nguồn audio và queue.

Tạo lại ảnh bằng:

```powershell
flutter test --dart-define=CAPTURE_VINYL_REVIEW=true test/vinyl_record_artwork_test.dart
```

Kết quả ảnh ở `build/vinyl-review/`. Fixture không dùng tài khoản, Neon, Cloud Storage hoặc nhạc thật.
