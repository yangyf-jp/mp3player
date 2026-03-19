import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_player_service.dart';

/// Player controls bar at the bottom of the screen
class PlayerControlsBar extends StatelessWidget {
  const PlayerControlsBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerService>(
      builder: (context, audioService, child) {
        final currentTrack = audioService.currentTrack;
        
        return Container(
          height: 90,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Progress bar
              LinearProgressIndicator(
                value: audioService.duration.inMilliseconds > 0
                    ? audioService.position.inMilliseconds / 
                      audioService.duration.inMilliseconds
                    : 0,
                backgroundColor: Colors.grey[800],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[400]!),
                minHeight: 3,
              ),
              // Controls
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Track info
                      Expanded(
                        child: _buildTrackInfo(currentTrack),
                      ),
                      // Playback controls
                      _buildPlaybackControls(audioService),
                      // Volume and other controls
                      _buildExtraControls(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrackInfo(dynamic currentTrack) {
    if (currentTrack == null) {
      return Text(
        '未播放任何曲目',
        style: TextStyle(color: Colors.grey[600]),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          currentTrack.title ?? currentTrack.fileName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (currentTrack.artist != null)
          Text(
            currentTrack.artist!,
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget _buildPlaybackControls(AudioPlayerService audioService) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.skip_previous),
          color: Colors.white,
          iconSize: 32,
          onPressed: audioService.currentPlaylist.isNotEmpty
              ? () => audioService.skipPrevious()
              : null,
          tooltip: '上一曲',
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.blue[600],
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              audioService.isPlaying ? Icons.pause : Icons.play_arrow,
              size: 36,
            ),
            color: Colors.white,
            onPressed: audioService.currentPlaylist.isNotEmpty
                ? () => audioService.playPause()
                : null,
            tooltip: audioService.isPlaying ? '暂停' : '播放',
          ),
        ),
        IconButton(
          icon: const Icon(Icons.skip_next),
          color: Colors.white,
          iconSize: 32,
          onPressed: audioService.currentPlaylist.isNotEmpty
              ? () => audioService.skipNext()
              : null,
          tooltip: '下一曲',
        ),
      ],
    );
  }

  Widget _buildExtraControls() {
    return Row(
      children: [
        // Time display
        Consumer<AudioPlayerService>(
          builder: (context, audioService, child) {
            return Text(
              '${_formatDuration(audioService.position)} / ${_formatDuration(audioService.duration)}',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            );
          },
        ),
        const SizedBox(width: 16),
        // Strategy indicator
        Consumer<AudioPlayerService>(
          builder: (context, audioService, child) {
            final strategy = audioService.currentStrategy;
            if (strategy == null) return const SizedBox.shrink();
            
            return Tooltip(
              message: '${strategy.playbackModeLabel} • ${strategy.playControlLabel}',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.settings, size: 14, color: Colors.blue[400]),
                    const SizedBox(width: 4),
                    Text(
                      strategy.name,
                      style: TextStyle(
                        color: Colors.blue[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}
