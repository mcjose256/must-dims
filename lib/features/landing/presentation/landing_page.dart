// lib/features/landing/presentation/landing_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _mustGreen = Color(0xFF1B5E20);
const _mustGreenLight = Color(0xFF2E7D32);
const _mustGold = Color(0xFFF9A825);
const _slideLabels = ['Welcome', 'Stories', 'Requirements'];

// ============================================================================
// FIRESTORE PROVIDERS
// ============================================================================

final landingStatsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('landing_stats')
      .orderBy('order')
      .snapshots()
      .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());
});

final successStoriesProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('success_stories')
      .snapshots()
      .map((snapshot) {
    final stories = snapshot.docs
        .map((doc) => {...doc.data(), 'id': doc.id})
        .where((story) => story['isVisible'] != false)
        .toList();

    stories.sort((a, b) {
      final aOrder = (a['order'] as num?)?.toInt() ?? 0;
      final bOrder = (b['order'] as num?)?.toInt() ?? 0;
      if (aOrder != bOrder) return aOrder.compareTo(bOrder);

      final aName = (a['name'] ?? '').toString().toLowerCase();
      final bName = (b['name'] ?? '').toString().toLowerCase();
      return aName.compareTo(bName);
    });

    return stories;
  });
});

final internshipRequirementsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('internship_requirements')
      .orderBy('order')
      .snapshots()
      .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());
});

// ============================================================================
// LANDING PAGE
// ============================================================================

class LandingPage extends ConsumerStatefulWidget {
  const LandingPage({super.key});

  @override
  ConsumerState<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends ConsumerState<LandingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const _totalSlides = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalSlides - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Slides ─────────────────────────────────────────────
          PageView(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: const [
              _StatsSlide(),
              _StoriesSlide(),
              _RequirementsSlide(),
            ],
          ),

          // ── Top bar ────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Container(
                        key: ValueKey<int>(_currentPage),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _currentPage == 0
                              ? Colors.white.withOpacity(0.14)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: _currentPage == 0
                                ? Colors.white.withOpacity(0.18)
                                : _mustGreen.withOpacity(0.08),
                          ),
                        ),
                        child: Text(
                          _slideLabels[_currentPage],
                          style: TextStyle(
                            color:
                                _currentPage == 0 ? Colors.white : _mustGreen,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_currentPage < _totalSlides - 1)
                    TextButton(
                      onPressed: () => _pageController.animateToPage(
                        _totalSlides - 1,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      ),
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: _currentPage == 0
                              ? Colors.white.withOpacity(0.86)
                              : Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Bottom navigation bar ───────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _totalSlides,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _currentPage ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _currentPage
                              ? _mustGreen
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Navigation buttons
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 380;

                      if (_currentPage < _totalSlides - 1) {
                        return Row(
                          children: [
                            if (_currentPage > 0)
                              IconButton(
                                onPressed: _prevPage,
                                icon: const Icon(Icons.arrow_back_ios_rounded),
                                color: _mustGreen,
                              )
                            else
                              const SizedBox(width: 48),
                            const Spacer(),
                            FilledButton(
                              onPressed: _nextPage,
                              style: FilledButton.styleFrom(
                                backgroundColor: _mustGreen,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Next',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold)),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_ios_rounded,
                                      size: 14),
                                ],
                              ),
                            ),
                          ],
                        );
                      }

                      if (compact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            OutlinedButton(
                              onPressed: () => context.go('/login'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _mustGreen,
                                side: const BorderSide(
                                    color: _mustGreen, width: 1.5),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Log In',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                            ),
                            const SizedBox(height: 10),
                            FilledButton(
                              onPressed: () => context.go('/register'),
                              style: FilledButton.styleFrom(
                                backgroundColor: _mustGold,
                                foregroundColor: Colors.black87,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Register',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => context.go('/login'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _mustGreen,
                                side: const BorderSide(
                                    color: _mustGreen, width: 1.5),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Log In',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => context.go('/register'),
                              style: FilledButton.styleFrom(
                                backgroundColor: _mustGold,
                                foregroundColor: Colors.black87,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Register',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                            ),
                          ),
                        ],
                      );
                    },
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
// SLIDE 1 — STATS
// ============================================================================

// Stat model using IconData instead of emoji
class _StatItem {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final String? note;
  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.note,
  });
}

class _StatsSlide extends ConsumerWidget {
  const _StatsSlide();

  // Fallback stats with proper Flutter icons
  static const _fallback = [
    _StatItem(
      icon: Icons.school_rounded,
      iconColor: _mustGreen,
      value: '500+',
      label: 'Students Placed',
      note: 'Students successfully attached to host organisations.',
    ),
    _StatItem(
      icon: Icons.business_rounded,
      iconColor: Colors.blue,
      value: '120+',
      label: 'Partner Companies',
      note: 'Approved companies available for placement and supervision.',
    ),
    _StatItem(
      icon: Icons.verified_rounded,
      iconColor: Colors.green,
      value: '94%',
      label: 'Completion Rate',
      note: 'Internships completed with the required logbook cycle.',
    ),
    _StatItem(
      icon: Icons.calendar_month_rounded,
      iconColor: _mustGold,
      value: '12',
      label: 'Weeks Duration',
      note: 'Standard internship duration tracked in the platform.',
    ),
  ];

  List<_StatItem> _buildStats(List<Map<String, dynamic>> stats) {
    if (stats.isEmpty) return _fallback;

    return List.generate(stats.length, (index) {
      final stat = stats[index];
      final label = (stat['label'] ??
              stat['title'] ??
              stat['name'] ??
              'Metric ${index + 1}')
          .toString();
      final value =
          (stat['value'] ?? stat['count'] ?? stat['total'] ?? '--').toString();
      final note =
          (stat['description'] ?? stat['subtitle'] ?? stat['note'])?.toString();
      final appearance = _statAppearanceForLabel(label, index: index);

      return _StatItem(
        icon: appearance.icon,
        iconColor: appearance.color,
        value: value,
        label: label,
        note: note == null || note.trim().isEmpty ? null : note.trim(),
      );
    });
  }

  _StatAppearance _statAppearanceForLabel(String label, {required int index}) {
    final normalized = label.toLowerCase();

    if (normalized.contains('student')) {
      return const _StatAppearance(Icons.school_rounded, _mustGreen);
    }
    if (normalized.contains('company') || normalized.contains('partner')) {
      return const _StatAppearance(Icons.business_rounded, Colors.blue);
    }
    if (normalized.contains('supervisor')) {
      return const _StatAppearance(Icons.groups_rounded, Colors.indigo);
    }
    if (normalized.contains('placement')) {
      return const _StatAppearance(Icons.work_history_rounded, Colors.teal);
    }
    if (normalized.contains('completion') ||
        normalized.contains('approved') ||
        normalized.contains('success')) {
      return const _StatAppearance(Icons.verified_rounded, Colors.green);
    }
    if (normalized.contains('week') ||
        normalized.contains('duration') ||
        normalized.contains('time')) {
      return const _StatAppearance(Icons.calendar_month_rounded, _mustGold);
    }
    if (normalized.contains('report')) {
      return const _StatAppearance(Icons.assessment_rounded, Colors.deepOrange);
    }

    const fallbackPalette = [
      _StatAppearance(Icons.school_rounded, _mustGreen),
      _StatAppearance(Icons.business_rounded, Colors.blue),
      _StatAppearance(Icons.verified_rounded, Colors.green),
      _StatAppearance(Icons.calendar_month_rounded, _mustGold),
      _StatAppearance(Icons.groups_rounded, Colors.indigo),
      _StatAppearance(Icons.work_history_rounded, Colors.teal),
    ];

    return fallbackPalette[index % fallbackPalette.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(landingStatsProvider);

    return SingleChildScrollView(
      child: Column(
        children: [
          // ── Hero header with logo ────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 100, 24, 36),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_mustGreen, _mustGreenLight],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Primary brand block
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: _mustGold, width: 2),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/icons/must logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MUST · DIMS',
                          style: TextStyle(
                            color: _mustGold,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          'Digital Internship Management System',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Connecting Students\nto Opportunities',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Mbarara University of Science and Technology\'s '
                  'official internship management platform.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // ── Stats grid ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Platform Snapshot',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _mustGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Structured figures from the DIMS platform.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 20),

                statsAsync.when(
                  data: (stats) {
                    final items = _buildStats(stats);
                    return _StatsTableCard(items: items);
                  },
                  loading: () => const _StatsTableCard(items: _fallback),
                  error: (_, __) => const _StatsTableCard(items: _fallback),
                ),

                const SizedBox(height: 110), // space for bottom bar
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatAppearance {
  final IconData icon;
  final Color color;

  const _StatAppearance(this.icon, this.color);
}

class _StatsTableCard extends StatelessWidget {
  final List<_StatItem> items;

  const _StatsTableCard({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _mustGreen.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ...List.generate(items.length, (index) {
            final item = items[index];
            return _StatsTableRow(
              item: item,
              showDivider: index < items.length - 1,
              striped: index.isOdd,
              isFirst: index == 0,
              isLast: index == items.length - 1,
            );
          }),
        ],
      ),
    );
  }
}

class _StatsTableRow extends StatelessWidget {
  final _StatItem item;
  final bool showDivider;
  final bool striped;
  final bool isFirst;
  final bool isLast;

  const _StatsTableRow({
    required this.item,
    required this.showDivider,
    required this.striped,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: striped ? _mustGreen.withOpacity(0.015) : Colors.white,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(18) : Radius.zero,
          bottom: isLast ? const Radius.circular(18) : Radius.zero,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: item.iconColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          item.icon,
                          color: item.iconColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.label,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                            if (item.note != null) ...[
                              const SizedBox(height: 3),
                              Text(
                                item.note!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  item.value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _mustGreen,
                  ),
                ),
              ],
            ),
          ),
          if (showDivider)
            Divider(
              height: 1,
              thickness: 1,
              color: _mustGreen.withOpacity(0.08),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// SLIDE 2 - SUCCESS STORIES
// ============================================================================

class _StoriesSlide extends ConsumerWidget {
  const _StoriesSlide();

  static const _fallback = [
    {
      'name': 'Nakamya Sarah',
      'program': 'BSc Computer Science, 2023',
      'company': 'MTN Uganda',
      'quote':
          'DIMS made the placement process seamless. I got placed at MTN within two weeks and the logbook kept me accountable.',
      'initials': 'NS',
    },
    {
      'name': 'Tumusiime Brian',
      'program': 'BSc Information Technology, 2022',
      'company': 'NITA-U',
      'quote':
          'The digital logbook was a game changer. My supervisor reviewed my work in real time and feedback came within days.',
      'initials': 'TB',
    },
    {
      'name': 'Atuhaire Grace',
      'program': 'BSc Software Engineering, 2023',
      'company': 'Andela Uganda',
      'quote':
          'Everything from letter submission to final evaluation was handled professionally through DIMS.',
      'initials': 'AG',
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(successStoriesProvider);

    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 100, 24, 28),
          decoration: BoxDecoration(
            color: _mustGreen.withOpacity(0.05),
            border:
                Border(bottom: BorderSide(color: _mustGreen.withOpacity(0.1))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.format_quote_rounded,
                      color: _mustGold, size: 28),
                  const SizedBox(width: 8),
                  const Text(
                    'Success Stories',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _mustGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Real experiences from MUST interns',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),

        Expanded(
          child: storiesAsync.when(
            data: (stories) {
              final items = stories.isNotEmpty ? stories : _fallback;
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (_, i) {
                  final s = items[i];
                  return _StoryCard(
                    name: s['name'] as String? ?? '',
                    program: s['program'] as String? ?? '',
                    company: s['company'] as String? ?? '',
                    quote: s['quote'] as String? ?? '',
                    initials: s['initials'] as String? ?? 'S',
                    imageUrl: s['imageUrl'] as String?,
                  );
                },
              );
            },
            loading: () => _buildList(_fallback),
            error: (_, __) => _buildList(_fallback),
          ),
        ),
      ],
    );
  }

  Widget _buildList(List items) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, i) => _StoryCard(
        name: items[i]['name']!,
        program: items[i]['program']!,
        company: items[i]['company']!,
        quote: items[i]['quote']!,
        initials: items[i]['initials']!,
        imageUrl: items[i]['imageUrl'] as String?,
      ),
    );
  }
}

// ============================================================================
// SLIDE 3 — REQUIREMENTS
// ============================================================================

class _Requirement {
  final IconData icon;
  final Color iconColor;
  final String step;
  final String title;
  final String description;
  const _Requirement({
    required this.icon,
    required this.iconColor,
    required this.step,
    required this.title,
    required this.description,
  });
}

class _RequirementsSlide extends ConsumerWidget {
  const _RequirementsSlide();

  static const _fallback = [
    _Requirement(
      icon: Icons.school_rounded,
      iconColor: _mustGreen,
      step: '1',
      title: 'Be a Registered MUST Student',
      description:
          'You must be an active student at Mbarara University of Science and Technology in a qualifying programme.',
    ),
    _Requirement(
      icon: Icons.person_outline_rounded,
      iconColor: Colors.blue,
      step: '2',
      title: 'Complete Your Profile',
      description:
          'Fill in your registration number, programme, and academic year on the DIMS platform before applying.',
    ),
    _Requirement(
      icon: Icons.business_rounded,
      iconColor: Colors.indigo,
      step: '3',
      title: 'Secure a Host Organisation',
      description:
          'Find and confirm a company or institution willing to host you for the internship period (minimum 12 weeks).',
    ),
    _Requirement(
      icon: Icons.upload_file_rounded,
      iconColor: _mustGold,
      step: '4',
      title: 'Upload Acceptance Letter',
      description:
          'Obtain an official acceptance letter from your host organisation and upload it on DIMS for supervisor review.',
    ),
    _Requirement(
      icon: Icons.book_rounded,
      iconColor: Colors.orange,
      step: '5',
      title: 'Maintain a Daily Logbook',
      description:
          'Record your daily activities and submit weekly summaries through the DIMS logbook for supervisor feedback.',
    ),
    _Requirement(
      icon: Icons.verified_rounded,
      iconColor: Colors.green,
      step: '6',
      title: 'Final Evaluation',
      description:
          'Both your company and university supervisors will submit a final evaluation on completion of your internship.',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reqAsync = ref.watch(internshipRequirementsProvider);

    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 100, 24, 28),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_mustGreen, _mustGreenLight],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.checklist_rounded,
                      color: _mustGold, size: 26),
                  const SizedBox(width: 8),
                  const Text(
                    'Requirements',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'What you need to get started at MUST',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.8), fontSize: 13),
              ),
            ],
          ),
        ),

        Expanded(
          child: reqAsync.when(
            data: (reqs) {
              // Use Firestore title+description, keep Flutter icons
              final items = reqs.isNotEmpty
                  ? List.generate(
                      reqs.length > _fallback.length
                          ? _fallback.length
                          : reqs.length,
                      (i) => _Requirement(
                        icon: _fallback[
                                i < _fallback.length ? i : _fallback.length - 1]
                            .icon,
                        iconColor: _fallback[
                                i < _fallback.length ? i : _fallback.length - 1]
                            .iconColor,
                        step: '${i + 1}',
                        title:
                            reqs[i]['title'] as String? ?? _fallback[i].title,
                        description: reqs[i]['description'] as String? ??
                            _fallback[i].description,
                      ),
                    )
                  : _fallback;
              return _buildList(items);
            },
            loading: () => _buildList(_fallback),
            error: (_, __) => _buildList(_fallback),
          ),
        ),
      ],
    );
  }

  Widget _buildList(List<_Requirement> items) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _RequirementCard(req: items[i]),
    );
  }
}

// ============================================================================
// REUSABLE CARD WIDGETS
// ============================================================================

class _StoryCard extends StatelessWidget {
  final String name;
  final String program;
  final String company;
  final String quote;
  final String initials;
  final String? imageUrl;

  const _StoryCard({
    required this.name,
    required this.program,
    required this.company,
    required this.quote,
    required this.initials,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasImage)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.network(
                imageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.format_quote_rounded,
                  color: _mustGold,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  quote,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: _mustGreen,
                      backgroundImage:
                          hasImage ? NetworkImage(imageUrl!) : null,
                      child: hasImage
                          ? null
                          : Text(
                              initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _mustGreen,
                            ),
                          ),
                          Text(
                            '$program • $company',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequirementCard extends StatelessWidget {
  final _Requirement req;
  const _RequirementCard({required this.req});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _mustGreen.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: req.iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(req.icon, color: req.iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _mustGold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Step ${req.step}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _mustGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  req.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: _mustGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  req.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
