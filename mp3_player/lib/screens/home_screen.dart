import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/playlist.dart';
import '../providers/app_provider.dart';
import '../services/audio_player_service.dart';
import '../widgets/playlist_list.dart';
import '../widgets/playlist_detail.dart';
import '../widgets/player_controls.dart';
import '../widgets/strategy_manager.dart';

/// Main home screen with sidebar navigation and content area
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(),
          // Main content
          Expanded(
            child: Column(
              children: [
                // Main content area
                Expanded(
                  child: IndexedStack(
                    index: _selectedPageIndex,
                    children: [
                      PlaylistDetailView(),
                      StrategyManagerView(),
                    ],
                  ),
                ),
                // Player controls bar at bottom
                const PlayerControlsBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // App title
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Icon(Icons.music_note, color: Colors.blue[400], size: 32),
                const SizedBox(width: 12),
                const Text(
                  'MP3 播放器',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24),
          // Navigation items
          _buildNavItem(0, Icons.list, '播放列表'),
          _buildNavItem(1, Icons.settings, '播放策略'),
          const Spacer(),
          // Drag and drop hint
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '拖拽 MP3 文件或文件夹\n到播放列表',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedPageIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.blue[400] : Colors.grey[400],
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[400],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.blue.withOpacity(0.1),
      onTap: () {
        setState(() {
          _selectedPageIndex = index;
        });
      },
    );
  }
}

/// Playlist detail view with drag and drop support
class PlaylistDetailView extends StatefulWidget {
  const PlaylistDetailView({super.key});

  @override
  State<PlaylistDetailView> createState() => _PlaylistDetailViewState();
}

class _PlaylistDetailViewState extends State<PlaylistDetailView> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        if (appProvider.selectedPlaylist == null) {
          return _buildEmptyState();
        }
        return DragTarget<List<String>>(
          onWillAccept: (data) => true,
          onAccept: (filePaths) {
            if (appProvider.selectedPlaylist != null) {
              appProvider.addTracksToPlaylist(
                appProvider.selectedPlaylist!.id,
                filePaths,
              );
            }
          },
          builder: (context, candidateData, rejectedData) {
            return Container(
              color: candidateData.isNotEmpty 
                  ? Colors.blue.withOpacity(0.1) 
                  : Colors.transparent,
              child: PlaylistDetailContent(),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note,
            size: 80,
            color: Colors.grey[700],
          ),
          const SizedBox(height: 24),
          Text(
            '选择或创建一个播放列表',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '您可以从左侧选择播放列表，或直接拖拽 MP3 文件到这里',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

/// Content of playlist detail with track list
class PlaylistDetailContent extends StatelessWidget {
  const PlaylistDetailContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppProvider, AudioPlayerService>(
      builder: (context, appProvider, audioService, child) {
        final playlist = appProvider.selectedPlaylist;
        if (playlist == null) {
          return const SizedBox.shrink();
        }

        return FutureBuilder<List<PlaylistTrack>>(
          future: appProvider.dbService.getTracksByPlaylistId(playlist.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  '播放列表为空，拖拽 MP3 文件到这里',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              );
            }

            return PlaylistDetailWidget(
              playlist: playlist,
              tracks: snapshot.data!,
              currentTrackId: audioService.currentTrack?.id,
              isPlaying: audioService.isPlaying,
            );
          },
        );
      },
    );
  }
}
