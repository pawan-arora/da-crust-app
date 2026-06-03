import 'package:flutter/material.dart';
import 'package:da_crust_app/features/menu/widgets/nav_button.dart';

class ModernCarousel extends StatefulWidget {
  final List<Widget> items;
  final double height;
  final double scrollAmount;
  final double separatorWidth;

  const ModernCarousel({
    super.key,
    required this.items,
    required this.height,
    this.scrollAmount = 320.0,
    this.separatorWidth = 16.0,
  });

  @override
  State<ModernCarousel> createState() => _ModernCarouselState();
}

class _ModernCarouselState extends State<ModernCarousel> {
  final ScrollController _scrollController = ScrollController();
  bool _showLeftButton = false;
  bool _showRightButton = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateButtonVisibility());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() => _updateButtonVisibility();

  void _updateButtonVisibility() {
    if (!_scrollController.hasClients) return;
    final showLeft = _scrollController.offset > 0;
    final showRight = _scrollController.offset < _scrollController.position.maxScrollExtent;

    if (showLeft != _showLeftButton || showRight != _showRightButton) {
      setState(() {
        _showLeftButton = showLeft;
        _showRightButton = showRight;
      });
    }
  }

  void _scroll(int direction) {
    if (!_scrollController.hasClients) return;
    final targetPosition = (_scrollController.offset + (widget.scrollAmount * direction))
        .clamp(0.0, _scrollController.position.maxScrollExtent);

    _scrollController.animateTo(
      targetPosition,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return SizedBox(height: widget.height);

    return SizedBox(
      height: widget.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ShaderMask(
            shaderCallback: (Rect bounds) {
              return const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.white, Colors.transparent, Colors.transparent, Colors.white],
                stops: [0.0, 0.02, 0.98, 1.0],
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstOut,
            child: ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.items.length,
              separatorBuilder: (_, __) => SizedBox(width: widget.separatorWidth),
              itemBuilder: (context, index) => widget.items[index],
            ),
          ),
          
          if (_showLeftButton)
            Positioned(
              left: 4,
              child: NavButton(icon: Icons.chevron_left, onTap: () => _scroll(-1)),
            ),
            
          if (_showRightButton && widget.items.length > 2) 
            Positioned(
              right: 4,
              child: NavButton(icon: Icons.chevron_right, onTap: () => _scroll(1)),
            ),
        ],
      ),
    );
  }
}