import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/app_user.dart';
import '../../../logic/cubits/auth/auth_cubit.dart';
import '../../widgets/app_card.dart';
import '../../widgets/user_avatar.dart';

/// Shared by students and staff.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final user = state.user;
          if (user == null) return const SizedBox.shrink();
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.screenPadding,
              16,
              AppDimens.screenPadding,
              32,
            ),
            children: [
              Center(child: UserAvatar(initial: user.initial, size: 96)),
              const SizedBox(height: 16),
              Text(
                user.name,
                style: AppTextStyles.title,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                style: AppTextStyles.bodySecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Center(child: _RoleBadge(role: user.role)),
              const SizedBox(height: 28),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Name',
                      value: user.name,
                    ),
                    const Divider(height: 1, indent: 56),
                    _InfoRow(
                      icon: Icons.mail_outline_rounded,
                      label: 'Email',
                      value: user.email,
                    ),
                    const Divider(height: 1, indent: 56),
                    _InfoRow(
                      icon: Icons.school_outlined,
                      label: 'Department',
                      value: user.department.isEmpty ? '—' : user.department,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              OutlinedButton.icon(
                onPressed: () => context.read<AuthCubit>().signOut(),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Log Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.errorLight),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final isStaff = role == UserRole.staff;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isStaff ? AppColors.resolvedLight : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isStaff ? Icons.badge_outlined : Icons.school_outlined,
            size: 16,
            color: isStaff ? AppColors.resolved : AppColors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            role.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isStaff ? AppColors.resolved : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style: AppTextStyles.caption),
      subtitle: Text(value, style: AppTextStyles.label),
    );
  }
}
