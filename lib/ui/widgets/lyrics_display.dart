import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

// ═══════════════════════════════════════════════════════════════
// LYRICS DISPLAY
// ═══════════════════════════════════════════════════════════════

/// A full-screen lyrics display with elegant typography and smooth scrolling.
/// Supports both synchronized (LRC) and plain lyrics.
class LyricsDisplay extends StatefulWidget {
  final List<LyricLine> lyrics;
  final Duration currentPosition;
  final VoidCallback? onClose;
  final String? title;
  final String? artist;

  const LyricsDisplay({
    super.key,
    required this.lyrics,
    required this.currentPosition,
    this.onClose,
    this.title,
    this.artist,
  });

  @override
  State<LyricsDisplay> createState() => _LyricsDisplayState();
}

class _LyricsDisplayState extends State<LyricsDisplay> {
  final ScrollController _scrollController = ScrollController();
  int _currentLine = -1;

  @override
  void didUpdateWidget(covariant LyricsDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateCurrentLine();
  }

  void _updateCurrentLine() {
    if (widget.lyrics.isEmpty) return;

    final pos = widget.currentPosition;
    int newLine = -1;

    for (var i = 0; i < widget.lyrics.length; i++) {
      if (widget.lyrics[i].timestamp != null &&
          widget.lyrics[i].timestamp! <= pos) {
        newLine = i;
      }
    }

    if (newLine != _currentLine && newLine >= 0) {
      setState(() => _currentLine = newLine);
      _scrollToLine(newLine);
    }
  }

  void _scrollToLine(int index) {
    if (!_scrollController.hasClients) return;

    final itemHeight = 56.0;
    final viewportHeight = _scrollController.position.viewportDimension;
    final targetOffset = (index * itemHeight) - (viewportHeight / 2) + (itemHeight / 2);

    _scrollController.animateTo(
      targetOffset.clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background.withValues(alpha: 0.97),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: widget.lyrics.isEmpty
                  ? _buildEmptyState()
                  : _buildLyricsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.text,
              size: 30,
            ),
            onPressed: widget.onClose ?? () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'LYRICS',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    letterSpacing: 2.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (widget.title != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.title!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lyrics_outlined,
            size: 48,
            color: AppColors.textDim,
          ),
          const SizedBox(height: 16),
          Text(
            'No lyrics available',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Lyrics will appear here when available',
            style: TextStyle(
              color: AppColors.textDim,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 32),
      itemCount: widget.lyrics.length,
      itemBuilder: (context, index) {
        final line = widget.lyrics[index];
        final isCurrent = index == _currentLine;
        final isPast = index < _currentLine;

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            // Could seek to this timestamp if available
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 14,
            ),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                color: isCurrent
                    ? AppColors.text
                    : isPast
                        ? AppColors.textDim
                        : AppColors.textMuted.withValues(alpha: 0.6),
                fontSize: isCurrent ? 20 : 17,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                height: 1.5,
                letterSpacing: isCurrent ? -0.2 : 0,
              ),
              child: Text(
                line.text,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// LYRIC LINE MODEL
// ═══════════════════════════════════════════════════════════════

/// Represents a single line of lyrics with optional timestamp.
class LyricLine {
  final String text;
  final Duration? timestamp;

  const LyricLine({
    required this.text,
    this.timestamp,
  });

  /// Parse LRC format lyrics.
  /// Format: [mm:ss.xx]Lyric text
  static List<LyricLine> parseLrc(String lrc) {
    final lines = <LyricLine>[];
    final regex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');

    for (final line in lrc.split('\n')) {
      final match = regex.firstMatch(line.trim());
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final millis = int.parse(match.group(3)!.padRight(3, '0'));
        final text = match.group(4)!.trim();

        if (text.isNotEmpty) {
          lines.add(LyricLine(
            text: text,
            timestamp: Duration(
              minutes: minutes,
              seconds: seconds,
              milliseconds: millis,
            ),
          ));
        }
      } else if (line.trim().isNotEmpty && !line.trim().startsWith('[')) {
        // Plain text line without timestamp
        lines.add(LyricLine(text: line.trim()));
      }
    }

    return lines;
  }

  /// Parse plain text lyrics (no timestamps).
  static List<LyricLine> parsePlain(String text) {
    return text
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .map((l) => LyricLine(text: l.trim()))
        .toList();
  }
}

// ═══════════════════════════════════════════════════════════════
// LYRICS BUTTON (for player screen)
// ═══════════════════════════════════════════════════════════════

/// A button that opens the lyrics display from the player screen.
class LyricsButton extends StatelessWidget {
  final bool hasLyrics;
  final VoidCallback onTap;

  const LyricsButton({
    super.key,
    required this.hasLyrics,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: hasLyrics
              ? AppColors.accent.withValues(alpha: 0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasLyrics
                ? AppColors.accent.withValues(alpha: 0.4)
                : AppColors.border,
            width: 0.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lyrics_rounded,
              size: 16,
              color: hasLyrics ? AppColors.accent : AppColors.text,
            ),
            const SizedBox(width: 6),
            Text(
              'Lyrics',
              style: TextStyle(
                color: hasLyrics ? AppColors.accent : AppColors.text,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
