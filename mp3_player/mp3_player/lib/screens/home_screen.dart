import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
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
                      const PlaylistDetailView(),
                      const StrategyManagerView(),
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

  void _showCreatePlaylistDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    bool isSpecial = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('新建播放列表'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '播放列表名称',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: '备注 (可选)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('特殊播放列表'),
                subtitle: const Text('特殊播放列表可在添加曲目时快速选择'),
                value: isSpecial,
                onChanged: (value) {
                  setDialogState(() => isSpecial = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  context.read<AppProvider>().createPlaylist(
                    name: nameController.text.trim(),
                    description: descController.text.trim().isEmpty 
                        ? null 
                        : descController.text.trim(),
                    isSpecial: isSpecial,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPlaylistDialog(
    BuildContext context,
    AppProvider appProvider,
    Playlist playlist,
  ) {
    final nameController = TextEditingController(text: playlist.name);
    final descController = TextEditingController(text: playlist.description ?? '');
    bool isSpecial = playlist.isSpecial;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('编辑播放列表'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '播放列表名称',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: '备注',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('特殊播放列表'),
                value: isSpecial,
                onChanged: (value) {
                  setDialogState(() => isSpecial = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  appProvider.updatePlaylist(
                    playlist.copyWith(
                      name: nameController.text.trim(),
                      description: descController.text.trim().isEmpty 
                          ? null 
                          : descController.text.trim(),
                      isSpecial: isSpecial,
                    ),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePlaylist(
    BuildContext context,
    AppProvider appProvider,
    Playlist playlist,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除播放列表 "${playlist.name}" 吗？\n此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              appProvider.deletePlaylist(playlist.id);
              Navigator.pop(context);
            },
            child: const Text('删除'),
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
          // Playlist list section
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with add button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      const Text(
                        '播放列表',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        color: Colors.blue[400],
                        tooltip: '新建播放列表',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: () => _showCreatePlaylistDialog(context),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),
                // Playlist items
                Expanded(
                  child: Consumer<AppProvider>(
                    builder: (context, appProvider, child) {
                      if (appProvider.playlists.isEmpty) {
                        return Center(
                          child: Text(
                            '暂无播放列表\n点击 + 新建',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        );
                      }
                      return ReorderableListView.builder(
                        itemCount: appProvider.playlists.length,
                        onReorder: (oldIndex, newIndex) {
                          if (newIndex > oldIndex) {
                            newIndex -= 1;
                          }
                          final updatedList = List<Playlist>.from(appProvider.playlists);
                          final item = updatedList.removeAt(oldIndex);
                          updatedList.insert(newIndex, item);
                          appProvider.reorderPlaylists(updatedList.map((p) => p.id).toList());
                        },
                        itemBuilder: (context, index) {
                          final playlist = appProvider.playlists[index];
                          return PlaylistTile(
                            key: ValueKey(playlist.id),
                            playlist: playlist,
                            isSelected: appProvider.selectedPlaylist?.id == playlist.id,
                            onTap: () => appProvider.selectPlaylist(playlist),
                            onEdit: () => _showEditPlaylistDialog(context, appProvider, playlist),
                            onDelete: () => _confirmDeletePlaylist(context, appProvider, playlist),
                            index: index,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24),
          // Navigation items
          _buildNavItem(0, Icons.list, '播放列表详情'),
          _buildNavItem(1, Icons.settings, '播放策略'),
          const Divider(color: Colors.white24),
          // Drag and drop hint
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '拖拽 MP3 文件或文件夹\n到播放列表',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
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
        return _buildDragDropArea(appProvider);
      },
    );
  }

  Widget _buildDragDropArea(AppProvider appProvider) {
    return DragTarget<List<String>>(
      onWillAcceptWithDetails: (details) => true,
      onAccept: (filePaths) {
        if (filePaths.isNotEmpty && appProvider.selectedPlaylist != null) {
          appProvider.addTracksToPlaylist(
            appProvider.selectedPlaylist!.id,
            filePaths,
          );
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          color: candidateData.isNotEmpty 
              ? Colors.blue.withOpacity(0.2) 
              : Colors.transparent,
          child: const PlaylistDetailContent(),
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
class PlaylistDetailContent extends StatefulWidget {
  const PlaylistDetailContent({super.key});

  @override
  State<PlaylistDetailContent> createState() => _PlaylistDetailContentState();
}

class _PlaylistDetailContentState extends State<PlaylistDetailContent> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
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

            // Only pass necessary data to avoid excessive rebuilds
            return PlaylistDetailWidget(
              playlist: playlist,
              tracks: snapshot.data!,
            );
          },
        );
      },
    );
  }
}
