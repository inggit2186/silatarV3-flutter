import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../core/models/news_model.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/neo_mirai_theme.dart';
import '../../core/utils/responsive.dart';
import 'news_detail_page.dart';

/// Halaman daftar seluruh berita
class NewsListPage extends StatefulWidget {
  /// Kategori awal (opsional), misal dari dashboard
  final String? initialCategory;

  const NewsListPage({super.key, this.initialCategory});

  @override
  State<NewsListPage> createState() => _NewsListPageState();
}

class _NewsListPageState extends State<NewsListPage> {
  /// Ambil seluruh berita sekaligus (backend membatasi maksimal 200).
  /// Fallback: bila jumlah berita melebihi batas, infinite scroll tetap aktif.
  static const int _perPage = 200;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  final List<NewsModel> _news = [];
  List<NewsCategory> _categories = [];

  String _selectedCategory = 'all';
  String _searchQuery = '';

  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  String? _error;

  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;

  bool get _hasMore => _currentPage < _lastPage;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'all';
    _scrollController.addListener(_onScroll);
    _loadCategories();
    _loadNews(reset: true);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _loadCategories() async {
    final response = await ApiService.instance.getNewsCategories();
    if (!mounted) return;
    if (response.success && response.data != null) {
      setState(() => _categories = response.data!);
    }
  }

  Future<void> _loadNews({bool reset = false}) async {
    if (reset) {
      setState(() {
        _isInitialLoading = true;
        _error = null;
        _currentPage = 1;
      });
    }

    final response = await ApiService.instance.getNewsList(
      page: reset ? 1 : _currentPage + 1,
      perPage: _perPage,
      category: _selectedCategory,
      query: _searchQuery,
    );

    if (!mounted) return;

    setState(() {
      _isInitialLoading = false;
      _isLoadingMore = false;

      if (response.success && response.data != null) {
        final result = response.data!;
        if (reset) {
          _news
            ..clear()
            ..addAll(result.items);
        } else {
          _news.addAll(result.items);
        }
        _currentPage = result.currentPage;
        _lastPage = result.lastPage;
        _total = result.total;
        _error = null;
      } else {
        _error = response.message ?? 'Gagal memuat berita';
      }
    });
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _isInitialLoading || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    await _loadNews();
  }

  void _onCategorySelected(String category) {
    if (_selectedCategory == category) return;
    setState(() => _selectedCategory = category);
    _loadNews(reset: true);
  }

  void _onSearchSubmitted(String value) {
    final query = value.trim();
    if (query == _searchQuery) return;
    setState(() => _searchQuery = query);
    _loadNews(reset: true);
  }

  void _clearSearch() {
    if (_searchQuery.isEmpty) return;
    _searchController.clear();
    setState(() => _searchQuery = '');
    _loadNews(reset: true);
  }

  void _openDetail(NewsModel news) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NewsDetailPage(news: news)),
    );
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return Scaffold(
      backgroundColor: NeoMiraiColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildSearchField(context),
            _buildCategoryChips(context),
            Expanded(child: _buildContent(context)),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // HEADER
  // ═════════════════════════════════════════════════════════════════

  Widget _buildHeader(BuildContext context) {
    final bool isSmall = context.isSmallPhone;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(gradient: NeoMiraiTheme.nightGradient),
      padding: EdgeInsets.fromLTRB(
        Responsive.spacing(12),
        Responsive.spacing(10),
        Responsive.spacing(12),
        Responsive.spacing(14),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(Responsive.spacing(7)),
              decoration: BoxDecoration(
                color: NeoMiraiColors.rice.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(Responsive.radius(10)),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                size: Responsive.iconSize(18),
                color: NeoMiraiColors.rice,
              ),
            ),
          ),
          SizedBox(width: Responsive.spacing(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Semua Berita',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(isSmall ? 15 : 17),
                    fontWeight: FontWeight.bold,
                    color: NeoMiraiColors.rice,
                  ),
                ),
                SizedBox(height: Responsive.spacing(2)),
                Text(
                  _total > 0
                      ? '$_total berita dipublikasikan'
                      : 'Informasi & kegiatan Kankemenag',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(isSmall ? 9 : 10),
                    color: NeoMiraiColors.rice.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(Responsive.spacing(7)),
            decoration: BoxDecoration(
              color: NeoMiraiColors.gold.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(Responsive.radius(10)),
            ),
            child: Icon(
              Icons.newspaper_rounded,
              size: Responsive.iconSize(18),
              color: NeoMiraiColors.goldLight,
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // SEARCH
  // ═════════════════════════════════════════════════════════════════

  Widget _buildSearchField(BuildContext context) {
    final bool isSmall = context.isSmallPhone;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Responsive.spacing(12),
        Responsive.spacing(12),
        Responsive.spacing(12),
        Responsive.spacing(4),
      ),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onSubmitted: _onSearchSubmitted,
        style: TextStyle(
          fontSize: Responsive.fontSize(isSmall ? 11 : 12),
          color: NeoMiraiColors.ink,
        ),
        decoration: InputDecoration(
          hintText: 'Cari judul berita...',
          hintStyle: TextStyle(
            fontSize: Responsive.fontSize(isSmall ? 11 : 12),
            color: NeoMiraiColors.ash,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: Responsive.iconSize(18),
            color: NeoMiraiColors.inkSoft,
          ),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : GestureDetector(
                  onTap: _clearSearch,
                  child: Icon(
                    Icons.close_rounded,
                    size: Responsive.iconSize(16),
                    color: NeoMiraiColors.ash,
                  ),
                ),
          filled: true,
          fillColor: NeoMiraiColors.rice,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            vertical: Responsive.spacing(10),
            horizontal: Responsive.spacing(10),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Responsive.radius(12)),
            borderSide: BorderSide(
              color: NeoMiraiColors.line.withValues(alpha: 0.5),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Responsive.radius(12)),
            borderSide: BorderSide(
              color: NeoMiraiColors.line.withValues(alpha: 0.5),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Responsive.radius(12)),
            borderSide: const BorderSide(color: NeoMiraiColors.gold),
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // FILTER KATEGORI
  // ═════════════════════════════════════════════════════════════════

  Widget _buildCategoryChips(BuildContext context) {
    if (_categories.isEmpty) return const SizedBox.shrink();

    final bool isSmall = context.isSmallPhone;

    return SizedBox(
      height: isSmall ? 44 : 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: Responsive.spacing(12)),
        children: [
          _buildChip(context, 'all', 'Semua'),
          ..._categories.map(
            (c) => _buildChip(context, c.category, c.label, count: c.total),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(
    BuildContext context,
    String value,
    String label, {
    int? count,
  }) {
    final bool isSmall = context.isSmallPhone;
    final bool isActive = _selectedCategory == value;

    return GestureDetector(
      onTap: () => _onCategorySelected(value),
      child: Container(
        margin: EdgeInsets.only(right: Responsive.spacing(6)),
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.spacing(12),
          vertical: Responsive.spacing(6),
        ),
        decoration: BoxDecoration(
          gradient: isActive ? NeoMiraiTheme.goldGradient : null,
          color: isActive ? null : NeoMiraiColors.rice,
          borderRadius: BorderRadius.circular(Responsive.radius(20)),
          border: Border.all(
            color: isActive
                ? Colors.transparent
                : NeoMiraiColors.line.withValues(alpha: 0.5),
          ),
        ),
        child: Center(
          child: Text(
            count == null ? label : '$label ($count)',
            style: TextStyle(
              fontSize: Responsive.fontSize(isSmall ? 9 : 10),
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? NeoMiraiColors.rice : NeoMiraiColors.inkSoft,
            ),
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // CONTENT
  // ═════════════════════════════════════════════════════════════════

  Widget _buildContent(BuildContext context) {
    if (_isInitialLoading) {
      return _buildLoadingState(context);
    }

    if (_error != null && _news.isEmpty) {
      return _buildErrorState(context);
    }

    if (_news.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      color: NeoMiraiColors.gold,
      onRefresh: () => _loadNews(reset: true),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          Responsive.spacing(12),
          Responsive.spacing(8),
          Responsive.spacing(12),
          Responsive.spacing(20),
        ),
        itemCount: _news.length + 1,
        separatorBuilder: (_, _) => SizedBox(height: Responsive.spacing(10)),
        itemBuilder: (context, index) {
          if (index == _news.length) {
            return _buildListFooter(context);
          }
          return _buildNewsCard(context, _news[index]);
        },
      ),
    );
  }

  Widget _buildNewsCard(BuildContext context, NewsModel news) {
    final bool isSmall = context.isSmallPhone;
    final coverSize = isSmall ? 88.0 : 100.0;

    return GestureDetector(
      onTap: () => _openDetail(news),
      child: Container(
        padding: EdgeInsets.all(Responsive.spacing(8)),
        decoration: BoxDecoration(
          color: NeoMiraiColors.rice,
          borderRadius: BorderRadius.circular(Responsive.radius(14)),
          border: Border.all(color: NeoMiraiColors.line.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: NeoMiraiColors.ink.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(Responsive.radius(10)),
              child: SizedBox(
                width: coverSize,
                height: coverSize,
                child: news.hasCover
                    ? CachedNetworkImage(
                        imageUrl: news.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => _buildCoverFallback(context),
                        errorWidget: (_, _, _) => _buildCoverFallback(context),
                      )
                    : _buildCoverFallback(context),
              ),
            ),
            SizedBox(width: Responsive.spacing(10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((news.category ?? '').isNotEmpty) ...[
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.spacing(6),
                        vertical: Responsive.spacing(2),
                      ),
                      decoration: BoxDecoration(
                        color: NeoMiraiColors.gold.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(
                          Responsive.radius(5),
                        ),
                      ),
                      child: Text(
                        news.category!.toUpperCase(),
                        style: TextStyle(
                          fontSize: Responsive.fontSize(7),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                          color: NeoMiraiColors.gold,
                        ),
                      ),
                    ),
                    SizedBox(height: Responsive.spacing(5)),
                  ],
                  Text(
                    news.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(isSmall ? 11 : 12.5),
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                      color: NeoMiraiColors.ink,
                    ),
                  ),
                  if ((news.excerpt ?? '').isNotEmpty) ...[
                    SizedBox(height: Responsive.spacing(4)),
                    Text(
                      news.excerpt!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: Responsive.fontSize(isSmall ? 9 : 10),
                        height: 1.35,
                        color: NeoMiraiColors.inkSoft,
                      ),
                    ),
                  ],
                  SizedBox(height: Responsive.spacing(6)),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: Responsive.iconSize(9),
                        color: NeoMiraiColors.ash,
                      ),
                      SizedBox(width: Responsive.spacing(4)),
                      Text(
                        _formatDate(news.publishDate),
                        style: TextStyle(
                          fontSize: Responsive.fontSize(8),
                          color: NeoMiraiColors.ash,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: Responsive.iconSize(9),
                        color: NeoMiraiColors.gold,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverFallback(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: NeoMiraiTheme.nightGradient),
      child: Center(
        child: Icon(
          Icons.newspaper_rounded,
          size: Responsive.iconSize(22),
          color: NeoMiraiColors.rice.withValues(alpha: 0.35),
        ),
      ),
    );
  }

  Widget _buildListFooter(BuildContext context) {
    if (_isLoadingMore) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: Responsive.spacing(14)),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: NeoMiraiColors.gold,
            ),
          ),
        ),
      );
    }

    if (_hasMore) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: Responsive.spacing(10)),
        child: Center(
          child: TextButton(
            onPressed: _loadMore,
            child: Text(
              'Muat berita lainnya',
              style: TextStyle(
                fontSize: Responsive.fontSize(10),
                fontWeight: FontWeight.w600,
                color: NeoMiraiColors.gold,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: Responsive.spacing(14)),
      child: Center(
        child: Text(
          '— Semua berita sudah ditampilkan —',
          style: TextStyle(
            fontSize: Responsive.fontSize(9),
            color: NeoMiraiColors.ash,
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // STATES
  // ═════════════════════════════════════════════════════════════════

  Widget _buildLoadingState(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.all(Responsive.spacing(12)),
      itemCount: 5,
      separatorBuilder: (_, _) => SizedBox(height: Responsive.spacing(10)),
      itemBuilder: (context, index) {
        return Container(
          height: 116,
          decoration: BoxDecoration(
            color: NeoMiraiColors.paperDeep.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(Responsive.radius(14)),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(Responsive.spacing(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: Responsive.iconSize(42),
              color: NeoMiraiColors.ash,
            ),
            SizedBox(height: Responsive.spacing(12)),
            Text(
              _error ?? 'Gagal memuat berita',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Responsive.fontSize(11),
                color: NeoMiraiColors.inkSoft,
              ),
            ),
            SizedBox(height: Responsive.spacing(14)),
            ElevatedButton(
              onPressed: () => _loadNews(reset: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: NeoMiraiColors.gold,
                foregroundColor: NeoMiraiColors.rice,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Responsive.radius(10)),
                ),
              ),
              child: Text(
                'Coba lagi',
                style: TextStyle(fontSize: Responsive.fontSize(11)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(Responsive.spacing(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.newspaper_rounded,
              size: Responsive.iconSize(42),
              color: NeoMiraiColors.ash,
            ),
            SizedBox(height: Responsive.spacing(12)),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Tidak ada berita untuk "$_searchQuery"'
                  : 'Belum ada berita',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Responsive.fontSize(11),
                fontWeight: FontWeight.w600,
                color: NeoMiraiColors.inkSoft,
              ),
            ),
            if (_selectedCategory != 'all' || _searchQuery.isNotEmpty) ...[
              SizedBox(height: Responsive.spacing(10)),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _selectedCategory = 'all';
                  });
                  _loadNews(reset: true);
                },
                child: Text(
                  'Reset filter',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(10),
                    fontWeight: FontWeight.w600,
                    color: NeoMiraiColors.gold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // HELPERS
  // ═════════════════════════════════════════════════════════════════

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    try {
      return DateFormat('d MMM yyyy', 'id_ID').format(date.toLocal());
    } catch (_) {
      return DateFormat('d MMM yyyy').format(date.toLocal());
    }
  }
}
