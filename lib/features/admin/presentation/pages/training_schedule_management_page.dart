import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../training_schedule/controllers/training_schedule_controller.dart';
import '../../../training_schedule/data/training_schedule_item.dart';

class TrainingScheduleManagementPage extends ConsumerStatefulWidget {
  const TrainingScheduleManagementPage({super.key});

  @override
  ConsumerState<TrainingScheduleManagementPage> createState() =>
      _TrainingScheduleManagementPageState();
}

class _TrainingScheduleManagementPageState
    extends ConsumerState<TrainingScheduleManagementPage> {
  void _openScheduleForm({TrainingScheduleItem? item}) {
    showDialog<void>(
      context: context,
      builder: (context) => _TrainingScheduleFormDialog(item: item),
    );
  }

  Future<void> _seedDefaultSchedule() async {
    final existing =
        ref.read(trainingScheduleCollectionProvider).value ?? const [];

    if (existing.isNotEmpty) {
      _showSnackBar('The timeline already has items.');
      return;
    }

    try {
      await ref.read(trainingScheduleControllerProvider).seedDefaultSchedule();
      _showSnackBar('Timeline template loaded.');
    } catch (error) {
      _showSnackBar('Unable to load template: $error', isError: true);
    }
  }

  Future<void> _toggleVisibility(TrainingScheduleItem item) async {
    try {
      await ref.read(trainingScheduleControllerProvider).setVisibility(
            id: item.id,
            isVisible: !item.isVisible,
          );
      _showSnackBar(
        item.isVisible ? 'Timeline item hidden.' : 'Timeline item published.',
      );
    } catch (error) {
      _showSnackBar('Unable to update item: $error', isError: true);
    }
  }

  Future<void> _deleteItem(TrainingScheduleItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Timeline Item'),
        content: Text(
          'Delete "${item.title}" from the shared training timeline? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(trainingScheduleControllerProvider).deleteItem(item.id);
      _showSnackBar('Timeline item deleted.');
    } catch (error) {
      _showSnackBar('Unable to delete item: $error', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheduleAsync = ref.watch(trainingScheduleCollectionProvider);
    final visibleItems = ref.watch(visibleTrainingScheduleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Timeline'),
        actions: [
          IconButton(
            onPressed: _seedDefaultSchedule,
            icon: const Icon(Icons.auto_fix_high_rounded),
            tooltip: 'Load template',
          ),
          IconButton(
            onPressed: () => _openScheduleForm(),
            icon: const Icon(Icons.add),
            tooltip: 'Add timeline item',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(trainingScheduleCollectionProvider);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shared Timeline Management',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage one shared internship timeline for the whole system. Students and supervisors will see the same published items.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.icon(
                          onPressed: () => _openScheduleForm(),
                          icon: const Icon(Icons.add),
                          label: const Text('Add item'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _seedDefaultSchedule,
                          icon: const Icon(Icons.auto_fix_high_rounded),
                          label: const Text('Load template'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaChip(
                          label:
                              '${visibleItems.length} published item${visibleItems.length == 1 ? '' : 's'}',
                          color: Colors.green,
                        ),
                        _MetaChip(
                          label: 'Single shared timeline',
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            scheduleAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return _TrainingScheduleEmptyState(
                    onAdd: () => _openScheduleForm(),
                    onSeed: _seedDefaultSchedule,
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 12),
                      child: Text(
                        '${items.length} timeline item${items.length == 1 ? '' : 's'}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    ...items.map(
                      (item) => _TrainingScheduleCard(
                        item: item,
                        onEdit: () => _openScheduleForm(item: item),
                        onDelete: () => _deleteItem(item),
                        onToggleVisibility: () => _toggleVisibility(item),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => _TrainingScheduleMessageState(
                icon: Icons.error_outline_rounded,
                title: 'Unable to load the timeline',
                description: '$error',
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openScheduleForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add timeline item'),
      ),
    );
  }
}

class _TrainingScheduleCard extends StatelessWidget {
  const _TrainingScheduleCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleVisibility,
  });

  final TrainingScheduleItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleVisibility;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${item.order}',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MetaChip(
                              label: item.dateRange, color: Colors.indigo),
                          _MetaChip(
                            label: item.isVisible ? 'Published' : 'Hidden',
                            color:
                                item.isVisible ? Colors.green : Colors.orange,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'toggle') onToggleVisibility();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit item'),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child:
                          Text(item.isVisible ? 'Hide item' : 'Publish item'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete item'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'In charge: ${item.personInCharge}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            if ((item.description ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                item.description!.trim(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrainingScheduleFormDialog extends ConsumerStatefulWidget {
  const _TrainingScheduleFormDialog({
    this.item,
  });

  final TrainingScheduleItem? item;

  @override
  ConsumerState<_TrainingScheduleFormDialog> createState() =>
      _TrainingScheduleFormDialogState();
}

class _TrainingScheduleFormDialogState
    extends ConsumerState<_TrainingScheduleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _dateRangeController;
  late final TextEditingController _personInChargeController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _orderController;
  late bool _isVisible;
  bool _isSaving = false;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _titleController = TextEditingController(text: item?.title ?? '');
    _dateRangeController = TextEditingController(text: item?.dateRange ?? '');
    _personInChargeController =
        TextEditingController(text: item?.personInCharge ?? '');
    _descriptionController =
        TextEditingController(text: item?.description ?? '');
    _orderController =
        TextEditingController(text: (item?.order ?? 1).toString());
    _isVisible = item?.isVisible ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateRangeController.dispose();
    _personInChargeController.dispose();
    _descriptionController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    final order = int.tryParse(_orderController.text.trim()) ?? 0;
    final existing = widget.item;
    final item = TrainingScheduleItem(
      id: existing?.id ?? '',
      title: _titleController.text.trim(),
      dateRange: _dateRangeController.text.trim(),
      personInCharge: _personInChargeController.text.trim(),
      academicYear: sharedTrainingTimelineKey,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      order: order,
      isVisible: _isVisible,
      createdAt: existing?.createdAt,
      updatedAt: existing?.updatedAt,
    );

    try {
      await ref.read(trainingScheduleControllerProvider).saveItem(item);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Timeline item updated.' : 'Timeline item added.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to save item: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Timeline Item' : 'Add Timeline Item'),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Title is required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _dateRangeController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Date range',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Date range is required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _personInChargeController,
                  textInputAction: TextInputAction.next,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Person in charge',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Person in charge is required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _orderController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Display order',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final order = int.tryParse(value?.trim() ?? '');
                    if (order == null || order <= 0) {
                      return 'Enter a valid order number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isVisible,
                  onChanged: (value) => setState(() => _isVisible = value),
                  title: const Text('Published'),
                  subtitle: const Text(
                    'Published items are visible to both students and supervisors.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: Text(_isSaving ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }
}

class _TrainingScheduleEmptyState extends StatelessWidget {
  const _TrainingScheduleEmptyState({
    required this.onAdd,
    required this.onSeed,
  });

  final VoidCallback onAdd;
  final VoidCallback onSeed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.timeline_rounded,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              'No timeline items yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add items manually or load the default shared template.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('Add item'),
                ),
                OutlinedButton.icon(
                  onPressed: onSeed,
                  icon: const Icon(Icons.auto_fix_high_rounded),
                  label: const Text('Load template'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainingScheduleMessageState extends StatelessWidget {
  const _TrainingScheduleMessageState({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: theme.colorScheme.primary),
            const SizedBox(height: 14),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
