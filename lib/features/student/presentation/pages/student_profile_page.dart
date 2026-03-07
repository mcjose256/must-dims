// lib/features/student/presentation/pages/student_profile_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dims/features/student/controllers/student_controllers.dart';
import 'package:dims/features/auth/controllers/auth_controller.dart';
import 'package:dims/features/student/data/models/student_profile_model.dart';
import 'edit_profile_page.dart';

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
          profileAsync.when(
            data: (profile) => IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Profile',
              onPressed: profile == null
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProfilePage(profile: profile),
                        ),
                      ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(studentProfileProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ── Profile header ───────────────────────────────────
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      profileAsync.when(
                        data: (profile) => Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 48,
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              child: Text(
                                _getInitial(profile,
                                    authState.value?.email),
                                style: TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme
                                      .onPrimaryContainer,
                                ),
                              ),
                            ),
                            if (profile != null)
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        EditProfilePage(profile: profile),
                                  ),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.edit,
                                      size: 14, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                        loading: () => CircleAvatar(
                          radius: 48,
                          backgroundColor:
                              theme.colorScheme.primaryContainer,
                          child: const CircularProgressIndicator(),
                        ),
                        error: (_, __) => CircleAvatar(
                          radius: 48,
                          backgroundColor:
                              theme.colorScheme.primaryContainer,
                          child: const Icon(Icons.person, size: 40),
                        ),
                      ),
                      const SizedBox(height: 16),
                      profileAsync.when(
                        data: (profile) => Column(
                          children: [
                            Text(
                              profile?.fullName.isNotEmpty == true
                                  ? profile!.fullName
                                  : authState.value?.displayName ??
                                      'Student',
                              style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              authState.value?.email ?? '',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme
                                      .onSurfaceVariant),
                            ),
                            if (profile?.registrationNumber.isNotEmpty ==
                                true) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      theme.colorScheme.primaryContainer,
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: Text(
                                  profile!.registrationNumber,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme
                                        .onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        loading: () =>
                            const CircularProgressIndicator(),
                        error: (_, __) =>
                            const Text('Error loading profile'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Academic & internship info ───────────────────────
              profileAsync.when(
                data: (profile) {
                  if (profile == null) {
                    return _buildNoProfileCard(context, theme);
                  }
                  return Column(
                    children: [
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side:
                              BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                        Icons.school_outlined,
                                        size: 16,
                                        color:
                                            theme.colorScheme.primary),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Academic Information',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                            fontWeight:
                                                FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  TextButton.icon(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EditProfilePage(
                                            profile: profile),
                                      ),
                                    ),
                                    icon: const Icon(Icons.edit,
                                        size: 14),
                                    label: const Text('Edit',
                                        style:
                                            TextStyle(fontSize: 12)),
                                    style: TextButton.styleFrom(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _ProfileInfoRow(
                                icon: Icons.badge_outlined,
                                label: 'Registration Number',
                                value: profile.registrationNumber,
                              ),
                              const Divider(height: 24),
                              _ProfileInfoRow(
                                icon: Icons.school_outlined,
                                label: 'Program',
                                value: profile.program,
                              ),
                              const Divider(height: 24),
                              _ProfileInfoRow(
                                icon: Icons.calendar_today_outlined,
                                label: 'Academic Year',
                                value: 'Year ${profile.academicYear}',
                              ),
                              const Divider(height: 24),
                              _ProfileInfoRow(
                                icon: Icons.layers_outlined,
                                label: 'Current Level',
                                value:
                                    profile.currentLevel.isNotEmpty
                                        ? profile.currentLevel
                                        : '—',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Internship status card
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                              color: _getStatusIconColor(
                                      profile.internshipStatus)
                                  .withOpacity(0.3)),
                        ),
                        color: _getStatusColor(
                            profile.internshipStatus, theme),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _getStatusIconColor(
                                          profile.internshipStatus)
                                      .withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getStatusIcon(
                                      profile.internshipStatus),
                                  color: _getStatusIconColor(
                                      profile.internshipStatus),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text('Internship Status',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color:
                                              Colors.grey.shade600)),
                                  Text(
                                    _getStatusLabel(
                                        profile.internshipStatus),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: _getStatusIconColor(
                                          profile.internshipStatus),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) =>
                    _buildErrorCard(context, ref, error),
              ),

              const SizedBox(height: 24),

              // ── Logout ───────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async =>
                      ref.read(authControllerProvider).signOut(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
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

  String _getInitial(StudentProfileModel? profile, String? email) {
    if (profile?.fullName.isNotEmpty == true) {
      return profile!.fullName[0].toUpperCase();
    }
    if (email?.isNotEmpty == true) return email![0].toUpperCase();
    return 'S';
  }

  Widget _buildNoProfileCard(BuildContext context, ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.orange.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.warning_amber_rounded,
                size: 48, color: Colors.orange.shade400),
            const SizedBox(height: 16),
            const Text('Profile not set up',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Please complete your profile details.',
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(
      BuildContext context, WidgetRef ref, Object error) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error', textAlign: TextAlign.center),
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
      case StudentInternshipStatus.notStarted:
        return Icons.pending_outlined;
      case StudentInternshipStatus.awaitingApproval:
        return Icons.hourglass_top_rounded;
      case StudentInternshipStatus.approved:
        return Icons.check_circle_outline_rounded;
      case StudentInternshipStatus.rejected:
        return Icons.cancel_outlined;
      case StudentInternshipStatus.inProgress:
        return Icons.play_circle_outline_rounded;
      case StudentInternshipStatus.completed:
        return Icons.task_alt_rounded;
      case StudentInternshipStatus.deferred:
        return Icons.pause_circle_outline_rounded;
      case StudentInternshipStatus.terminated:
        return Icons.block_rounded;
    }
  }

  String _getStatusLabel(StudentInternshipStatus status) {
    switch (status) {
      case StudentInternshipStatus.notStarted:
        return 'NOT STARTED';
      case StudentInternshipStatus.awaitingApproval:
        return 'AWAITING SUPERVISOR REVIEW';
      case StudentInternshipStatus.approved:
        return 'APPROVED — READY TO BEGIN';
      case StudentInternshipStatus.rejected:
        return 'REVISION REQUIRED';
      case StudentInternshipStatus.inProgress:
        return 'IN PROGRESS';
      case StudentInternshipStatus.completed:
        return 'COMPLETED';
      case StudentInternshipStatus.deferred:
        return 'DEFERRED';
      case StudentInternshipStatus.terminated:
        return 'TERMINATED';
    }
  }

  Color _getStatusColor(
      StudentInternshipStatus status, ThemeData theme) {
    switch (status) {
      case StudentInternshipStatus.notStarted:
        return theme.colorScheme.surfaceContainerHighest;
      case StudentInternshipStatus.awaitingApproval:
        return Colors.orange.shade50;
      case StudentInternshipStatus.approved:
        return Colors.green.shade50;
      case StudentInternshipStatus.rejected:
        return Colors.red.shade50;
      case StudentInternshipStatus.inProgress:
        return Colors.blue.shade50;
      case StudentInternshipStatus.completed:
        return Colors.green.shade50;
      case StudentInternshipStatus.deferred:
        return Colors.purple.shade50;
      case StudentInternshipStatus.terminated:
        return Colors.red.shade50;
    }
  }

  Color _getStatusIconColor(StudentInternshipStatus status) {
    switch (status) {
      case StudentInternshipStatus.notStarted:
        return Colors.grey.shade600;
      case StudentInternshipStatus.awaitingApproval:
        return Colors.orange.shade700;
      case StudentInternshipStatus.approved:
        return Colors.green.shade700;
      case StudentInternshipStatus.rejected:
        return Colors.red.shade700;
      case StudentInternshipStatus.inProgress:
        return Colors.blue.shade700;
      case StudentInternshipStatus.completed:
        return Colors.green.shade700;
      case StudentInternshipStatus.deferred:
        return Colors.purple.shade700;
      case StudentInternshipStatus.terminated:
        return Colors.red.shade700;
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
              Text(label,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 15)),
            ],
          ),
        ),
      ],
    );
  }
}