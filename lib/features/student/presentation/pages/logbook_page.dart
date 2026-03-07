// lib/features/student/presentation/pages/logbook_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/student_controllers.dart';
import '../../data/models/student_profile_model.dart';
import '../../../logbook/presentation/pages/daily_entries_list_page.dart';
import '../../../logbook/presentation/pages/weekly_summaries_list_page.dart';
import '../../../logbook/presentation/pages/daily_entry_form_page.dart';
import '../../../logbook/presentation/pages/weekly_summary_form_page.dart';
import '../../../logbook/controllers/logbook_controller.dart' as logbook_ctrl;

class LogbookPage extends ConsumerStatefulWidget {
  const LogbookPage({super.key});

  @override
  ConsumerState<LogbookPage> createState() => _LogbookPageState();
}

class _LogbookPageState extends ConsumerState<LogbookPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTab = 0; // 0 = Daily, 1 = Weekly

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      // addListener fires on animation too — only update on actual index change
      if (!_tabController.indexIsChanging) {
        setState(() => _currentTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// FAB handler — routes correctly based on active tab
  Future<void> _onNewEntry(BuildContext context) async {
    if (_currentTab == 0) {
      // ── Daily entry ──────────────────────────────────────────────────
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DailyEntryFormPage()),
      );
    } else {
      // ── Weekly summary ───────────────────────────────────────────────
      // Calculate the correct next week number from existing summaries
      final summaries =
          ref.read(logbook_ctrl.weeklySummariesProvider).value ?? [];

      // summaries are ordered descending — .first is highest week number
      // If none exist yet, start at week 1
      final nextWeek =
          summaries.isNotEmpty ? summaries.first.weekNumber + 1 : 1;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WeeklySummaryFormPage(weekNumber: nextWeek),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(studentProfileProvider);

    return Scaffold(
      body: profileAsync.when(
        data: (profile) {
          final status =
              profile?.internshipStatus ?? StudentInternshipStatus.notStarted;

          // Guard: only approved/inProgress/completed students can log
          if (status == StudentInternshipStatus.notStarted ||
              status == StudentInternshipStatus.awaitingApproval ||
              status == StudentInternshipStatus.rejected) {
            return _buildNotStartedState(context, theme, status);
          }

          return Column(
            children: [
              // ── Tab bar ───────────────────────────────────────────────
              Container(
                color: theme.colorScheme.surface,
                child: TabBar(
                  controller: _tabController,
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                  indicatorColor: theme.colorScheme.primary,
                  tabs: const [
                    Tab(icon: Icon(Icons.event_note), text: 'Daily Entries'),
                    Tab(
                        icon: Icon(Icons.summarize),
                        text: 'Weekly Summaries'),
                  ],
                ),
              ),

              // ── Tab content + FAB ─────────────────────────────────────
              Expanded(
                child: Stack(
                  children: [
                    TabBarView(
                      controller: _tabController,
                      children: const [
                        DailyEntriesListPage(),
                        WeeklySummariesListPage(),
                      ],
                    ),

                    // ── Context-aware FAB ─────────────────────────────
                    Positioned(
                      bottom: 20,
                      right: 16,
                      child: FloatingActionButton.extended(
                        heroTag: 'logbook_fab',
                        onPressed: () => _onNewEntry(context),
                        icon: const Icon(Icons.add),
                        // Label changes with active tab
                        label: Text(
                          _currentTab == 0
                              ? 'New Daily Entry'
                              : 'New Weekly Summary',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Error loading logbook')),
      ),
    );
  }

  Widget _buildNotStartedState(
    BuildContext context,
    ThemeData theme,
    StudentInternshipStatus status,
  ) {
    final isPending = status == StudentInternshipStatus.awaitingApproval;
    final isRejected = status == StudentInternshipStatus.rejected;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isPending
                    ? Colors.orange.shade50
                    : isRejected
                        ? Colors.red.shade50
                        : Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPending
                    ? Icons.hourglass_top
                    : isRejected
                        ? Icons.cancel_outlined
                        : Icons.book_outlined,
                size: 56,
                color: isPending
                    ? Colors.orange.shade400
                    : isRejected
                        ? Colors.red.shade400
                        : Colors.blue.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isPending
                  ? 'Awaiting Approval'
                  : isRejected
                      ? 'Letter Needs Revision'
                      : 'Logbook Not Yet Available',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              isPending
                  ? 'Your logbook will be available once your supervisor approves your placement letter.'
                  : isRejected
                      ? 'Your supervisor has requested changes to your acceptance letter. Please resubmit.'
                      : 'Upload your acceptance letter to get started.',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            if (status == StudentInternshipStatus.notStarted)
              FilledButton.icon(
                onPressed: () => context.go('/student/upload-letter'),
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Upload Acceptance Letter'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: () => context.go('/student/placement-status'),
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('View Application Status'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}