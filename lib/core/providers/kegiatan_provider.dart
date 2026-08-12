import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/kegiatan_model.dart';
import '../services/kegiatan_service.dart';

/// Kegiatan Provider - Manages state for laporan kegiatan
class KegiatanProvider extends ChangeNotifier {
  final KegiatanService _kegiatanService = KegiatanService.instance;

  List<KegiatanHarian> _dailyGroups = [];
  KegiatanRekap? _rekap;
  String _selectedMonth = '';
  bool _isLoading = false;
  String? _error;

  // Getters
  List<KegiatanHarian> get dailyGroups => _dailyGroups;
  KegiatanRekap? get rekap => _rekap;
  String get selectedMonth => _selectedMonth;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load kegiatan bulanan
  Future<void> loadKegiatan(String month) async {
    _isLoading = true;
    _error = null;
    _selectedMonth = month;
    notifyListeners();

    try {
      final response = await _kegiatanService.getKegiatanBulanan(month: month);

      if (response.success && response.data != null) {
        final dailyGroupsData = response.data!['dailyGroups'] as List? ?? [];
        _dailyGroups = dailyGroupsData
            .map((group) => KegiatanHarian.fromJson(group))
            .toList();

        // Sort by date
        _dailyGroups.sort((a, b) => a.date.compareTo(b.date));

        // Calculate rekap from daily groups
        _rekap = _calculateRekap();
      } else {
        _error = response.message;
        _dailyGroups = [];
        _rekap = null;
      }
    } catch (e) {
      _error = e.toString();
      _dailyGroups = [];
      _rekap = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Simpan kegiatan baru
  Future<bool> saveKegiatan({
    required String tanggal,
    required List<KegiatanItem> items,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('[Provider] Calling storeKegiatan...');
      print('[Provider] Tanggal: $tanggal');
      print('[Provider] Items: ${items.length}');

      final response = await _kegiatanService.storeKegiatan(
        tanggal: tanggal,
        items: items,
      );

      print('[Provider] Response success: ${response.success}');
      print('[Provider] Response message: ${response.message}');
      print('[Provider] Response statusCode: ${response.statusCode}');

      if (response.success) {
        // Reload data after successful save
        await loadKegiatan(_selectedMonth);
        return true;
      } else {
        _error = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('[Provider] Save error: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update kegiatan
  Future<bool> updateKegiatan({
    required String tanggal,
    required List<KegiatanItem> items,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _kegiatanService.updateKegiatanByDate(
        tanggal: tanggal,
        items: items,
      );

      if (response.success) {
        // Reload data after successful update
        await loadKegiatan(_selectedMonth);
        return true;
      } else {
        _error = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Hapus kegiatan
  Future<bool> deleteKegiatan(String tanggal) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('[Provider] Calling deleteKegiatan...');
      print('[Provider] Tanggal: $tanggal');

      final response = await _kegiatanService.deleteKegiatanByDate(
        tanggal: tanggal,
      );

      print('[Provider] Delete response success: ${response.success}');
      print('[Provider] Delete response message: ${response.message}');
      print('[Provider] Delete response statusCode: ${response.statusCode}');

      if (response.success) {
        // Reload data after successful delete
        await loadKegiatan(_selectedMonth);
        return true;
      } else {
        _error = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('[Provider] Delete error: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Calculate rekap from daily groups
  KegiatanRekap _calculateRekap() {
    int totalEntries = 0;
    int totalVolume = 0;

    for (final group in _dailyGroups) {
      totalEntries += group.items.length;
      totalVolume += group.items.fold(0, (sum, item) => sum + item.volume);
    }

    return KegiatanRekap(
      totalEntries: totalEntries,
      totalDays: _dailyGroups.length,
      totalVolume: totalVolume,
    );
  }

  /// Get filtered kegiatan based on search query
  List<KegiatanHarian> getFilteredKegiatan(String searchQuery) {
    if (searchQuery.isEmpty) return _dailyGroups;

    return _dailyGroups.where((group) {
      return group.items.any((item) =>
          item.kegiatan.toLowerCase().contains(searchQuery.toLowerCase()));
    }).toList();
  }

  /// Get kegiatan for specific date
  KegiatanHarian? getKegiatanByDate(String date) {
    try {
      return _dailyGroups.firstWhere((group) => group.date == date);
    } catch (e) {
      return null;
    }
  }

  /// Format selected month for display
  String get formattedMonth {
    if (_selectedMonth.isEmpty) return '';
    try {
      final date = DateFormat('yyyy-MM').parse(_selectedMonth);
      return DateFormat('MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return _selectedMonth;
    }
  }
}
