/// Only local, decoded images may leave Dart for Android's public metadata.
abstract class MediaArtworkStore {
  Future<Uri?> resolve(String artworkUrl);
  void dispose();
}
