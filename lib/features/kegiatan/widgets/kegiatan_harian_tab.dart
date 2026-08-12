import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/providers/kegiatan_provider.dart';
import '../../../core/models/kegiatan_model.dart';
import 'kegiatan_harian_item.dart';
import 'kegiatan_search_filter.dart';

/// Tab untuk menampilkan daftar kegiatan harian
class KegiatanHarianTab extends StatefulWidget {
  final String searchQuery;
  final Function(String) onSearchChanged;

  const KegiatanHarianTab({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
  });

  @override
  State<KegiatanHarianTab> createState() => _KegiatanHarianTabState();
}

class _KegiatanHarianTabState extends State<KegiatanHarianTab> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Statistics Cards
        _buildStatsCards(),

        // Search Bar
        KegiatanSearchFilter(
          searchQuery: widget.searchQuery,
          onSearchChanged: widget.onSearchChanged,
        ),

        // List Kegiatan
        Expanded(
          child: _buildKegiatanList(),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    return Consumer<KegiatanProvider>(
      builder: (context, provider, child) {
        final rekap = provider.rekap;
        if (rekap == null) return const SizedBox.shrink();

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.cardPadding(16),
            vertical: Responsive.spacing(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard(
                '${rekap.totalEntries}',
                'Kegiatan',
                Icons.check_circle_rounded,
                const Color(0xFF2E7D32),
              ),
              _buildStatCard(
                '${rekap.totalDays}',
                'Hari',
                Icons.calendar_today_rounded,
                const Color(0xFFEF6C00),
              ),
              _buildStatCard(
                '${rekap.totalVolume}',
                'Volume',
                Icons.inventory_rounded,
                const Color(0xFF1565C0),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.spacing(8),
          vertical: Responsive.spacing(10),
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(Responsive.radius(12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: Responsive.iconSize(18)),
            SizedBox(height: Responsive.spacing(4)),
            Text(
              value,
              style: TextStyle(
                fontSize: Responsive.fontSize(16),
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: Responsive.fontSize(10),
                color: color.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKegiatanList() {
    return Consumer<KegiatanProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return _buildLoadingState();
        }

        if (provider.error != null) {
          return _buildErrorState(provider.error!);
        }

        final filteredGroups = provider.getFilteredKegiatan(widget.searchQuery);

        if (filteredGroups.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: EdgeInsets.all(Responsive.spacing(12)),
          itemCount: filteredGroups.length,
          itemBuilder: (context, index) {
            return KegiatanHarianItem(
              harian: filteredGroups[index],
              onDelete: () => _confirmDelete(filteredGroups[index]),
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: const Color(0xFFEF6C00),
          ),
          SizedBox(height: Responsive.spacing(16)),
          Text(
            'Memuat kegiatan...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: Responsive.fontSize(13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(Responsive.spacing(32)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.radius(20)),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: Responsive.iconSize(48),
                color: Colors.red,
              ),
            ),
            SizedBox(height: Responsive.spacing(16)),
            Text(
              'Gagal Memuat Data',
              style: TextStyle(
                fontSize: Responsive.fontSize(15),
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: Responsive.spacing(6)),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Responsive.fontSize(12),
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: Responsive.spacing(16)),
            ElevatedButton.icon(
              onPressed: () {
                final provider = context.read<KegiatanProvider>();
                provider.clearError();
                provider.loadKegiatan(provider.selectedMonth);
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF6C00),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(Responsive.spacing(32)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.radius(20)),
              decoration: BoxDecoration(
                color: const Color(0xFFEF6C00).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_note_rounded,
                size: Responsive.iconSize(48),
                color: const Color(0xFFEF6C00),
              ),
            ),
            SizedBox(height: Responsive.spacing(16)),
            Text(
              'Belum Ada Kegiatan',
              style: TextStyle(
                fontSize: Responsive.fontSize(15),
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: Responsive.spacing(6)),
            Text(
              'Mulai tambahkan kegiatan harian Anda',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Responsive.fontSize(12),
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(KegiatanHarian harian) {
    final provider = context.read<KegiatanProvider>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Kegiatan'),
        content: Text(
          'Hapus semua kegiatan pada tanggal ${harian.label}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await provider.deleteKegiatan(harian.date);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Kegiatan berhasil dihapus'
                          : 'Gagal menghapus kegiatan',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
