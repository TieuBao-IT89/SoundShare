import 'dart:typed_data';

import '../../../core/services/upload_control.dart';

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
    this.visibility = 'private',
    this.rightsConfirmed = false,
    this.transfer,
  });
  final String title, artist, genre, description, audioName;
  final Uint8List audioBytes;
  final String? artworkName;
  final Uint8List? artworkBytes;
  final String visibility;
  final bool rightsConfirmed;
  final UploadControl? transfer;
}
