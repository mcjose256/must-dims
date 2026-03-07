// lib/features/student/presentation/pages/edit_profile_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dims/features/student/controllers/student_controllers.dart';
import 'package:dims/features/student/data/models/student_profile_model.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  final StudentProfileModel profile;

  const EditProfilePage({super.key, required this.profile});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _hasChanges = false;

  // Controllers
  late final TextEditingController _fullNameController;
  late final TextEditingController _programController;
  late final TextEditingController _levelController;

  // Academic year — dropdown 1–6
  late int _selectedYear;

  // Programs offered at MUST (editable via free text too)
  static const _programs = [
    'Bachelor of Computer Science',
    'Bachelor of Information Technology',
    'Bachelor of Software Engineering',
    'Bachelor of Information Systems',
    'Bachelor of Science in Computer Science',
    'Diploma in Computer Science',
    'Diploma in Information Technology',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _fullNameController =
        TextEditingController(text: widget.profile.fullName);
    _programController =
        TextEditingController(text: widget.profile.program);
    _levelController =
        TextEditingController(text: widget.profile.currentLevel);
    _selectedYear =
        widget.profile.academicYear.clamp(1, 6);

    // Track changes
    _fullNameController.addListener(_onChanged);
    _programController.addListener(_onChanged);
    _levelController.addListener(_onChanged);
  }

  void _onChanged() {
    final changed = _fullNameController.text != widget.profile.fullName ||
        _programController.text != widget.profile.program ||
        _levelController.text != widget.profile.currentLevel ||
        _selectedYear != widget.profile.academicYear;
    if (changed != _hasChanges) setState(() => _hasChanges = changed);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _programController.dispose();
    _levelController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Not logged in');

      final updated = widget.profile.copyWith(
        fullName: _fullNameController.text.trim(),
        program: _programController.text.trim(),
        currentLevel: _levelController.text.trim(),
        academicYear: _selectedYear,
        updatedAt: DateTime.now(),
      );

      await ref
          .read(studentProfileControllerProvider)
          .saveProfile(uid, updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
            'You have unsaved changes. Are you sure you want to go back?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_hasChanges,
      onPopInvoked: (didPop) async {
        if (!didPop && _hasChanges) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Profile'),
          actions: [
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              TextButton(
                onPressed: _hasChanges ? _save : null,
                child: Text(
                  'Save',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: _hasChanges
                        ? theme.colorScheme.primary
                        : Colors.grey,
                  ),
                ),
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Avatar preview ─────────────────────────────────
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor:
                          theme.colorScheme.primaryContainer,
                      child: ValueListenableBuilder(
                        valueListenable: _fullNameController,
                        builder: (_, value, __) => Text(
                          value.text.isNotEmpty
                              ? value.text[0].toUpperCase()
                              : 'S',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            color:
                                theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt,
                          size: 14, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Profile photo (coming soon)',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500),
                ),
              ),
              const SizedBox(height: 32),

              // ── Section: Personal ──────────────────────────────
              _SectionHeader(title: 'Personal Information'),
              const SizedBox(height: 12),

              // Full Name
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  hintText: 'e.g. Kunkwataho Joseph',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Full name is required';
                  }
                  if (v.trim().length < 3) {
                    return 'Name must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),

              // ── Section: Academic ──────────────────────────────
              _SectionHeader(title: 'Academic Information'),
              const SizedBox(height: 12),

              // Registration number — read only
              TextFormField(
                initialValue: widget.profile.registrationNumber,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Registration Number',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  helperText:
                      'Registration number cannot be changed',
                ),
              ),
              const SizedBox(height: 16),

              // Program — autocomplete from list but allow free text
              Autocomplete<String>(
                initialValue:
                    TextEditingValue(text: widget.profile.program),
                optionsBuilder: (textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return _programs;
                  }
                  return _programs.where((p) => p
                      .toLowerCase()
                      .contains(
                          textEditingValue.text.toLowerCase()));
                },
                onSelected: (value) {
                  _programController.text = value;
                  _onChanged();
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onSubmit) {
                  // Sync autocomplete controller with our controller
                  controller.text = _programController.text;
                  controller.addListener(() {
                    _programController.text = controller.text;
                  });
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Program *',
                      hintText:
                          'e.g. Bachelor of Computer Science',
                      prefixIcon: Icon(Icons.school_outlined),
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Program is required';
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              // Academic Year — dropdown
              DropdownButtonFormField<int>(
                value: _selectedYear,
                decoration: const InputDecoration(
                  labelText: 'Academic Year *',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                  border: OutlineInputBorder(),
                ),
                items: List.generate(
                  6,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text('Year ${i + 1}'),
                  ),
                ),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedYear = value);
                    _onChanged();
                  }
                },
              ),
              const SizedBox(height: 16),

              // Current Level — free text (e.g. "3.2", "Level 3")
              TextFormField(
                controller: _levelController,
                decoration: const InputDecoration(
                  labelText: 'Current Level',
                  hintText: 'e.g. 3.2 or Level 3',
                  prefixIcon: Icon(Icons.layers_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 40),

              // ── Save button ────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: (_hasChanges && !_isSaving) ? _save : null,
                  style: FilledButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Divider(color: theme.colorScheme.primary.withOpacity(0.2)),
      ],
    );
  }
}