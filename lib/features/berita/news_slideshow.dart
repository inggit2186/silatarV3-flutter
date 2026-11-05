import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/models/news_model.dart';
import '../../../core/theme/neo_mirai_theme.dart';
import '../../../core/utils/responsive.dart';
import 'news_detail_sheet.dart';

/// Slideshow berita terbaru di dashboard
class NewsSlideshow extends StatefulWidget {
  final List<NewsModel> news;
  final bool isLoading;
  final VoidCallback? onRetry;

  const NewsSlideshow({
    super.key,
    required this.news,
    this.isLoading = false,
    this.onRetry,
  });

  @override
  State<NewsSlideshow> createState() => _NewsSlideshowState();
}

class _NewsSlideshowState extends State<NewsSlideshow> {
  late final PageController _pageController;
  Timer? _autoPlayTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _startAutoPlay();
  }

  @override
  void didUpdateWidget(covariant NewsSlideshow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.news.length != widget.news.length) {
      _currentPage = 0;
      _startAutoPlay();
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    if (widget.news.length <= 1) return;

    _autoPlayTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final next = (_currentPage + 1) % widget.news.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isSmall = context.isSmallPhone;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Berita Terbaru',
              style: TextStyle(
                fontSize: Responsive.fontSize(isSmall ? 13 : 14),
                fontWeight: FontWeight.bold,
                color: NeoMiraiColors.ink,
              ),
            ),
            if (widget.news.length > 1)
              Row(
                children: List.generate(widget.news.length, (index) {
                  final isActive = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: EdgeInsets.only(left: Responsive.spacing(4)),
                    width: isActive ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive
                          ? NeoMiraiColors.gold
                          : NeoMiraiColors.line,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
          ],
        ),
        SizedBox(height: Responsive.spacing(10)),
        SizedBox(height: isSmall ? 190 : 220, child: _buildBody(context)),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (widget.isLoading) {
      return _buildSkeleton(context);
    }

    if (widget.news.isEmpty) {
      return _buildEmpty(context);
    }

    return PageView.builder(
      controller: _pageController,
      itemCount: widget.news.length,
      onPageChanged: (index) {
        setState(() => _currentPage = index);
      },
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: Responsive.spacing(4)),
          child: _buildNewsCard(context, widget.news[index]),
        );
      },
    );
  }

  Widget _buildNewsCard(BuildContext context, NewsModel news) {
    final bool isSmall = context.isSmallPhone;

    return GestureDetector(
      onTap: () => showNewsDetailSheet(context, news),
      child: Container(
        decoration: BoxDecoration(
          color: NeoMiraiColors.rice,
          borderRadius: BorderRadius.circular(
            Responsive.radius(isSmall ? 14 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: NeoMiraiColors.ink.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Cover image
            if (news.imageUrl != null && news.imageUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: news.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, _) =>
                    Container(color: NeoMiraiColors.paperDeep),
                errorWidget: (_, _, _) => _buildFallbackCover(),
              )
            else
              _buildFallbackCover(),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    NeoMiraiColors.ink.withValues(alpha: 0.15),
                    NeoMiraiColors.ink.withValues(alpha: 0.92),
                  ],
                  stops: const [0.35, 0.62, 1.0],
                ),
              ),
            ),

            // Category badge
            if (news.category != null && news.category!.isNotEmpty)
              Positioned(
                top: Responsive.spacing(10),
                left: Responsive.spacing(10),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.spacing(8),
                    vertical: Responsive.spacing(3),
                  ),
                  decoration: BoxDecoration(
                    color: NeoMiraiColors.gold,
                    borderRadius: BorderRadius.circular(Responsive.radius(6)),
                  ),
                  child: Text(
                    news.category!.toUpperCase(),
                    style: TextStyle(
                      fontSize: Responsive.fontSize(7),
                      fontWeight: FontWeight.bold,
                      color: NeoMiraiColors.rice,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),

            // Title + excerpt
            Positioned(
              left: Responsive.spacing(12),
              right: Responsive.spacing(12),
              bottom: Responsive.spacing(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    news.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(isSmall ? 12 : 14),
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: Responsive.spacing(4)),
                  Text(
                    news.excerpt ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(isSmall ? 9 : 10),
                      height: 1.35,
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackCover() {
    return Container(
      decoration: BoxDecoration(gradient: NeoMiraiTheme.nightGradient),
      child: Center(
        child: Icon(
          Icons.newspaper_rounded,
          size: Responsive.iconSize(40),
          color: NeoMiraiColors.rice.withValues(alpha: 0.35),
        ),
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: Responsive.spacing(4)),
      decoration: BoxDecoration(
        color: NeoMiraiColors.paperDeep,
        borderRadius: BorderRadius.circular(Responsive.radius(16)),
      ),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: NeoMiraiColors.gold,
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: Responsive.spacing(4)),
      padding: EdgeInsets.all(Responsive.cardPadding(20)),
      decoration: BoxDecoration(
        color: NeoMiraiColors.rice,
        borderRadius: BorderRadius.circular(Responsive.radius(16)),
        border: Border.all(color: NeoMiraiColors.line.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.newspaper_rounded,
            size: Responsive.iconSize(32),
            color: NeoMiraiColors.ash,
          ),
          SizedBox(height: Responsive.spacing(8)),
          Text(
            'Belum ada berita',
            style: TextStyle(
              fontSize: Responsive.fontSize(11),
              color: NeoMiraiColors.inkSoft,
            ),
          ),
          if (widget.onRetry != null) ...[
            SizedBox(height: Responsive.spacing(8)),
            TextButton(
              onPressed: widget.onRetry,
              child: Text(
                'Muat ulang',
                style: TextStyle(
                  fontSize: Responsive.fontSize(10),
                  color: NeoMiraiColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
