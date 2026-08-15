import 'package:cached_network_image/cached_network_image.dart';
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

    if (_useHtmlFallback) {
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

    // Decode at roughly the on-screen size (scaled for device pixel ratio)
    // instead of the source resolution. Menu photos are uploaded at full
    // camera resolution but only ever shown at a few hundred logical
    // pixels, so decoding full-size wastes GPU texture memory across a
    // whole grid of cards — that memory pressure is what makes CanvasKit
    // evict "live" image textures and then fail to redraw them.
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