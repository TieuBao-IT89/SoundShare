class Song {
  const Song({
    required this.title,
    required this.artist,
    required this.artwork,
    required this.duration,
    this.genre = 'Indie',
    this.audioUrl =
        'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
  });

  final String title;
  final String artist;
  final String artwork;
  final String duration;
  final String genre;
  final String audioUrl;
}

const sampleSongs = <Song>[
  Song(
    title: 'Slow Motion',
    artist: 'Mila Sol',
    artwork:
        'https://images.unsplash.com/photo-1519608487953-e999c86e7455?w=800',
    duration: '3:42',
    genre: 'Dream pop',
  ),
  Song(
    title: 'Golden Hour',
    artist: 'Juniper Lane',
    artwork:
        'https://images.unsplash.com/photo-1470252649378-9c29740c9fa8?w=800',
    duration: '4:08',
    genre: 'Indie folk',
  ),
  Song(
    title: 'Afterglow',
    artist: 'Theo Rivers',
    artwork:
        'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=800',
    duration: '3:26',
    genre: 'Alternative',
  ),
  Song(
    title: 'Blue Again',
    artist: 'Nia Bloom',
    artwork:
        'https://images.unsplash.com/photo-1518837695005-2083093ee35b?w=800',
    duration: '2:58',
    genre: 'Electronic',
  ),
];
