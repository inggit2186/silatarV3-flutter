import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/theme/neo_mirai_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/services/api_service.dart';
import '../../core/models/janji_temu_model.dart';

class BuatJanjiTemuPage extends StatefulWidget {
  const BuatJanjiTemuPage({super.key});

  @override
  State<BuatJanjiTemuPage> createState() => _BuatJanjiTemuPageState();
}

class _BuatJanjiTemuPageState extends State<BuatJanjiTemuPage> {
  final _formKey = GlobalKey<FormState>();
  final _keteranganController = TextEditingController();

  List<JanjiTemuDepartment> _departments = [];
  List<Employee> _employees = [];
  JanjiTemuDepartment? _selectedDepartment;
  Employee? _selectedEmployee;
  String _selectedTipe = 'asn'; // 'asn' atau 'satker'
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  bool _isLoadingDepartments = true;
  bool _isLoadingEmployees = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  @override
  void dispose() {
    _keteranganController.dispose();
    super.dispose();
  }

  Future<void> _loadDepartments() async {
    setState(() {
      _isLoadingDepartments = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.instance.getDepartments();
      if (response.success && response.data != null) {
        setState(() {
          _departments = response.data!;
          _isLoadingDepartments = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Gagal memuat daftar unit kerja';
          _isLoadingDepartments = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: $e';
        _isLoadingDepartments = false;
      });
    }
  }

  Future<void> _loadEmployees(int deptId) async {
    setState(() {
      _isLoadingEmployees = true;
      _employees = [];
      _selectedEmployee = null;
    });

    try {
      // ignore: avoid_print
      print('Loading employees for deptId: $deptId');
      final response = await ApiService.instance.getDepartmentEmployees(deptId);
      // ignore: avoid_print
      print('Response success: ${response.success}');
      // ignore: avoid_print
      print('Response data: ${response.data}');

      if (response.success && response.data != null) {
        final Map<String, dynamic> data = response.data!;
        final dynamic employeesRaw = data['employees'];
        // ignore: avoid_print
        print('Employees raw: $employeesRaw');

        List<Employee> employees = [];
        if (employeesRaw is List) {
          for (var item in employeesRaw) {
            if (item is Map<String, dynamic>) {
              try {
                employees.add(Employee.fromJson(item));
              } catch (e) {
                // ignore: avoid_print
                print('Error parsing employee: $e');
              }
            }
          }
        }
        // ignore: avoid_print
        print('Parsed employees count: ${employees.length}');

        setState(() {
          _employees = employees;
          _isLoadingEmployees = false;
        });
      } else {
        // ignore: avoid_print
        print('Failed to load employees: ${response.message}');
        setState(() {
          _employees = [];
          _isLoadingEmployees = false;
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error loading employees: $e');
      setState(() {
        _employees = [];
        _isLoadingEmployees = false;
      });
    }
  }

  void _onDepartmentChanged(JanjiTemuDepartment? department) {
    setState(() {
      _selectedDepartment = department;
      _selectedEmployee = null;
      _employees = [];
    });

    if (department != null) {
      _loadEmployees(department.id);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: NeoMiraiColors.gold,
              onPrimary: Colors.white,
              surface: NeoMiraiColors.rice,
              onSurface: NeoMiraiColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: NeoMiraiColors.gold,
              onPrimary: Colors.white,
              surface: NeoMiraiColors.rice,
              onSurface: NeoMiraiColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submitJanjiTemu() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pilih unit kerja tujuan'),
          backgroundColor: NeoMiraiColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(12))),
        ),
      );
      return;
    }

    if (_selectedTipe == 'asn' && _selectedEmployee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pilih pegawai tujuan'),
          backgroundColor: NeoMiraiColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(12))),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final tanggal = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final jam = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

      final response = await ApiService.instance.submitJanjiTemu(
        deptId: _selectedDepartment!.id,
        nipTujuan: _selectedTipe == 'asn' ? _selectedEmployee?.nomorInduk : _selectedDepartment!.id.toString(),
        tipe: _selectedTipe,
        tanggal: tanggal,
        jam: jam,
        keterangan: _keteranganController.text,
      );

      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Janji temu berhasil dibuat'),
              backgroundColor: NeoMiraiColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(12))),
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Gagal membuat janji temu'),
              backgroundColor: NeoMiraiColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(12))),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: NeoMiraiColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(12))),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: NeoMiraiTheme.paperGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoadingDepartments
                    ? _buildLoadingState()
                    : _errorMessage != null
                        ? _buildErrorState()
                        : _buildForm(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.cardPadding(16),
        vertical: Responsive.spacing(12),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(Responsive.radius(10)),
              decoration: BoxDecoration(
                color: NeoMiraiColors.rice,
                borderRadius: BorderRadius.circular(Responsive.radius(12)),
                border: Border.all(color: NeoMiraiColors.line.withValues(alpha: 0.3)),
              ),
              child: Icon(Icons.arrow_back_rounded, size: Responsive.iconSize(20), color: NeoMiraiColors.ink),
            ),
          ),
          SizedBox(width: Responsive.spacing(14)),
          Container(
            padding: EdgeInsets.all(Responsive.radius(12)),
            decoration: BoxDecoration(
              gradient: NeoMiraiTheme.goldGradient,
              borderRadius: BorderRadius.circular(Responsive.radius(14)),
              boxShadow: [BoxShadow(color: NeoMiraiColors.gold.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Icon(Icons.add_circle_rounded, size: Responsive.iconSize(26), color: Colors.white),
          ),
          SizedBox(width: Responsive.spacing(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Buat Janji Temu', style: TextStyle(fontSize: Responsive.fontSize(18), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink)),
                SizedBox(height: Responsive.spacing(2)),
                Text('Isi form untuk mengajukan janji temu', style: TextStyle(fontSize: Responsive.fontSize(11), color: NeoMiraiColors.inkSoft)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(Responsive.spacing(16)),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTargetSection(),
            SizedBox(height: Responsive.spacing(20)),
            _buildDateTimeSection(),
            SizedBox(height: Responsive.spacing(20)),
            _buildKeteranganSection(),
            SizedBox(height: Responsive.spacing(24)),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetSection() {
    return _buildCard(
      title: 'Tujuan Pertemuan',
      icon: Icons.person_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tipe selection
          Text('Tipe Janji Temu', style: TextStyle(fontSize: Responsive.fontSize(12), fontWeight: FontWeight.w600, color: NeoMiraiColors.ink)),
          SizedBox(height: Responsive.spacing(8)),
          Row(
            children: [
              Expanded(
                child: _buildTipeOption('asn', 'Ke Pegawai', Icons.person_rounded),
              ),
              SizedBox(width: Responsive.spacing(12)),
              Expanded(
                child: _buildTipeOption('satker', 'Ke Seksi', Icons.business_rounded),
              ),
            ],
          ),

          SizedBox(height: Responsive.spacing(16)),

          // Department selection
          Text('Unit Kerja', style: TextStyle(fontSize: Responsive.fontSize(12), fontWeight: FontWeight.w600, color: NeoMiraiColors.ink)),
          SizedBox(height: Responsive.spacing(8)),
          DropdownButtonFormField<JanjiTemuDepartment>(
            initialValue: _selectedDepartment,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: Responsive.spacing(14), vertical: Responsive.spacing(12)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Responsive.radius(12)),
                borderSide: BorderSide(color: NeoMiraiColors.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Responsive.radius(12)),
                borderSide: BorderSide(color: NeoMiraiColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Responsive.radius(12)),
                borderSide: BorderSide(color: NeoMiraiColors.gold, width: 2),
              ),
              fillColor: NeoMiraiColors.rice,
              filled: true,
            ),
            hint: Text('Pilih unit kerja', style: TextStyle(color: NeoMiraiColors.ash)),
            items: _departments.map((dept) {
              return DropdownMenuItem<JanjiTemuDepartment>(
                value: dept,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 250),
                  child: Text(
                    dept.nama,
                    style: TextStyle(color: NeoMiraiColors.ink, fontSize: Responsive.fontSize(12)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }).toList(),
            onChanged: _onDepartmentChanged,
          ),

          // Employee selection (only for tipe asn)
          if (_selectedTipe == 'asn') ...[
            SizedBox(height: Responsive.spacing(16)),
            Text('Pegawai', style: TextStyle(fontSize: Responsive.fontSize(12), fontWeight: FontWeight.w600, color: NeoMiraiColors.ink)),
            SizedBox(height: Responsive.spacing(8)),
            if (_isLoadingEmployees)
              const Center(child: CircularProgressIndicator())
            else if (_selectedDepartment != null && _employees.isEmpty)
              Container(
                padding: EdgeInsets.all(Responsive.spacing(14)),
                decoration: BoxDecoration(
                  color: NeoMiraiColors.rice,
                  borderRadius: BorderRadius.circular(Responsive.radius(12)),
                  border: Border.all(color: NeoMiraiColors.line),
                ),
                child: Text('Tidak ada pegawai di unit kerja ini', style: TextStyle(color: NeoMiraiColors.ash, fontSize: Responsive.fontSize(12))),
              )
            else
              DropdownButtonFormField<Employee>(
                initialValue: _selectedEmployee,
                isExpanded: true,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: Responsive.spacing(14), vertical: Responsive.spacing(12)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Responsive.radius(12)),
                    borderSide: BorderSide(color: NeoMiraiColors.line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Responsive.radius(12)),
                    borderSide: BorderSide(color: NeoMiraiColors.line),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Responsive.radius(12)),
                    borderSide: BorderSide(color: NeoMiraiColors.gold, width: 2),
                  ),
                  fillColor: NeoMiraiColors.rice,
                  filled: true,
                ),
                hint: Text('Pilih pegawai', style: TextStyle(color: NeoMiraiColors.ash)),
                selectedItemBuilder: (context) {
                  return _employees.map((emp) {
                    return Container(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        emp.name,
                        style: TextStyle(
                          color: emp.isHead ? NeoMiraiColors.gold : NeoMiraiColors.ink,
                          fontSize: Responsive.fontSize(13),
                          fontWeight: emp.isHead ? FontWeight.w600 : FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList();
                },
                items: _employees.map((emp) {
                  return DropdownMenuItem<Employee>(
                    value: emp,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 250),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Nama Pegawai
                          Row(
                            children: [
                              if (emp.isHead) ...[
                                Icon(Icons.star_rounded, size: 14, color: NeoMiraiColors.gold),
                                SizedBox(width: 4),
                              ],
                              Expanded(
                                child: Text(
                                  emp.name,
                                  style: TextStyle(
                                    color: emp.isHead ? NeoMiraiColors.gold : NeoMiraiColors.ink,
                                    fontSize: Responsive.fontSize(13),
                                    fontWeight: emp.isHead ? FontWeight.w600 : FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          // Pergi/pekerjaan
                          if (emp.jabatan != null && emp.jabatan!.isNotEmpty) ...[
                            SizedBox(height: 2),
                            Padding(
                              padding: EdgeInsets.only(left: emp.isHead ? 18 : 0),
                              child: Text(
                                emp.jabatan!,
                                style: TextStyle(
                                  fontSize: Responsive.fontSize(10),
                                  color: emp.isHead ? NeoMiraiColors.gold.withValues(alpha: 0.8) : NeoMiraiColors.ash,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedEmployee = value;
                  });
                },
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildTipeOption(String value, String label, IconData icon) {
    final isSelected = _selectedTipe == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTipe = value;
          _selectedEmployee = null;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: Responsive.spacing(10), horizontal: Responsive.spacing(8)),
        decoration: BoxDecoration(
          color: isSelected ? NeoMiraiColors.gold.withValues(alpha: 0.1) : NeoMiraiColors.rice,
          borderRadius: BorderRadius.circular(Responsive.radius(10)),
          border: Border.all(
            color: isSelected ? NeoMiraiColors.gold : NeoMiraiColors.line,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: Responsive.iconSize(20), color: isSelected ? NeoMiraiColors.gold : NeoMiraiColors.ash),
            SizedBox(height: Responsive.spacing(4)),
            Text(
              label,
              style: TextStyle(fontSize: Responsive.fontSize(10), fontWeight: FontWeight.w600, color: isSelected ? NeoMiraiColors.gold : NeoMiraiColors.ink),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return _buildCard(
      title: 'Tanggal & Waktu',
      icon: Icons.access_time_rounded,
      child: Column(
        children: [
          // Date picker
          _buildDateTimeRow(
            icon: Icons.calendar_today_rounded,
            label: 'Tanggal',
            value: DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate),
            onTap: _selectDate,
          ),

          SizedBox(height: Responsive.spacing(12)),

          // Time picker
          _buildDateTimeRow(
            icon: Icons.access_time_rounded,
            label: 'Waktu',
            value: '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')} WIB',
            onTap: _selectTime,
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: Responsive.spacing(12), vertical: Responsive.spacing(10)),
        decoration: BoxDecoration(
          color: NeoMiraiColors.rice,
          borderRadius: BorderRadius.circular(Responsive.radius(12)),
          border: Border.all(color: NeoMiraiColors.line),
        ),
        child: Row(
          children: [
            Icon(icon, size: Responsive.iconSize(16), color: NeoMiraiColors.gold),
            SizedBox(width: Responsive.spacing(10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: Responsive.fontSize(9), color: NeoMiraiColors.ash)),
                  SizedBox(height: Responsive.spacing(2)),
                  Text(
                    value,
                    style: TextStyle(fontSize: Responsive.fontSize(12), fontWeight: FontWeight.w600, color: NeoMiraiColors.ink),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: Responsive.iconSize(16), color: NeoMiraiColors.ash),
          ],
        ),
      ),
    );
  }

  Widget _buildKeteranganSection() {
    return _buildCard(
      title: 'Keperluan / Alasan',
      icon: Icons.description_rounded,
      child: TextFormField(
        controller: _keteranganController,
        maxLines: 4,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Keterangan harus diisi';
          }
          if (value.length > 1000) {
            return 'Keterangan maksimal 1000 karakter';
          }
          return null;
        },
        decoration: InputDecoration(
          hintText: 'Jelaskan keperluan Anda...',
          hintStyle: TextStyle(color: NeoMiraiColors.ash),
          contentPadding: EdgeInsets.all(Responsive.spacing(14)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Responsive.radius(12)),
            borderSide: BorderSide(color: NeoMiraiColors.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Responsive.radius(12)),
            borderSide: BorderSide(color: NeoMiraiColors.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Responsive.radius(12)),
            borderSide: BorderSide(color: NeoMiraiColors.gold, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Responsive.radius(12)),
            borderSide: BorderSide(color: NeoMiraiColors.error),
          ),
          fillColor: NeoMiraiColors.rice,
          filled: true,
        ),
        style: TextStyle(color: NeoMiraiColors.ink),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submitJanjiTemu,
        icon: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.send_rounded, size: 20),
        label: Text(_isSubmitting ? 'Mengirim...' : 'Kirim Janji Temu'),
        style: ElevatedButton.styleFrom(
          backgroundColor: NeoMiraiColors.gold,
          foregroundColor: Colors.white,
          disabledBackgroundColor: NeoMiraiColors.ash,
          padding: EdgeInsets.symmetric(vertical: Responsive.spacing(16)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(12))),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.spacing(20)),
      decoration: BoxDecoration(
        color: NeoMiraiColors.rice,
        borderRadius: BorderRadius.circular(Responsive.radius(16)),
        border: Border.all(color: NeoMiraiColors.line.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: NeoMiraiColors.ink.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(Responsive.radius(8)),
                decoration: BoxDecoration(
                  color: NeoMiraiColors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Responsive.radius(8)),
                ),
                child: Icon(icon, size: Responsive.iconSize(18), color: NeoMiraiColors.gold),
              ),
              SizedBox(width: Responsive.spacing(12)),
              Text(title, style: TextStyle(fontSize: Responsive.fontSize(14), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink)),
            ],
          ),
          SizedBox(height: Responsive.spacing(16)),
          child,
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: NeoMiraiColors.gold),
          SizedBox(height: Responsive.spacing(16)),
          Text('Memuat data...', style: TextStyle(fontSize: Responsive.fontSize(14), color: NeoMiraiColors.inkSoft)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(Responsive.cardPadding(32)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.radius(20)),
              decoration: BoxDecoration(
                color: NeoMiraiColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded, size: Responsive.iconSize(48), color: NeoMiraiColors.error),
            ),
            SizedBox(height: Responsive.spacing(16)),
            Text('Gagal Memuat', style: TextStyle(fontSize: Responsive.fontSize(15), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink)),
            SizedBox(height: Responsive.spacing(6)),
            Text(_errorMessage ?? 'Terjadi kesalahan', textAlign: TextAlign.center, style: TextStyle(fontSize: Responsive.fontSize(12), color: NeoMiraiColors.inkSoft)),
            SizedBox(height: Responsive.spacing(24)),
            ElevatedButton.icon(
              onPressed: _loadDepartments,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Muat Ulang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: NeoMiraiColors.gold,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: Responsive.spacing(20), vertical: Responsive.spacing(12)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(12))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
