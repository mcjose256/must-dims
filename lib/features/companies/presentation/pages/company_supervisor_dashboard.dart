import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dims/core/widgets/brand_app_bar_title.dart';

import '../../../logbook/data/models/logbook_entry_model.dart';
import 'logbook_review_page.dart';
import '../../controllers/company_supervisor_controller.dart';

// ============================================================================
// PROVIDER: Pending Weekly Logbooks for Company Supervisor
// ============================================================================

final pendingCompanyWeeklyReviewsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final authState = FirebaseAuth.instance.currentUser;
  final userId = authState?.uid;

  if (userId == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('logbookEntries')
      .where('isReviewedByCompanySupervisor', isEqualTo: false)
      .snapshots()
      .asyncMap((snapshot) async {
        // Get placements where this company supervisor is assigned
        final placementsSnapshot = await FirebaseFirestore.instance
            .collection('placements')
            .where('companySupervisorId', isEqualTo: userId)
            .get();

        final placementsById = {
          for (final doc in placementsSnapshot.docs) doc.id: doc.data(),
        };

        final pendingEntries = snapshot.docs
            .map((doc) => LogbookEntryModel.fromFirestore(doc, null))
            .where((entry) {
              final status = entry.status.toLowerCase();
              return placementsById.containsKey(entry.placementId) &&
                  status != 'draft' &&
                  status != 'rejected';
            })
            .toList()
          ..sort((a, b) => b.weekNumber.compareTo(a.weekNumber));

        final studentCache = <String, Map<String, dynamic>?>{};
        for (final entry in pendingEntries) {
          if (studentCache.containsKey(entry.studentId)) continue;
          final studentDoc = await FirebaseFirestore.instance
              .collection('students')
              .doc(entry.studentId)
              .get();
          studentCache[entry.studentId] = studentDoc.data();
        }

        return pendingEntries
            .map<Map<String, dynamic>>((entry) => {
                  'entry': entry,
                  'student': studentCache[entry.studentId],
                  'placement': placementsById[entry.placementId],
                })
            .toList();
      })
      .handleError((e) {
        print('[PendingCompanyReviews] Error: $e');
        return <Map<String, dynamic>>[];
      });
});

final pendingCompanyReviewsCountProvider = Provider<int>((ref) {
  final entries = ref.watch(pendingCompanyWeeklyReviewsProvider).value ?? [];
  return entries.length;
});

// ============================================================================
// DASHBOARD WIDGET
// ============================================================================

class CompanySupervisorDashboard extends ConsumerWidget {
  const CompanySupervisorDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }

    final supervisorAsync = ref.watch(companySupervisorProvider(user.uid));
    final studentsAsync = ref.watch(companySupervisorStudentsProvider);
    final pendingWeeklyLogbooksAsync = ref.watch(pendingCompanyWeeklyReviewsProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: const BrandAppBarTitle(
          title: 'Company Supervisor',
          subtitle: 'MUST Internship Placement Portal',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: supervisorAsync.when(
        data: (supervisor) {
          if (supervisor == null) {
            return const Center(child: Text('Supervisor profile not found'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(companySupervisorProvider(user.uid));
              ref.invalidate(companySupervisorStudentsProvider);
              ref.invalidate(pendingCompanyWeeklyReviewsProvider);
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back, ${supervisor.fullName}!',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${supervisor.position ?? 'Supervisor'} at ${supervisor.companyName}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: studentsAsync.when(
                          data: (students) => _StatCard(
                            title: 'My Interns',
                            value: students.length.toString(),
                            icon: Icons.people,
                            color: Colors.blue,
                          ),
                          loading: () => const _StatCard(
                            title: 'My Interns',
                            value: '...',
                            icon: Icons.people,
                            color: Colors.blue,
                          ),
                          error: (_, __) => const _StatCard(
                            title: 'My Interns',
                            value: '0',
                            icon: Icons.people,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Consumer(
                          builder: (context, ref, child) {
                            final weeklyCount =
                                ref.watch(pendingCompanyReviewsCountProvider);
                            return _StatCard(
                              title: 'Pending Reviews',
                              value: weeklyCount.toString(),
                              icon: Icons.pending_actions,
                              color: Colors.orange,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Pending Weekly Logbooks Section
                  Row(
                    children: [
                      Icon(Icons.menu_book, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        'Pending Weekly Logbooks',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  pendingWeeklyLogbooksAsync.when(
                    data: (entries) {
                      if (entries.isEmpty) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.done_all,
                                    size: 48,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No pending weekly logbooks',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'All submitted weekly logbooks have been reviewed',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: entries.map((entryData) {
                          final entry = entryData['entry'] as LogbookEntryModel;
                          final student =
                              entryData['student'] as Map<String, dynamic>?;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.orange,
                                child: Text(
                                  '${entry.weekNumber}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                student?['fullName'] ?? 'Week ${entry.weekNumber}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Week ${entry.weekNumber} • ${entry.hoursWorked.toStringAsFixed(entry.hoursWorked.truncateToDouble() == entry.hoursWorked ? 0 : 1)} hours',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => LogbookReviewPage(
                                      logbookId: entry.id!,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, stack) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Error loading reviews: $error',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // My Interns Section
                  Row(
                    children: [
                      Icon(Icons.people, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        'My Interns',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  studentsAsync.when(
                    data: (students) {
                      if (students.isEmpty) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(48),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No interns assigned yet',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Interns will appear here once assigned',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final studentData = students[index];
                          final student = studentData['student'] as Map<String, dynamic>;
                          final placement = studentData['placement'] as Map<String, dynamic>;
                          final studentId = studentData['studentId'] as String;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                child: Text(
                                  student['fullName']?[0]?.toUpperCase() ?? 'S',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              title: Text(
                                student['fullName'] ?? 'Unknown',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                '${student['program'] ?? 'Unknown Program'}\n'
                                'Week ${placement['weeksCompleted'] ?? 0}/${placement['totalWeeks'] ?? 12}',
                              ),
                              isThreeLine: true,
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () {
                                // Navigate to student details
                                context.go('/company-supervisor/student/$studentId');
                              },
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, stack) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Error loading students: $error',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(companySupervisorProvider(user.uid));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// STAT CARD WIDGET
// ============================================================================

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
