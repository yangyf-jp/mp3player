import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/playlist.dart';
import '../models/playback_strategy.dart';
import '../services/database_service.dart';
import '../services/audio_player_service.dart';

/// Main application state provider
class AppProvider extends ChangeNotifier {
  final DatabaseService dbService = DatabaseService();
  final Uuid _uuid = const Uuid();

  List<Playlist> _playlists = [];
  List<PlaybackStrategy> _strategies = [];
  Playlist? _selectedPlaylist;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Playlist> get playlists => _playlists;
  List<PlaybackStrategy> get strategies => _strategies;
  Playlist? get selectedPlaylist => _selectedPlaylist;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Playlist> get specialPlaylists => 
      _playlists.where((p) => p.isSpecial).toList();

  List<Playlist> get normalPlaylists => 
      _playlists.where((p) => !p.isSpecial).toList();

  AppProvider() {
    loadData();
  }

  /// Load all data from database
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        _loadPlaylists(),
        _loadStrategies(),
      ]);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadPlaylists() async {
    _playlists = await dbService.getAllPlaylists();
  }

  Future<void> _loadStrategies() async {
    _strategies = await dbService.getAllPlaybackStrategies();
  }

  // ==================== Playlist Management ====================

  /// Create a new playlist
  Future<void> createPlaylist({
    required String name,
    String? description,
    bool isSpecial = false,
    String? strategyId,
  }) async {
    final playlist = Playlist(
      id: _uuid.v4(),
      name: name,
      description: description,
      playbackStrategyId: strategyId ?? _strategies.firstOrNull?.id ?? 'default',
      isSpecial: isSpecial,
      orderIndex: _playlists.length,
    );

    await dbService.createPlaylist(playlist);
    await _loadPlaylists();
    notifyListeners();
  }

  /// Update playlist
  Future<void> updatePlaylist(Playlist playlist) async {
    await dbService.updatePlaylist(playlist);
    await _loadPlaylists();
    if (_selectedPlaylist?.id == playlist.id) {
      _selectedPlaylist = playlist;
    }
    notifyListeners();
  }

  /// Delete playlist
  Future<void> deletePlaylist(String playlistId) async {
    // Check if this playlist is currently selected
    if (_selectedPlaylist?.id == playlistId) {
      _selectedPlaylist = null;
    }
    
    await dbService.deletePlaylist(playlistId);
    await _loadPlaylists();
    notifyListeners();
  }

  /// Select a playlist
  void selectPlaylist(Playlist? playlist) {
    _selectedPlaylist = playlist;
    notifyListeners();
  }

  /// Reorder playlists
  Future<void> reorderPlaylists(List<String> playlistIds) async {
    await dbService.reorderPlaylists(playlistIds);
    await _loadPlaylists();
    notifyListeners();
  }

  // ==================== Track Management ====================

  /// Add tracks to playlist
  Future<void> addTracksToPlaylist(
    String playlistId,
    List<String> filePaths,
  ) async {
    final existingTracks = await dbService.getTracksByPlaylistId(playlistId);
    final existingPaths = existingTracks.map((t) => t.filePath).toSet();
    
    int orderIndex = existingTracks.length;
    
    for (final path in filePaths) {
      if (!existingPaths.contains(path)) {
        final fileName = path.split('\\').last.split('/').last;
        final track = PlaylistTrack(
          id: _uuid.v4(),
          playlistId: playlistId,
          filePath: path,
          fileName: fileName,
          orderIndex: orderIndex++,
        );
        await dbService.addTrackToPlaylist(track);
      }
    }
    
    notifyListeners();
  }

  /// Remove track from playlist
  Future<void> removeTrackFromPlaylist(String trackId) async {
    await dbService.removeTrackFromPlaylist(trackId);
    notifyListeners();
  }

  /// Reorder tracks in playlist
  Future<void> reorderTracks(String playlistId, List<String> trackIds) async {
    await dbService.reorderTracks(playlistId, trackIds);
    notifyListeners();
  }

  // ==================== Strategy Management ====================

  /// Create a new playback strategy
  Future<void> createPlaybackStrategy({
    required String name,
    int intervalSeconds = 0,
    int repeatCount = 1,
    PlaybackMode playbackMode = PlaybackMode.sequential,
    PlayControl playControl = PlayControl.singlePlay,
  }) async {
    final strategy = PlaybackStrategy(
      id: _uuid.v4(),
      name: name,
      intervalSeconds: intervalSeconds,
      repeatCount: repeatCount,
      playbackMode: playbackMode,
      playControl: playControl,
    );

    await dbService.createPlaybackStrategy(strategy);
    await _loadStrategies();
    notifyListeners();
  }

  /// Update playback strategy
  Future<void> updatePlaybackStrategy(PlaybackStrategy strategy) async {
    await dbService.updatePlaybackStrategy(strategy);
    await _loadStrategies();
    notifyListeners();
  }

  /// Delete playback strategy
  Future<void> deletePlaybackStrategy(String strategyId) async {
    final result = await dbService.deletePlaybackStrategy(strategyId);
    if (result == -1) {
      throw Exception('无法删除正在使用的播放策略');
    }
    await _loadStrategies();
    notifyListeners();
  }

  /// Check if strategy is in use
  bool isStrategyInUse(String strategyId) {
    return _playlists.any((p) => p.playbackStrategyId == strategyId);
  }

  // ==================== Playlist Strategy ====================

  /// Update playlist's playback strategy
  Future<void> updatePlaylistStrategy(String playlistId, String strategyId) async {
    final playlist = _playlists.firstWhere((p) => p.id == playlistId);
    final updatedPlaylist = playlist.copyWith(playbackStrategyId: strategyId);
    await updatePlaylist(updatedPlaylist);
  }
}
