import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/controllers/auth_controller.dart'; // Ensure this path is correct
import '../../../student/data/models/student_profile_model.dart';
import '../../../evaluations/data/models/evaluation_model.dart';
import '../../controllers/supervisor_controller.dart';

class StudentEvaluationScreen extends ConsumerStatefulWidget {
  final StudentProfileModel student;
  const StudentEvaluationScreen({super.key, required this.student});

  @override
  ConsumerState<StudentEvaluationScreen> createState() => _StudentEvaluationScreenState();
}

class _StudentEvaluationScreenState extends ConsumerState<StudentEvaluationScreen> {
  final _formKey = GlobalKey<FormState>();
  double performanceScore = 5.0;
  double attendanceScore = 5.0;
  double communicationScore = 5.0;
  String comments = '';

 Future<void> _submit() async {
  final auth = ref.read(authStateProvider).value;
  if (auth == null) return;
  final placementId = widget.student.currentPlacementId;
  if (placementId == null || placementId.trim().isEmpty) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internship placement found for this student.')),
      );
    }
    return;
  }

  // Get supervisor name
  final supervisorName = auth.displayName ?? auth.email ?? 'Unknown Supervisor';

  final eval = EvaluationModel(
    studentId: widget.student.uid,
    placementId: placementId,
    evaluatorType: EvaluationType.universitySupervisor,
    evaluatorId: auth.uid,
    evaluatorName: supervisorName,
    finalMarks: ((performanceScore + attendanceScore + communicationScore) / 3) * 10, // Convert to /100
    technicalSkillsRating: performanceScore,
    workEthicRating: attendanceScore,
    communicationRating: communicationScore,
    problemSolvingRating: performanceScore, // Use same for now
    initiativeRating: performanceScore, // Use same for now
    teamworkRating: communicationScore, // Use same for now
    daysPresent: 0, // TODO: Get actual attendance
    daysAbsent: 0,
    totalWorkingDays: 0,
    overallComments: comments,
    createdAt: DateTime.now(),
  );

  await ref.read(supervisorControllerProvider).submitEvaluation(eval);
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Evaluation Saved')));
    Navigator.pop(context);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Evaluation')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Performance: ${performanceScore.toInt()}'),
            Slider(value: performanceScore, min: 1, max: 10, divisions: 9, onChanged: (v) => setState(() => performanceScore = v)),
            Text('Attendance: ${attendanceScore.toInt()}'),
            Slider(value: attendanceScore, min: 1, max: 10, divisions: 9, onChanged: (v) => setState(() => attendanceScore = v)),
            Text('Communication: ${communicationScore.toInt()}'),
            Slider(value: communicationScore, min: 1, max: 10, divisions: 9, onChanged: (v) => setState(() => communicationScore = v)),
            const SizedBox(height: 20),
            TextFormField(
              decoration: const InputDecoration(labelText: 'General Comments', border: OutlineInputBorder()),
              maxLines: 4,
              onChanged: (v) => comments = v,
            ),
            const SizedBox(height: 30),
            ElevatedButton(onPressed: _submit, child: const Text('SUBMIT EVALUATION'))
          ],
        ),
      ),
    );
  }
}
