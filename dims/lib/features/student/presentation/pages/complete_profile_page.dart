// lib/features/student/presentation/pages/complete_profile_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dims/features/auth/controllers/auth_controller.dart';
import 'package:dims/features/student/controllers/student_controllers.dart';
import 'package:dims/features/student/data/models/student_profile_model.dart';

class CompleteProfilePage extends ConsumerStatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  ConsumerState<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends ConsumerState<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _registrationNumberController = TextEditingController();
  final _programController = TextEditingController();
  final _academicYearController = TextEditingController();
  final _currentLevelController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _registrationNumberController.dispose();
    _programController.dispose();
    _academicYearController.dispose();
    _currentLevelController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authStateProvider).value;
      if (authState == null) {
        throw Exception('User not authenticated');
      }

      final profile = StudentProfileModel(
        registrationNumber: _registrationNumberController.text.trim(),
         uid: authState.uid,
        program: _programController.text.trim(),
        academicYear: int.parse(_academicYearController.text.trim()),
        currentLevel: _currentLevelController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref
          .read(studentProfileControllerProvider)
          .saveProfile(authState.uid, profile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // The router will automatically redirect to dashboard when profile is complete
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton.icon(
            onPressed: () async {
              await ref.read(authControllerProvider).signOut();
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.person_add,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome to DIMS!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please complete your profile to get started',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Registration Number
              TextFormField(
                controller: _registrationNumberController,
                decoration: const InputDecoration(
                  labelText: 'Registration Number *',
                  hintText: 'e.g., 2021/BIT/001',
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your registration number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Program
              TextFormField(
                controller: _programController,
                decoration: const InputDecoration(
                  labelText: 'Program *',
                  hintText: 'e.g., Bachelor of Information Technology',
                  prefixIcon: Icon(Icons.school),
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your program';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Academic Year
              TextFormField(
                controller: _academicYearController,
                decoration: const InputDecoration(
                  labelText: 'Academic Year *',
                  hintText: 'e.g., 2024',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter academic year';
                  }
                  final year = int.tryParse(value);
                  if (year == null) {
                    return 'Please enter a valid year';
                  }
                  if (year < 2000 || year > 2100) {
                    return 'Please enter a valid year';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Current Level
              TextFormField(
                controller: _currentLevelController,
                decoration: const InputDecoration(
                  labelText: 'Current Level *',
                  hintText: 'e.g., Year 3',
                  prefixIcon: Icon(Icons.grade),
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current level';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              
              // Submit Button
              FilledButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Complete Profile',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 16),
              Text(
                '* Required fields',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}