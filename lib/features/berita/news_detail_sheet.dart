import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/news_model.dart';
import '../../../core/theme/neo_mirai_theme.dart';
import '../../../core/utils/responsive.dart';

/// Bottom sheet ringkasan berita
void showNewsDetailSheet(BuildContext context, NewsModel news) {
  final bool isSmall = context.isSmallPhone;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetContext).size.height * 0.82,
        ),
        decoration: BoxDecoration(
          color: NeoMiraiColors.rice,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Responsive.radius(isSmall ? 18 : 22)),
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: EdgeInsets.symmetric(
                    vertical: Responsive.spacing(10),
                  ),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: NeoMiraiColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              if (news.imageUrl != null && news.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                    Responsive.radius(isSmall ? 12 : 16),
                  ),
                  child: Image.network(
                    news.imageUrl!,
                    width: double.infinity,
                    height: isSmall ? 170 : 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),

              Padding(
                padding: EdgeInsets.all(Responsive.cardPadding(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (news.category != null &&
                            news.category!.isNotEmpty) ...[
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: Responsive.spacing(8),
                              vertical: Responsive.spacing(3),
                            ),
                            decoration: BoxDecoration(
                              color: NeoMiraiColors.gold.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(
                                Responsive.radius(6),
                              ),
                            ),
                            child: Text(
                              news.category!.toUpperCase(),
                              style: TextStyle(
                                fontSize: Responsive.fontSize(8),
                                fontWeight: FontWeight.bold,
                                color: NeoMiraiColors.gold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          SizedBox(width: Responsive.spacing(8)),
                        ],
                        if (news.publishDate != null)
                          Text(
                            DateFormat(
                              'd MMM yyyy',
                              'id_ID',
                            ).format(news.publishDate!),
                            style: TextStyle(
                              fontSize: Responsive.fontSize(9),
                              color: NeoMiraiColors.inkSoft,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: Responsive.spacing(10)),
                    Text(
                      news.title,
                      style: TextStyle(
                        fontSize: Responsive.fontSize(isSmall ? 15 : 18),
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                        color: NeoMiraiColors.ink,
                      ),
                    ),
                    SizedBox(height: Responsive.spacing(10)),
                    Text(
                      news.excerpt ?? 'Tidak ada ringkasan.',
                      style: TextStyle(
                        fontSize: Responsive.fontSize(isSmall ? 11 : 13),
                        height: 1.6,
                        color: NeoMiraiColors.inkSoft,
                      ),
                    ),
                    SizedBox(height: Responsive.spacing(20)),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NeoMiraiColors.gold,
                          foregroundColor: NeoMiraiColors.rice,
                          padding: EdgeInsets.symmetric(
                            vertical: Responsive.spacing(12),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              Responsive.radius(12),
                            ),
                          ),
                        ),
                        child: const Text('Tutup'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
