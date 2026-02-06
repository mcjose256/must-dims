import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../data/models/supervisor_profile_model.dart';
import '../providers/supervisor_providers.dart';
import '../../controllers/supervisor_controller.dart';

class SupervisorProfileScreen extends ConsumerStatefulWidget {
  const SupervisorProfileScreen({super.key});

  @override
  ConsumerState<SupervisorProfileScreen> createState() => _SupervisorProfileScreenState();
}

class _SupervisorProfileScreenState extends ConsumerState<SupervisorProfileScreen> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for editing
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _deptController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _deptController = TextEditingController();
  }

  void _initializeControllers(SupervisorProfileModel profile) {
    _nameController.text = profile.fullName;
    _phoneController.text = profile.phoneNumber ?? '';
    _deptController.text = profile.department;
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(supervisorProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                final profile = profileAsync.value;
                if (profile != null) {
                  _initializeControllers(profile);
                  setState(() => _isEditing = true);
                }
              },
            )
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) return const Center(child: Text('No profile found'));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
                  const SizedBox(height: 20),
                  
                  _buildField('Full Name', _nameController, profile.fullName, Icons.person),
                  _buildField('Department', _deptController, profile.department, Icons.business),
                  _buildField('Phone Number', _phoneController, profile.phoneNumber ?? 'Not set', Icons.phone),
                  
                  const SizedBox(height: 30),
                  
                  if (_isEditing)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _isEditing = false),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _saveProfile(profile),
                            child: const Text('Save Changes'),
                          ),
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        onPressed: () => ref.read(authControllerProvider).signOut(),
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout'),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, String displayValue, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _isEditing
          ? TextFormField(
              controller: controller,
              decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: const OutlineInputBorder()),
            )
          : ListTile(
              leading: Icon(icon, color: Theme.of(context).primaryColor),
              title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              subtitle: Text(displayValue, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
    );
  }

  Future<void> _saveProfile(SupervisorProfileModel profile) async {
    final updated = profile.copyWith(
      fullName: _nameController.text,
      department: _deptController.text,
      phoneNumber: _phoneController.text,
    );
    await ref.read(supervisorControllerProvider).updateProfile(updated);
    setState(() => _isEditing = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Updated')));
  }
}