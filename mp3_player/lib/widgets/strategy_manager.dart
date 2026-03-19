import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/playback_strategy.dart';
import '../providers/app_provider.dart';

/// Strategy manager view for CRUD operations on playback strategies
class StrategyManagerView extends StatefulWidget {
  const StrategyManagerView({super.key});

  @override
  State<StrategyManagerView> createState() => _StrategyManagerViewState();
}

class _StrategyManagerViewState extends State<StrategyManagerView> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    '播放策略管理',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateStrategyDialog(context, appProvider),
                    icon: const Icon(Icons.add),
                    label: const Text('新建策略'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '管理和配置不同的播放策略，每个播放列表可以选择不同的策略',
                style: TextStyle(color: Colors.grey[500]),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _buildStrategyList(appProvider),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStrategyList(AppProvider appProvider) {
    if (appProvider.strategies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.settings, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text(
              '暂无播放策略',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              '点击"新建策略"创建第一个播放策略',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: appProvider.strategies.length,
      itemBuilder: (context, index) {
        final strategy = appProvider.strategies[index];
        final isInUse = appProvider.isStrategyInUse(strategy.id);
        
        return StrategyCard(
          strategy: strategy,
          isInUse: isInUse,
          onEdit: () => _showEditStrategyDialog(context, appProvider, strategy),
          onDelete: () => _confirmDeleteStrategy(context, appProvider, strategy),
        );
      },
    );
  }

  void _showCreateStrategyDialog(BuildContext context, AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (context) => StrategyFormDialog(
        title: '新建播放策略',
        onSave: (strategyData) {
          appProvider.createPlaybackStrategy(
            name: strategyData['name'] as String,
            intervalSeconds: strategyData['intervalSeconds'] as int,
            repeatCount: strategyData['repeatCount'] as int,
            playbackMode: strategyData['playbackMode'] as PlaybackMode,
            playControl: strategyData['playControl'] as PlayControl,
          );
        },
      ),
    );
  }

  void _showEditStrategyDialog(
    BuildContext context,
    AppProvider appProvider,
    PlaybackStrategy strategy,
  ) {
    showDialog(
      context: context,
      builder: (context) => StrategyFormDialog(
        title: '编辑播放策略',
        strategy: strategy,
        onSave: (strategyData) {
          appProvider.updatePlaybackStrategy(
            strategy.copyWith(
              name: strategyData['name'] as String,
              intervalSeconds: strategyData['intervalSeconds'] as int,
              repeatCount: strategyData['repeatCount'] as int,
              playbackMode: strategyData['playbackMode'] as PlaybackMode,
              playControl: strategyData['playControl'] as PlayControl,
            ),
          );
        },
      ),
    );
  }

  void _confirmDeleteStrategy(
    BuildContext context,
    AppProvider appProvider,
    PlaybackStrategy strategy,
  ) {
    final isInUse = appProvider.isStrategyInUse(strategy.id);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('确定要删除播放策略 "${strategy.name}" 吗？'),
            if (isInUse) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '该策略正在被播放列表使用，无法删除',
                        style: TextStyle(color: Colors.amber[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          if (!isInUse)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                appProvider.deletePlaybackStrategy(strategy.id);
                Navigator.pop(context);
              },
              child: const Text('删除'),
            ),
        ],
      ),
    );
  }
}

/// Strategy card widget
class StrategyCard extends StatelessWidget {
  final PlaybackStrategy strategy;
  final bool isInUse;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const StrategyCard({
    super.key,
    required this.strategy,
    required this.isInUse,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        isInUse ? Icons.play_circle : Icons.settings,
                        color: isInUse ? Colors.green[400] : Colors.grey[400],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  strategy.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                if (isInUse) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '使用中',
                                      style: TextStyle(
                                        color: Colors.green[400],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('编辑')),
                    PopupMenuItem(
                      value: 'delete',
                      enabled: !isInUse,
                      child: Text(
                        '删除',
                        style: TextStyle(color: isInUse ? Colors.grey : Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildInfoChip(
                  Icons.timer,
                  '间隔：${strategy.intervalSeconds}秒',
                ),
                _buildInfoChip(
                  Icons.repeat,
                  '重复：${strategy.repeatCount}次',
                ),
                _buildInfoChip(
                  Icons.shuffle,
                  strategy.playbackModeLabel,
                ),
                _buildInfoChip(
                  Icons.playlist_play,
                  strategy.playControlLabel,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.blue[400]),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      backgroundColor: Colors.grey[800],
    );
  }
}

/// Dialog form for creating/editing strategies
class StrategyFormDialog extends StatefulWidget {
  final String title;
  final PlaybackStrategy? strategy;
  final Function(Map<String, dynamic>) onSave;

  const StrategyFormDialog({
    super.key,
    required this.title,
    this.strategy,
    required this.onSave,
  });

  @override
  State<StrategyFormDialog> createState() => _StrategyFormDialogState();
}

class _StrategyFormDialogState extends State<StrategyFormDialog> {
  late TextEditingController _nameController;
  late TextEditingController _intervalController;
  late TextEditingController _repeatController;
  late PlaybackMode _playbackMode;
  late PlayControl _playControl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.strategy?.name ?? '');
    _intervalController = TextEditingController(
      text: (widget.strategy?.intervalSeconds ?? 0).toString(),
    );
    _repeatController = TextEditingController(
      text: (widget.strategy?.repeatCount ?? 1).toString(),
    );
    _playbackMode = widget.strategy?.playbackMode ?? PlaybackMode.sequential;
    _playControl = widget.strategy?.playControl ?? PlayControl.singlePlay;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _intervalController.dispose();
    _repeatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '策略名称',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _intervalController,
              decoration: const InputDecoration(
                labelText: '播放间隔（秒）',
                border: OutlineInputBorder(),
                suffixText: '秒',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _repeatController,
              decoration: const InputDecoration(
                labelText: '单曲重复次数',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            const Text('播放模式', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Column(
              children: [
                RadioListTile<PlaybackMode>(
                  title: const Text('顺序播放'),
                  subtitle: const Text('按播放列表顺序依次播放'),
                  value: PlaybackMode.sequential,
                  groupValue: _playbackMode,
                  onChanged: (value) {
                    setState(() => _playbackMode = value!);
                  },
                ),
                RadioListTile<PlaybackMode>(
                  title: const Text('随机播放'),
                  subtitle: const Text('随机选择下一首曲目'),
                  value: PlaybackMode.shuffle,
                  groupValue: _playbackMode,
                  onChanged: (value) {
                    setState(() => _playbackMode = value!);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('播放控制', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Column(
              children: [
                RadioListTile<PlayControl>(
                  title: const Text('单次播放'),
                  subtitle: const Text('播放完整个列表后停止'),
                  value: PlayControl.singlePlay,
                  groupValue: _playControl,
                  onChanged: (value) {
                    setState(() => _playControl = value!);
                  },
                ),
                RadioListTile<PlayControl>(
                  title: const Text('循环播放'),
                  subtitle: const Text('播放完整个列表后重新开始'),
                  value: PlayControl.loopPlaylist,
                  groupValue: _playControl,
                  onChanged: (value) {
                    setState(() => _playControl = value!);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('保存'),
        ),
      ],
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入策略名称')),
      );
      return;
    }

    final intervalSeconds = int.tryParse(_intervalController.text) ?? 0;
    final repeatCount = int.tryParse(_repeatController.text) ?? 1;

    widget.onSave({
      'name': name,
      'intervalSeconds': intervalSeconds.clamp(0, 3600),
      'repeatCount': repeatCount.clamp(1, 100),
      'playbackMode': _playbackMode,
      'playControl': _playControl,
    });

    Navigator.pop(context);
  }
}
