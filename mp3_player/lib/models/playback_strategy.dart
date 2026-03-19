import 'dart:convert';

/// Playback mode enum
enum PlaybackMode {
  sequential, // Play tracks in order
  shuffle,    // Play tracks randomly
}

/// Playlist play control enum
enum PlayControl {
  singlePlay,   // Play playlist once
  loopPlaylist, // Loop the entire playlist
}

/// Represents a playback strategy
class PlaybackStrategy {
  final String id;
  String name;
  int intervalSeconds;     // Delay between tracks (in seconds)
  int repeatCount;         // Number of times to repeat each track
  PlaybackMode playbackMode;
  PlayControl playControl;
  DateTime createdAt;
  DateTime updatedAt;

  PlaybackStrategy({
    required this.id,
    required this.name,
    this.intervalSeconds = 0,
    this.repeatCount = 1,
    this.playbackMode = PlaybackMode.sequential,
    this.playControl = PlayControl.singlePlay,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'interval_seconds': intervalSeconds,
      'repeat_count': repeatCount,
      'playback_mode': playbackMode.index,
      'play_control': playControl.index,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory PlaybackStrategy.fromMap(Map<String, dynamic> map) {
    return PlaybackStrategy(
      id: map['id'],
      name: map['name'],
      intervalSeconds: map['interval_seconds'] ?? 0,
      repeatCount: map['repeat_count'] ?? 1,
      playbackMode: PlaybackMode.values[map['playback_mode'] ?? 0],
      playControl: PlayControl.values[map['play_control'] ?? 0],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  String toJson() => json.encode(toMap());

  factory PlaybackStrategy.fromJson(String source) =>
      PlaybackStrategy.fromMap(json.decode(source));

  PlaybackStrategy copyWith({
    String? id,
    String? name,
    int? intervalSeconds,
    int? repeatCount,
    PlaybackMode? playbackMode,
    PlayControl? playControl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlaybackStrategy(
      id: id ?? this.id,
      name: name ?? this.name,
      intervalSeconds: intervalSeconds ?? this.intervalSeconds,
      repeatCount: repeatCount ?? this.repeatCount,
      playbackMode: playbackMode ?? this.playbackMode,
      playControl: playControl ?? this.playControl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get playbackModeLabel {
    switch (playbackMode) {
      case PlaybackMode.sequential:
        return '顺序播放';
      case PlaybackMode.shuffle:
        return '随机播放';
    }
  }

  String get playControlLabel {
    switch (playControl) {
      case PlayControl.singlePlay:
        return '单次播放';
      case PlayControl.loopPlaylist:
        return '循环播放';
    }
  }
}
