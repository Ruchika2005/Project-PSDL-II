import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/video_player_widget.dart';

class HelpGuidanceScreen extends StatelessWidget {
  const HelpGuidanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Guidance'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TUTORIAL VIDEOS',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            _buildVideoTile(
              context,
              'App Overview',
              'Watch how to navigate through the app',
              'assets/videos/guide_1.mp4',
            ),
            const SizedBox(height: 16),
            _buildVideoTile(
              context,
              'Splitting Expenses',
              'Learn how to split bills with friends',
              'assets/videos/guide_2.mp4',
            ),
            const SizedBox(height: 32),
            const Center(
              child: Text(
                'More videos coming soon!',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoTile(
      BuildContext context, String title, String subtitle, String videoPath) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.play_circle_fill_rounded,
              color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded,
            size: 16, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPlayerWidget(videoPath: videoPath),
            ),
          );
        },
      ),
    );
  }
}
