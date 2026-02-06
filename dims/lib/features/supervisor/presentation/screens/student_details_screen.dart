import 'package:flutter/material.dart';
import '../../../student/data/models/student_profile_model.dart';
import 'student_evaluation_screen.dart';

class StudentDetailsScreen extends StatelessWidget {
  final StudentProfileModel student;
  const StudentDetailsScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Progress')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
          const SizedBox(height: 16),
          Center(
            child: Text(student.registrationNumber, style: Theme.of(context).textTheme.headlineSmall),
          ),
          Center(child: Text(student.program)),
          const Divider(height: 40),
          ListTile(
            leading: const Icon(Icons.assignment),
            title: const Text('View All Logbooks'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () { /* Navigate to a filtered list of all this student's logs */ },
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => StudentEvaluationScreen(student: student)),
            ),
            icon: const Icon(Icons.grade),
            label: const Text('Submit Final Evaluation'),
          ),
        ],
      ),
    );
  }
}