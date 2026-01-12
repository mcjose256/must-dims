import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/logbook_entry_model.dart';
import '../providers/logbook_form_provider.dart';

class LogbookEntryFormScreen extends ConsumerStatefulWidget {
  final LogbookEntryModel? existingEntry; // Optional - for edit mode
  const LogbookEntryFormScreen({super.key, this.existingEntry});

  @override
  ConsumerState<LogbookEntryFormScreen> createState() => _LogbookEntryFormScreenState();
}

class _LogbookEntryFormScreenState extends ConsumerState<LogbookEntryFormScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    // Delay loading until after build to avoid Riverpod lifecycle error
    if (widget.existingEntry != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final notifier = ref.read(logbookFormProvider.notifier);
        final entry = widget.existingEntry!;
        notifier.loadExistingEntry(entry);
        print('[Form] Loaded existing entry for edit: ${entry.id}');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(logbookFormProvider);
    final notifier = ref.read(logbookFormProvider.notifier);
    final isSubmitting = formState.isSubmitting;
    final errorMessage = formState.errorMessage;
    final isEditMode = widget.existingEntry != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Logbook Entry' : 'New Logbook Entry'),
        actions: [
          if (formState.formSubmittedSuccessfully)
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: () => Navigator.pop(context),
            ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Date Picker Field
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(
                        formState.selectedDate == null
                            ? 'Select Date *'
                            : DateFormat('EEEE, MMM d, yyyy').format(formState.selectedDate!),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: isSubmitting
                          ? null
                          : () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: formState.selectedDate ?? DateTime.now(),
                                firstDate: DateTime(2023),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                notifier.updateDate(picked);
                              }
                            },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tasks Performed
                  TextFormField(
                    maxLines: 4,
                    minLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Tasks Performed *',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    enabled: !isSubmitting,
                    onChanged: notifier.updateTasks,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please describe what you did today';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Challenges Faced
                  TextFormField(
                    maxLines: 3,
                    minLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Challenges / Difficulties Faced',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    enabled: !isSubmitting,
                    onChanged: notifier.updateChallenges,
                  ),
                  const SizedBox(height: 16),

                  // Skills Learned
                  TextFormField(
                    maxLines: 3,
                    minLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Skills / Knowledge Acquired',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    enabled: !isSubmitting,
                    onChanged: notifier.updateSkillsLearned,
                  ),
                  const SizedBox(height: 24),

                  // Hours Worked
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Hours Worked Today *',
                      border: OutlineInputBorder(),
                      suffixText: 'hours',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    enabled: !isSubmitting,
                    onChanged: (value) {
                      final hours = double.tryParse(value) ?? 0.0;
                      notifier.updateHours(hours);
                    },
                    validator: (value) {
                      final hours = double.tryParse(value ?? '0');
                      if (hours == null || hours <= 0) {
                        return 'Enter valid hours (0.5–24)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  FilledButton.icon(
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(isSubmitting ? 'Saving...' : isEditMode ? 'Update Entry' : 'Save Entry'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (_formKey.currentState?.validate() ?? false) {
                              final success = await notifier.submit();
                              if (success && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isEditMode ? 'Entry updated successfully!' : 'Entry saved successfully!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                Navigator.pop(context); // Close form after success
                              }
                            }
                          },
                  ),

                  if (errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      errorMessage!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),

            if (formState.formSubmittedSuccessfully)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                          const SizedBox(height: 16),
                          Text(
                            isEditMode ? 'Entry Updated!' : 'Entry Saved!',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 24),
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Back to Dashboard'),
                          ),
                        ],
                      ),
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