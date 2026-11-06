import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';

/// The student's bottom navigation: Home, My Reports, a center "+" button
/// that opens the report form, Campus Reports and Profile.
class StudentShell extends StatelessWidget {
  const StudentShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _goToBranch(int index) {
    navigationShell.goBranch(
      index,
      // Tapping the active tab returns it to its first page.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        tooltip: 'Report an issue',
        onPressed: () => context.push(AppRoutes.reportIncident),
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          height: 68,
          padding: EdgeInsets.zero,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                label: 'Home',
                selected: navigationShell.currentIndex == 0,
                onTap: () => _goToBranch(0),
              ),
              _NavItem(
                icon: Icons.description_outlined,
                selectedIcon: Icons.description_rounded,
                label: 'Reports',
                selected: navigationShell.currentIndex == 1,
                onTap: () => _goToBranch(1),
              ),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 36),
                  child: Text(
                    'Report',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              _NavItem(
                icon: Icons.groups_outlined,
                selectedIcon: Icons.groups_rounded,
                label: 'Campus',
                selected: navigationShell.currentIndex == 2,
                onTap: () => _goToBranch(2),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                selectedIcon: Icons.person_rounded,
                label: 'Profile',
                selected: navigationShell.currentIndex == 3,
                onTap: () => _goToBranch(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    return Expanded(
      child: InkResponse(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? selectedIcon : icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
