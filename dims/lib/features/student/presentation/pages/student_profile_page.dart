import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dims/features/student/controllers/student_controllers.dart';
import 'package:dims/features/auth/controllers/auth_controller.dart';
import 'package:dims/features/student/data/models/student_profile_model.dart'; // Ensure this is imported

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
              // TODO: Navigate to edit profile page
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(studentProfileProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Profile Header Section
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
                              user?.displayName ?? 'Student User',
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
                        error: (_, __) => const Text('Error loading user info'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Academic & Internship Information
              profileAsync.when(
                data: (profile) {
                  if (profile == null) {
                    return _buildNoProfileCard(context);
                  }

                  return Column(
                    children: [
                      // Academic Info Card
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

                      // Internship Status Card
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
                error: (error, stack) => _buildErrorCard(context, ref, error),
              ),

              const SizedBox(height: 24),

              // Logout Button
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
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoProfileCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.warning_outlined, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            const Text('Profile not set up'),
            const SizedBox(height: 8),
            const Text('Please complete your profile details.', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, WidgetRef ref, Object error) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
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
    );
  }

  IconData _getStatusIcon(StudentInternshipStatus status) {
    switch (status) {
      case StudentInternshipStatus.inProgress:
        return Icons.play_circle;
      case StudentInternshipStatus.completed:
        return Icons.check_circle;
      case StudentInternshipStatus.notStarted:
        return Icons.pending;
      case StudentInternshipStatus.awaitingApproval:
        return Icons.hourglass_empty;
      case StudentInternshipStatus.deferred:
        return Icons.pause_circle;
      case StudentInternshipStatus.terminated:
        return Icons.cancel;
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
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
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