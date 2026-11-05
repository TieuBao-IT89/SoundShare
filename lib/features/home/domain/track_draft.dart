import 'dart:typed_data';

class TrackDraft {
  const TrackDraft({
    required this.title,
    required this.artist,
    required this.genre,
    required this.description,
    required this.audioName,
    required this.audioBytes,
    this.artworkName,
    this.artworkBytes,
  });
  final String title, artist, genre, description, audioName;
  final Uint8List audioBytes;
  final String? artworkName;
  final Uint8List? artworkBytes;
}
