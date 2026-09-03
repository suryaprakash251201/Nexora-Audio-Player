import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../nexora/nexora_tokens.dart';
import '../theme.dart';

/// Full-screen synced lyrics — glass over blurred artwork, bold live line
/// with glow pill + smooth auto-scroll. Tap a synced line to jump the
/// song there; double-tap header/artwork to go back to the player.
class LyricsDisplay extends StatefulWidget {
  final List<LyricLine> lyrics;
  final Duration currentPosition;
  final VoidCallback? onClose;
  final ValueChanged<Duration>? onLineTap;
  final String? title;
  final String? artist;
  final String? artworkUrl;

  const LyricsDisplay({
    super.key,
    required this.lyrics,
    required this.currentPosition,
    this.onClose,
    this.onLineTap,
    this.title,
    this.artist,
    this.artworkUrl,
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
    final targetOffset =
        (index * itemHeight) - (viewportHeight / 2) + (itemHeight / 2);
    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _close() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.maybePop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Glass backdrop — blurred artwork + deep scrim.
          if (widget.artworkUrl != null && widget.artworkUrl!.isNotEmpty)
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 46, sigmaY: 46),
              child: Image.network(
                widget.artworkUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Container(color: AppColors.background),
              ),
            )
          else
            Container(color: AppColors.background),
          Container(color: Colors.black.withValues(alpha: 0.62)),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.background.withValues(alpha: 0.55),
                  Colors.transparent,
                  AppColors.background.withValues(alpha: 0.78),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                if (widget.artworkUrl != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: _buildArtwork(),
                  ),
                // Tap-a-line hint
                if (widget.lyrics.isNotEmpty &&
                    widget.lyrics.any((l) => l.timestamp != null))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'TAP A LINE TO JUMP  •  DOUBLE-TAP ART TO GO BACK',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ),
                Expanded(
                  child: widget.lyrics.isEmpty
                      ? _buildEmptyState()
                      : _buildLyricsList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtwork() {
    // Double-tap artwork ⇄ player.
    return GestureDetector(
      onDoubleTap: () {
        HapticFeedback.lightImpact();
        _close();
      },
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.35),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            widget.artworkUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              color: AppColors.surfaceRaised,
              child: Icon(
                Icons.music_note_rounded,
                color: AppColors.textDim,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // Double-tap header ⇄ player.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: () {
        HapticFeedback.lightImpact();
        _close();
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white,
                size: 30,
              ),
              onPressed: _close,
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    'LYRICS',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 10,
                      letterSpacing: 2.4,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (widget.title != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.title!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
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
            color: Colors.white.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No lyrics available',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Lyrics will appear here when available',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsList() {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.black,
          Colors.black,
          Colors.transparent,
        ],
        stops: [0.0, 0.08, 0.92, 1.0],
      ).createShader(bounds),
      blendMode: BlendMode.dstIn,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        itemCount: widget.lyrics.length,
        itemBuilder: (context, index) {
          final line = widget.lyrics[index];
          final isCurrent = index == _currentLine;
          final isPast = _currentLine >= 0 && index < _currentLine;
          final tappable = line.timestamp != null && widget.onLineTap != null;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: tappable
                ? () {
                    HapticFeedback.selectionClick();
                    widget.onLineTap!(line.timestamp!);
                  }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(vertical: 3),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: isCurrent ? AppColors.accentGradient : null,
                color: isCurrent ? null : Colors.white.withValues(alpha: 0.04),
                border: Border.all(
                  color: isCurrent
                      ? Colors.white.withValues(alpha: 0.35)
                      : Colors.white.withValues(alpha: 0.05),
                  width: 0.8,
                ),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.45),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  color: isCurrent
                      ? Colors.white
                      : isPast
                      ? Colors.white.withValues(alpha: 0.45)
                      : Colors.white.withValues(alpha: 0.75),
                  fontSize: isCurrent ? 21 : 16.5,
                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                  height: 1.45,
                  letterSpacing: isCurrent ? -0.3 : 0,
                  shadows: isCurrent
                      ? [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: Text(line.text, textAlign: TextAlign.center),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Represents a single line of lyrics with optional timestamp.
class LyricLine {
  final String text;
  final Duration? timestamp;

  const LyricLine({required this.text, this.timestamp});

  /// Parse LRC format lyrics.
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
          lines.add(
            LyricLine(
              text: text,
              timestamp: Duration(
                minutes: minutes,
                seconds: seconds,
                milliseconds: millis,
              ),
            ),
          );
        }
      } else if (line.trim().isNotEmpty && !line.trim().startsWith('[')) {
        lines.add(LyricLine(text: line.trim()));
      }
    }
    return lines;
  }

  static List<LyricLine> parsePlain(String text) {
    return text
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .map((l) => LyricLine(text: l.trim()))
        .toList();
  }
}

/// A button that opens the lyrics display from the player screen.
class LyricsButton extends StatelessWidget {
  final bool hasLyrics;
  final VoidCallback onTap;

  const LyricsButton({super.key, required this.hasLyrics, required this.onTap});

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
