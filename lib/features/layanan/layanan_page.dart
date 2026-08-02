import 'package:flutter/material.dart';
import '../../core/theme/neo_mirai_theme.dart';
import '../../core/utils/responsive.dart';

class LayananPage extends StatefulWidget {
  const LayananPage({super.key});

  @override
  State<LayananPage> createState() => _LayananPageState();
}

class _LayananPageState extends State<LayananPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: NeoMiraiTheme.paperGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context),

              // Search
              _buildSearchBar(context),

              // Content
              Expanded(
                child: _buildContent(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Responsive.cardPadding(16)),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(Responsive.radius(10)),
              decoration: BoxDecoration(
                color: NeoMiraiColors.rice,
                borderRadius: BorderRadius.circular(Responsive.radius(12)),
                boxShadow: [
                  BoxShadow(
                    color: NeoMiraiColors.ink.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: Responsive.iconSize(18),
                color: NeoMiraiColors.ink,
              ),
            ),
          ),
          SizedBox(width: Responsive.spacing(16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Layanan',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(20),
                    fontWeight: FontWeight.bold,
                    color: NeoMiraiColors.ink,
                  ),
                ),
                Text(
                  'Pilih layanan yang dibutuhkan',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(12),
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

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.cardPadding(16),
        vertical: Responsive.spacing(8),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: NeoMiraiColors.rice,
          borderRadius: BorderRadius.circular(Responsive.radius(16)),
          boxShadow: [
            BoxShadow(
              color: NeoMiraiColors.ink.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Cari layanan...',
            hintStyle: TextStyle(
              color: NeoMiraiColors.inkSoft,
              fontSize: Responsive.fontSize(13),
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: NeoMiraiColors.inkSoft,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: Responsive.spacing(16),
              vertical: Responsive.spacing(14),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(Responsive.spacing(16)),
      child: Column(
        children: [
          // Empty state
          _buildEmptyState(context),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Responsive.cardPadding(32)),
      decoration: BoxDecoration(
        color: NeoMiraiColors.rice,
        borderRadius: BorderRadius.circular(Responsive.radius(20)),
        border: Border.all(
          color: NeoMiraiColors.line.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(Responsive.radius(16)),
            decoration: BoxDecoration(
              gradient: NeoMiraiTheme.goldGradient,
              borderRadius: BorderRadius.circular(Responsive.radius(20)),
            ),
            child: Icon(
              Icons.grid_view_rounded,
              size: Responsive.iconSize(48),
              color: NeoMiraiColors.rice,
            ),
          ),
          SizedBox(height: Responsive.spacing(16)),
          Text(
            'Katalog Layanan',
            style: TextStyle(
              fontSize: Responsive.fontSize(16),
              fontWeight: FontWeight.bold,
              color: NeoMiraiColors.ink,
            ),
          ),
          SizedBox(height: Responsive.spacing(6)),
          Text(
            'Daftar layanan akan dimuat\ndari server',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: Responsive.fontSize(12),
              color: NeoMiraiColors.inkSoft,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
