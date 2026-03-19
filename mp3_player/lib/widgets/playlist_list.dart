import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/playlist.dart';
import '../providers/app_provider.dart';

/// Playlist list widget with drag and drop reordering
class PlaylistListWidget extends StatelessWidget {
  const PlaylistListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Column(
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    color: Colors.blue[400],
                    tooltip: '新建播放列表',
                    onPressed: () => _showCreatePlaylistDialog(context, appProvider),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            // Playlist items
            Expanded(
              child: ReorderableListView.builder(
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
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, AppProvider appProvider) {
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
                  appProvider.createPlaylist(
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
}

/// Individual playlist tile
class PlaylistTile extends StatelessWidget {
  final Playlist playlist;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PlaylistTile({
    super.key,
    required this.playlist,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
        border: Border(
          bottom: BorderSide(color: Colors.white12, width: 0.5),
        ),
      ),
      child: ListTile(
        leading: Icon(
          playlist.isSpecial ? Icons.star : Icons.music_note,
          color: playlist.isSpecial ? Colors.amber : (isSelected ? Colors.blue[400] : Colors.grey[400]),
        ),
        title: Text(
          playlist.name,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[300],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: playlist.description != null && playlist.description!.isNotEmpty
            ? Text(
                playlist.description!,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.grey[500]),
          onSelected: (value) {
            if (value == 'edit') {
              onEdit();
            } else if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('编辑')),
            const PopupMenuItem(value: 'delete', child: Text('删除')),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
