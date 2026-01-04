// lib/features/admin/presentation/pages/overview_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dims/features/admin/controllers/admin_stats_controller.dart';

class OverviewPage extends ConsumerWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final theme = Theme.of(context);
    
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminStatsProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Dashboard Overview',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Monitor system statistics and activity',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              
              // Stats cards
              statsAsync.when(
                data: (stats) => _buildStatsGrid(context, stats),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, size: 48),
                      const SizedBox(height: 16),
                      Text('Error loading stats: $error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(adminStatsProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, AdminStats stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // More responsive breakpoints
        final crossAxisCount = constraints.maxWidth > 1000 
            ? 3 
            : constraints.maxWidth > 600 
                ? 2 
                : 1;
        
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            _StatCard(
              title: 'Total Students',
              value: stats.totalStudents.toString(),
              icon: Icons.school,
              color: Colors.blue,
            ),
            _StatCard(
              title: 'Total Supervisors',
              value: stats.totalSupervisors.toString(),
              icon: Icons.supervised_user_circle,
              color: Colors.green,
            ),
            _StatCard(
              title: 'Pending Approvals',
              value: stats.pendingApprovals.toString(),
              icon: Icons.pending_actions,
              color: Colors.orange,
              isAlert: stats.pendingApprovals > 0,
            ),
            _StatCard(
              title: 'Active Internships',
              value: stats.activeInternships.toString(),
              icon: Icons.work,
              color: Colors.purple,
            ),
            _StatCard(
              title: 'Companies',
              value: stats.totalCompanies.toString(),
              icon: Icons.business,
              color: Colors.teal,
            ),
            _StatCard(
              title: 'Completion Rate',
              value: '${stats.completionRate.toStringAsFixed(1)}%',
              icon: Icons.check_circle,
              color: Colors.indigo,
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isAlert;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 0,
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isAlert ? Colors.orange : color.withOpacity(0.3),
          width: isAlert ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 32),
                if (isAlert)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Action Required',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}