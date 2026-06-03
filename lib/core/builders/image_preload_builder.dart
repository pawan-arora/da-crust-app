import 'package:flutter/material.dart';

class ImagePreloadBuilder extends StatefulWidget {
  final String imagePath;
  final Widget Function(BuildContext context, bool isLoading) builder;

  const ImagePreloadBuilder({
    super.key,
    required this.imagePath,
    required this.builder,
  });

  @override
  State<ImagePreloadBuilder> createState() => _ImagePreloadBuilderState();
}

class _ImagePreloadBuilderState extends State<ImagePreloadBuilder> {
  bool _isLoading = true;
  ImageStream? _imageStream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _preloadImage();
  }

  void _preloadImage() {
    final provider = widget.imagePath.startsWith('https')
        ? NetworkImage(widget.imagePath)
        : AssetImage(widget.imagePath) as ImageProvider;

    final stream = provider.resolve(createLocalImageConfiguration(context));

    if (_imageStream?.key != stream.key) {
      _imageStream?.removeListener(_getListener());
      _imageStream = stream;
      _imageStream!.addListener(_getListener());
    }
  }

  ImageStreamListener _getListener() {
    return ImageStreamListener(
      (info, synchronousCall) {
        if (mounted && _isLoading) setState(() => _isLoading = false);
      },
      onError: (exception, stackTrace) {
        if (mounted && _isLoading) setState(() => _isLoading = false);
      },
    );
  }

  @override
  void dispose() {
    _imageStream?.removeListener(_getListener());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _isLoading);
  }
}