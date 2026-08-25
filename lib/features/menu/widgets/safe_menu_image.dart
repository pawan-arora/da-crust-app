import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class SafeMenuImage extends StatefulWidget {
  final String imagePath; // This now expects the full https:// URL from Firestore
  final double height;
  final double width;
  const SafeMenuImage({
    super.key,
    required this.imagePath,
    this.height = 140,
    this.width = double.infinity,
  });

  @override
  State<SafeMenuImage> createState() => _SafeMenuImageState();
}

class _SafeMenuImageState extends State<SafeMenuImage> {
  // Some valid images (e.g. JPEGs with certain embedded ICC color profiles)
  // fail Flutter Web's own byte decoder with ImageCodecException even though
  // the file is intact — the browser can display them fine. When
  // CachedNetworkImage's decode fails, we fall back to rendering via the
  // browser's native <img> element instead of endlessly retrying the same
  // decode that will just fail again.
  bool _useHtmlFallback = false;

  @override
  void didUpdateWidget(covariant SafeMenuImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      _useHtmlFallback = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Safety check: Make sure we actually have a valid HTTP URL
    if (widget.imagePath.isEmpty || !widget.imagePath.startsWith('http')) {
      return _fallback(reason: "Invalid or empty URL", error: null);
    }

    // On web this is the primary path, not a fallback.
    //
    // CanvasKit decodes photos through WebCodecs into a VideoFrame and wraps
    // it in a *lazy* SkImage (MakeLazyImageFromTextureSourceWithInfo), which
    // re-uploads that texture from the VideoFrame on every repaint after Skia
    // evicts it from the GPU cache. A VideoFrame is a scarce browser resource
    // the engine itself documents as closable "any time" — and once it's gone
    // the re-upload gets nothing, logging
    // "WebGL: INVALID_VALUE: texImage2D: no image" and painting the card
    // blank. It shows up randomly because it's a race between Skia evicting
    // the texture and the browser reclaiming the frame, so it bites hardest
    // on long grids under fast scrolling.
    //
    // Rendering through a real <img> leaves the pixels with the browser and
    // never involves a CanvasKit texture upload, sidestepping the race.
    if (kIsWeb || _useHtmlFallback) {
      return Image.network(
        widget.imagePath,
        height: widget.height,
        width: widget.width,
        fit: BoxFit.cover,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : _loading(),
        errorBuilder: (_, error, _) =>
            _fallback(reason: "Image.network (HTML) error", error: error),
      );
    }

    // Mobile only from here down: decode at roughly the on-screen size
    // (scaled for device pixel ratio) instead of the source resolution. Menu
    // photos are uploaded at full camera resolution but only ever shown at a
    // few hundred logical pixels, so decoding full-size wastes texture memory
    // across a whole grid of cards. This is also where CachedNetworkImage's
    // disk cache earns its keep, which the web <img> path gets from the
    // browser's own HTTP cache instead.
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final cacheHeight = (widget.height * dpr).round();
    final cacheWidth = widget.width.isFinite
        ? (widget.width * dpr).round()
        : null;

    return CachedNetworkImage(
      imageUrl: widget.imagePath,
      height: widget.height,
      width: widget.width,
      fit: BoxFit.cover,
      memCacheHeight: cacheHeight,
      memCacheWidth: cacheWidth,

      placeholder: (_, _) => _loading(),

      errorWidget: (_, _, error) {
        debugPrint("❌ Image Load Failed (CachedNetworkImage)");
        debugPrint("🌐 URL: ${widget.imagePath}");
        debugPrint("🔥 Error: $error");
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _useHtmlFallback = true);
        });
        return _loading();
      },
    );
  }

  /// -------------------------
  /// LOADING
  /// -------------------------
  Widget _loading() {
    return Container(
      height: widget.height,
      color: Colors.grey.shade200,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// -------------------------
  /// FALLBACK + LOGGING
  /// -------------------------
  Widget _fallback({required String reason, required dynamic error}) {
    debugPrint("❌ Image Load Failed");
    debugPrint("🌐 URL: ${widget.imagePath}");
    debugPrint("⚠️ Reason: $reason");
    if (error != null) debugPrint("🔥 Error: $error");

    return Container(
      height: widget.height,
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.fastfood, size: 50, color: Colors.grey),
      ),
    );
  }
}