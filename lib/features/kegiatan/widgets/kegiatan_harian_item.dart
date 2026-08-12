import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/neo_mirai_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/models/kegiatan_model.dart';
import '../../../core/providers/kegiatan_provider.dart';
import 'kegiatan_form_modal.dart';

/// Widget untuk menampilkan kegiatan satu hari
class KegiatanHarianItem extends StatelessWidget {
  final KegiatanHarian harian;
  final VoidCallback onDelete;

  const KegiatanHarianItem({
    super.key,
    required this.harian,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: Responsive.spacing(4),
        vertical: Responsive.spacing(4),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Responsive.radius(12)),
        boxShadow: [
          BoxShadow(
            color: NeoMiraiColors.ink.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateHeader(),
          _buildActivityList(),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildDateHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.spacing(12),
        vertical: Responsive.spacing(8),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Responsive.radius(12)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today_rounded,
            color: const Color(0xFFEF6C00),
            size: Responsive.iconSize(16),
          ),
          SizedBox(width: Responsive.spacing(8)),
          Expanded(
            child: Text(
              harian.label,
              style: TextStyle(
                fontSize: Responsive.fontSize(12),
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.spacing(6),
              vertical: Responsive.spacing(2),
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFEF6C00).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Responsive.radius(6)),
            ),
            child: Text(
              '${harian.items.length} kegiatan',
              style: TextStyle(
                fontSize: Responsive.fontSize(10),
                color: const Color(0xFFEF6C00),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.spacing(12),
        vertical: Responsive.spacing(8),
      ),
      child: Column(
        children: harian.items.map((item) => _buildActivityItem(item)).toList(),
      ),
    );
  }

  Widget _buildActivityItem(KegiatanItem item) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Responsive.spacing(4)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: const Color(0xFF2E7D32),
            size: Responsive.iconSize(16),
          ),
          SizedBox(width: Responsive.spacing(8)),
          Expanded(
            child: Text(
              item.kegiatan,
              style: TextStyle(
                fontSize: Responsive.fontSize(12),
                color: Colors.black87,
              ),
            ),
          ),
          SizedBox(width: Responsive.spacing(8)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.spacing(6),
              vertical: Responsive.spacing(2),
            ),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Responsive.radius(4)),
            ),
            child: Text(
              '${item.volume} ${item.satuan}',
              style: TextStyle(
                fontSize: Responsive.fontSize(10),
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.spacing(8),
        vertical: Responsive.spacing(6),
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildActionButton(
            context,
            'Edit',
            Icons.edit_rounded,
            Colors.blue,
            () => _showEditModal(context),
          ),
          SizedBox(width: Responsive.spacing(4)),
          _buildActionButton(
            context,
            'Hapus',
            Icons.delete_rounded,
            Colors.red,
            onDelete,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: Responsive.iconSize(14), color: color),
      label: Text(
        label,
        style: TextStyle(
          fontSize: Responsive.fontSize(10),
          color: color,
        ),
      ),
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.spacing(6),
          vertical: Responsive.spacing(4),
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  void _showEditModal(BuildContext context) {
    final provider = context.read<KegiatanProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: KegiatanFormModal(
          selectedDate: harian.date,
          existingItems: harian.items,
          kegiatanProvider: provider,
          onSaved: () {
            // Refresh will be handled by parent
          },
        ),
      ),
    );
  }
}
