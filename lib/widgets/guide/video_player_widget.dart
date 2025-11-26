import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatelessWidget {
  final VideoPlayerController? controller;
  final Future<void>? initializeFuture;
  final VoidCallback onPlayPause;

  const VideoPlayerWidget({
    super.key,
    required this.controller,
    required this.initializeFuture,
    required this.onPlayPause,
  });

  @override
  Widget build(BuildContext context) {
    if (controller == null) {
      return const Text('영상 로딩에 실패했습니다.', style: TextStyle(fontSize: 14));
    }

    return FutureBuilder<void>(
      future: initializeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
          );
        }

        return Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: controller!.value.aspectRatio,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: VideoPlayer(controller!),
                  ),
                ),
                if (!controller!.value.isPlaying)
                  InkWell(
                    onTap: onPlayPause,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            IconButton(
              iconSize: 40,
              icon: Icon(
                controller!.value.isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
              ),
              onPressed: onPlayPause,
            ),
          ],
        );
      },
    );
  }
}
