import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../evaluations/data/models/evaluation_model.dart';

class FinalEvaluationFormPage extends ConsumerStatefulWidget {
  final String placementId;
  final String studentId;

  const FinalEvaluationFormPage({
    super.key,
    required this.placementId,
    required this.studentId,
  });

  @override
  ConsumerState<FinalEvaluationFormPage> createState() =>
      _FinalEvaluationFormPageState();
}

class _FinalEvaluationFormPageState
    extends ConsumerState<FinalEvaluationFormPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Ratings (1-5)
  double _technicalSkills = 3.0;
  double _workEthic = 3.0;
  double _communication = 3.0;
  double _problemSolving = 3.0;
  double _initiative = 3.0;
  double _teamwork = 3.0;

  // Attendance
  final _daysPresentController = TextEditingController();
  final _daysAbsentController = TextEditingController();

  // Comments
  final _overallCommentsController = TextEditingController();
  final _strengthsController = TextEditingController();
  final _areasForImprovementController = TextEditingController();
  final _recommendationsController = TextEditingController();

  // Would hire again
  bool? _wouldHireAgain;
  final _hiringConditionsController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _daysPresentController.dispose();
    _daysAbsentController.dispose();
    _overallCommentsController.dispose();
    _strengthsController.dispose();
    _areasForImprovementController.dispose();
    _recommendationsController.dispose();
    _hiringConditionsController.dispose();
    super.dispose();
  }

  double _calculateFinalMarks() {
    // Weighted average (out of 100)
    // Technical Skills: 30%
    // Work Ethic: 20%
    // Communication: 15%
    // Problem Solving: 15%
    // Initiative: 10%
    // Teamwork: 10%
    
    return ((_technicalSkills / 5 * 30) +
            (_workEthic / 5 * 20) +
            (_communication / 5 * 15) +
            (_problemSolving / 5 * 15) +
            (_initiative / 5 * 10) +
            (_teamwork / 5 * 10));
  }

  Future<void> _submitEvaluation() async {
    if (!_formKey.currentState!.validate()) return;

    if (_wouldHireAgain == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please indicate if you would hire this intern again'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      // Get supervisor details
      final supervisorDoc = await FirebaseFirestore.instance
          .collection('companySupervisors')
          .doc(user.uid)
          .get();

      final supervisorData = supervisorDoc.data();
      final finalMarks = _calculateFinalMarks();

      // Calculate attendance
      final daysPresent = int.tryParse(_daysPresentController.text.trim()) ?? 0;
      final daysAbsent = int.tryParse(_daysAbsentController.text.trim()) ?? 0;
      final totalDays = daysPresent + daysAbsent;

      final existingEvaluation = await FirebaseFirestore.instance
          .collection('evaluations')
          .where('placementId', isEqualTo: widget.placementId)
          .where(
            'evaluatorType',
            isEqualTo: EvaluationType.companySupervisor.name,
          )
          .limit(1)
          .get();

      final existingDoc =
          existingEvaluation.docs.isEmpty ? null : existingEvaluation.docs.first;
      final existingCreatedAt = existingDoc?.data()['createdAt'];
      final evaluationPayload = {
        'placementId': widget.placementId,
        'studentId': widget.studentId,
        'evaluatorType': EvaluationType.companySupervisor.name,
        'evaluatorId': user.uid,
        'evaluatorName': supervisorData?['fullName'] ?? 'Unknown',
        'finalMarks': finalMarks,
        'technicalSkillsRating': _technicalSkills,
        'workEthicRating': _workEthic,
        'communicationRating': _communication,
        'problemSolvingRating': _problemSolving,
        'initiativeRating': _initiative,
        'teamworkRating': _teamwork,
        'daysPresent': daysPresent,
        'daysAbsent': daysAbsent,
        'totalWorkingDays': totalDays,
        'overallComments': _overallCommentsController.text.trim(),
        'strengthsHighlighted': _strengthsController.text.trim().isEmpty
            ? null
            : _strengthsController.text.trim(),
        'areasForImprovement': _areasForImprovementController.text.trim().isEmpty
            ? null
            : _areasForImprovementController.text.trim(),
        'recommendationsForFutureInterns':
            _recommendationsController.text.trim().isEmpty
                ? null
                : _recommendationsController.text.trim(),
        'wouldHireAgain': _wouldHireAgain,
        'hiringConditions': _hiringConditionsController.text.trim().isEmpty
            ? null
            : _hiringConditionsController.text.trim(),
        'createdAt': existingCreatedAt ?? FieldValue.serverTimestamp(),
        'submittedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Create evaluation
      if (existingDoc == null) {
        await FirebaseFirestore.instance
            .collection('evaluations')
            .add(evaluationPayload);
      } else {
        await existingDoc.reference.set(
          evaluationPayload,
          SetOptions(merge: true),
        );
      }

      // Update placement status
      await FirebaseFirestore.instance
          .collection('placements')
          .doc(widget.placementId)
          .update({
        'status': 'completed',
        'progressPercentage': 1.0,
        'actualEndDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.studentId)
          .update({
        'internshipStatus': 'completed',
        'progressPercentage': 100.0,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.celebration, color: Colors.green, size: 64),
            title: const Text('Evaluation Submitted!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Thank you for completing the final evaluation.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Final Mark: ${finalMarks.toStringAsFixed(1)}/100',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finalMarks = _calculateFinalMarks();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Final Evaluation'),
      ),
      body: _isSubmitting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Submitting evaluation...'),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Header
                  Card(
                    color: theme.colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Intern Final Evaluation',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please evaluate the intern\'s overall performance during their internship period.',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Performance Ratings
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Performance Categories',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Rate each category from 1 (Poor) to 5 (Excellent)',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const Divider(height: 24),
                          _RatingSlider(
                            'Technical Skills (Weight: 30%)',
                            _technicalSkills,
                            (value) => setState(() => _technicalSkills = value),
                          ),
                          _RatingSlider(
                            'Work Ethic (Weight: 20%)',
                            _workEthic,
                            (value) => setState(() => _workEthic = value),
                          ),
                          _RatingSlider(
                            'Communication (Weight: 15%)',
                            _communication,
                            (value) => setState(() => _communication = value),
                          ),
                          _RatingSlider(
                            'Problem Solving (Weight: 15%)',
                            _problemSolving,
                            (value) => setState(() => _problemSolving = value),
                          ),
                          _RatingSlider(
                            'Initiative (Weight: 10%)',
                            _initiative,
                            (value) => setState(() => _initiative = value),
                          ),
                          _RatingSlider(
                            'Teamwork (Weight: 10%)',
                            _teamwork,
                            (value) => setState(() => _teamwork = value),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Calculated Final Mark
                  Card(
                    color: Colors.blue.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Calculated Final Mark:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${finalMarks.toStringAsFixed(1)}/100',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Attendance
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Attendance',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _daysPresentController,
                                  decoration: const InputDecoration(
                                    labelText: 'Days Present *',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    if (int.tryParse(value) == null) {
                                      return 'Invalid number';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _daysAbsentController,
                                  decoration: const InputDecoration(
                                    labelText: 'Days Absent',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Comments Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detailed Feedback',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(height: 24),
                          TextFormField(
                            controller: _overallCommentsController,
                            decoration: const InputDecoration(
                              labelText: 'Overall Comments *',
                              hintText: 'Provide a comprehensive assessment of the intern\'s performance...',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 4,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _strengthsController,
                            decoration: const InputDecoration(
                              labelText: 'Key Strengths',
                              hintText: 'What were the intern\'s main strengths?',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _areasForImprovementController,
                            decoration: const InputDecoration(
                              labelText: 'Areas for Improvement',
                              hintText: 'What could the intern work on?',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _recommendationsController,
                            decoration: const InputDecoration(
                              labelText: 'Recommendations for Future Interns',
                              hintText: 'Any advice for future interns?',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Hiring Decision
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hiring Potential',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(height: 24),
                          const Text('Would you hire this intern? *'),
                          const SizedBox(height: 12),
                          Column(
                            children: [
                              RadioListTile<bool>(
                                title: const Text('Yes, definitely'),
                                value: true,
                                groupValue: _wouldHireAgain,
                                onChanged: (value) {
                                  setState(() => _wouldHireAgain = value);
                                },
                              ),
                              RadioListTile<bool>(
                                title: const Text('No'),
                                value: false,
                                groupValue: _wouldHireAgain,
                                onChanged: (value) {
                                  setState(() => _wouldHireAgain = value);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _hiringConditionsController,
                            decoration: const InputDecoration(
                              labelText: 'Conditions or Additional Notes',
                              hintText: 'Any specific conditions or reasons?',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _submitEvaluation,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Submit Final Evaluation'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}

class _RatingSlider extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _RatingSlider(this.label, this.value, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(label)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _getRatingColor(value).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getRatingText(value),
                  style: TextStyle(
                    color: _getRatingColor(value),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: 1,
            max: 5,
            divisions: 4,
            label: value.toStringAsFixed(0),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  String _getRatingText(double rating) {
    if (rating <= 1.5) return 'Poor';
    if (rating <= 2.5) return 'Fair';
    if (rating <= 3.5) return 'Good';
    if (rating <= 4.5) return 'Very Good';
    return 'Excellent';
  }

  Color _getRatingColor(double rating) {
    if (rating <= 2) return Colors.red;
    if (rating <= 3) return Colors.orange;
    if (rating <= 4) return Colors.blue;
    return Colors.green;
  }
}
