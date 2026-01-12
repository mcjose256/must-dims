import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart'; // ← Added for context.go / context.push

import '../../controllers/student_controllers.dart';
import '../../../logbook/data/models/logbook_entry_model.dart';
import '../../../logbook/presentation/screens/logbook_entry_details_screen.dart';
import 'package:dims/features/logbook/presentation/screens/logbook_entry_form_screen.dart';
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
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () {
                      // Navigate to new entry form using go_router
                      context.push('/logbook/add');
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
                final entryMap = entries[index];
                final docId = entryMap['id'] as String;
                final entry = entryMap['entry'] as LogbookEntryModel;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(entry.status),
                      radius: 28,
                      child: Text(
                        '${entry.dayNumber}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
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
                          '${_formatDate(entry.date)} • ${entry.status?.toUpperCase() ?? "Pending"}',
                          style: TextStyle(
                            color: _getStatusTextColor(entry.status),
                          ),
                        ),
                        Text(
                          '${entry.hoursWorked.toStringAsFixed(1)} hours',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _showOptionsMenu(context, ref, docId, entry),
                    ),
                    onTap: () => _navigateToDetails(context, entry),
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
              Text('Error loading entries: $error'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.invalidate(logbookEntriesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_logbook_entry',
        onPressed: () {
          context.push('/logbook/add'); // New entry route
        },
        icon: const Icon(Icons.add),
        label: const Text('New Entry'),
      ),
    );
  }

  // ── Navigation Helpers ─────────────────────────────────────────────────────

  void _navigateToDetails(BuildContext context, LogbookEntryModel entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogbookEntryDetailsScreen(entry: entry),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context, WidgetRef ref, String docId, LogbookEntryModel entry) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // View Details
            ListTile(
              leading: Icon(Icons.visibility, color: Theme.of(context).colorScheme.primary),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _navigateToDetails(context, entry);
              },
            ),

            // Edit (only for draft/pending)
            if (entry.status?.toLowerCase() == 'draft' || entry.status?.toLowerCase() == 'pending')
              ListTile(
                leading: Icon(Icons.edit, color: Theme.of(context).colorScheme.secondary),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  // FIXED: Navigate to edit form with existing entry
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LogbookEntryFormScreen(existingEntry: entry),
                    ),
                  );
                },
              ),

            // Delete (only for draft/pending)
            if (entry.status?.toLowerCase() == 'draft' || entry.status?.toLowerCase() == 'pending')
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);

                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Entry'),
                      content: const Text(
                        'Are you sure you want to delete this logbook entry?\nThis action cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Entry deleted successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error deleting entry: $e')),
                      );
                    }
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  // ── Helper Methods ─────────────────────────────────────────────────────────

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

  Color _getStatusTextColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Colors.green.shade800;
      case 'rejected':
        return Colors.red.shade800;
      default:
        return Colors.orange.shade800;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }
}