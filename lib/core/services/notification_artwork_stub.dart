import 'media_artwork.dart';

MediaArtworkStore createNotificationArtwork() => _NoArtwork();

class _NoArtwork implements MediaArtworkStore {
  @override
  Future<Uri?> resolve(String artworkUrl) async => null;
  @override
  void dispose() {}
}
