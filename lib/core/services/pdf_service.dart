import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/kegiatan_model.dart';

/// PDF Service - Generate Laporan Kegiatan Harian PDF
class PdfService {
  static PdfService? _instance;
  static PdfService get instance => _instance ??= PdfService._();
  PdfService._();

  /// Generate PDF bytes for laporan kegiatan
  Future<Uint8List> generateKegiatanPdf({
    required String userName,
    required String userNip,
    required String unitName,
    required String month,
    required List<KegiatanHarian> dailyGroups,
    required KegiatanRekap rekap,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          _buildHeader(userName, userNip, unitName, month),
          pw.SizedBox(height: 15),
          _buildTable(dailyGroups),
          pw.SizedBox(height: 15),
          _buildSummary(rekap),
          pw.SizedBox(height: 30),
          _buildSignatureArea(),
        ],
      ),
    );

    return pdf.save();
  }

  /// Build header section
  pw.Widget _buildHeader(
    String userName,
    String userNip,
    String unitName,
    String month,
  ) {
    final formattedMonth = _formatMonth(month);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Title
        pw.Center(
          child: pw.Column(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue600,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Text(
                  'LAPORAN KEGIATAN HARIAN',
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'LAPORAN KEGIATAN HARIAN',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.Text(
                'Kementerian Agama Kabupaten Tanah Datar',
                style: pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Divider(color: PdfColors.blue600, thickness: 2),
        pw.SizedBox(height: 10),

        // Identity Section
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            children: [
              _buildIdentityRow('Nama', userName),
              _buildIdentityRow('NIP', userNip),
              _buildIdentityRow('Unit Kerja', unitName),
              _buildIdentityRow('Bulan', formattedMonth),
            ],
          ),
        ),
      ],
    );
  }

  /// Build identity row
  pw.Widget _buildIdentityRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 8,
                color: PdfColors.grey600,
              ),
            ),
          ),
          pw.Text(': ', style: pw.TextStyle(fontSize: 8)),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build table
  pw.Widget _buildTable(List<KegiatanHarian> dailyGroups) {
    int no = 1;
    final tableData = <List<String>>[];

    for (final group in dailyGroups) {
      for (int i = 0; i < group.items.length; i++) {
        final item = group.items[i];
        tableData.add([
          i == 0 ? no.toString() : '',
          i == 0 ? _formatDate(group.date) : '',
          item.kegiatan,
          item.volume.toString(),
          item.satuan,
        ]);
        no++;
      }
    }

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue600),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.TableHelper.fromTextArray(
        headerStyle: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        headerDecoration: const pw.BoxDecoration(
          color: PdfColors.blue600,
        ),
        headerAlignment: pw.Alignment.center,
        cellStyle: const pw.TextStyle(fontSize: 8),
        cellAlignment: pw.Alignment.centerLeft,
        cellHeight: 28,
        cellAlignments: {
          0: pw.Alignment.center,
          1: pw.Alignment.centerLeft,
          2: pw.Alignment.centerLeft,
          3: pw.Alignment.center,
          4: pw.Alignment.center,
        },
        headerAlignments: {
          0: pw.Alignment.center,
          1: pw.Alignment.centerLeft,
          2: pw.Alignment.centerLeft,
          3: pw.Alignment.center,
          4: pw.Alignment.center,
        },
        headers: ['No', 'Tanggal', 'Kegiatan', 'Volume', 'Satuan'],
        data: tableData,
      ),
    );
  }

  /// Build summary
  pw.Widget _buildSummary(KegiatanRekap rekap) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.blue200),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Total Kegiatan', '${rekap.totalEntries}'),
          _buildSummaryItem('Hari Terisi', '${rekap.totalDays} Hari'),
          _buildSummaryItem('Total Volume', '${rekap.totalVolume}'),
        ],
      ),
    );
  }

  /// Build summary item
  pw.Widget _buildSummaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 8,
            color: PdfColors.grey600,
          ),
        ),
      ],
    );
  }

  /// Build signature area
  pw.Widget _buildSignatureArea() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _buildSignatureColumn('Disiapkan oleh:', '[Nama Pegawai]'),
        _buildSignatureColumn('Mengetahui:', '[Nama Supervisor]'),
      ],
    );
  }

  /// Build signature column
  pw.Widget _buildSignatureColumn(String label, String name) {
    return pw.Container(
      width: 180,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey600,
            ),
          ),
          pw.SizedBox(height: 40),
          pw.Container(
            width: 120,
            height: 1,
            color: PdfColors.black,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '($name)',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            'Tgl: ___/___/_____',
            style: pw.TextStyle(
              fontSize: 7,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  /// Format month string
  String _formatMonth(String month) {
    try {
      final date = DateFormat('yyyy-MM').parse(month);
      return DateFormat('MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return month;
    }
  }

  /// Format date to Indonesian format
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final dayNames = [
        '', 'Senin', 'Selasa', 'Rabu', 'Kamis',
        'Jumat', 'Sabtu', 'Minggu'
      ];
      final monthNames = [
        '', 'Januari', 'Februari', 'Maret', 'April',
        'Mei', 'Juni', 'Juli', 'Agustus', 'September',
        'Oktober', 'November', 'Desember'
      ];
      return '${dayNames[date.weekday]}, ${date.day} ${monthNames[date.month]} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
