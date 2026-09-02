import 'package:flutter/material.dart';

import '../../../ui/theme.dart';
import '../../../ui/widgets/error_view.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 64,
        title: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Downloads',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
              fontSize: 28,
              letterSpacing: -0.6,
            ),
          ),
        ),
      ),
      body: const EmptyView(
        title: 'No downloads',
        subtitle:
            'Downloaded tracks will appear here for offline playback',
        icon: Icons.download_outlined,
      ),
    );
  }
}