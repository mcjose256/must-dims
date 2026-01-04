// lib/features/student/presentation/pages/student_overview_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dims/features/student/controllers/student_controllers.dart';
import 'package:dims/features/student/presentation/student_dashboard.dart';
import 'package:dims/features/logbook/data/models/logbook_entry_model.dart';
import 'package:dims/features/student/data/models/student_profile_model.dart';

class StudentOverviewPage extends ConsumerWidget {
  const StudentOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(studentProfileProvider);
    final placementAsync = ref.watch(currentPlacementProvider);
    final theme = Theme.of(context);
    
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(studentProfileProvider);
          ref.invalidate(currentPlacementProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome header
              Text(
                'Welcome Back!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              profileAsync.when(
                data: (profile) => Text(
                  profile?.registrationNumber ?? 'Student',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                loading: () => const Text('Loading...'),
                error: (_, __) => const Text(''),
              ),
              const SizedBox(height: 24),
              
              // Status card
              _buildStatusCard(context, ref, profileAsync, placementAsync),
              
              const SizedBox(height: 16),
              
              // Quick actions
              Text(
                'Quick Actions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildQuickActions(context, ref),
              
              const SizedBox(height: 24),
              
              // Recent activity
              Text(
                'Recent Activity',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildRecentActivity(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    WidgetRef ref,
    AsyncValue profileAsync,
    AsyncValue placementAsync,
  ) {
    final theme = Theme.of(context);
    final approvedCount = ref.watch(approvedLogbookCountProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: theme.colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Internship Progress',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      profileAsync.when(
                        data: (profile) {
                          // Fixed: Use toString().split('.').last instead of .name
                          final statusText = profile?.internshipStatus
                              .toString()
                              .split('.')
                              .last
                              .replaceAllMapped(
                                RegExp(r'([A-Z])'),
                                (match) => ' ${match.group(0)}',
                              )
                              .trim()
                              .toUpperCase() ?? 'NOT STARTED';
                          
                          return Text(
                            statusText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _getStatusColor(profile?.internshipStatus),
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                        loading: () => const SizedBox(),
                        error: (_, __) => const SizedBox(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            profileAsync.when(
              data: (profile) {
                final progress = profile?.progressPercentage ?? 0.0;
                return Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress / 100,
                        minHeight: 8,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$approvedCount days completed',
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          '${progress.toStringAsFixed(0)}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Error loading progress'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _QuickActionCard(
          icon: Icons.add_circle_outline,
          title: 'New Entry',
          subtitle: 'Add logbook',
          color: Colors.blue,
          onTap: () {
            ref.read(selectedStudentTabProvider.notifier).state = 1;
          },
        ),
        _QuickActionCard(
          icon: Icons.business,
          title: 'Internship',
          subtitle: 'View details',
          color: Colors.green,
          onTap: () {
            ref.read(selectedStudentTabProvider.notifier).state = 2;
          },
        ),
        _QuickActionCard(
          icon: Icons.book,
          title: 'Logbook',
          subtitle: 'View all',
          color: Colors.orange,
          onTap: () {
            ref.read(selectedStudentTabProvider.notifier).state = 1;
          },
        ),
        _QuickActionCard(
          icon: Icons.person,
          title: 'Profile',
          subtitle: 'Edit info',
          color: Colors.purple,
          onTap: () {
            ref.read(selectedStudentTabProvider.notifier).state = 3;
          },
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(logbookEntriesProvider);
    
    return entriesAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  const Text('No logbook entries yet'),
                  const SizedBox(height: 8),
                  const Text(
                    'Start by adding your first entry',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }
        
        final recentEntries = entries.take(3).toList();
        return Column(
          children: recentEntries.map((entryData) {
            final entry = entryData['entry'] as LogbookEntryModel;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  _getStatusIcon(entry.status),
                  color: _getLogbookStatusColor(entry.status),
                ),
                title: Text(
                  'Day ${entry.dayNumber}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${entry.date.day}/${entry.date.month}/${entry.date.year} • ${entry.status ?? "pending"}',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Navigate to logbook page
                  ref.read(selectedStudentTabProvider.notifier).state = 1;
                },
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Text('Error loading activity'),
    );
  }

  Color _getStatusColor(StudentInternshipStatus? status) {
    if (status == null) return Colors.grey;
    switch (status) {
      case StudentInternshipStatus.inProgress:
        return Colors.blue;
      case StudentInternshipStatus.completed:
        return Colors.green;
      case StudentInternshipStatus.awaitingApproval:
        return Colors.orange;
      case StudentInternshipStatus.deferred:
        return Colors.amber;
      case StudentInternshipStatus.terminated:
        return Colors.red;
      case StudentInternshipStatus.notStarted:
      default:
        return Colors.grey;
    }
  }

  Color _getLogbookStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.schedule;
    }
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12), // Reduced from 16 to fix overflow
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Added to prevent overflow
            children: [
              Icon(icon, size: 32, color: color), // Reduced from 36
              const SizedBox(height: 6), // Reduced from 8
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13, // Reduced from 14
                ),
                textAlign: TextAlign.center,
                maxLines: 1, // Prevent text wrapping
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2), // Reduced from 4
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11, // Reduced from 12
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 1, // Prevent text wrapping
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}