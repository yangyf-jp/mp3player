import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/playlist.dart';
import '../models/playback_strategy.dart';

/// Database service for managing playlists, tracks, and playback strategies
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Initialize FFI for Windows
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'mp3_player.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create playlists table
    await db.execute('''
      CREATE TABLE playlists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        playback_strategy_id TEXT NOT NULL,
        is_special INTEGER DEFAULT 0,
        order_index INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create playlist_tracks table
    await db.execute('''
      CREATE TABLE playlist_tracks (
        id TEXT PRIMARY KEY,
        playlist_id TEXT NOT NULL,
        file_path TEXT NOT NULL,
        file_name TEXT NOT NULL,
        title TEXT,
        artist TEXT,
        album TEXT,
        duration INTEGER DEFAULT 0,
        order_index INTEGER DEFAULT 0,
        added_at TEXT NOT NULL,
        FOREIGN KEY (playlist_id) REFERENCES playlists(id) ON DELETE CASCADE
      )
    ''');

    // Create playback_strategies table
    await db.execute('''
      CREATE TABLE playback_strategies (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        interval_seconds INTEGER DEFAULT 0,
        repeat_count INTEGER DEFAULT 1,
        playback_mode INTEGER DEFAULT 0,
        play_control INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_playlist_tracks_playlist_id ON playlist_tracks(playlist_id)');
    await db.execute('CREATE INDEX idx_playlist_tracks_order ON playlist_tracks(playlist_id, order_index)');
    await db.execute('CREATE INDEX idx_playlists_order ON playlists(order_index)');
    await db.execute('CREATE INDEX idx_playlists_special ON playlists(is_special)');

    // Insert default playback strategy
    final defaultStrategy = PlaybackStrategy(
      id: 'default',
      name: '默认策略',
      intervalSeconds: 0,
      repeatCount: 1,
      playbackMode: PlaybackMode.sequential,
      playControl: PlayControl.singlePlay,
    );
    await db.insert('playback_strategies', defaultStrategy.toMap());
  }

  // ==================== Playlist Operations ====================

  Future<int> createPlaylist(Playlist playlist) async {
    final db = await database;
    return await db.insert('playlists', playlist.toMap());
  }

  Future<List<Playlist>> getAllPlaylists() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'playlists',
      orderBy: 'order_index ASC',
    );
    return List.generate(maps.length, (i) => Playlist.fromMap(maps[i]));
  }

  Future<List<Playlist>> getSpecialPlaylists() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'playlists',
      where: 'is_special = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Playlist.fromMap(maps[i]));
  }

  Future<Playlist?> getPlaylistById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'playlists',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Playlist.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updatePlaylist(Playlist playlist) async {
    final db = await database;
    return await db.update(
      'playlists',
      playlist.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [playlist.id],
    );
  }

  Future<int> deletePlaylist(String id) async {
    final db = await database;
    // First delete all tracks in the playlist
    await db.delete(
      'playlist_tracks',
      where: 'playlist_id = ?',
      whereArgs: [id],
    );
    // Then delete the playlist
    return await db.delete(
      'playlists',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> reorderPlaylists(List<String> playlistIds) async {
    final db = await database;
    await db.transaction((txn) async {
      for (int i = 0; i < playlistIds.length; i++) {
        await txn.rawUpdate(
          'UPDATE playlists SET order_index = ?, updated_at = ? WHERE id = ?',
          [i, DateTime.now().toIso8601String(), playlistIds[i]],
        );
      }
    });
  }

  // ==================== Playlist Track Operations ====================

  Future<int> addTrackToPlaylist(PlaylistTrack track) async {
    final db = await database;
    return await db.insert('playlist_tracks', track.toMap());
  }

  Future<List<PlaylistTrack>> getTracksByPlaylistId(String playlistId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'playlist_tracks',
      where: 'playlist_id = ?',
      whereArgs: [playlistId],
      orderBy: 'order_index ASC',
    );
    return List.generate(maps.length, (i) => PlaylistTrack.fromMap(maps[i]));
  }

  Future<int> removeTrackFromPlaylist(String trackId) async {
    final db = await database;
    return await db.delete(
      'playlist_tracks',
      where: 'id = ?',
      whereArgs: [trackId],
    );
  }

  Future<void> reorderTracks(String playlistId, List<String> trackIds) async {
    final db = await database;
    await db.transaction((txn) async {
      for (int i = 0; i < trackIds.length; i++) {
        await txn.rawUpdate(
          'UPDATE playlist_tracks SET order_index = ? WHERE id = ?',
          [i, trackIds[i]],
        );
      }
    });
  }

  Future<bool> trackExistsInPlaylist(String playlistId, String filePath) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'playlist_tracks',
      where: 'playlist_id = ? AND file_path = ?',
      whereArgs: [playlistId, filePath],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  // ==================== Playback Strategy Operations ====================

  Future<int> createPlaybackStrategy(PlaybackStrategy strategy) async {
    final db = await database;
    return await db.insert('playback_strategies', strategy.toMap());
  }

  Future<List<PlaybackStrategy>> getAllPlaybackStrategies() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'playback_strategies',
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => PlaybackStrategy.fromMap(maps[i]));
  }

  Future<PlaybackStrategy?> getPlaybackStrategyById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'playback_strategies',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return PlaybackStrategy.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updatePlaybackStrategy(PlaybackStrategy strategy) async {
    final db = await database;
    return await db.update(
      'playback_strategies',
      strategy.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [strategy.id],
    );
  }

  Future<int> deletePlaybackStrategy(String id) async {
    final db = await database;
    // Check if any playlist is using this strategy
    final List<Map<String, dynamic>> usageCheck = await db.query(
      'playlists',
      where: 'playback_strategy_id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (usageCheck.isNotEmpty) {
      // Strategy is in use, cannot delete
      return -1;
    }
    
    return await db.delete(
      'playback_strategies',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> isStrategyInUse(String strategyId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'playlists',
      where: 'playback_strategy_id = ?',
      whereArgs: [strategyId],
      limit: 1,
    );
    return maps.isNotEmpty;
  }
}
