import 'package:flutter/material.dart';
import '../../../core/theme/neo_mirai_theme.dart';
import '../../../core/utils/responsive.dart';

/// Search bar untuk filter kegiatan
class KegiatanSearchFilter extends StatelessWidget {
  final String searchQuery;
  final Function(String) onSearchChanged;

  const KegiatanSearchFilter({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.cardPadding(16),
        vertical: Responsive.spacing(8),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(Responsive.radius(14)),
          boxShadow: [
            BoxShadow(
              color: NeoMiraiColors.ink.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Cari kegiatan...',
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: Responsive.fontSize(12),
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Colors.grey[400],
              size: Responsive.iconSize(20),
            ),
            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      color: Colors.grey[400],
                      size: Responsive.iconSize(20),
                    ),
                    onPressed: () => onSearchChanged(''),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: Responsive.spacing(16),
              vertical: Responsive.spacing(12),
            ),
          ),
          style: TextStyle(
            fontSize: Responsive.fontSize(13),
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
