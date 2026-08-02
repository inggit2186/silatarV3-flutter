/// Request Status Model
class RequestStatus {
  final String code;
  final String label;
  final int color; // hex color value

  const RequestStatus({
    required this.code,
    required this.label,
    required this.color,
  });

  /// Available statuses from database
  static const List<RequestStatus> all = [
    RequestStatus(code: 'DRAFT', label: 'Draft', color: 0xFF9CA3AF),
    RequestStatus(code: 'UNCHECK', label: 'Belum Dicek', color: 0xFF6B7280),
    RequestStatus(code: 'PENDING', label: 'Menunggu', color: 0xFFF59E0B),
    RequestStatus(code: 'DITERIMA', label: 'Diterima', color: 0xFF3B82F6),
    RequestStatus(code: 'DIPROSES', label: 'Diproses', color: 0xFF8B5CF6),
    RequestStatus(code: 'SUKSES', label: 'Sukses', color: 0xFF10B981),
    RequestStatus(code: 'DITOLAK', label: 'Ditolak', color: 0xFFEF4444),
    RequestStatus(code: 'BATAL', label: 'Batal', color: 0xFF6B7280),
  ];

  /// Get status by code
  static RequestStatus? fromCode(String code) {
    try {
      return all.firstWhere((s) => s.code == code);
    } catch (_) {
      return null;
    }
  }

  /// Get color based on status
  static int getColor(String code) {
    return fromCode(code)?.color ?? 0xFF9CA3AF;
  }

  /// Get label based on status
  static String getLabel(String code) {
    return fromCode(code)?.label ?? code;
  }
}
