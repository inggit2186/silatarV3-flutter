import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/providers/kegiatan_provider.dart';
import '../../../core/models/kegiatan_model.dart';

/// Modal form untuk input/edit kegiatan
class KegiatanFormModal extends StatefulWidget {
  final String? selectedDate;
  final String? selectedMonth;
  final List<KegiatanItem>? existingItems;
  final KegiatanProvider? kegiatanProvider;
  final VoidCallback onSaved;

  const KegiatanFormModal({
    super.key,
    this.selectedDate,
    this.selectedMonth,
    this.existingItems,
    this.kegiatanProvider,
    required this.onSaved,
  });

  @override
  State<KegiatanFormModal> createState() => _KegiatanFormModalState();
}

class _KegiatanFormModalState extends State<KegiatanFormModal> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  late List<_ActivityRow> _activityRows;
  bool _isSaving = false;

  // Satuan options
  final List<String> _satuanOptions = [
    'Kegiatan',
    'Dokumen',
    'Modul',
    'Jam',
    'Berkas',
    'Orang',
    'Paket',
    'Unit',
    'Lembar',
    'Buah',
    'Laporan',
    'Data',
  ];

  @override
  void initState() {
    super.initState();

    // Initialize date
    if (widget.selectedDate != null) {
      _selectedDate = DateTime.parse(widget.selectedDate!);
    } else if (widget.selectedMonth != null) {
      _selectedDate = DateFormat('yyyy-MM').parse(widget.selectedMonth!);
    } else {
      _selectedDate = DateTime.now();
    }

    // Initialize activity rows
    if (widget.existingItems != null && widget.existingItems!.isNotEmpty) {
      _activityRows = widget.existingItems!
          .map((item) => _ActivityRow(
                kegiatanController: TextEditingController(text: item.kegiatan),
                volumeController: TextEditingController(
                  text: item.volume > 0 ? item.volume.toString() : '',
                ),
                selectedSatuan: item.satuan,
              ))
          .toList();
    } else {
      _activityRows = [_ActivityRow()];
    }
  }

  @override
  void dispose() {
    for (final row in _activityRows) {
      row.dispose();
    }
    super.dispose();
  }

  void _addRow() {
    setState(() {
      _activityRows.add(_ActivityRow());
    });
  }

  void _removeRow(int index) {
    if (_activityRows.length > 1) {
      setState(() {
        _activityRows[index].dispose();
        _activityRows.removeAt(index);
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _save() async {
    print('=== SAVE STARTED ===');

    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');
      return;
    }
    print('Form validation passed');

    setState(() {
      _isSaving = true;
    });

    try {
      final items = _activityRows
          .where((row) => row.kegiatanController.text.isNotEmpty)
          .map((row) => KegiatanItem(
                kegiatan: row.kegiatanController.text,
                volume: int.tryParse(row.volumeController.text) ?? 0,
                satuan: row.selectedSatuan,
              ))
          .toList();

      print('Items count: ${items.length}');

      if (items.isEmpty) {
        _showError('Tambahkan minimal satu kegiatan');
        return;
      }

      final provider = widget.kegiatanProvider ?? context.read<KegiatanProvider>();
      final tanggal = DateFormat('yyyy-MM-dd').format(_selectedDate);
      print('Tanggal: $tanggal');
      print('Provider: $provider');

      bool success;
      if (widget.existingItems != null) {
        print('Calling updateKegiatan...');
        success = await provider.updateKegiatan(
          tanggal: tanggal,
          items: items,
        );
      } else {
        print('Calling saveKegiatan...');
        success = await provider.saveKegiatan(
          tanggal: tanggal,
          items: items,
        );
      }

      print('Save result: $success');
      print('Provider error: ${provider.error}');

      if (mounted) {
        if (success) {
          print('Save SUCCESS - closing modal');
          widget.onSaved();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.existingItems != null
                    ? 'Kegiatan berhasil diupdate'
                    : 'Kegiatan berhasil disimpan',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          print('Save FAILED: ${provider.error}');
          _showError(provider.error ?? 'Gagal menyimpan kegiatan');
        }
      }
    } catch (e) {
      print('Save ERROR: $e');
      _showError('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Responsive.radius(20)),
          ),
        ),
        child: Column(
          children: [
            _buildHandle(),
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: EdgeInsets.all(Responsive.spacing(16)),
                child: _buildFormContent(),
              ),
            ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: EdgeInsets.only(top: Responsive.spacing(12)),
      width: Responsive.spacing(40),
      height: Responsive.spacing(4),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(Responsive.radius(2)),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(Responsive.spacing(16)),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          SizedBox(width: Responsive.spacing(8)),
          Expanded(
            child: Text(
              widget.existingItems != null
                  ? 'Edit Kegiatan'
                  : 'Tambah Kegiatan',
              style: TextStyle(
                fontSize: Responsive.fontSize(18),
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDatePicker(),
          SizedBox(height: Responsive.spacing(16)),
          _buildActivityListHeader(),
          SizedBox(height: Responsive.spacing(12)),
          ..._buildActivityRows(),
          _buildAddRowButton(),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tanggal *',
          style: TextStyle(
            fontSize: Responsive.fontSize(14),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: Responsive.spacing(8)),
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            padding: EdgeInsets.all(Responsive.spacing(14)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(Responsive.radius(12)),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: const Color(0xFFEF6C00),
                  size: Responsive.iconSize(20),
                ),
                SizedBox(width: Responsive.spacing(12)),
                Text(
                  DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_selectedDate),
                  style: TextStyle(
                    fontSize: Responsive.fontSize(14),
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityListHeader() {
    return Row(
      children: [
        Icon(
          Icons.list_rounded,
          color: const Color(0xFFEF6C00),
          size: Responsive.iconSize(20),
        ),
        SizedBox(width: Responsive.spacing(8)),
        Text(
          'Daftar Kegiatan',
          style: TextStyle(
            fontSize: Responsive.fontSize(14),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActivityRows() {
    return _activityRows.asMap().entries.map((entry) {
      final index = entry.key;
      final row = entry.value;

      return Container(
        margin: EdgeInsets.only(bottom: Responsive.spacing(12)),
        padding: EdgeInsets.all(Responsive.spacing(12)),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(Responsive.radius(12)),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            _buildKegiatanField(row, index),
            SizedBox(height: Responsive.spacing(12)),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildVolumeField(row),
                ),
                SizedBox(width: Responsive.spacing(12)),
                Expanded(
                  flex: 3,
                  child: _buildSatuanDropdown(row),
                ),
              ],
            ),
            if (_activityRows.length > 1)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: Icon(
                    Icons.delete_rounded,
                    color: Colors.red,
                    size: Responsive.iconSize(20),
                  ),
                  onPressed: () => _removeRow(index),
                ),
              ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildKegiatanField(_ActivityRow row, int index) {
    return TextFormField(
      controller: row.kegiatanController,
      decoration: InputDecoration(
        labelText: 'Kegiatan *',
        hintText: 'Masukkan nama kegiatan',
        labelStyle: TextStyle(
          fontSize: Responsive.fontSize(12),
          color: Colors.grey[600],
        ),
        hintStyle: TextStyle(
          fontSize: Responsive.fontSize(12),
          color: Colors.grey[400],
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Responsive.radius(10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Responsive.radius(10)),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Responsive.radius(10)),
          borderSide: const BorderSide(color: Color(0xFFEF6C00)),
        ),
      ),
      style: TextStyle(fontSize: Responsive.fontSize(13)),
      validator: (value) {
        if (index == 0 && (value == null || value.isEmpty)) {
          return 'Wajib diisi';
        }
        return null;
      },
    );
  }

  Widget _buildVolumeField(_ActivityRow row) {
    return TextFormField(
      controller: row.volumeController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Volume',
        hintText: '0',
        labelStyle: TextStyle(
          fontSize: Responsive.fontSize(12),
          color: Colors.grey[600],
        ),
        hintStyle: TextStyle(
          fontSize: Responsive.fontSize(12),
          color: Colors.grey[400],
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Responsive.radius(10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Responsive.radius(10)),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Responsive.radius(10)),
          borderSide: const BorderSide(color: Color(0xFFEF6C00)),
        ),
      ),
      style: TextStyle(fontSize: Responsive.fontSize(13)),
    );
  }

  Widget _buildSatuanDropdown(_ActivityRow row) {
    return DropdownButtonFormField<String>(
      initialValue: row.selectedSatuan,
      decoration: InputDecoration(
        labelText: 'Satuan',
        labelStyle: TextStyle(
          fontSize: Responsive.fontSize(12),
          color: Colors.grey[600],
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Responsive.radius(10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Responsive.radius(10)),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Responsive.radius(10)),
          borderSide: const BorderSide(color: Color(0xFFEF6C00)),
        ),
      ),
      style: TextStyle(
        fontSize: Responsive.fontSize(13),
        color: Colors.black87,
      ),
      items: _satuanOptions.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            row.selectedSatuan = newValue;
          });
        }
      },
    );
  }

  Widget _buildAddRowButton() {
    return OutlinedButton.icon(
      onPressed: _addRow,
      icon: Icon(
        Icons.add_rounded,
        color: const Color(0xFFEF6C00),
        size: Responsive.iconSize(20),
      ),
      label: Text(
        'Tambah Kegiatan Lainnya',
        style: TextStyle(
          color: const Color(0xFFEF6C00),
          fontSize: Responsive.fontSize(13),
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.all(Responsive.spacing(12)),
        side: const BorderSide(color: Color(0xFFEF6C00)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Responsive.radius(12)),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.only(
        left: Responsive.spacing(16),
        right: Responsive.spacing(16),
        top: Responsive.spacing(16),
        bottom: Responsive.spacing(16) + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isSaving ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: Responsive.spacing(14)),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Responsive.radius(12)),
                ),
              ),
              child: Text(
                'Batal',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: Responsive.fontSize(14),
                ),
              ),
            ),
          ),
          SizedBox(width: Responsive.spacing(12)),
          Expanded(
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF6C00),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: Responsive.spacing(14)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Responsive.radius(12)),
                ),
              ),
              child: _isSaving
                  ? SizedBox(
                      height: Responsive.spacing(20),
                      width: Responsive.spacing(20),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Simpan',
                      style: TextStyle(
                        fontSize: Responsive.fontSize(14),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper class for activity row state
class _ActivityRow {
  final TextEditingController kegiatanController;
  final TextEditingController volumeController;
  String selectedSatuan;

  _ActivityRow({
    TextEditingController? kegiatanController,
    TextEditingController? volumeController,
    this.selectedSatuan = 'Kegiatan',
  })  : kegiatanController = kegiatanController ?? TextEditingController(),
        volumeController = volumeController ?? TextEditingController();

  void dispose() {
    kegiatanController.dispose();
    volumeController.dispose();
  }
}
