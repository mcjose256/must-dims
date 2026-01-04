// lib/features/student/presentation/pages/logbook_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dims/features/student/controllers/student_controllers.dart';
import 'package:dims/features/logbook/data/models/logbook_entry_model.dart';

class LogbookPage extends ConsumerWidget {
  const LogbookPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(logbookEntriesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: entriesAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.book_outlined,
                    size: 80,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No logbook entries yet',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start documenting your internship journey',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      // TODO: Navigate to add entry
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Add entry feature coming soon')),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Entry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(logbookEntriesProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final docId = entries[index]['id'] as String;
                final entry = entries[index]['entry'] as LogbookEntryModel;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(entry.status),
                      child: Text(
                        '${entry.dayNumber}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      'Day ${entry.dayNumber}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_formatDate(entry.date)} • ${entry.status ?? "pending"}',
                        ),
                        Text(
                          '${entry.hoursWorked.toStringAsFixed(1)} hours',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () {
                        _showOptionsMenu(context, ref, docId, entry);
                      },
                    ),
                    onTap: () {
                      // TODO: Navigate to entry details
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('View details for Day ${entry.dayNumber}')),
                      );
                    },
                  ),
                );
              },
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
                onPressed: () => ref.invalidate(logbookEntriesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to add entry
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add entry feature coming soon')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Entry'),
      ),
    );
  }

  void _showOptionsMenu(
    BuildContext context, 
    WidgetRef ref, 
    String docId, 
    LogbookEntryModel entry,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (entry.status?.toLowerCase() != 'approved')
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit feature coming soon')),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('View details feature coming soon')),
                );
              },
            ),
            if (entry.status?.toLowerCase() != 'approved')
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Entry'),
                      content: const Text('Are you sure you want to delete this entry?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirm == true && context.mounted) {
                    try {
                      await ref.read(logbookControllerProvider).deleteEntry(
                        docId,
                        entry.status,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Entry deleted')),
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
                },
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}