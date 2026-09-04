import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import 'artwork_image.dart' show nexoraArtworkCache;

/// Full-screen synced lyrics — glass over blurred artwork, left-aligned
/// Apple-Music-style lines with a signature karaoke sweep: the active
/// line fills with a moving aurora gradient timed to its timestamps.
/// Tap a synced line to jump the song there; auto-centering pauses while
/// you scrub manually and resumes after 3s; double-tap header/artwork
/// to go back to the player.
class LyricsDisplay extends StatefulWidget {
  final List<LyricLine> lyrics;
  final Duration currentPosition;

  /// Total track length — enables plain-text sync (progress-ratio
  /// highlight) when no line carries a timestamp.
  final Duration duration;
  final VoidCallback? onClose;
  final ValueChanged<Duration>? onLineTap;
  final String? title;
  final String? artist;
  final String? artworkUrl;

  const LyricsDisplay({
    super.key,
    required this.lyrics,
    required this.currentPosition,
    this.duration = Duration.zero,
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

  /// Width available to a lyric line inside the list (set by LayoutBuilder).
  double _listWidth = 0;

  /// Measured line-box heights, keyed by text+width. Enables pixel-exact
  /// auto-scroll (the old hardcoded 56px row height drifted on wraps).
  final Map<String, double> _boxHeights = {};

  /// Auto-scroll pauses while the user scrubs around manually, then
  /// quietly resumes so it never fights the reader.
  bool _autoScroll = true;
  Timer? _resumeTimer;

  @override
  void didUpdateWidget(covariant LyricsDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateCurrentLine();
  }

  /// True when at least one line carries a timestamp.
  bool get _hasTiming => widget.lyrics.any((l) => l.timestamp != null);

  void _updateCurrentLine() {
    if (widget.lyrics.isEmpty) return;
    final pos = widget.currentPosition;
    int newLine;
    if (_hasTiming) {
      // Synced lyrics — last line whose time has passed.
      newLine = -1;
      for (var i = 0; i < widget.lyrics.length; i++) {
        if (widget.lyrics[i].timestamp != null &&
            widget.lyrics[i].timestamp! <= pos) {
          newLine = i;
        }
      }
    } else {
      // Plain-text sync — highlight follows song progress ratio so
      // unsynced lyrics still move live with the music.
      final totalMs = widget.duration.inMilliseconds;
      if (totalMs <= 0) return;
      final ratio = (pos.inMilliseconds / totalMs).clamp(0.0, 0.999);
      newLine = (ratio * widget.lyrics.length).floor().clamp(
        0,
        widget.lyrics.length - 1,
      );
    }
    if (newLine != _currentLine && newLine >= 0) {
      setState(() => _currentLine = newLine);
      _scrollToLine(newLine);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {}); // first frame measured — width now known
      _updateCurrentLine();
    });
  }

  // ── Karaoke timing ──────────────────────────────────────────

  /// Line start: synced timestamp, or an equal slice of the track for
  /// plain-text lyrics.
  Duration _lineStart(int index) {
    if (_hasTiming) {
      return widget.lyrics[index].timestamp ?? Duration.zero;
    }
    final totalMs = widget.duration.inMilliseconds;
    if (totalMs <= 0) return Duration.zero;
    final seg = totalMs / widget.lyrics.length;
    return Duration(milliseconds: (seg * index).round());
  }

  /// Line end: next synced stamp / next equal slice / track end.
  Duration _lineEnd(int index) {
    final t0 = _lineStart(index);
    if (_hasTiming) {
      for (var j = index + 1; j < widget.lyrics.length; j++) {
        final t = widget.lyrics[j].timestamp;
        if (t != null && t > t0) return t;
      }
    } else {
      final totalMs = widget.duration.inMilliseconds;
      if (totalMs > 0) {
        final seg = totalMs / widget.lyrics.length;
        return Duration(milliseconds: (seg * (index + 1)).round());
      }
    }
    final d = widget.duration;
    return d > t0 ? d : t0 + const Duration(seconds: 8);
  }

  /// 0..1 karaoke sweep of the given line — drives the moving fill.
  double _lineProgress(int index) {
    final t0 = _lineStart(index);
    final t1 = _lineEnd(index);
    final span = t1.inMilliseconds - t0.inMilliseconds;
    if (span <= 0) return 1;
    return ((widget.currentPosition.inMilliseconds - t0.inMilliseconds) / span)
        .clamp(0.0, 1.0);
  }

  // ── Measured heights → exact scroll offsets ────────────────

  /// Box height for one line. Reserves the LARGER of the resting and the
  /// active type sizes, so a box never changes height when its line
  /// becomes current — scroll offsets stay perfectly stable.
  double _boxHeightFor(String text, double width) {
    final key = '$text|$width';
    final cached = _boxHeights[key];
    if (cached != null) return cached;

    double measure(TextStyle style) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        maxLines: 4,
      )..layout(maxWidth: width);
      final h = tp.height;
      tp.dispose();
      return h;
    }

    final resting = measure(_LyricsStyles.resting);
    final active = measure(_LyricsStyles.active);
    final h = (resting > active ? resting : active) + 24;
    _boxHeights[key] = h;
    return h;
  }

  /// Top edge of [index]'s box in list coordinates.
  double _offsetOf(int index) {
    var offset = 0.0;
    for (var i = 0; i < index; i++) {
      offset += _boxHeightFor(widget.lyrics[i].text, _listWidth);
    }
    return offset;
  }

  void _scrollToLine(int index) {
    if (!_autoScroll || _listWidth <= 0) return;
    if (!_scrollController.hasClients) return;
    final box = _boxHeightFor(widget.lyrics[index].text, _listWidth);
    final viewport = _scrollController.position.viewportDimension;
    final target = _offsetOf(index) + box / 2 - viewport / 2;
    _scrollController.animateTo(
      target.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeInOutCubic,
    );
  }

  void _pauseAutoScroll() {
    _resumeTimer?.cancel();
    if (_autoScroll) setState(() => _autoScroll = false);
  }

  void _scheduleAutoScrollResume() {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _autoScroll = true);
      if (_currentLine >= 0) _scrollToLine(_currentLine);
    });
  }

  @override
  void dispose() {
    _resumeTimer?.cancel();
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
              child: CachedNetworkImage(
                imageUrl: widget.artworkUrl!,
                fit: BoxFit.cover,
                cacheManager: nexoraArtworkCache,
                errorWidget: (_, _, _) =>
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
          child: CachedNetworkImage(
            imageUrl: widget.artworkUrl!,
            fit: BoxFit.cover,
            cacheManager: nexoraArtworkCache,
            errorWidget: (_, _, _) => Container(
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
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 10,
                      letterSpacing: 3.0,
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
                    if (widget.artist != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.artist!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
        stops: [0.0, 0.09, 0.9, 1.0],
      ).createShader(bounds),
      blendMode: BlendMode.dstIn,
      child: LayoutBuilder(
        builder: (context, constraints) {
          _listWidth = constraints.maxWidth - 48; // 24pt gutters
          return NotificationListener<ScrollNotification>(
            onNotification: (n) {
              // Manual scrubbing pauses the auto-centering; it resumes
              // after 3s of idle via _scheduleAutoScrollResume.
              if (n is ScrollStartNotification && n.dragDetails != null) {
                _pauseAutoScroll();
              } else if (n is ScrollEndNotification) {
                _scheduleAutoScrollResume();
              }
              return false;
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              itemCount: widget.lyrics.length,
              itemBuilder: _buildLineItem,
            ),
          );
        },
      ),
    );
  }

  Widget _buildLineItem(BuildContext context, int index) {
    final line = widget.lyrics[index];
    final isCurrent = index == _currentLine;
    final isPast = _currentLine >= 0 && index < _currentLine;
    final canSeek =
        widget.onLineTap != null &&
        (_hasTiming
            ? line.timestamp != null
            : widget.duration > Duration.zero);

    final content = isCurrent
        ? _buildKaraokeLine(line, index)
        : Text(
            line.text,
            style: _LyricsStyles.resting,
          );

    return RepaintBoundary(
      key: ValueKey('lyric-$index'),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: canSeek
            ? () {
                HapticFeedback.selectionClick();
                widget.onLineTap!(_hasTiming ? line.timestamp! : _lineStart(index));
              }
            : null,
        child: SizedBox(
          height: _boxHeightFor(line.text, _listWidth),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 340),
              curve: Curves.easeOutBack,
              alignment: Alignment.centerLeft,
              scale: isCurrent ? 1.0 : 0.96,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 340),
                curve: Curves.easeOutCubic,
                opacity: isCurrent ? 1.0 : (isPast ? 0.34 : 0.62),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The active line — signature karaoke: a gradient fill sweeps across
  /// the text in time with the song (interpolated smoothly between
  /// position ticks). Base layer is dimmed white with a soft glow; the
  /// sweep reveals the bright aurora gradient on top.
  Widget _buildKaraokeLine(LyricLine line, int index) {
    final progress = _lineProgress(index);
    final base = _LyricsStyles.active.copyWith(
      color: Colors.white.withValues(alpha: 0.40),
      shadows: [
        Shadow(
          color: AppColors.accent.withValues(alpha: 0.55),
          blurRadius: 26,
        ),
      ],
    );
    return Stack(
      children: [
        Text(line.text, style: base),
        TweenAnimationBuilder<double>(
          // Keyed so a new line restarts the sweep from zero instead of
          // animating backwards from the previous line's progress.
          key: ValueKey('karaoke-${line.text}-${line.timestamp}'),
          tween: Tween<double>(begin: 0.0, end: progress),
          duration: const Duration(milliseconds: 450),
          curve: Curves.linear,
          builder: (context, v, child) => ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: v,
              child: child,
            ),
          ),
          child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Colors.white, AppColors.accentCyan],
            ).createShader(bounds),
            blendMode: BlendMode.srcIn,
            child: Text(
              line.text,
              style: _LyricsStyles.active.copyWith(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

/// Type scale for the lyric lines. Shared by the TextPainter measurement
/// and the rendered widgets so measured heights always match on screen.
class _LyricsStyles {
  _LyricsStyles._();

  /// Resting lines — medium, slightly dimmed (opacity handled per state).
  static const TextStyle resting = TextStyle(
    fontSize: 16.5,
    fontWeight: FontWeight.w600,
    height: 1.35,
    letterSpacing: -0.3,
    color: Colors.white,
  );

  /// Active line — bold, larger, tight tracking.
  static const TextStyle active = TextStyle(
    fontSize: 23,
    fontWeight: FontWeight.w800,
    height: 1.35,
    letterSpacing: -0.3,
    color: Colors.white,
  );
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
