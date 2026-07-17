import 'package:flutter/material.dart';

class RoundedNetworkImage extends StatefulWidget {
  final String? imageUrl;
  final double borderRadius;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color loaderColor;
  final double loaderStrokeWidth;
  final Widget? errorWidget;
  final Color backgroundColor;

  const RoundedNetworkImage({
    super.key,
    required this.imageUrl,
    this.borderRadius = 12,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.loaderColor = const Color.fromARGB(255, 20, 223, 54),
    this.loaderStrokeWidth = 3,
    this.errorWidget,
    this.backgroundColor = const Color(0xFF1E293B),
  });

  @override
  State<RoundedNetworkImage> createState() => _RoundedNetworkImageState();
}

class _RoundedNetworkImageState extends State<RoundedNetworkImage> {
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void didUpdateWidget(covariant RoundedNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValidUrl =
        widget.imageUrl != null && widget.imageUrl!.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: !hasValidUrl || _hasError
          ? _buildError()
          : SizedBox(
              width: widget.width,
              height: widget.height,
              child: Stack(
                // Removed fit: StackFit.expand
                children: [
                  // Image
                  Positioned.fill(
                    child: Image.network(
                      widget.imageUrl!,
                      fit: widget.fit,
                      frameBuilder:
                          (context, child, frame, wasSynchronouslyLoaded) {
                        if (wasSynchronouslyLoaded || frame != null) {
                          if (_isLoading) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() => _isLoading = false);
                              }
                            });
                          }
                          return child;
                        }
                        return const SizedBox();
                      },
                      errorBuilder: (_, _, _) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {
                              _isLoading = false;
                              _hasError = true;
                            });
                          }
                        });
                        return const SizedBox();
                      },
                    ),
                  ),

                  // Loader
                  if (_isLoading)
                    Positioned.fill(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: widget.loaderColor,
                          strokeWidth: widget.loaderStrokeWidth,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildError() {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ColoredBox(
        color: widget.backgroundColor,
        child: widget.errorWidget ??
            const Center(
              child: Icon(
                Icons.storefront,
                size: 48,
                color: Colors.white54,
              ),
            ),
      ),
    );
  }
}