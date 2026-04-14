import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../logbook/controllers/logbook_controller.dart' as legacy_logbook;
import '../../../logbook/data/models/daily_logbook_entry_model.dart';
import '../../../logbook/presentation/pages/daily_entry_details_page.dart';
import '../../../logbook/presentation/pages/daily_entry_form_page.dart';

class DailyLogbookListPage extends ConsumerStatefulWidget {
  const DailyLogbookListPage({super.key});

  @override
  ConsumerState<DailyLogbookListPage> createState() =>
      _DailyLogbookListPageState();
}

class _DailyLogbookListPageState extends ConsumerState<DailyLogbookListPage> {
  String _searchQuery = '';

  Future<void> _openDailyLogForm([DailyLogbookEntryModel? entry]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DailyEntryFormPage(existingEntry: entry),
      ),
    );
  }

  List<DailyLogbookEntryModel> _filterEntries(
    List<DailyLogbookEntryModel> entries,
  ) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return entries;

    return entries.where((entry) {
      final text = [
        'day ${entry.dayNumber}',
        _formatDate(entry.date),
        entry.tasksPerformed,
        entry.challenges ?? '',
        entry.skillsLearned ?? '',
        entry.notes ?? '',
      ].join(' ').toLowerCase();
      return text.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(legacy_logbook.dailyEntriesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Logbook'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDailyLogForm(),
        icon: const Icon(Icons.edit_note),
        label: const Text('New Daily Log'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search daily entries',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor:
                    theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: entriesAsync.when(
              data: (entries) {
                final filteredEntries = _filterEntries(entries);

                if (entries.isEmpty) {
                  return _EmptyState(
                    icon: Icons.edit_note,
                    title: 'No daily entries',
                    description: 'Add each workday here.',
                    actionLabel: 'Add Daily Log',
                    onTap: () => _openDailyLogForm(),
                  );
                }

                if (filteredEntries.isEmpty) {
                  return const _SearchEmptyState(
                    title: 'No matching daily entries',
                    description: 'Try another search term.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(legacy_logbook.dailyEntriesProvider);
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: filteredEntries.length,
                    itemBuilder: (context, index) {
                      return _DailyEntryCard(
                        entry: filteredEntries[index],
                        onEdit: () => _openDailyLogForm(filteredEntries[index]),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _LoadErrorState(
                title: 'Unable to load daily entries',
                details: '$error',
                onRetry: () {
                  ref.invalidate(legacy_logbook.dailyEntriesProvider);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String _formatHours(double hours) {
  return hours.toStringAsFixed(
    hours.truncateToDouble() == hours ? 0 : 1,
  );
}

class _DailyEntryCard extends ConsumerWidget {
  final DailyLogbookEntryModel entry;
  final VoidCallback onEdit;

  const _DailyEntryCard({
    required this.entry,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            '${entry.dayNumber}',
            style: TextStyle(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          _formatDate(entry.date),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              entry.tasksPerformed,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.schedule_outlined,
                  label: '${_formatHours(entry.hoursWorked)} hrs',
                ),
                if (entry.attachmentUrls.isNotEmpty)
                  _InfoChip(
                    icon: Icons.attach_file,
                    label:
                        '${entry.attachmentUrls.length} attachment${entry.attachmentUrls.length == 1 ? '' : 's'}',
                  ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'view') {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DailyEntryDetailsPage(entry: entry),
                ),
              );
              return;
            }

            if (value == 'edit') {
              onEdit();
              return;
            }

            if (value == 'delete') {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete daily log'),
                  content: const Text('This entry will be removed.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                try {
                  await ref
                      .read(legacy_logbook.logbookControllerProvider)
                      .deleteDailyEntry(entry.id!);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Daily log deleted')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              }
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'view', child: Text('View')),
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DailyEntryDetailsPage(entry: entry),
            ),
          );
        },
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.55),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onTap;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 14),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.add),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  final String title;
  final String description;

  const _SearchEmptyState({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 44,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadErrorState extends StatelessWidget {
  final String title;
  final String details;
  final VoidCallback onRetry;

  const _LoadErrorState({
    required this.title,
    required this.details,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              details,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade600),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
