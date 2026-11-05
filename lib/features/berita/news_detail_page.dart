import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/news_model.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/neo_mirai_theme.dart';
import '../../core/utils/responsive.dart';

/// Halaman baca berita lengkap
class NewsDetailPage extends StatefulWidget {
  final NewsModel news;

  const NewsDetailPage({super.key, required this.news});

  @override
  State<NewsDetailPage> createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends State<NewsDetailPage> {
  late NewsModel _news;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _news = widget.news;

    // Jika konten belum tersedia (dari list), ambil detail lengkap
    if ((_news.content ?? '').trim().isEmpty) {
      _loadDetail();
    }
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final slug = _news.slug.isNotEmpty ? _news.slug : _news.id.toString();
    final response = await ApiService.instance.getNewsDetail(slug);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (response.success && response.data != null) {
        _news = response.data!;
      } else {
        _error = response.message ?? 'Gagal memuat berita';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final bool isSmall = context.isSmallPhone;

    return Scaffold(
      backgroundColor: NeoMiraiColors.paper,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            // App bar dengan cover
            SliverAppBar(
              expandedHeight: isSmall ? 220 : 260,
              pinned: true,
              backgroundColor: NeoMiraiColors.night,
              foregroundColor: NeoMiraiColors.rice,
              leading: Padding(
                padding: EdgeInsets.all(Responsive.spacing(6)),
                child: _buildCircleButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.pop(context),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(background: _buildCover()),
            ),

            // Konten
            SliverToBoxAdapter(
              child: Container(
                color: NeoMiraiColors.rice,
                padding: EdgeInsets.all(
                  Responsive.cardPadding(isSmall ? 16 : 20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMeta(context),
                    SizedBox(height: Responsive.spacing(10)),
                    Text(
                      _news.title,
                      style: TextStyle(
                        fontSize: Responsive.fontSize(isSmall ? 17 : 21),
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                        color: NeoMiraiColors.ink,
                      ),
                    ),
                    if ((_news.excerpt ?? '').isNotEmpty) ...[
                      SizedBox(height: Responsive.spacing(10)),
                      Container(
                        padding: EdgeInsets.all(Responsive.spacing(10)),
                        decoration: BoxDecoration(
                          color: NeoMiraiColors.paperSoft,
                          border: Border(
                            left: BorderSide(
                              color: NeoMiraiColors.gold,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Text(
                          _news.excerpt!,
                          style: TextStyle(
                            fontSize: Responsive.fontSize(isSmall ? 11 : 12),
                            height: 1.55,
                            fontStyle: FontStyle.italic,
                            color: NeoMiraiColors.inkSoft,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: Responsive.spacing(14)),
                    const Divider(color: NeoMiraiColors.line, height: 1),
                    SizedBox(height: Responsive.spacing(14)),
                    _buildContent(context),
                    SizedBox(height: Responsive.spacing(24)),
                    _buildFooter(context),
                    SizedBox(height: Responsive.spacing(24)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: NeoMiraiColors.ink.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(Responsive.spacing(8)),
          child: Icon(
            icon,
            size: Responsive.iconSize(20),
            color: NeoMiraiColors.rice,
          ),
        ),
      ),
    );
  }

  Widget _buildCover() {
    if (_news.imageUrl != null && _news.imageUrl!.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: _news.imageUrl!,
            fit: BoxFit.cover,
            placeholder: (_, _) => Container(color: NeoMiraiColors.paperDeep),
            errorWidget: (_, _, _) => _buildCoverFallback(),
          ),
          // Gradient agar judul app bar terbaca
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  NeoMiraiColors.ink.withValues(alpha: 0.55),
                  Colors.transparent,
                  NeoMiraiColors.ink.withValues(alpha: 0.35),
                ],
                stops: const [0, 0.5, 1],
              ),
            ),
          ),
        ],
      );
    }
    return _buildCoverFallback();
  }

  Widget _buildCoverFallback() {
    return Container(
      decoration: BoxDecoration(gradient: NeoMiraiTheme.nightGradient),
      child: Center(
        child: Icon(
          Icons.newspaper_rounded,
          size: Responsive.iconSize(52),
          color: NeoMiraiColors.rice.withValues(alpha: 0.35),
        ),
      ),
    );
  }

  Widget _buildMeta(BuildContext context) {
    final bool isSmall = context.isSmallPhone;

    return Wrap(
      spacing: Responsive.spacing(8),
      runSpacing: Responsive.spacing(6),
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if ((_news.category ?? '').isNotEmpty)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.spacing(8),
              vertical: Responsive.spacing(3),
            ),
            decoration: BoxDecoration(
              color: NeoMiraiColors.gold,
              borderRadius: BorderRadius.circular(Responsive.radius(6)),
            ),
            child: Text(
              _news.category!.toUpperCase(),
              style: TextStyle(
                fontSize: Responsive.fontSize(8),
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: NeoMiraiColors.rice,
              ),
            ),
          ),
        if (_news.publishDate != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: Responsive.iconSize(11),
                color: NeoMiraiColors.inkSoft,
              ),
              SizedBox(width: Responsive.spacing(4)),
              Text(
                DateFormat('d MMMM yyyy', 'id_ID').format(_news.publishDate!),
                style: TextStyle(
                  fontSize: Responsive.fontSize(isSmall ? 9 : 10),
                  color: NeoMiraiColors.inkSoft,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    final bool isSmall = context.isSmallPhone;

    if (_isLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: Responsive.spacing(32)),
        child: Center(
          child: Column(
            children: [
              SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: NeoMiraiColors.gold,
                ),
              ),
              SizedBox(height: Responsive.spacing(10)),
              Text(
                'Memuat berita...',
                style: TextStyle(
                  fontSize: Responsive.fontSize(11),
                  color: NeoMiraiColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(Responsive.cardPadding(20)),
        decoration: BoxDecoration(
          color: NeoMiraiColors.error.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(Responsive.radius(12)),
          border: Border.all(
            color: NeoMiraiColors.error.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: Responsive.iconSize(28),
              color: NeoMiraiColors.error,
            ),
            SizedBox(height: Responsive.spacing(8)),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Responsive.fontSize(11),
                color: NeoMiraiColors.inkSoft,
              ),
            ),
            SizedBox(height: Responsive.spacing(8)),
            TextButton(
              onPressed: _loadDetail,
              child: Text(
                'Coba lagi',
                style: TextStyle(
                  fontSize: Responsive.fontSize(11),
                  fontWeight: FontWeight.w600,
                  color: NeoMiraiColors.gold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final content = (_news.content ?? '').trim();
    if (content.isEmpty) {
      return Text(
        'Isi berita tidak tersedia.',
        style: TextStyle(
          fontSize: Responsive.fontSize(isSmall ? 11 : 12),
          color: NeoMiraiColors.inkSoft,
        ),
      );
    }

    return Html(
      data: content,
      style: {
        'body': Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          fontSize: FontSize(Responsive.fontSize(isSmall ? 12 : 13.5)),
          lineHeight: const LineHeight(1.7),
          color: NeoMiraiColors.inkSoft,
        ),
        'p': Style(margin: Margins.only(bottom: 10)),
        'h1': Style(
          fontSize: FontSize(Responsive.fontSize(isSmall ? 16 : 19)),
          color: NeoMiraiColors.ink,
          fontWeight: FontWeight.bold,
          margin: Margins.only(top: 10, bottom: 8),
        ),
        'h2': Style(
          fontSize: FontSize(Responsive.fontSize(isSmall ? 15 : 17)),
          color: NeoMiraiColors.ink,
          fontWeight: FontWeight.bold,
          margin: Margins.only(top: 10, bottom: 8),
        ),
        'h3': Style(
          fontSize: FontSize(Responsive.fontSize(isSmall ? 13 : 15)),
          color: NeoMiraiColors.ink,
          fontWeight: FontWeight.w600,
          margin: Margins.only(top: 8, bottom: 6),
        ),
        'a': Style(
          color: NeoMiraiColors.info,
          textDecoration: TextDecoration.underline,
        ),
        'li': Style(
          margin: Margins.only(bottom: 4),
          lineHeight: const LineHeight(1.6),
        ),
        'blockquote': Style(
          margin: Margins.symmetric(vertical: 10),
          padding: HtmlPaddings.only(left: 12),
          border: Border(
            left: BorderSide(color: NeoMiraiColors.gold, width: 3),
          ),
          fontStyle: FontStyle.italic,
          color: NeoMiraiColors.inkSoft,
        ),
        'img': Style(margin: Margins.symmetric(vertical: 10)),
        'table': Style(
          border: Border.all(color: NeoMiraiColors.line),
          margin: Margins.symmetric(vertical: 10),
        ),
        'th': Style(
          backgroundColor: NeoMiraiColors.paperSoft,
          fontWeight: FontWeight.bold,
          color: NeoMiraiColors.ink,
        ),
        'td': Style(border: Border.all(color: NeoMiraiColors.line)),
        'figcaption': Style(
          fontSize: FontSize(Responsive.fontSize(9)),
          color: NeoMiraiColors.ash,
          fontStyle: FontStyle.italic,
        ),
      },
      onLinkTap: (url, attributes, element) async {
        if (url == null || url.isEmpty) return;
        final uri = Uri.tryParse(url);
        if (uri == null) return;

        final opened = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!opened && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tidak dapat membuka tautan: $url'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    final bool isSmall = context.isSmallPhone;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.spacing(12)),
      decoration: BoxDecoration(
        color: NeoMiraiColors.paperSoft,
        borderRadius: BorderRadius.circular(Responsive.radius(12)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_rounded,
            size: Responsive.iconSize(18),
            color: NeoMiraiColors.gold,
          ),
          SizedBox(width: Responsive.spacing(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kementerian Agama',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(isSmall ? 10 : 11),
                    fontWeight: FontWeight.w600,
                    color: NeoMiraiColors.ink,
                  ),
                ),
                Text(
                  'Kabupaten Tanah Datar',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(isSmall ? 9 : 10),
                    color: NeoMiraiColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
