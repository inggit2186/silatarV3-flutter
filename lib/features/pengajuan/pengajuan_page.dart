import 'package:flutter/material.dart';
import '../../core/theme/neo_mirai_theme.dart';
import '../../core/utils/responsive.dart';

class PengajuanPage extends StatefulWidget {
  const PengajuanPage({super.key});

  @override
  State<PengajuanPage> createState() => _PengajuanPageState();
}

class _PengajuanPageState extends State<PengajuanPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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

              // Tab Bar
              _buildTabBar(context),

              // Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildListTab('Semua'),
                    _buildListTab('Pending'),
                    _buildListTab('Diproses'),
                    _buildListTab('Selesai'),
                    _buildListTab('Ditolak'),
                  ],
                ),
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
                  'Pengajuan Saya',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(20),
                    fontWeight: FontWeight.bold,
                    color: NeoMiraiColors.ink,
                  ),
                ),
                Text(
                  'Lacak status pengajuan layanan',
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

  Widget _buildTabBar(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: Responsive.spacing(16)),
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
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: NeoMiraiColors.rice,
        unselectedLabelColor: NeoMiraiColors.inkSoft,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          gradient: NeoMiraiTheme.goldGradient,
          borderRadius: BorderRadius.circular(Responsive.radius(10)),
        ),
        labelStyle: TextStyle(
          fontSize: Responsive.fontSize(11),
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: Responsive.fontSize(11),
          fontWeight: FontWeight.normal,
        ),
        padding: EdgeInsets.all(Responsive.radius(4)),
        tabs: const [
          Tab(text: 'Semua'),
          Tab(text: 'Pending'),
          Tab(text: 'Diproses'),
          Tab(text: 'Selesai'),
          Tab(text: 'Ditolak'),
        ],
      ),
    );
  }

  Widget _buildListTab(String status) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(Responsive.spacing(24)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.radius(16)),
              decoration: BoxDecoration(
                color: NeoMiraiColors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(Responsive.radius(20)),
              ),
              child: Icon(
                Icons.description_outlined,
                size: Responsive.iconSize(48),
                color: NeoMiraiColors.gold,
              ),
            ),
            SizedBox(height: Responsive.spacing(16)),
            Text(
              status == 'Semua' ? 'Belum Ada Pengajuan' : 'Tidak Ada $status',
              style: TextStyle(
                fontSize: Responsive.fontSize(14),
                fontWeight: FontWeight.w600,
                color: NeoMiraiColors.ink,
              ),
            ),
            SizedBox(height: Responsive.spacing(6)),
            Text(
              status == 'Semua'
                  ? 'Ajukan layanan pertama Anda'
                  : 'Pengajuan dengan status $status\ntidak ditemukan',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Responsive.fontSize(12),
                color: NeoMiraiColors.inkSoft,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
