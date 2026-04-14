// lib/features/student/presentation/pages/upload_acceptance_letter_page.dart
import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dims/core/widgets/brand_app_bar_title.dart';
import 'package:dims/features/auth/controllers/auth_controller.dart';

import '../../../companies/data/models/company_model.dart';
import '../../../placements/data/models/placement_model.dart';

// ============================================================================
// PROVIDERS
// ============================================================================

final companiesListProvider =
    StreamProvider.autoDispose<List<CompanyModel>>((ref) {
  final authState = ref.watch(authStateProvider);

  if (authState.isLoading) {
    final controller = StreamController<List<CompanyModel>>();
    ref.onDispose(controller.close);
    return controller.stream;
  }

  if (FirebaseAuth.instance.currentUser == null) {
    return Stream.value(const <CompanyModel>[]);
  }

  return FirebaseFirestore.instance.collection('companies').snapshots().map((
    snapshot,
  ) {
    final companies = snapshot.docs
        .map((doc) => CompanyModel.fromFirestore(doc, null))
        .where((company) => company.isActive && company.acceptingInterns)
        .toList()
      ..sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

    return companies;
  });
});

// ============================================================================
// PAGE
// ============================================================================

class UploadAcceptanceLetterPage extends ConsumerStatefulWidget {
  const UploadAcceptanceLetterPage({super.key});

  @override
  ConsumerState<UploadAcceptanceLetterPage> createState() =>
      _UploadAcceptanceLetterPageState();
}

class _UploadAcceptanceLetterPageState
    extends ConsumerState<UploadAcceptanceLetterPage> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();

  // Form controllers
  final _supervisorNameController = TextEditingController();
  final _supervisorEmailController = TextEditingController();
  final _supervisorPhoneController = TextEditingController();
  final _studentNotesController = TextEditingController();
  final _totalWeeksController = TextEditingController(text: '12');

  // State
  int _currentStep = 0;
  CompanyModel? _selectedCompany;
  String? _selectedCompanyId;
  File? _selectedFile;
  String? _fileName;
  bool _isUploading = false;
  DateTime? _selectedStartDate;

  // Supervisor info fetched from student profile
  String? _universitySupervisorId;
  String? _universitySupervisorName;

  static const int _totalSteps = 3;

  @override
  void initState() {
    super.initState();
    _fetchAssignedSupervisor();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _supervisorNameController.dispose();
    _supervisorEmailController.dispose();
    _supervisorPhoneController.dispose();
    _studentNotesController.dispose();
    _totalWeeksController.dispose();
    super.dispose();
  }

  // ── Fetch assigned university supervisor ─────────────────────────────────
  // We fetch this early so the student knows who will review their letter.

  Future<void> _fetchAssignedSupervisor() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .get();

      final supervisorId =
          studentDoc.data()?['currentSupervisorId'] as String?;
      if (supervisorId == null) return;

      final supervisorDoc = await FirebaseFirestore.instance
          .collection('supervisorProfiles')
          .doc(supervisorId)
          .get();

      final supervisorName =
          supervisorDoc.data()?['fullName'] as String? ?? 'Your Supervisor';

      if (mounted) {
        setState(() {
          _universitySupervisorId = supervisorId;
          _universitySupervisorName = supervisorName;
        });
      }
    } catch (_) {
      // Non-critical — supervisor info is fetched again on submit
    }
  }

  // ── Step validation ──────────────────────────────────────────────────────

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        if (_universitySupervisorId == null) {
          _showError(
            'You must first be allocated a university supervisor before submitting an acceptance letter.',
          );
          return false;
        }
        if (_selectedCompanyId == null) {
          _showError('Please select a company to continue.');
          return false;
        }
        final supervisorEmail = _supervisorEmailController.text.trim();
        if (supervisorEmail.isNotEmpty && !supervisorEmail.contains('@')) {
          _showError('Please enter a valid company supervisor email.');
          return false;
        }
        return true;
      case 1:
        if (_selectedFile == null) {
          _showError('Please upload your acceptance letter.');
          return false;
        }
        return true;
      case 2:
        return true;
      default:
        return false;
    }
  }

  Future<void> _openCompanyPicker(List<CompanyModel> companies) async {
    final searchController = TextEditingController();
    List<CompanyModel> filtered = List<CompanyModel>.from(companies);

    final selected = await showModalBottomSheet<CompanyModel>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.72,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Company',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search by company, district, or industry',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          setModalState(() {
                            final query = value.trim().toLowerCase();
                            filtered = companies.where((company) {
                              return company.name.toLowerCase().contains(query) ||
                                  company.location.toLowerCase().contains(query) ||
                                  company.industry.toLowerCase().contains(query);
                            }).toList();
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(
                                child: Text('No companies match your search'),
                              )
                            : ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final company = filtered[index];
                                  final isSelected =
                                      company.id == _selectedCompanyId;
                                  return ListTile(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(
                                        color: isSelected
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Theme.of(context)
                                                .colorScheme
                                                .outlineVariant,
                                      ),
                                    ),
                                    tileColor: isSelected
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primaryContainer
                                            .withOpacity(0.35)
                                        : Colors.white,
                                    leading: CircleAvatar(
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .secondaryContainer,
                                      child: const Icon(Icons.business_outlined),
                                    ),
                                    title: Text(
                                      company.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${company.industry} • ${company.location}',
                                    ),
                                    trailing: isSelected
                                        ? Icon(
                                            Icons.check_circle,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          )
                                        : const Icon(Icons.chevron_right),
                                    onTap: () => Navigator.pop(context, company),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    searchController.dispose();

    if (selected != null && mounted) {
      setState(() {
        _selectedCompanyId = selected.id;
        _selectedCompany = selected;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _nextStep() {
    if (!_validateStep(_currentStep)) return;
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  // ── File picker ──────────────────────────────────────────────────────────

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.size > 5 * 1024 * 1024) {
          _showError('File too large. Maximum size is 5MB.');
          return;
        }
        setState(() {
          _selectedFile = File(file.path!);
          _fileName = file.name;
        });
      }
    } catch (e) {
      _showError('Error picking file: $e');
    }
  }

  Future<void> _selectStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme,
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedStartDate = picked);
    }
  }

  // ── Submit ───────────────────────────────────────────────────────────────

  Future<void> _submitApplication() async {
    setState(() => _isUploading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');
      if (_universitySupervisorId == null) {
        throw Exception(
          'You must first be allocated a university supervisor before submitting.',
        );
      }

      // 1. Upload file to Firebase Storage
      final storageFileName =
          'acceptance_letters/${user.uid}_${DateTime.now().millisecondsSinceEpoch}_$_fileName';
      final storageRef =
          FirebaseStorage.instance.ref().child(storageFileName);
      await storageRef.putFile(_selectedFile!);
      final downloadUrl = await storageRef.getDownloadURL();

      // 2. Fetch student data (re-fetch for accuracy)
      final studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .get();
      final studentData = studentDoc.data();
      final universitySupervisorId =
          _universitySupervisorId ?? studentData?['currentSupervisorId'] as String?;
      final academicYear = studentData?['academicYear']?.toString() ??
          DateTime.now().year.toString();

      // 3. Calculate timeline
      final totalWeeks = int.tryParse(_totalWeeksController.text) ?? 12;
      final endDate =
          _selectedStartDate?.add(Duration(days: totalWeeks * 7));

      final supervisorName = _supervisorNameController.text.trim();
      final supervisorEmail = _supervisorEmailController.text.trim();
      final supervisorPhone = _supervisorPhoneController.text.trim();

      // 4. Create placement document
      // Status is now 'pendingSupervisorReview' — goes to university supervisor,
      // NOT admin. Admin is no longer in the acceptance letter approval chain.
      final placementRef =
          await FirebaseFirestore.instance.collection('placements').add({
        'studentId': user.uid,
        'companyId': _selectedCompanyId,
        'universitySupervisorId': universitySupervisorId,
        'companySupervisorName':
            supervisorName.isEmpty ? null : supervisorName,
        'companySupervisorEmail':
            supervisorEmail.isEmpty ? null : supervisorEmail,
        'companySupervisorPhone':
            supervisorPhone.isEmpty ? null : supervisorPhone,
        'companySupervisorId': null,
        'acceptanceLetterUrl': downloadUrl,
        'acceptanceLetterFileName': _fileName,
        'letterUploadedAt': FieldValue.serverTimestamp(),
        'status': PlacementStatus.pendingSupervisorReview.name,
        'supervisorFeedback': null,
        'academicYear': academicYear,
        'startDate': _selectedStartDate != null
            ? Timestamp.fromDate(_selectedStartDate!)
            : null,
        'endDate': endDate != null ? Timestamp.fromDate(endDate) : null,
        'totalWeeks': totalWeeks,
        'weeksCompleted': 0,
        'progressPercentage': 0.0,
        'studentNotes': _studentNotesController.text.trim().isEmpty
            ? null
            : _studentNotesController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 5. Update student profile
      await FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .update({
        'currentPlacementId': placementRef.id,
        'internshipStatus': 'awaitingApproval',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        _showError('Submission failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showSuccessDialog() {
    final supervisorDisplay =
        _universitySupervisorName ?? 'your assigned supervisor';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_rounded,
                    color: Colors.green.shade600, size: 48),
              ),
              const SizedBox(height: 24),
              const Text(
                'Letter Submitted!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // ── Key change: tells the student WHO reviews it ─────────────
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.6,
                  ),
                  children: [
                    const TextSpan(
                        text: 'Your acceptance letter has been sent to '),
                    TextSpan(
                      text: supervisorDisplay,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const TextSpan(
                        text:
                            ' for review. You will be notified once they approve or provide feedback.'),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/student/dashboard');
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Back to Dashboard'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        toolbarHeight: 72,
        title: const BrandAppBarTitle(
          title: 'Apply for Internship',
          subtitle: 'MUST Student Placement Journey',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/student/dashboard'),
        ),
        elevation: 0,
      ),
      bottomNavigationBar: _isUploading || keyboardOpen
          ? null
          : SafeArea(
              top: false,
              child: _buildBottomNavigation(theme),
            ),
      body: SafeArea(
        child: _isUploading
            ? _buildUploadingState()
            : Column(
                children: [
                  _buildStepIndicator(theme),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStep1CompanyAndSupervisor(theme),
                        _buildStep2UploadLetter(theme),
                        _buildStep3ReviewAndSubmit(theme),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Upload state ─────────────────────────────────────────────────────────

  Widget _buildUploadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          const Text(
            'Submitting your application...',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait, do not close this page',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // ── Step indicator ───────────────────────────────────────────────────────

  Widget _buildStepIndicator(ThemeData theme) {
    final steps = ['Company & Supervisor', 'Acceptance Letter', 'Review & Submit'];
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_totalSteps, (i) {
          final isActive = i == _currentStep;
          final isDone = i < _currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone
                              ? Colors.green
                              : isActive
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surfaceContainerHighest,
                        ),
                        child: Center(
                          child: isDone
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 16)
                              : Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    color: isActive
                                        ? Colors.white
                                        : theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        steps[i],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isActive
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                if (i < _totalSteps - 1)
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 22),
                      color: i < _currentStep
                          ? Colors.green
                          : theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCompanySelector(List<CompanyModel> companies) {
    if (companies.isEmpty) return _EmptyCompaniesCard();

    return InkWell(
      onTap:
          _universitySupervisorId == null ? null : () => _openCompanyPicker(companies),
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: InputDecoration(
          hintText: 'Select a company',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
          enabled: _universitySupervisorId != null,
        ),
        child: _selectedCompany == null
            ? Text(
                _universitySupervisorId == null
                    ? 'Awaiting university supervisor allocation'
                    : 'Tap to browse companies',
                style: TextStyle(color: Colors.grey.shade600),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedCompany!.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_selectedCompany!.industry} • ${_selectedCompany!.location}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Step 1: Company & Supervisor ─────────────────────────────────────────

  Widget _buildStep1CompanyAndSupervisor(ThemeData theme) {
    final companiesAsync = ref.watch(companiesListProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Reviewer info banner ─────────────────────────────────────────
          // Show the student who will review their letter upfront.
          // This builds trust and sets expectations early.
          if (_universitySupervisorName != null)
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.school_outlined,
                      color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onPrimaryContainer,
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(
                              text: 'Your letter will be reviewed by '),
                          TextSpan(
                            text: _universitySupervisorName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: ', your assigned university supervisor.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_universitySupervisorName == null)
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'You cannot submit an acceptance letter until the university assigns you a supervisor.',
                    ),
                  ),
                ],
              ),
            ),

          _SectionHeader(
            icon: Icons.business,
            title: 'Company Selection',
            subtitle:
                'Select the company where you will be doing your internship',
          ),
          const SizedBox(height: 16),
          companiesAsync.when(
            data: (companies) {
              return _buildCompanySelector(companies);
              if (companies.isEmpty) return _EmptyCompaniesCard();
              return DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  hintText: 'Select a company',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                ),
                value: _selectedCompanyId,
                isExpanded: true,
                items: companies.map((company) {
                  return DropdownMenuItem(
                    value: company.id,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(company.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          '${company.industry} • ${company.location}',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() {
                  _selectedCompanyId = value;
                  _selectedCompany =
                      companies.firstWhere((c) => c.id == value);
                }),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Company list unavailable. Refresh and try again.',
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => ref.invalidate(companiesListProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _SectionHeader(
            icon: Icons.person_outline,
            title: 'Company Supervisor Details',
            subtitle:
                'Add your company supervisor details if you already have them',
          ),
          const SizedBox(height: 16),
          _StyledTextField(
            controller: _supervisorNameController,
            label: 'Supervisor Full Name (Optional)',
            icon: Icons.badge_outlined,
            keyboardType: TextInputType.name,
          ),
          const SizedBox(height: 14),
          _StyledTextField(
            controller: _supervisorEmailController,
            label: 'Supervisor Email (Optional)',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          _StyledTextField(
            controller: _supervisorPhoneController,
            label: 'Supervisor Phone (Optional)',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            hint: '+256 700 000000',
          ),
          const SizedBox(height: 28),
          _SectionHeader(
            icon: Icons.calendar_month_outlined,
            title: 'Internship Timeline',
            subtitle: 'Set your expected start date and duration',
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _selectStartDate,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Expected Start Date',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.calendar_today_outlined),
                filled: true,
              ),
              child: Text(
                _selectedStartDate != null
                    ? '${_selectedStartDate!.day}/${_selectedStartDate!.month}/${_selectedStartDate!.year}'
                    : 'Select date',
                style: TextStyle(
                  color: _selectedStartDate != null
                      ? null
                      : Colors.grey.shade500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _StyledTextField(
            controller: _totalWeeksController,
            label: 'Duration (Weeks)',
            icon: Icons.timelapse_outlined,
            keyboardType: TextInputType.number,
            hint: '12',
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  // ── Step 2: Upload Letter ────────────────────────────────────────────────

  Widget _buildStep2UploadLetter(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.upload_file_outlined,
            title: 'Acceptance Letter',
            subtitle:
                'Upload the official acceptance letter from your company. Accepted formats: PDF, JPG, PNG (max 5MB)',
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _pickFile,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              decoration: BoxDecoration(
                color: _selectedFile != null
                    ? Colors.green.shade50
                    : theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedFile != null
                      ? Colors.green.shade400
                      : theme.colorScheme.outline.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _selectedFile != null
                        ? Icons.check_circle_rounded
                        : Icons.cloud_upload_outlined,
                    size: 56,
                    color: _selectedFile != null
                        ? Colors.green.shade600
                        : theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _selectedFile != null ? 'File Selected!' : 'Tap to Upload File',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _selectedFile != null
                          ? Colors.green.shade700
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _fileName ?? 'PDF, JPG or PNG • Max 5MB',
                    style: TextStyle(
                      fontSize: 13,
                      color: _selectedFile != null
                          ? Colors.green.shade600
                          : Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_selectedFile != null) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.swap_horiz, size: 16),
                      label: const Text('Change File'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green.shade700,
                        side: BorderSide(color: Colors.green.shade400),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          _SectionHeader(
            icon: Icons.notes_outlined,
            title: 'Additional Notes (Optional)',
            subtitle:
                'Why did you choose this company? What do you hope to learn?',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _studentNotesController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Share your motivation and learning goals...',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              filled: true,
            ),
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  // ── Step 3: Review & Submit ──────────────────────────────────────────────

  Widget _buildStep3ReviewAndSubmit(ThemeData theme) {
    final totalWeeks = int.tryParse(_totalWeeksController.text) ?? 12;
    final endDate = _selectedStartDate?.add(Duration(days: totalWeeks * 7));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.fact_check_outlined,
            title: 'Review Your Application',
            subtitle:
                'Please confirm all details are correct before submitting',
          ),
          const SizedBox(height: 20),

          _ReviewCard(
            title: 'Company',
            icon: Icons.business,
            color: Colors.blue,
            items: {
              'Company Name': _selectedCompany?.name ?? 'Not selected',
              'Industry': _selectedCompany?.industry ?? 'N/A',
              'Location': _selectedCompany?.location ?? 'N/A',
            },
          ),
          const SizedBox(height: 12),

          _ReviewCard(
            title: 'Company Supervisor',
            icon: Icons.person,
            color: Colors.purple,
            items: {
              'Name': _supervisorNameController.text.trim().isEmpty
                  ? 'Not provided'
                  : _supervisorNameController.text.trim(),
              'Email': _supervisorEmailController.text.trim().isEmpty
                  ? 'Not provided'
                  : _supervisorEmailController.text.trim(),
              if (_supervisorPhoneController.text.trim().isNotEmpty)
                'Phone': _supervisorPhoneController.text.trim(),
            },
          ),
          const SizedBox(height: 12),

          // ── Who reviews this letter ──────────────────────────────────────
          if (_universitySupervisorName != null)
            _ReviewCard(
              title: 'University Supervisor',
              icon: Icons.school,
              color: Colors.teal,
              items: {
                'Reviewer': _universitySupervisorName!,
                'Action': 'Will approve or request changes',
              },
            ),
          const SizedBox(height: 12),

          _ReviewCard(
            title: 'Timeline',
            icon: Icons.schedule,
            color: Colors.orange,
            items: {
              'Start Date': _selectedStartDate != null
                  ? '${_selectedStartDate!.day}/${_selectedStartDate!.month}/${_selectedStartDate!.year}'
                  : 'Not specified',
              'End Date': endDate != null
                  ? '${endDate.day}/${endDate.month}/${endDate.year}'
                  : 'Not specified',
              'Duration': '$totalWeeks weeks',
            },
          ),
          const SizedBox(height: 12),

          _ReviewCard(
            title: 'Acceptance Letter',
            icon: Icons.description,
            color: Colors.green,
            items: {
              'File': _fileName ?? 'No file selected',
              'Status':
                  _selectedFile != null ? '✅ Ready to upload' : '❌ Missing',
            },
          ),

          const SizedBox(height: 24),

          // Info notice
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your letter will be sent directly to your assigned university supervisor for review. You will be notified of their decision.',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onPrimaryContainer,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  // ── Bottom navigation ────────────────────────────────────────────────────

  Widget _buildBottomNavigation(ThemeData theme) {
    final isLastStep = _currentStep == _totalSteps - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: isLastStep ? _submitApplication : _nextStep,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(isLastStep ? 'Submit Application' : 'Continue'),
                  const SizedBox(width: 8),
                  Icon(
                    isLastStep
                        ? Icons.send_rounded
                        : Icons.arrow_forward_rounded,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// REUSABLE WIDGETS
// ============================================================================

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 3),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final String? hint;

  const _StyledTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: Icon(icon),
        filled: true,
      ),
    );
  }
}

class _EmptyCompaniesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'No companies available at the moment. Please contact admin to add companies.',
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Map<String, String> items;

  const _ReviewCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            ...items.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          '${e.key}:',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          e.value,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
