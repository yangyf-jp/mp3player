import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:uuid/uuid.dart';
import '../models/playlist.dart';
import '../models/playback_strategy.dart';
import '../services/database_service.dart';

/// Audio player service that handles playback with strategies
class AudioPlayerService extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final DatabaseService _dbService = DatabaseService();
  final Uuid _uuid = const Uuid();

  List<PlaylistTrack> _currentPlaylist = [];
  int _currentIndex = -1;
  Playlist? _currentPlaylistModel;
  PlaybackStrategy? _currentStrategy;
  
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  int _currentRepeatCount = 0;
  bool _isPlaylistFinished = false;

  // Getters
  AudioPlayer get audioPlayer => _audioPlayer;
  List<PlaylistTrack> get currentPlaylist => _currentPlaylist;
  int get currentIndex => _currentIndex;
  Playlist? get currentPlaylistModel => _currentPlaylistModel;
  PlaybackStrategy? get currentStrategy => _currentStrategy;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  Duration get position => _position;
  Duration get duration => _duration;
  PlaylistTrack? get currentTrack => 
      _currentIndex >= 0 && _currentIndex < _currentPlaylist.length 
          ? _currentPlaylist[_currentIndex] 
          : null;
  bool get isPlaylistFinished => _isPlaylistFinished;

  AudioPlayerService() {
    _initListeners();
  }

  void _initListeners() {
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      if (state.processingState == ProcessingState.completed) {
        _onTrackComplete();
      }
      notifyListeners();
    });

    _audioPlayer.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _audioPlayer.durationStream.listen((dur) {
      _duration = dur ?? Duration.zero;
      notifyListeners();
    });
  }

  /// Load and play a playlist with the given strategy
  Future<void> loadPlaylist({
    required Playlist playlist,
    required List<PlaylistTrack> tracks,
    required PlaybackStrategy strategy,
    int startIndex = 0,
  }) async {
    _currentPlaylistModel = playlist;
    _currentPlaylist = List.from(tracks);
    _currentStrategy = strategy;
    _currentIndex = -1;
    _currentRepeatCount = 0;
    _isPlaylistFinished = false;
    
    notifyListeners();
    
    if (_currentPlaylist.isNotEmpty && startIndex < _currentPlaylist.length) {
      await _playTrackAt(startIndex);
    }
  }

  /// Play track at specific index
  Future<void> _playTrackAt(int index) async {
    if (index < 0 || index >= _currentPlaylist.length) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      final track = _currentPlaylist[index];
      final file = File(track.filePath);
      
      if (!await file.exists()) {
        // File doesn't exist, skip to next
        await _skipToNext();
        return;
      }

      _currentIndex = index;
      await _audioPlayer.setFilePath(track.filePath);
      await _audioPlayer.play();
      _currentRepeatCount = 0;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      // Try to play next track on error
      await _skipToNext();
    }
  }

  /// Handle track completion based on strategy
  Future<void> _onTrackComplete() async {
    if (_currentStrategy == null) return;

    _currentRepeatCount++;

    // Check if we need to repeat the current track
    if (_currentRepeatCount < _currentStrategy!.repeatCount) {
      // Repeat current track
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
      return;
    }

    // Reset repeat count for next track
    _currentRepeatCount = 0;

    // Apply interval delay
    if (_currentStrategy!.intervalSeconds > 0) {
      await Future.delayed(Duration(seconds: _currentStrategy!.intervalSeconds));
    }

    // Move to next track
    await _skipToNext();
  }

  /// Skip to next track based on strategy
  Future<void> _skipToNext() async {
    if (_currentPlaylist.isEmpty || _currentStrategy == null) return;

    int nextIndex;

    if (_currentStrategy!.playbackMode == PlaybackMode.shuffle) {
      // Random next track
      nextIndex = _getRandomNextIndex();
    } else {
      // Sequential next track
      nextIndex = _currentIndex + 1;
      
      // Check if we've reached the end
      if (nextIndex >= _currentPlaylist.length) {
        if (_currentStrategy!.playControl == PlayControl.loopPlaylist) {
          // Loop back to start
          nextIndex = 0;
        } else {
          // Playlist finished
          _isPlaylistFinished = true;
          _isPlaying = false;
          notifyListeners();
          return;
        }
      }
    }

    await _playTrackAt(nextIndex);
  }

  /// Get random next index (not the current one)
  int _getRandomNextIndex() {
    if (_currentPlaylist.length <= 1) return 0;
    
    int nextIndex;
    do {
      nextIndex = DateTime.now().millisecondsSinceEpoch % _currentPlaylist.length;
    } while (nextIndex == _currentIndex && _currentPlaylist.length > 1);
    
    return nextIndex;
  }

  /// Play or pause current track
  Future<void> playPause() async {
    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  /// Play current track
  Future<void> play() async {
    await _audioPlayer.play();
  }

  /// Pause current track
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  /// Stop playback
  Future<void> stop() async {
    await _audioPlayer.stop();
    _currentIndex = -1;
    _isPlaying = false;
    _isPlaylistFinished = false;
    notifyListeners();
  }

  /// Skip to previous track
  Future<void> skipPrevious() async {
    if (_currentPlaylist.isEmpty) return;
    
    // If we're more than 3 seconds into the track, restart it
    if (_position.inSeconds > 3) {
      await _audioPlayer.seek(Duration.zero);
      return;
    }
    
    int prevIndex = _currentIndex - 1;
    if (prevIndex < 0) {
      if (_currentStrategy?.playControl == PlayControl.loopPlaylist) {
        prevIndex = _currentPlaylist.length - 1;
      } else {
        prevIndex = 0;
      }
    }
    
    await _playTrackAt(prevIndex);
  }

  /// Skip to next track manually
  Future<void> skipNext() async {
    _currentRepeatCount = _currentStrategy?.repeatCount ?? 1; // Force track change
    await _onTrackComplete();
  }

  /// Seek to position
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  /// Update playback strategy (takes effect on next track)
  Future<void> updateStrategy(PlaybackStrategy newStrategy) async {
    _currentStrategy = newStrategy;
    notifyListeners();
  }

  /// Add track to special playlist
  Future<void> addTrackToSpecialPlaylist(PlaylistTrack track, String targetPlaylistId) async {
    final existingTracks = await _dbService.getTracksByPlaylistId(targetPlaylistId);
    final exists = existingTracks.any((t) => t.filePath == track.filePath);
    
    if (!exists) {
      final newTrack = PlaylistTrack(
        id: _uuid.v4(),
        playlistId: targetPlaylistId,
        filePath: track.filePath,
        fileName: track.fileName,
        title: track.title,
        artist: track.artist,
        album: track.album,
        duration: track.duration,
        orderIndex: existingTracks.length,
      );
      await _dbService.addTrackToPlaylist(newTrack);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
