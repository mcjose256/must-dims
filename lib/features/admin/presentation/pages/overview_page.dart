import 'dart:math' as math;

import 'package:dims/core/theme/must_theme.dart';
import 'package:dims/core/utils/report_exporter.dart';
import 'package:dims/features/admin/controllers/admin_stats_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _ReportSupervisorFilter { all, assigned, unassigned }

enum _ReportVisitFilter {
  all,
  hasVisited,
  zeroCompleted,
  oneCompleted,
  twoCompleted,
  markedNotVisited,
}

String _reportSupervisorFilterLabel(_ReportSupervisorFilter filter) {
  switch (filter) {
    case _ReportSupervisorFilter.all:
      return 'All supervisors';
    case _ReportSupervisorFilter.assigned:
      return 'Has supervisor';
    case _ReportSupervisorFilter.unassigned:
      return 'No supervisor';
  }
}

String _reportVisitFilterLabel(_ReportVisitFilter filter) {
  switch (filter) {
    case _ReportVisitFilter.all:
      return 'All visit outcomes';
    case _ReportVisitFilter.hasVisited:
      return 'Has visited';
    case _ReportVisitFilter.zeroCompleted:
      return '0 of 2 completed';
    case _ReportVisitFilter.oneCompleted:
      return '1 of 2 completed';
    case _ReportVisitFilter.twoCompleted:
      return '2 of 2 completed';
    case _ReportVisitFilter.markedNotVisited:
      return 'Marked not visited';
  }
}

class OverviewPage extends ConsumerStatefulWidget {
  const OverviewPage({super.key});

  @override
  ConsumerState<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends ConsumerState<OverviewPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  _ReportSupervisorFilter _supervisorFilter = _ReportSupervisorFilter.all;
  _ReportVisitFilter _visitFilter = _ReportVisitFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(adminStatsProvider);
    final districtStatsAsync = ref.watch(districtAllocationStatsProvider);
    final reportRowsAsync = ref.watch(studentPlacementReportProvider);

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
              data: (districts) => _DistrictBreakdownSection(stats: districts),
              loading: () => const _LoadingCard(),
              error: (error, _) => _ErrorCard(
                message: 'Unable to load district statistics',
                onRetry: () => ref.invalidate(districtAllocationStatsProvider),
              ),
            ),
            const SizedBox(height: 20),
            reportRowsAsync.when(
              data: (rows) {
                final filteredRows = _filterRows(
                  rows,
                  query: _searchQuery,
                  supervisorFilter: _supervisorFilter,
                  visitFilter: _visitFilter,
                );
                return Column(
                  children: [
                    _VisitCoverageSection(rows: rows),
                    const SizedBox(height: 20),
                    _ReportSection(
                      rows: filteredRows,
                      totalRows: rows.length,
                      searchController: _searchController,
                      searchQuery: _searchQuery,
                      supervisorFilter: _supervisorFilter,
                      visitFilter: _visitFilter,
                      onSearchChanged: (value) =>
                          setState(() => _searchQuery = value.trim()),
                      onSupervisorFilterChanged: (value) =>
                          setState(() => _supervisorFilter = value),
                      onVisitFilterChanged: (value) =>
                          setState(() => _visitFilter = value),
                      onClearFilters: _clearReportFilters,
                      onOpenReport: () => _showReportDialog(
                        context,
                        rows: filteredRows,
                        totalRows: rows.length,
                      ),
                    ),
                  ],
                );
              },
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

  List<StudentPlacementReportRow> _filterRows(
    List<StudentPlacementReportRow> rows, {
    required String query,
    required _ReportSupervisorFilter supervisorFilter,
    required _ReportVisitFilter visitFilter,
  }) {
    final normalized = query.trim().toLowerCase();

    return rows.where((row) {
      final matchesQuery = normalized.isEmpty ||
          [
            row.studentName,
            row.registrationNumber,
            row.program,
            row.supervisorName,
            row.companyName,
            row.district,
            _formatStatus(row.internshipStatus),
            row.visitOneStatus,
            row.visitTwoStatus,
            row.visitCoverageLabel,
          ].join(' ').toLowerCase().contains(normalized);

      final matchesSupervisor = switch (supervisorFilter) {
        _ReportSupervisorFilter.all => true,
        _ReportSupervisorFilter.assigned => row.hasSupervisor,
        _ReportSupervisorFilter.unassigned => !row.hasSupervisor,
      };

      final matchesVisit = switch (visitFilter) {
        _ReportVisitFilter.all => true,
        _ReportVisitFilter.hasVisited => row.hasVisited,
        _ReportVisitFilter.zeroCompleted => row.isVisitTrackable &&
            !row.hasNotVisited &&
            row.visitsCompleted == 0,
        _ReportVisitFilter.oneCompleted => row.isVisitTrackable &&
            !row.hasNotVisited &&
            row.visitsCompleted == 1,
        _ReportVisitFilter.twoCompleted => row.isVisitTrackable &&
            !row.hasNotVisited &&
            row.visitsCompleted >= 2,
        _ReportVisitFilter.markedNotVisited => row.hasNotVisited,
      };

      return matchesQuery && matchesSupervisor && matchesVisit;
    }).toList();
  }

  void _clearReportFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _supervisorFilter = _ReportSupervisorFilter.all;
      _visitFilter = _ReportVisitFilter.all;
    });
  }

  Future<void> _showReportDialog(
    BuildContext context, {
    required List<StudentPlacementReportRow> rows,
    required int totalRows,
  }) async {
    final csvContent = _buildCsv(rows);
    final date = DateTime.now();
    final filenamePrefix = rows.length == totalRows
        ? 'must_student_report'
        : 'must_student_report_filtered';
    final filename =
        '${filenamePrefix}_${date.year}_${date.month.toString().padLeft(2, '0')}_${date.day.toString().padLeft(2, '0')}.csv';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 980,
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
                              rows.length == totalRows
                                  ? '$totalRows students'
                                  : '${rows.length} of $totalRows students',
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
                              DataColumn(label: Text('Visit 1')),
                              DataColumn(label: Text('Visit 2')),
                              DataColumn(label: Text('Progress')),
                            ],
                            rows: rows
                                .map(
                                  (row) => DataRow(
                                    cells: [
                                      DataCell(Text(row.studentName)),
                                      DataCell(Text(row.registrationNumber)),
                                      DataCell(Text(row.program)),
                                      DataCell(_StatusBadge(
                                        label:
                                            _formatStatus(row.internshipStatus),
                                      )),
                                      DataCell(Text(row.supervisorName)),
                                      DataCell(Text(row.companyName)),
                                      DataCell(Text(row.district)),
                                      DataCell(Text(row.visitOneStatus)),
                                      DataCell(Text(row.visitTwoStatus)),
                                      DataCell(
                                        _VisitSummaryPill(
                                          visitsCompleted: row.visitsCompleted,
                                        ),
                                      ),
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
                                      const SnackBar(
                                          content: Text('Report saved')),
                                    );
                                  }
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Save failed')),
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
                                      const SnackBar(
                                          content: Text('Share ready')),
                                    );
                                  }
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Share failed')),
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
                                await Clipboard.setData(
                                    ClipboardData(text: csvContent));
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
                              await Clipboard.setData(
                                  ClipboardData(text: csvContent));
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
                                    const SnackBar(
                                        content: Text('Share ready')),
                                  );
                                }
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Share failed')),
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
                                    const SnackBar(
                                        content: Text('Report saved')),
                                  );
                                }
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Save failed')),
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
          'Visit 1',
          'Visit 2',
          'Visits Completed',
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
          row.visitOneStatus,
          row.visitTwoStatus,
          '${row.visitsCompleted}/2',
        ].map(_escapeCsv).join(','),
      );
    }

    return buffer.toString();
  }

  String _escapeCsv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
}

String _formatStatus(String value) {
  if (value.isEmpty) return 'Not started';
  final normalized = value.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (match) => '${match.group(1)} ${match.group(2)}',
  );
  return normalized
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map(
        (part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .join(' ');
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                      'Operations, reports, and allocation insights.',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Track placements, search records, and review district coverage from one dashboard.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.88),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _HeroPill(
                icon: Icons.table_chart_rounded,
                label: 'Searchable report',
              ),
              _HeroPill(
                icon: Icons.pie_chart_rounded,
                label: 'Visual allocation view',
              ),
              _HeroPill(
                icon: Icons.bar_chart_rounded,
                label: 'District comparison',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overview',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Live system counts.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: MustBrandColors.surfaceTint.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Completion',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${stats.completionRate.toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: MustBrandColors.green,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: MustBrandColors.green.withOpacity(0.08),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 32,
                    horizontalMargin: 16,
                    headingRowHeight: 50,
                    dataRowMinHeight: 62,
                    dataRowMaxHeight: 72,
                    headingRowColor: WidgetStatePropertyAll(
                      MustBrandColors.surfaceTint.withOpacity(0.92),
                    ),
                    columns: const [
                      DataColumn(label: Text('Metric')),
                      DataColumn(numeric: true, label: Text('Count')),
                    ],
                    rows: items.map((item) {
                      return DataRow(
                        cells: [
                          DataCell(_StatsMetricCell(item: item)),
                          DataCell(
                            SizedBox(
                              width: 72,
                              child: Text(
                                item.value,
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  color: item.color,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DistrictBreakdownSection extends StatelessWidget {
  const _DistrictBreakdownSection({required this.stats});

  final List<DistrictAllocationStat> stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final districtRows = [...stats]
      ..sort((a, b) => b.studentCount.compareTo(a.studentCount));
    final hasRows = districtRows.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'District Breakdown',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Students by district.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: MustBrandColors.green.withOpacity(0.08),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 32,
                    horizontalMargin: 16,
                    headingRowHeight: 50,
                    dataRowMinHeight: 56,
                    dataRowMaxHeight: 62,
                    headingRowColor: WidgetStatePropertyAll(
                      MustBrandColors.surfaceTint.withOpacity(0.92),
                    ),
                    columns: const [
                      DataColumn(label: Text('District')),
                      DataColumn(
                        numeric: true,
                        label: Text('Allocated'),
                      ),
                    ],
                    rows: hasRows
                        ? districtRows
                            .map(
                              (row) => DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      row.district,
                                      style:
                                          theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 96,
                                      child: Text(
                                        '${row.studentCount}',
                                        textAlign: TextAlign.end,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          color: MustBrandColors.green,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .toList()
                        : [
                            DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    'No allocation data',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 96,
                                    child: Text(
                                      '-',
                                      textAlign: TextAlign.end,
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisitCoverageSection extends StatelessWidget {
  const _VisitCoverageSection({required this.rows});

  final List<StudentPlacementReportRow> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trackableRows = rows
        .where(
          (row) => row.visitOneStatus != 'N/A' || row.visitTwoStatus != 'N/A',
        )
        .toList(growable: false);

    final noVisitsLogged = trackableRows
        .where((row) => !row.hasNotVisited && row.visitsCompleted == 0)
        .length;
    final oneVisitLogged = trackableRows
        .where((row) => !row.hasNotVisited && row.visitsCompleted == 1)
        .length;
    final twoVisitsLogged = trackableRows
        .where((row) => !row.hasNotVisited && row.visitsCompleted >= 2)
        .length;
    final markedNotVisited =
        trackableRows.where((row) => row.hasNotVisited).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Supervisor Visit Coverage',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Two expected visits per internship.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            if (trackableRows.isEmpty)
              const _EmptyState(
                icon: Icons.timeline_rounded,
                title: 'No visit records',
                subtitle: 'Visit records will appear here.',
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _VisitCoverageTile(
                    label: '0 of 2 visits recorded',
                    value: noVisitsLogged,
                    color: const Color(0xFFB26A00),
                    icon: Icons.schedule_rounded,
                  ),
                  _VisitCoverageTile(
                    label: '1 of 2 visits recorded',
                    value: oneVisitLogged,
                    color: MustBrandColors.greenLight,
                    icon: Icons.looks_one_rounded,
                  ),
                  _VisitCoverageTile(
                    label: '2 of 2 visits recorded',
                    value: twoVisitsLogged,
                    color: MustBrandColors.green,
                    icon: Icons.done_all_rounded,
                  ),
                  _VisitCoverageTile(
                    label: 'Marked not visited',
                    value: markedNotVisited,
                    color: const Color(0xFFB3261E),
                    icon: Icons.report_problem_outlined,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _VisitCoverageTile extends StatelessWidget {
  const _VisitCoverageTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final int value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
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

class _ReportSection extends StatelessWidget {
  const _ReportSection({
    required this.rows,
    required this.totalRows,
    required this.searchController,
    required this.searchQuery,
    required this.supervisorFilter,
    required this.visitFilter,
    required this.onSearchChanged,
    required this.onSupervisorFilterChanged,
    required this.onVisitFilterChanged,
    required this.onClearFilters,
    required this.onOpenReport,
  });

  final List<StudentPlacementReportRow> rows;
  final int totalRows;
  final TextEditingController searchController;
  final String searchQuery;
  final _ReportSupervisorFilter supervisorFilter;
  final _ReportVisitFilter visitFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<_ReportSupervisorFilter> onSupervisorFilterChanged;
  final ValueChanged<_ReportVisitFilter> onVisitFilterChanged;
  final VoidCallback onClearFilters;
  final VoidCallback onOpenReport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final previewRows = rows.take(8).toList();
    final hasActiveFilters = searchQuery.isNotEmpty ||
        supervisorFilter != _ReportSupervisorFilter.all ||
        visitFilter != _ReportVisitFilter.all;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 700;

                if (compact) {
                  return Column(
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
                        '$totalRows records',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: totalRows == 0 ? null : onOpenReport,
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('View Report'),
                      ),
                    ],
                  );
                }

                return Row(
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
                            '$totalRows records',
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
                );
              },
            ),
            const SizedBox(height: 18),
            TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: 'Search student, reg no., supervisor, company',
                suffixIcon: searchQuery.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          searchController.clear();
                          onSearchChanged('');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 760;

                final supervisorDropdown =
                    DropdownButtonFormField<_ReportSupervisorFilter>(
                  initialValue: supervisorFilter,
                  decoration: const InputDecoration(
                    labelText: 'Supervisor filter',
                  ),
                  items: _ReportSupervisorFilter.values
                      .map(
                        (filter) => DropdownMenuItem(
                          value: filter,
                          child: Text(_reportSupervisorFilterLabel(filter)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) onSupervisorFilterChanged(value);
                  },
                );

                final visitDropdown =
                    DropdownButtonFormField<_ReportVisitFilter>(
                  initialValue: visitFilter,
                  decoration: const InputDecoration(
                    labelText: 'Visit filter',
                  ),
                  items: _ReportVisitFilter.values
                      .map(
                        (filter) => DropdownMenuItem(
                          value: filter,
                          child: Text(_reportVisitFilterLabel(filter)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) onVisitFilterChanged(value);
                  },
                );

                final clearButton = hasActiveFilters
                    ? Align(
                        alignment: compact
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: onClearFilters,
                          icon: const Icon(Icons.filter_alt_off_rounded),
                          label: const Text('Clear filters'),
                        ),
                      )
                    : const SizedBox.shrink();

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      supervisorDropdown,
                      const SizedBox(height: 12),
                      visitDropdown,
                      if (hasActiveFilters) ...[
                        const SizedBox(height: 8),
                        clearButton,
                      ],
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: supervisorDropdown),
                    const SizedBox(width: 12),
                    Expanded(child: visitDropdown),
                    if (hasActiveFilters) ...[
                      const SizedBox(width: 8),
                      clearButton,
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: MustBrandColors.green.withOpacity(0.08),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowHeight: 52,
                    dataRowMinHeight: 58,
                    dataRowMaxHeight: 58,
                    headingRowColor: WidgetStatePropertyAll(
                      MustBrandColors.goldSoft.withOpacity(0.85),
                    ),
                    columns: const [
                      DataColumn(label: Text('Student')),
                      DataColumn(label: Text('Supervisor')),
                      DataColumn(label: Text('Company')),
                      DataColumn(label: Text('Visits')),
                    ],
                    rows: totalRows == 0
                        ? [
                            const DataRow(
                              cells: [
                                DataCell(Text('No records')),
                                DataCell(Text('-')),
                                DataCell(Text('-')),
                                DataCell(Text('-')),
                              ],
                            ),
                          ]
                        : rows.isEmpty
                            ? [
                                const DataRow(
                                  cells: [
                                    DataCell(Text('No results')),
                                    DataCell(Text('-')),
                                    DataCell(Text('-')),
                                    DataCell(Text('-')),
                                  ],
                                ),
                              ]
                            : previewRows
                                .map(
                                  (row) => DataRow(
                                    cells: [
                                      DataCell(Text(row.studentName)),
                                      DataCell(Text(row.supervisorName)),
                                      DataCell(Text(row.companyName)),
                                      DataCell(
                                        _VisitSummaryPill(
                                          visitsCompleted: row.visitsCompleted,
                                          visitOneStatus: row.visitOneStatus,
                                          visitTwoStatus: row.visitTwoStatus,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                .toList(),
                  ),
                ),
              ),
            ),
            if (rows.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                rows.length == totalRows
                    ? 'Showing ${previewRows.length} of $totalRows records.'
                    : 'Showing ${previewRows.length} of ${rows.length} filtered records.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VisitSummaryPill extends StatelessWidget {
  const _VisitSummaryPill({
    required this.visitsCompleted,
    this.visitOneStatus,
    this.visitTwoStatus,
  });

  final int visitsCompleted;
  final String? visitOneStatus;
  final String? visitTwoStatus;

  @override
  Widget build(BuildContext context) {
    final statuses = [visitOneStatus, visitTwoStatus]
        .whereType<String>()
        .where((status) => status != 'N/A')
        .toList(growable: false);

    final hasNotVisited = statuses.contains('Not visited');
    final color = hasNotVisited
        ? const Color(0xFFB3261E)
        : visitsCompleted >= 2
            ? MustBrandColors.green
            : visitsCompleted == 1
                ? const Color(0xFFB26A00)
                : const Color(0xFF8A5A00);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _visitPillLabel(statuses, visitsCompleted),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

String _visitPillLabel(List<String> statuses, int visitsCompleted) {
  if (statuses.isEmpty) return 'No visits';

  final notVisitedCount =
      statuses.where((status) => status == 'Not visited').length;
  if (notVisitedCount > 0 && visitsCompleted > 0) {
    return '$visitsCompleted visited, $notVisitedCount not visited';
  }

  if (notVisitedCount > 0) {
    return notVisitedCount == 1
        ? 'Not visited'
        : '$notVisitedCount visits not visited';
  }

  return '$visitsCompleted of ${StudentPlacementReportRow.expectedSupervisorVisits} visits recorded';
}

class _DistrictBarChart extends StatelessWidget {
  const _DistrictBarChart({required this.districts});

  final List<DistrictAllocationStat> districts;

  @override
  Widget build(BuildContext context) {
    final maxValue = districts
        .map((district) => district.studentCount)
        .fold<int>(0, math.max);

    return SizedBox(
      height: 220,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: districts.map((district) {
          final factor = maxValue == 0 ? 0.0 : district.studentCount / maxValue;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${district.studentCount}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: factor.clamp(0.08, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                MustBrandColors.greenLight,
                                MustBrandColors.green,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    district.district,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LegendStatChip extends StatelessWidget {
  const _LegendStatChip({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: $value',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

/* class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label • $value',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
} */

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final lower = label.toLowerCase();
    final Color background;
    final Color foreground;

    if (lower.contains('approved') || lower.contains('active')) {
      background = const Color(0xFFE3F4E8);
      foreground = const Color(0xFF1E6B34);
    } else if (lower.contains('pending') || lower.contains('awaiting')) {
      background = const Color(0xFFFFF3DB);
      foreground = const Color(0xFFB26A00);
    } else if (lower.contains('rejected')) {
      background = const Color(0xFFFBE5E5);
      foreground = const Color(0xFFB3261E);
    } else {
      background = const Color(0xFFEAF1ED);
      foreground = const Color(0xFF42624A);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StatsMetricCell extends StatelessWidget {
  const _StatsMetricCell({required this.item});

  final _StatItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: item.color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            item.icon,
            color: item.color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          item.title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
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
      duration: Duration(milliseconds: 450 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 14),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Card(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 138),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: item.color.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(15),
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
                const SizedBox(height: 18),
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: item.color,
                      ),
                ),
                const SizedBox(height: 4),
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

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.segments);

  final List<_ChartSegment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold<double>(0, (sum, item) => sum + item.value);
    final strokeWidth = 22.0;
    final rect = Offset.zero & size;
    final basePaint = Paint()
      ..color = MustBrandColors.surfaceTint
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect.deflate(strokeWidth),
      -math.pi / 2,
      math.pi * 2,
      false,
      basePaint,
    );

    if (total <= 0) return;

    var startAngle = -math.pi / 2;
    for (final segment in segments) {
      final sweepAngle = (segment.value / total) * math.pi * 2;
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        rect.deflate(strokeWidth),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.segments != segments;
  }
}

class _ChartSegment {
  const _ChartSegment({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
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
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
