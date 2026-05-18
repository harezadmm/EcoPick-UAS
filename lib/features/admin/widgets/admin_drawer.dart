import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/eco_logo.dart';
import '../../../shared/widgets/app_motion.dart';
import '../models/admin_section.dart';

class AdminDrawer extends StatelessWidget {
  final AdminSection selectedSection;
  final ValueChanged<AdminSection> onSectionSelected;
  final VoidCallback onLogout;

  const AdminDrawer({
    super.key,
    required this.selectedSection,
    required this.onSectionSelected,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.72,
      backgroundColor: AppColors.primary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.lg,
            AppSizes.xl,
            AppSizes.lg,
            AppSizes.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const MotionFadeSlide(
                delayMs: 40,
                child: Row(
                  children: [
                    EcoLogo(size: 40, dark: true),
                    SizedBox(width: AppSizes.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EcoPoin',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Admin',
                            style: TextStyle(
                              color: Color(0xB3FFFFFF),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 92),
              _DrawerItem(
                icon: Icons.dashboard_rounded,
                label: 'Overview',
                active: selectedSection == AdminSection.overview,
                delayMs: 80,
                onTap: () => _select(context, AdminSection.overview),
              ),
              _DrawerItem(
                icon: Icons.group_outlined,
                label: 'Users Management',
                active: selectedSection == AdminSection.users,
                delayMs: 115,
                onTap: () => _select(context, AdminSection.users),
              ),
              _DrawerItem(
                icon: Icons.local_shipping_outlined,
                label: 'EcoPick Management',
                active: selectedSection == AdminSection.ecopick,
                delayMs: 150,
                onTap: () => _select(context, AdminSection.ecopick),
              ),
              _DrawerItem(
                icon: Icons.recycling_rounded,
                label: 'EcoDrop Management',
                active: selectedSection == AdminSection.ecodrop,
                delayMs: 185,
                onTap: () => _select(context, AdminSection.ecodrop),
              ),
              _DrawerItem(
                icon: Icons.receipt_long_outlined,
                label: 'Transactions & GreenCoin',
                active: selectedSection == AdminSection.transactions,
                delayMs: 220,
                onTap: () => _select(context, AdminSection.transactions),
              ),
              _DrawerItem(
                icon: Icons.storefront_outlined,
                label: 'Marketplace',
                active: selectedSection == AdminSection.marketplace,
                delayMs: 255,
                onTap: () => _select(context, AdminSection.marketplace),
              ),
              _DrawerItem(
                icon: Icons.view_list_rounded,
                label: 'Master Data',
                active: false,
                delayMs: 290,
                onTap: () {
                  Navigator.of(context).pop();
                  context.go('/admin/master-data');
                },
              ),
              const Spacer(),
              _DrawerItem(
                icon: Icons.settings_outlined,
                label: 'Settings',
                active: selectedSection == AdminSection.settings,
                delayMs: 325,
                onTap: () => _select(context, AdminSection.settings),
              ),
              _DrawerItem(
                icon: Icons.logout_rounded,
                label: 'Log Out',
                active: false,
                delayMs: 360,
                onTap: () {
                  Navigator.of(context).pop();
                  onLogout();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _select(BuildContext context, AdminSection section) {
    Navigator.of(context).pop();
    onSectionSelected(section);
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final int delayMs;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.delayMs = 0,
  });

  @override
  Widget build(BuildContext context) {
    return MotionFadeSlide(
      delayMs: delayMs,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSizes.md),
        child: MotionPressable(
          child: AnimatedContainer(
            duration: AppMotion.medium,
            curve: AppMotion.curve,
            decoration: BoxDecoration(
              color: active
                  ? Colors.white.withValues(alpha: 0.22)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.lg,
                    vertical: AppSizes.md,
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: Colors.white, size: 23),
                      const SizedBox(width: AppSizes.lg),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
