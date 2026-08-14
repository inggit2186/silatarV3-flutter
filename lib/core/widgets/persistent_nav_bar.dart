import 'package:flutter/material.dart';
import '../theme/neo_mirai_theme.dart';
import '../utils/responsive.dart';

class PersistentNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool showAdminTab;

  const PersistentNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.showAdminTab = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSmall = context.isSmallPhone;

    // Calculate indices based on whether admin tab is shown
    final int homeIndex = 0;
    final int presensiIndex = 1;
    final int layananIndex = 2;
    final int adminIndex = showAdminTab ? 3 : -1;
    final int profilIndex = showAdminTab ? 4 : 3;

    return Container(
      decoration: BoxDecoration(
        color: NeoMiraiColors.rice,
        boxShadow: [
          BoxShadow(
            color: NeoMiraiColors.ink.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.spacing(isSmall ? 6 : 12),
            vertical: Responsive.spacing(isSmall ? 6 : 8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,
                icon: Icons.home_rounded,
                label: 'Home',
                isActive: currentIndex == homeIndex,
                onTap: () => onTap(homeIndex),
              ),
              _buildNavItem(
                context: context,
                icon: Icons.fingerprint_rounded,
                label: 'Presensi',
                isActive: currentIndex == presensiIndex,
                onTap: () => onTap(presensiIndex),
              ),
              _buildNavItem(
                context: context,
                icon: Icons.grid_view_rounded,
                label: 'Layanan',
                isActive: currentIndex == layananIndex,
                onTap: () => onTap(layananIndex),
              ),
              if (showAdminTab)
                _buildNavItem(
                  context: context,
                  icon: Icons.admin_panel_settings_rounded,
                  label: 'Admin',
                  isActive: currentIndex == adminIndex,
                  onTap: () => onTap(adminIndex),
                ),
              _buildNavItem(
                context: context,
                icon: Icons.person_outline_rounded,
                label: 'Profil',
                isActive: currentIndex == profilIndex,
                onTap: () => onTap(profilIndex),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final bool isSmall = context.isSmallPhone;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.spacing(isSmall ? 6 : 10),
            vertical: Responsive.spacing(isSmall ? 6 : 8),
          ),
          decoration: isActive
              ? BoxDecoration(
                  gradient: NeoMiraiTheme.goldGradient,
                  borderRadius: BorderRadius.circular(Responsive.radius(isSmall ? 10 : 14)),
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: Responsive.iconSize(isSmall ? 20 : 22),
                color: isActive ? NeoMiraiColors.rice : NeoMiraiColors.inkSoft,
              ),
              SizedBox(height: Responsive.spacing(2)),
              Text(
                label,
                style: TextStyle(
                  fontSize: Responsive.fontSize(isSmall ? 8 : 10),
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isActive ? NeoMiraiColors.rice : NeoMiraiColors.inkSoft,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
