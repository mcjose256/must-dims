import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final successStoriesManagementProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('success_stories')
      .orderBy('order')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => {...doc.data(), 'id': doc.id})
            .toList(),
      );
});

class SuccessStoriesManagementPage extends ConsumerStatefulWidget {
  const SuccessStoriesManagementPage({super.key});

  @override
  ConsumerState<SuccessStoriesManagementPage> createState() =>
      _SuccessStoriesManagementPageState();
}

class _SuccessStoriesManagementPageState
    extends ConsumerState<SuccessStoriesManagementPage> {
  String _searchQuery = '';

  List<Map<String, dynamic>> _filterStories(List<Map<String, dynamic>> stories) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return stories;

    return stories.where((story) {
      final text = [
        story['name'] ?? '',
        story['program'] ?? '',
        story['company'] ?? '',
        story['quote'] ?? '',
      ].join(' ').toLowerCase();
      return text.contains(query);
    }).toList();
  }

  void _openStoryForm({Map<String, dynamic>? story}) {
    showDialog<void>(
      context: context,
      builder: (context) => _SuccessStoryFormDialog(story: story),
    );
  }

  Future<void> _toggleVisibility(Map<String, dynamic> story) async {
    final storyId = story['id'] as String?;
    if (storyId == null) return;

    await FirebaseFirestore.instance
        .collection('success_stories')
        .doc(storyId)
        .update({
      'isVisible': !(story['isVisible'] as bool? ?? true),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _deleteStory(Map<String, dynamic> story) async {
    final storyId = story['id'] as String?;
    if (storyId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Success Story'),
        content: const Text('This success story will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final imageUrl = story['imageUrl'] as String?;
    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      try {
        await FirebaseStorage.instance.refFromURL(imageUrl).delete();
      } catch (_) {}
    }

    await FirebaseFirestore.instance
        .collection('success_stories')
        .doc(storyId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final storiesAsync = ref.watch(successStoriesManagementProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Success Stories'),
        actions: [
          IconButton(
            onPressed: () => _openStoryForm(),
            icon: const Icon(Icons.add_photo_alternate_outlined),
            tooltip: 'Add Story',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search stories',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor:
                    theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: storiesAsync.when(
              data: (stories) {
                final filteredStories = _filterStories(stories);

                if (stories.isEmpty) {
                  return _SuccessStoryEmptyState(
                    onAdd: () => _openStoryForm(),
                  );
                }

                if (filteredStories.isEmpty) {
                  return const _SuccessStoryMessageState(
                    icon: Icons.search_off_rounded,
                    title: 'No matching stories',
                    description: 'Try another search term.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(successStoriesManagementProvider);
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: filteredStories.length,
                    itemBuilder: (context, index) {
                      final story = filteredStories[index];
                      return _SuccessStoryCard(
                        story: story,
                        onEdit: () => _openStoryForm(story: story),
                        onToggleVisibility: () => _toggleVisibility(story),
                        onDelete: () => _deleteStory(story),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _SuccessStoryMessageState(
                icon: Icons.error_outline_rounded,
                title: 'Unable to load stories',
                description: '$error',
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openStoryForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Story'),
      ),
    );
  }
}

class _SuccessStoryCard extends StatelessWidget {
  final Map<String, dynamic> story;
  final VoidCallback onEdit;
  final VoidCallback onToggleVisibility;
  final VoidCallback onDelete;

  const _SuccessStoryCard({
    required this.story,
    required this.onEdit,
    required this.onToggleVisibility,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = (story['name'] ?? 'Unnamed Story').toString();
    final program = (story['program'] ?? '').toString();
    final company = (story['company'] ?? '').toString();
    final quote = (story['quote'] ?? '').toString();
    final initials = (story['initials'] ?? _buildInitials(name)).toString();
    final imageUrl = (story['imageUrl'] ?? '').toString();
    final isVisible = story['isVisible'] as bool? ?? true;
    final order = story['order'];

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
                _StoryAvatar(
                  initials: initials,
                  imageUrl: imageUrl,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [program, company]
                            .where((item) => item.trim().isNotEmpty)
                            .join(' • '),
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _StoryMetaChip(
                            label: isVisible ? 'Visible' : 'Hidden',
                            color: isVisible ? Colors.green : Colors.orange,
                          ),
                          _StoryMetaChip(
                            label: 'Order ${order ?? 0}',
                            color: Colors.blueGrey,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                        break;
                      case 'toggle':
                        onToggleVisibility();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(isVisible ? 'Hide' : 'Show'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
            if (quote.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                quote,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.45,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StoryAvatar extends StatelessWidget {
  final String initials;
  final String imageUrl;

  const _StoryAvatar({
    required this.initials,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          imageUrl,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _FallbackAvatar(initials: initials),
        ),
      );
    }

    return _FallbackAvatar(initials: initials);
  }
}

class _FallbackAvatar extends StatelessWidget {
  final String initials;

  const _FallbackAvatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20).withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Color(0xFF1B5E20),
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
    );
  }
}

class _StoryMetaChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StoryMetaChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
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

class _SuccessStoryEmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _SuccessStoryEmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return _SuccessStoryMessageState(
      icon: Icons.auto_stories_outlined,
      title: 'No stories yet',
      description: 'Add success stories for the landing page.',
      action: FilledButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add),
        label: const Text('Add Story'),
      ),
    );
  }
}

class _SuccessStoryMessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget? action;

  const _SuccessStoryMessageState({
    required this.icon,
    required this.title,
    required this.description,
    this.action,
  });

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
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class _SuccessStoryFormDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? story;

  const _SuccessStoryFormDialog({this.story});

  @override
  ConsumerState<_SuccessStoryFormDialog> createState() =>
      _SuccessStoryFormDialogState();
}

class _SuccessStoryFormDialogState
    extends ConsumerState<_SuccessStoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _programController;
  late final TextEditingController _companyController;
  late final TextEditingController _quoteController;
  late final TextEditingController _initialsController;
  late final TextEditingController _orderController;

  File? _selectedImage;
  bool _removeCurrentImage = false;
  bool _isVisible = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final story = widget.story;
    _nameController = TextEditingController(text: (story?['name'] ?? '').toString());
    _programController =
        TextEditingController(text: (story?['program'] ?? '').toString());
    _companyController =
        TextEditingController(text: (story?['company'] ?? '').toString());
    _quoteController =
        TextEditingController(text: (story?['quote'] ?? '').toString());
    _initialsController =
        TextEditingController(text: (story?['initials'] ?? '').toString());
    _orderController = TextEditingController(
      text: (story?['order'] ?? 0).toString(),
    );
    _isVisible = story?['isVisible'] as bool? ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _programController.dispose();
    _companyController.dispose();
    _quoteController.dispose();
    _initialsController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'heic'],
    );

    final path = result?.files.single.path;
    if (path == null) return;

    setState(() {
      _selectedImage = File(path);
      _removeCurrentImage = false;
    });
  }

  Future<void> _saveStory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final stories = FirebaseFirestore.instance.collection('success_stories');
      final existingStory = widget.story;
      final existingImageUrl = (existingStory?['imageUrl'] ?? '').toString();
      var imageUrl = existingImageUrl.trim().isEmpty ? null : existingImageUrl;

      if (_selectedImage != null) {
        final filename = _selectedImage!.path.split(RegExp(r'[\\/]')).last;
        final storageRef = FirebaseStorage.instance.ref().child(
          'success_stories/${DateTime.now().millisecondsSinceEpoch}_$filename',
        );
        await storageRef.putFile(_selectedImage!);
        imageUrl = await storageRef.getDownloadURL();

        if (existingImageUrl.trim().isNotEmpty) {
          try {
            await FirebaseStorage.instance.refFromURL(existingImageUrl).delete();
          } catch (_) {}
        }
      } else if (_removeCurrentImage && existingImageUrl.trim().isNotEmpty) {
        try {
          await FirebaseStorage.instance.refFromURL(existingImageUrl).delete();
        } catch (_) {}
        imageUrl = null;
      }

      final name = _nameController.text.trim();
      final initials = _initialsController.text.trim().isEmpty
          ? _buildInitials(name)
          : _initialsController.text.trim().toUpperCase();

      final payload = <String, dynamic>{
        'name': name,
        'program': _programController.text.trim(),
        'company': _companyController.text.trim(),
        'quote': _quoteController.text.trim(),
        'initials': initials,
        'order': int.tryParse(_orderController.text.trim()) ?? 0,
        'isVisible': _isVisible,
        'imageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (existingStory == null) {
        payload['createdAt'] = FieldValue.serverTimestamp();
        await stories.add(payload);
      } else {
        await stories.doc(existingStory['id'] as String).set(
          payload,
          SetOptions(merge: true),
        );
      }

      if (mounted) {
        Navigator.pop(context);
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
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final existingImageUrl = (widget.story?['imageUrl'] ?? '').toString();
    final hasExistingImage =
        existingImageUrl.trim().isNotEmpty && !_removeCurrentImage;

    return AlertDialog(
      title: Text(widget.story == null ? 'Add Success Story' : 'Edit Success Story'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Story Image',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (_selectedImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      _selectedImage!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                else if (hasExistingImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      existingImageUrl,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _ImagePlaceholderCard(
                        label: 'Image unavailable',
                      ),
                    ),
                  )
                else
                  const _ImagePlaceholderCard(label: 'No image selected'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isSaving ? null : _pickImage,
                      icon: const Icon(Icons.image_outlined),
                      label: Text(_selectedImage == null ? 'Choose Image' : 'Replace Image'),
                    ),
                    if (_selectedImage != null || hasExistingImage)
                      TextButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () {
                                setState(() {
                                  _selectedImage = null;
                                  if (hasExistingImage) {
                                    _removeCurrentImage = true;
                                  }
                                });
                              },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Remove'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Student Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _programController,
                  decoration: const InputDecoration(
                    labelText: 'Program',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _companyController,
                  decoration: const InputDecoration(
                    labelText: 'Company',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _quoteController,
                  decoration: const InputDecoration(
                    labelText: 'Quote',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _initialsController,
                        decoration: const InputDecoration(
                          labelText: 'Initials',
                          border: OutlineInputBorder(),
                        ),
                        maxLength: 4,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _orderController,
                        decoration: const InputDecoration(
                          labelText: 'Order',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  value: _isVisible,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Visible on landing page'),
                  onChanged: _isSaving
                      ? null
                      : (value) => setState(() => _isVisible = value),
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
          onPressed: _isSaving ? null : _saveStory,
          child: Text(_isSaving ? 'Saving...' : 'Save Story'),
        ),
      ],
    );
  }
}

class _ImagePlaceholderCard extends StatelessWidget {
  final String label;

  const _ImagePlaceholderCard({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.18),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

String _buildInitials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();

  if (parts.isEmpty) return 'SS';
  if (parts.length == 1) {
    final single = parts.first;
    return single.substring(0, single.length >= 2 ? 2 : 1).toUpperCase();
  }

  return (parts.first[0] + parts.last[0]).toUpperCase();
}
