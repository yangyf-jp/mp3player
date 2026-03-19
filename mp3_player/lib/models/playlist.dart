import 'dart:convert';

/// Represents a playlist in the application
class Playlist {
  final String id;
  String name;
  String? description;
  String playbackStrategyId;
  bool isSpecial;
  int orderIndex;
  DateTime createdAt;
  DateTime updatedAt;

  Playlist({
    required this.id,
    required this.name,
    this.description,
    required this.playbackStrategyId,
    this.isSpecial = false,
    this.orderIndex = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'playback_strategy_id': playbackStrategyId,
      'is_special': isSpecial ? 1 : 0,
      'order_index': orderIndex,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Playlist.fromMap(Map<String, dynamic> map) {
    return Playlist(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      playbackStrategyId: map['playback_strategy_id'],
      isSpecial: map['is_special'] == 1,
      orderIndex: map['order_index'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  String toJson() => json.encode(toMap());

  factory Playlist.fromJson(String source) =>
      Playlist.fromMap(json.decode(source));

  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    String? playbackStrategyId,
    bool? isSpecial,
    int? orderIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      playbackStrategyId: playbackStrategyId ?? this.playbackStrategyId,
      isSpecial: isSpecial ?? this.isSpecial,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Represents a track (MP3 file) in a playlist
class PlaylistTrack {
  final String id;
  final String playlistId;
  final String filePath;
  final String fileName;
  final String? title;
  final String? artist;
  final String? album;
  final int duration; // in milliseconds
  final int orderIndex;
  final DateTime addedAt;

  PlaylistTrack({
    required this.id,
    required this.playlistId,
    required this.filePath,
    required this.fileName,
    this.title,
    this.artist,
    this.album,
    this.duration = 0,
    this.orderIndex = 0,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'playlist_id': playlistId,
      'file_path': filePath,
      'file_name': fileName,
      'title': title,
      'artist': artist,
      'album': album,
      'duration': duration,
      'order_index': orderIndex,
      'added_at': addedAt.toIso8601String(),
    };
  }

  factory PlaylistTrack.fromMap(Map<String, dynamic> map) {
    return PlaylistTrack(
      id: map['id'],
      playlistId: map['playlist_id'],
      filePath: map['file_path'],
      fileName: map['file_name'],
      title: map['title'],
      artist: map['artist'],
      album: map['album'],
      duration: map['duration'] ?? 0,
      orderIndex: map['order_index'] ?? 0,
      addedAt: DateTime.parse(map['added_at']),
    );
  }

  String toJson() => json.encode(toMap());

  factory PlaylistTrack.fromJson(String source) =>
      PlaylistTrack.fromMap(json.decode(source));

  PlaylistTrack copyWith({
    String? id,
    String? playlistId,
    String? filePath,
    String? fileName,
    String? title,
    String? artist,
    String? album,
    int? duration,
    int? orderIndex,
    DateTime? addedAt,
  }) {
    return PlaylistTrack(
      id: id ?? this.id,
      playlistId: playlistId ?? this.playlistId,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      orderIndex: orderIndex ?? this.orderIndex,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}
