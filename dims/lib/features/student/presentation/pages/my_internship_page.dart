// lib/features/student/presentation/pages/my_internship_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dims/features/student/controllers/student_controllers.dart';
import 'package:dims/features/placements/data/models/placement_model.dart';

class MyInternshipPage extends ConsumerWidget {
  const MyInternshipPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placementAsync = ref.watch(currentPlacementProvider);
    final companyAsync = ref.watch(placementCompanyProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentPlacementProvider);
          ref.invalidate(placementCompanyProvider);
        },
        child: placementAsync.when(
          data: (placement) {
            if (placement == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.business_outlined,
                      size: 80,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Active Internship',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You haven\'t been assigned to an internship yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(placement.status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      placement.status.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Company info card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.business,
                                color: theme.colorScheme.primary,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Company',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    companyAsync.when(
                                      data: (company) => Text(
                                        company?.name ?? 'Loading...',
                                        style: theme.textTheme.bodyLarge,
                                      ),
                                      loading: () => const Text('Loading...'),
                                      error: (_, __) => const Text('Error loading company'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (placement.companySupervisorName != null) ...[
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),
                            Text(
                              'Company Supervisor',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _InfoRow(
                              icon: Icons.person,
                              label: placement.companySupervisorName!,
                            ),
                            if (placement.companySupervisorEmail != null)
                              _InfoRow(
                                icon: Icons.email,
                                label: placement.companySupervisorEmail!,
                              ),
                            if (placement.companySupervisorPhone != null)
                              _InfoRow(
                                icon: Icons.phone,
                                label: placement.companySupervisorPhone!,
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Duration card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Duration',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _InfoTile(
                                  icon: Icons.calendar_today,
                                  label: 'Start Date',
                                  value: _formatDate(placement.startDate),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _InfoTile(
                                  icon: Icons.event,
                                  label: 'End Date',
                                  value: _formatDate(placement.endDate),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _InfoTile(
                            icon: Icons.school,
                            label: 'Academic Year',
                            value: placement.academicYear,
                          ),
                          if (placement.actualEndDate != null) ...[
                            const SizedBox(height: 16),
                            _InfoTile(
                              icon: Icons.check_circle,
                              label: 'Actual End Date',
                              value: _formatDate(placement.actualEndDate!),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  if (placement.remarks != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Remarks',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              placement.remarks!,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Action buttons
                  if (placement.companySupervisorEmail != null)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          // TODO: Open email client or contact supervisor
                        },
                        icon: const Icon(Icons.message),
                        label: const Text('Contact Supervisor'),
                      ),
                    ),
                  
                  if (placement.attachmentUrl != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Open attachment
                        },
                        icon: const Icon(Icons.attachment),
                        label: const Text('View Attachment'),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(currentPlacementProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getStatusColor(PlacementStatus status) {
    switch (status) {
      case PlacementStatus.active:
        return Colors.green;
      case PlacementStatus.pending:
        return Colors.orange;
      case PlacementStatus.completed:
        return Colors.blue;
      case PlacementStatus.cancelled:
        return Colors.red;
      case PlacementStatus.extended:
        return Colors.purple;
    }
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}