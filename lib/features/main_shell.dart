import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/user_provider.dart';
import '../core/services/api_service.dart';
import '../core/widgets/persistent_nav_bar.dart';
import 'dashboard/dashboard_content.dart';
import 'presensi/presensi_content.dart';
import 'layanan/layanan_content.dart';
import 'profile/profile_content.dart';
import 'admin/admin_section_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load user profile if not available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<UserProvider>();
      if (!userProvider.hasUser) {
        _loadUserProfile();
      }
    });
  }

  Future<void> _loadUserProfile() async {
    final userProvider = context.read<UserProvider>();
    final response = await ApiService.instance.getProfile();
    if (response.success && response.data != null) {
      userProvider.setUser(response.data);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final showAdminTab = AdminSectionPage.hasAdminAccess(user?.role);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const DashboardContent(),
          const PresensiContent(),
          const LayananContent(),
          if (showAdminTab) const AdminSectionPage(),
          const ProfileContent(),
        ],
      ),
      bottomNavigationBar: PersistentNavBar(
        currentIndex: _currentIndex,
        showAdminTab: showAdminTab,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
