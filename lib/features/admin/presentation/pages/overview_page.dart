import 'package:dims/core/theme/must_theme.dart';
import 'package:dims/core/utils/report_exporter.dart';
import 'package:dims/features/admin/controllers/admin_stats_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OverviewPage extends ConsumerWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final districtStatsAsync = ref.watch(districtAllocationStatsProvider);
    final reportRowsAsync = ref.watch(studentPlacementReportProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminStatsProvider);
          ref.invalidate(districtAllocationStatsProvider);
          ref.invalidate(studentPlacementReportProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            _HeroCard(theme: theme),
            const SizedBox(height: 20),
            statsAsync.when(
              data: (stats) => _StatsSection(stats: stats),
              loading: () => const _LoadingCard(),
              error: (error, _) => _ErrorCard(
                message: 'Unable to load overview',
                onRetry: () => ref.invalidate(adminStatsProvider),
              ),
            ),
            const SizedBox(height: 20),
            districtStatsAsync.when(
              data: (stats) => _DistrictSection(stats: stats),
              loading: () => const _LoadingCard(),
              error: (error, _) => _ErrorCard(
                message: 'Unable to load district statistics',
                onRetry: () => ref.invalidate(districtAllocationStatsProvider),
              ),
            ),
            const SizedBox(height: 20),
            reportRowsAsync.when(
              data: (rows) => _ReportSection(
                rows: rows,
                onOpenReport: () => _showReportDialog(context, rows),
              ),
              loading: () => const _LoadingCard(),
              error: (error, _) => _ErrorCard(
                message: 'Unable to load student report',
                onRetry: () => ref.invalidate(studentPlacementReportProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReportDialog(
    BuildContext context,
    List<StudentPlacementReportRow> rows,
  ) async {
    final csvContent = _buildCsv(rows);
    final date = DateTime.now();
    final filename =
        'must_student_report_${date.year}_${date.month.toString().padLeft(2, '0')}_${date.day.toString().padLeft(2, '0')}.csv';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 920,
              maxHeight: MediaQuery.of(dialogContext).size.height * 0.84,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Student Report',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${rows.length} students',
                              style: Theme.of(dialogContext)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(dialogContext)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: MustBrandColors.green.withOpacity(0.10),
                        ),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            headingRowColor: WidgetStatePropertyAll(
                              MustBrandColors.surfaceTint.withOpacity(0.9),
                            ),
                            columns: const [
                              DataColumn(label: Text('Student')),
                              DataColumn(label: Text('Reg No.')),
                              DataColumn(label: Text('Program')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Supervisor')),
                              DataColumn(label: Text('Company')),
                              DataColumn(label: Text('District')),
                            ],
                            rows: rows
                                .map(
                                  (row) => DataRow(
                                    cells: [
                                      DataCell(Text(row.studentName)),
                                      DataCell(Text(row.registrationNumber)),
                                      DataCell(Text(row.program)),
                                      DataCell(Text(_formatStatus(row.internshipStatus))),
                                      DataCell(Text(row.supervisorName)),
                                      DataCell(Text(row.companyName)),
                                      DataCell(Text(row.district)),
                                    ],
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 420;

                      if (compact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FilledButton.icon(
                              onPressed: () async {
                                try {
                                  await saveCsvReport(
                                    filename: filename,
                                    csvContent: csvContent,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Report saved')),
                                    );
                                  }
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Save failed')),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.download_rounded),
                              label: const Text('Download'),
                            ),
                            const SizedBox(height: 10),
                            FilledButton.tonalIcon(
                              onPressed: () async {
                                try {
                                  await shareCsvReport(
                                    filename: filename,
                                    csvContent: csvContent,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Share ready')),
                                    );
                                  }
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Share failed')),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.share_rounded),
                              label: const Text('Share'),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: () async {
                                await Clipboard.setData(ClipboardData(text: csvContent));
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('CSV copied')),
                                  );
                                }
                              },
                              icon: const Icon(Icons.copy_rounded),
                              label: const Text('Copy'),
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(text: csvContent));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('CSV copied')),
                                );
                              }
                            },
                            icon: const Icon(Icons.copy_rounded),
                            label: const Text('Copy'),
                          ),
                          const Spacer(),
                          FilledButton.tonalIcon(
                            onPressed: () async {
                              try {
                                await shareCsvReport(
                                  filename: filename,
                                  csvContent: csvContent,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Share ready')),
                                  );
                                }
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Share failed')),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.share_rounded),
                            label: const Text('Share'),
                          ),
                          const SizedBox(width: 10),
                          FilledButton.icon(
                            onPressed: () async {
                              try {
                                await saveCsvReport(
                                  filename: filename,
                                  csvContent: csvContent,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Report saved')),
                                  );
                                }
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Save failed')),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.download_rounded),
                            label: const Text('Download'),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _buildCsv(List<StudentPlacementReportRow> rows) {
    final buffer = StringBuffer()
      ..writeln(
        [
          'Student Name',
          'Registration Number',
          'Program',
          'Status',
          'University Supervisor',
          'Company',
          'District',
        ].map(_escapeCsv).join(','),
      );

    for (final row in rows) {
      buffer.writeln(
        [
          row.studentName,
          row.registrationNumber,
          row.program,
          _formatStatus(row.internshipStatus),
          row.supervisorName,
          row.companyName,
          row.district,
        ].map(_escapeCsv).join(','),
      );
    }

    return buffer.toString();
  }

  String _escapeCsv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  String _formatStatus(String value) {
    if (value.isEmpty) return 'Not started';
    final normalized = value.replaceAll(RegExp(r'([a-z])([A-Z])'), r'$1 $2');
    return normalized
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MustBrandColors.green,
            MustBrandColors.greenLight,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: MustBrandColors.green.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Image.asset(
              'assets/icons/must logo.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Admin Overview',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Placements, supervisors, and company coverage.',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Reports and district statistics.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.88),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({required this.stats});

  final AdminStats stats;

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem(
        title: 'Students',
        value: stats.totalStudents.toString(),
        icon: Icons.school_rounded,
        color: const Color(0xFF1B5E20),
      ),
      _StatItem(
        title: 'Supervisors',
        value: stats.totalSupervisors.toString(),
        icon: Icons.groups_rounded,
        color: const Color(0xFF2E7D32),
      ),
      _StatItem(
        title: 'With placement',
        value: stats.studentsWithPlacement.toString(),
        icon: Icons.approval_rounded,
        color: const Color(0xFFB26A00),
      ),
      _StatItem(
        title: 'Pending approvals',
        value: stats.pendingApprovals.toString(),
        icon: Icons.pending_actions_rounded,
        color: const Color(0xFFD97706),
      ),
      _StatItem(
        title: 'Active placements',
        value: stats.activeInternships.toString(),
        icon: Icons.work_history_rounded,
        color: const Color(0xFF14532D),
      ),
      _StatItem(
        title: 'Companies',
        value: stats.totalCompanies.toString(),
        icon: Icons.business_rounded,
        color: const Color(0xFF5B8C5A),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = 14.0;
        final columns = constraints.maxWidth >= 1100
            ? 3
            : constraints.maxWidth >= 700
                ? 2
                : 1;
        final tileWidth = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var index = 0; index < items.length; index++)
              SizedBox(
                width: tileWidth,
                child: _AnimatedStatCard(
                  item: items[index],
                  delay: index * 80,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DistrictSection extends StatelessWidget {
  const _DistrictSection({required this.stats});

  final List<DistrictAllocationStat> stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'District Statistics',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Students by company district.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            if (stats.isEmpty)
              const _EmptyState(
                icon: Icons.location_off_rounded,
                title: 'No allocation data',
                subtitle: 'District totals will appear here.',
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: stats
                    .map(
                      (stat) => Container(
                        constraints: const BoxConstraints(minWidth: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: MustBrandColors.surfaceTint,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: MustBrandColors.green.withOpacity(0.10),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stat.district,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: MustBrandColors.green,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${stat.studentCount}',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              stat.studentCount == 1 ? 'student' : 'students',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReportSection extends StatelessWidget {
  const _ReportSection({
    required this.rows,
    required this.onOpenReport,
  });

  final List<StudentPlacementReportRow> rows;
  final VoidCallback onOpenReport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final previewRows = rows.take(6).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Student Report',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Students, supervisors, and companies.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: rows.isEmpty ? null : onOpenReport,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('View Report'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (rows.isEmpty)
              const _EmptyState(
                icon: Icons.table_rows_outlined,
                title: 'No student records',
                subtitle: 'Reports will appear here.',
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStatePropertyAll(
                    MustBrandColors.goldSoft.withOpacity(0.85),
                  ),
                  columns: const [
                    DataColumn(label: Text('Student')),
                    DataColumn(label: Text('Supervisor')),
                    DataColumn(label: Text('Company')),
                    DataColumn(label: Text('District')),
                  ],
                  rows: previewRows
                      .map(
                        (row) => DataRow(
                          cells: [
                            DataCell(Text(row.studentName)),
                            DataCell(Text(row.supervisorName)),
                            DataCell(Text(row.companyName)),
                            DataCell(Text(row.district)),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedStatCard extends StatelessWidget {
  const _AnimatedStatCard({
    required this.item,
    required this.delay,
  });

  final _StatItem item;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 550 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 18),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Card(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 180),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: item.color.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(item.icon, color: item.color),
                    ),
                    const Spacer(),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: item.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: item.color,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem {
  const _StatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 42,
              color: Color(0xFFB3261E),
            ),
            const SizedBox(height: 12),
            Text(message),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: MustBrandColors.surfaceTint.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: MustBrandColors.greenLight),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
