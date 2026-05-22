import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import 'app_motion.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _indexFromLocation(location);

    return Scaffold(
      body: MotionSwitcher(
        child: KeyedSubtree(
          key: ValueKey(location),
          child: child,
        ),
      ),
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: AppColors.surf(context),
          border: Border(top: BorderSide(color: AppColors.div(context))),
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: index,
            onTap: (i) => _onTap(context, i),
            selectedFontSize: 11,
            unselectedFontSize: 11,
            items: [
              BottomNavigationBarItem(
                icon: _NavIcon(icon: Icons.home_outlined, active: index == 0),
                activeIcon:
                    const _NavIcon(icon: Icons.home_rounded, active: true),
                label: 'Beranda',
              ),
              BottomNavigationBarItem(
                icon: _NavIcon(
                  icon: Icons.local_shipping_outlined,
                  active: index == 1,
                ),
                activeIcon: const _NavIcon(
                  icon: Icons.local_shipping_rounded,
                  active: true,
                ),
                label: 'EcoPick',
              ),
              BottomNavigationBarItem(
                icon: _NavIcon(
                  icon: Icons.location_on_outlined,
                  active: index == 2,
                ),
                activeIcon: const _NavIcon(
                  icon: Icons.location_on_rounded,
                  active: true,
                ),
                label: 'EcoDrop',
              ),
              BottomNavigationBarItem(
                icon:
                    _NavIcon(icon: Icons.savings_outlined, active: index == 3),
                activeIcon:
                    const _NavIcon(icon: Icons.savings_rounded, active: true),
                label: 'GreenCoin',
              ),
              BottomNavigationBarItem(
                icon: _NavIcon(
                  icon: Icons.storefront_outlined,
                  active: index == 4,
                ),
                activeIcon: const _NavIcon(
                    icon: Icons.storefront_rounded, active: true),
                label: 'Market',
              ),
              BottomNavigationBarItem(
                icon: _NavIcon(
                  icon: Icons.person_outline_rounded,
                  active: index == 5,
                ),
                activeIcon:
                    const _NavIcon(icon: Icons.person_rounded, active: true),
                label: 'Akun',
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _indexFromLocation(String location) {
    if (location.startsWith('/ecopick')) return 1;
    if (location.startsWith('/ecodrop')) return 2;
    if (location.startsWith('/greencoin')) return 3;
    if (location.startsWith('/marketplace')) return 4;
    if (location.startsWith('/profile')) return 5;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/ecopick');
        break;
      case 2:
        context.go('/ecodrop');
        break;
      case 3:
        context.go('/greencoin');
        break;
      case 4:
        context.go('/marketplace');
        break;
      case 5:
        context.go('/profile');
        break;
    }
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool active;

  const _NavIcon({
    required this.icon,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: active ? 1.12 : 1,
      duration: AppMotion.fast,
      curve: AppMotion.fastCurve,
      child: AnimatedContainer(
        duration: AppMotion.medium,
        curve: AppMotion.curve,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon),
      ),
    );
  }
}
