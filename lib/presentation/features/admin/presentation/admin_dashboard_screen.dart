import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../../../core/constants/app_colors.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _AdminActionCard(
            title: 'Create Market',
            subtitle: 'Launch a new prediction market',
            icon: Icons.add_business_rounded,
            color: Colors.blueAccent,
            onTap: () => context.push('/admin/create-market'),
          ),
          const Gap(16),
          _AdminActionCard(
            title: 'Resolve Markets',
            subtitle: 'Pick winners and payout users',
            icon: Icons.gavel_rounded,
            color: Colors.orangeAccent,
            onTap: () => context.push('/admin/resolve-markets'),
          ),
          const Gap(16),
          _AdminActionCard(
            title: 'User Management',
            subtitle: 'View users, banning is manual via Supabase',
            icon: Icons.people_outline,
            color: Colors.purpleAccent,
            onTap: () => context.push('/admin/users'),
          ),
        ],
      ),
    );
  }
}

class _AdminActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AdminActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const Gap(24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack);
  }
}
