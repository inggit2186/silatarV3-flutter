import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../../core/utils/responsive.dart';

/// Halaman preview PDF
class PdfPreviewPage extends StatelessWidget {
  final Uint8List pdfBytes;
  final String title;
  final String filename;

  const PdfPreviewPage({
    super.key,
    required this.pdfBytes,
    required this.title,
    required this.filename,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(
            fontSize: Responsive.fontSize(16),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFFEF6C00),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: () => _downloadPdf(context),
            tooltip: 'Download PDF',
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => Future.value(pdfBytes),
        canChangeOrientation: false,
        canChangePageFormat: false,
        pdfFileName: filename,
        loadingWidget: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: const Color(0xFFEF6C00),
              ),
              SizedBox(height: Responsive.spacing(16)),
              Text(
                'Memuat PDF...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: Responsive.fontSize(13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadPdf(BuildContext context) async {
    try {
      // Get storage permission is handled by Printing plugin
      final bool? result = await Printing.layoutPdf(
        onLayout: (format) => Future.value(pdfBytes),
        name: filename,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result == true ? 'PDF berhasil didownload' : 'Download dibatalkan',
            ),
            backgroundColor: result == true ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal download: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
