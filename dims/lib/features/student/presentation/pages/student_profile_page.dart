// lib/features/student/presentation/pages/student_profile_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dims/features/student/controllers/student_controllers.dart';
import 'package:dims/features/auth/controllers/auth_controller.dart';

class StudentProfilePage extends ConsumerWidget {
  const StudentProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(studentProfileProvider);
    final authState = ref.watch(authStateProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Navigate to edit profile
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(studentProfileProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Profile header
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: authState.when(
                          data: (user) => Text(
                            (user?.email ?? 'S')[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          loading: () => const CircularProgressIndicator(),
                          error: (_, __) => const Icon(Icons.person, size: 40),
                        ),
                      ),
                      const SizedBox(height: 16),
                      authState.when(
                        data: (user) => Column(
                          children: [
                            Text(
                              user?.displayName ?? 'Student',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? '',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        loading: () => const CircularProgressIndicator(),
                        error: (_, __) => const Text('Error loading user'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Academic information
              profileAsync.when(
                data: (profile) {
                  if (profile == null) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.warning_outlined,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            const Text('Profile not set up'),
                            const SizedBox(height: 8),
                            const Text(
                              'Complete your profile to get started',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () {
                                // TODO: Navigate to profile setup
                              },
                              child: const Text('Set Up Profile'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      // Academic info card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Academic Information',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _ProfileInfoRow(
                                icon: Icons.badge,
                                label: 'Registration Number',
                                value: profile.registrationNumber,
                              ),
                              const Divider(height: 24),
                              _ProfileInfoRow(
                                icon: Icons.school,
                                label: 'Program',
                                value: profile.program,
                              ),
                              const Divider(height: 24),
                              _ProfileInfoRow(
                                icon: Icons.calendar_today,
                                label: 'Academic Year',
                                value: profile.academicYear.toString(),
                              ),
                              const Divider(height: 24),
                              _ProfileInfoRow(
                                icon: Icons.grade,
                                label: 'Current Level',
                                value: profile.currentLevel,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Internship status card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Internship Status',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _getStatusIcon(profile.internshipStatus),
                                      color: theme.colorScheme.onPrimaryContainer,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      profile.internshipStatus.name
                                          .toUpperCase()
                                          .replaceAll('_', ' '),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text('Error: $error'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.invalidate(studentProfileProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Logout button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authControllerProvider).signOut();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon(dynamic status) {
    final statusStr = status.toString().split('.').last;
    switch (statusStr) {
      case 'inProgress':
        return Icons.play_circle;
      case 'completed':
        return Icons.check_circle;
      case 'notStarted':
        return Icons.pending;
      default:
        return Icons.info;
    }
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}