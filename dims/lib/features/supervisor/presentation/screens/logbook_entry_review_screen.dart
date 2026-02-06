import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../logbook/data/models/logbook_entry_model.dart';
import '../../controllers/supervisor_controller.dart';

class LogbookEntryReviewScreen extends ConsumerStatefulWidget {
  final LogbookEntryModel entry;
  const LogbookEntryReviewScreen({super.key, required this.entry});

  @override
  ConsumerState<LogbookEntryReviewScreen> createState() => _LogbookEntryReviewScreenState();
}

class _LogbookEntryReviewScreenState extends ConsumerState<LogbookEntryReviewScreen> {
  final _commentController = TextEditingController();
  bool _isLoading = false;

  Future<void> _processReview(bool isApproved) async {
    setState(() => _isLoading = true);
    try {
      final controller = ref.read(supervisorControllerProvider);
      if (isApproved) {
        await controller.approveLogbookEntry(widget.entry.id!, _commentController.text);
      } else {
        await controller.rejectLogbookEntry(widget.entry.id!, _commentController.text);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Day ${widget.entry.dayNumber} Review')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(DateFormat('EEEE, MMM d, yyyy').format(widget.entry.date), style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              const Text('Tasks Performed:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(widget.entry.tasksPerformed),
              const SizedBox(height: 16),
              const Text('Skills Learned:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(widget.entry.skillsLearned ?? 'None listed'),
              const Divider(height: 40),
              TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: 'Feedback / Comment',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _processReview(false),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('REJECT'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _processReview(true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      child: const Text('APPROVE'),
                    ),
                  ),
                ],
              ),
            ],
          ),
    );
  }
}