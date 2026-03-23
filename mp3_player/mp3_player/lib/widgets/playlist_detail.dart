import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../models/playlist.dart';
import '../models/playback_strategy.dart';
import '../providers/app_provider.dart';
import '../services/audio_player_service.dart';

/// Playlist detail widget showing tracks with reorder support
class PlaylistDetailWidget extends StatefulWidget {
  final Playlist playlist;
  final List<PlaylistTrack> tracks;

  const PlaylistDetailWidget({
    super.key,
    required this.playlist,
    required this.tracks,
  });

  @override
  State<PlaylistDetailWidget> createState() => _PlaylistDetailWidgetState();
}

class _PlaylistDetailWidgetState extends State<PlaylistDetailWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer2<AppProvider, AudioPlayerService>(
      builder: (context, appProvider, audioService, child) {
        return Column(
          children: [
            // Playlist header with strategy selector
            _buildHeader(appProvider, audioService),
            const Divider(height: 1),
            // Track list
            Expanded(
              child: _buildTrackList(audioService),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(AppProvider appProvider, AudioPlayerService audioService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[900]!,
            Colors.blue[800]!,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                widget.playlist.isSpecial ? Icons.star : Icons.music_note,
                color: Colors.amber,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.playlist.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (widget.playlist.description != null && 
                        widget.playlist.description!.isNotEmpty)
                      Text(
                        widget.playlist.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                  ],
                ),
              ),
              // Add files button
              IconButton.filled(
                icon: const Icon(Icons.folder_open),
                onPressed: () => _showAddFilesDialog(context, appProvider),
                tooltip: '添加文件',
              ),
              const SizedBox(width: 8),
              // Add folder button
              IconButton.filled(
                icon: const Icon(Icons.folder),
                onPressed: () => _showAddFolderDialog(context, appProvider),
                tooltip: '添加文件夹',
              ),
              const SizedBox(width: 8),
              // Play button
              IconButton.filled(
                icon: Icon(audioService.isPlaying && 
                        audioService.currentPlaylistModel?.id == widget.playlist.id
                    ? Icons.pause
                    : Icons.play_arrow),
                onPressed: () => _playPlaylist(audioService, appProvider),
                tooltip: audioService.isPlaying && 
                        audioService.currentPlaylistModel?.id == widget.playlist.id
                    ? '暂停'
                    : '播放',
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Strategy selector
          Row(
            children: [
              const Text(
                '播放策略:',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStrategyDropdown(appProvider, audioService),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20, color: Colors.white70),
                tooltip: '编辑播放策略',
                onPressed: () => _navigateToStrategyManager(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyDropdown(
    AppProvider appProvider,
    AudioPlayerService audioService,
  ) {
    return FutureBuilder<List<PlaybackStrategy>>(
      future: appProvider.dbService.getAllPlaybackStrategies(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator.adaptive();
        }

        final strategies = snapshot.data!;
        final currentStrategy = strategies.firstWhere(
          (s) => s.id == widget.playlist.playbackStrategyId,
          orElse: () => strategies.first,
        );

        return DropdownButtonHideUnderline(
          child: ButtonTheme(
            alignedDropdown: true,
            child: DropdownButton<String>(
              value: currentStrategy.id,
              dropdownColor: Colors.grey[850],
              isExpanded: true,
              style: const TextStyle(color: Colors.white),
              items: strategies.map((strategy) {
                return DropdownMenuItem(
                  value: strategy.id,
                  child: Text(strategy.name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  appProvider.updatePlaylistStrategy(widget.playlist.id, value);
                  // Update audio player strategy if this is the current playlist
                  if (audioService.currentPlaylistModel?.id == widget.playlist.id) {
                    final newStrategy = strategies.firstWhere((s) => s.id == value);
                    audioService.updateStrategy(newStrategy);
                  }
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrackList(AudioPlayerService audioService) {
    return ReorderableListView.builder(
      itemCount: widget.tracks.length,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) {
          newIndex -= 1;
        }
        final updatedTracks = List<PlaylistTrack>.from(widget.tracks);
        final track = updatedTracks.removeAt(oldIndex);
        updatedTracks.insert(newIndex, track);
        
        final trackIds = updatedTracks.map((t) => t.id).toList();
        context.read<AppProvider>().reorderTracks(widget.playlist.id, trackIds);
      },
      padding: const EdgeInsets.only(bottom: 16),
      itemBuilder: (context, index) {
        final track = widget.tracks[index];
        final isCurrentTrack = track.id == audioService.currentTrack?.id;
        final isPlaying = isCurrentTrack && audioService.isPlaying;
        
        return TrackTile(
          key: ValueKey(track.id),
          track: track,
          index: index,
          isCurrentTrack: isCurrentTrack,
          isPlaying: isPlaying,
          onTap: () => _playTrack(track, index, audioService),
          onDelete: () => _confirmDeleteTrack(context, track),
          onAddToSpecial: () => _showAddToSpecialDialog(context, track),
        );
      },
    );
  }

  void _playPlaylist(AudioPlayerService audioService, AppProvider appProvider) {
    if (widget.tracks.isEmpty) return;

    final strategy = appProvider.strategies.firstWhere(
      (s) => s.id == widget.playlist.playbackStrategyId,
      orElse: () => appProvider.strategies.first,
    );

    if (audioService.currentPlaylistModel?.id == widget.playlist.id && 
        audioService.isPlaying) {
      audioService.pause();
    } else {
      audioService.loadPlaylist(
        playlist: widget.playlist,
        tracks: widget.tracks,
        strategy: strategy,
        startIndex: audioService.currentPlaylistModel?.id == widget.playlist.id
            ? audioService.currentIndex
            : 0,
      );
    }
  }

  void _playTrack(
    PlaylistTrack track,
    int index,
    AudioPlayerService audioService,
  ) {
    final appProvider = context.read<AppProvider>();
    final strategy = appProvider.strategies.firstWhere(
      (s) => s.id == widget.playlist.playbackStrategyId,
      orElse: () => appProvider.strategies.first,
    );

    audioService.loadPlaylist(
      playlist: widget.playlist,
      tracks: widget.tracks,
      strategy: strategy,
      startIndex: index,
    );
  }

  void _confirmDeleteTrack(BuildContext context, PlaylistTrack track) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要从播放列表中删除 "${track.fileName}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<AppProvider>().removeTrackFromPlaylist(track.id);
              Navigator.pop(context);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showAddToSpecialDialog(BuildContext context, PlaylistTrack track) {
    final appProvider = context.read<AppProvider>();
    final audioService = context.read<AudioPlayerService>();
    final specialPlaylists = appProvider.specialPlaylists;

    if (specialPlaylists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有可用的特殊播放列表')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加到特殊播放列表'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: specialPlaylists.length,
            itemBuilder: (context, index) {
              final playlist = specialPlaylists[index];
              return ListTile(
                leading: const Icon(Icons.star, color: Colors.amber),
                title: Text(playlist.name),
                subtitle: playlist.description != null
                    ? Text(playlist.description!)
                    : null,
                onTap: () {
                  audioService.addTrackToSpecialPlaylist(track, playlist.id);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('已添加到 ${playlist.name}')),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  void _navigateToStrategyManager(BuildContext context) {
    // This would navigate to the strategy manager page
    // For now, we'll just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('请在左侧导航栏选择"播放策略"进行管理')),
    );
  }

  /// Show dialog to select multiple MP3 files
  Future<void> _showAddFilesDialog(BuildContext context, AppProvider appProvider) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3'],
      allowMultiple: true,
    );

    if (result != null && result.paths.isNotEmpty) {
      final validPaths = result.paths.where((path) => path != null).cast<String>().toList();
      if (validPaths.isNotEmpty && widget.playlist.id != null) {
        await appProvider.addTracksToPlaylist(widget.playlist.id, validPaths);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已添加 ${validPaths.length} 首歌曲到 ${widget.playlist.name}')),
          );
        }
      }
    }
  }

  /// Show dialog to select a folder and add all MP3 files from it
  Future<void> _showAddFolderDialog(BuildContext context, AppProvider appProvider) async {
    final directoryPath = await FilePicker.platform.getDirectoryPath();

    if (directoryPath != null && widget.playlist.id != null) {
      try {
        final directory = Directory(directoryPath);
        final mp3Files = <String>[];
        
        // Recursively find all MP3 files in the directory
        await for (final entity in directory.list(recursive: true, followLinks: false)) {
          if (entity is File && entity.path.toLowerCase().endsWith('.mp3')) {
            mp3Files.add(entity.path);
          }
        }

        if (mp3Files.isNotEmpty) {
          await appProvider.addTracksToPlaylist(widget.playlist.id, mp3Files);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('已从文件夹添加 ${mp3Files.length} 首歌曲到 ${widget.playlist.name}')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('该文件夹中没有 MP3 文件')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('读取文件夹失败：$e')),
          );
        }
      }
    }
  }
}

/// Individual track tile
class TrackTile extends StatelessWidget {
  final PlaylistTrack track;
  final int index;
  final bool isCurrentTrack;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onAddToSpecial;

  const TrackTile({
    super.key,
    required this.track,
    required this.index,
    this.isCurrentTrack = false,
    this.isPlaying = false,
    required this.onTap,
    required this.onDelete,
    required this.onAddToSpecial,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isCurrentTrack ? Colors.blue.withOpacity(0.15) : Colors.transparent,
        border: Border(
          bottom: BorderSide(color: Colors.white12, width: 0.5),
        ),
      ),
      child: ListTile(
        leading: ReorderableDragStartListener(
          index: index,
          child: Icon(
            isCurrentTrack && isPlaying
                ? Icons.equalizer
                : Icons.music_note,
            color: isCurrentTrack
                ? Colors.blue[400]
                : Colors.grey[500],
          ),
        ),
        title: Text(
          track.title ?? track.fileName,
          style: TextStyle(
            color: isCurrentTrack ? Colors.blue[400] : Colors.white,
            fontWeight: isCurrentTrack ? FontWeight.bold : FontWeight.normal,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: track.artist != null || track.album != null
            ? Text(
                [track.artist, track.album].whereType<String>().join(' • '),
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 20),
              color: Colors.green[400],
              tooltip: '添加到特殊播放列表',
              onPressed: onAddToSpecial,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: Colors.red[400],
              tooltip: '从播放列表删除',
              onPressed: onDelete,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
