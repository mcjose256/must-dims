import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/controllers/auth_controller.dart';
import '../data/training_schedule_item.dart';

const sharedTrainingTimelineKey = 'shared_timeline';

final trainingScheduleCollectionProvider =
    StreamProvider<List<TrainingScheduleItem>>((ref) {
  final firestore = ref.watch(firestoreProvider);

  return firestore
      .collection('industrial_training_schedule')
      .snapshots()
      .map((snapshot) {
    final items = snapshot.docs
        .map(TrainingScheduleItem.fromFirestore)
        .where(
          (item) =>
              item.title.trim().isNotEmpty && item.dateRange.trim().isNotEmpty,
        )
        .toList()
      ..sort((a, b) {
        final orderCompare = a.order.compareTo(b.order);
        if (orderCompare != 0) {
          return orderCompare;
        }

        return a.title.compareTo(b.title);
      });

    return items;
  });
});

final visibleTrainingScheduleProvider = Provider<List<TrainingScheduleItem>>((
  ref,
) {
  final items = ref.watch(trainingScheduleCollectionProvider).value ?? const [];
  return items.where((item) => item.isVisible).toList(growable: false);
});

final effectiveVisibleTrainingScheduleProvider =
    Provider<List<TrainingScheduleItem>>((ref) {
  final configuredItems = ref.watch(visibleTrainingScheduleProvider);

  if (configuredItems.isNotEmpty) {
    return configuredItems;
  }

  return defaultTrainingScheduleForKey(sharedTrainingTimelineKey);
});

final trainingScheduleControllerProvider = Provider((ref) {
  return TrainingScheduleController(ref);
});

List<TrainingScheduleItem> defaultTrainingScheduleForKey(String timelineKey) {
  final normalizedKey = timelineKey.trim().isEmpty
      ? sharedTrainingTimelineKey
      : timelineKey.trim();

  return defaultTrainingScheduleSeed
      .map(
        (item) => item.copyWith(
          academicYear: normalizedKey,
        ),
      )
      .toList(growable: false);
}

class TrainingScheduleController {
  TrainingScheduleController(this._ref);

  final Ref _ref;

  FirebaseFirestore get _db => _ref.read(firestoreProvider);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('industrial_training_schedule');

  Future<void> saveItem(TrainingScheduleItem item) async {
    final now = DateTime.now();
    final payload = item
        .copyWith(
          createdAt: item.createdAt ?? now,
          updatedAt: now,
          academicYear: item.academicYear.trim().isEmpty
              ? sharedTrainingTimelineKey
              : item.academicYear.trim(),
        )
        .toFirestore();

    if (item.id.isEmpty) {
      await _collection.add(payload);
      return;
    }

    await _collection.doc(item.id).set(payload, SetOptions(merge: true));
  }

  Future<void> deleteItem(String id) async {
    await _collection.doc(id).delete();
  }

  Future<void> setVisibility({
    required String id,
    required bool isVisible,
  }) async {
    await _collection.doc(id).update({
      'isVisible': isVisible,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> seedDefaultSchedule({
    String academicYear = sharedTrainingTimelineKey,
  }) async {
    final existing = await _collection.limit(1).get();

    if (existing.docs.isNotEmpty) {
      return;
    }

    final batch = _db.batch();
    final now = DateTime.now();

    for (final item in defaultTrainingScheduleSeed) {
      final doc = _collection.doc();
      batch.set(
        doc,
        item
            .copyWith(
              id: doc.id,
              academicYear: academicYear,
              createdAt: now,
              updatedAt: now,
            )
            .toFirestore(),
      );
    }

    await batch.commit();
  }
}

const defaultTrainingScheduleSeed = [
  TrainingScheduleItem(
    id: '',
    title: 'Students Industrial training orientation workshop',
    dateRange: '5/6/7/8 November 2024',
    personInCharge:
        'Industrial Training Coordinator and all FCI BIT2, BSE2, BSE3, & BCS2 students',
    academicYear: '2024/2025',
    description: null,
    order: 1,
    isVisible: true,
  ),
  TrainingScheduleItem(
    id: '',
    title:
        'Survey of Industrial Training Places and delivery of letters of appreciation',
    dateRange: '7th January 2025 - 15th March 2025',
    personInCharge: 'FCI Industrial Training Coordination office',
    academicYear: '2024/2025',
    description: null,
    order: 2,
    isVisible: true,
  ),
  TrainingScheduleItem(
    id: '',
    title:
        'Handing in of the signed list of students and their training places to the coordinator',
    dateRange: '30th April 2025',
    personInCharge: 'All teaching staff (supervising)',
    academicYear: '2024/2025',
    description: null,
    order: 3,
    isVisible: true,
  ),
  TrainingScheduleItem(
    id: '',
    title: 'Industrial Training Supervisors\' Orientation Workshop',
    dateRange: '28th May 2025 (8:30am - 11:30am)',
    personInCharge: 'All teaching staff (supervising) - coordinator',
    academicYear: '2024/2025',
    description: null,
    order: 4,
    isVisible: true,
  ),
  TrainingScheduleItem(
    id: '',
    title: 'Industrial Training Period',
    dateRange: '2nd June 2025 - 31st July 2025',
    personInCharge: 'All FCI BIT2, BSE2, BSE3, & BCS2 students',
    academicYear: '2024/2025',
    description: null,
    order: 5,
    isVisible: true,
  ),
  TrainingScheduleItem(
    id: '',
    title:
        '1st Supervision by Staff (Supervisors), confirming presence at training places and progress of training, 1st oral interview with students',
    dateRange: '23rd June 2025 - 30th June 2025',
    personInCharge: 'All teaching staff (supervising)',
    academicYear: '2024/2025',
    description: null,
    order: 6,
    isVisible: true,
  ),
  TrainingScheduleItem(
    id: '',
    title:
        'Submission of draft Industrial training Report via Emails for supervisor review (Word Format)',
    dateRange: '30th June 2025 - 5th July 2025',
    personInCharge:
        'All FCI BIT2, BSE2, BSE3, & BCS2 students (ends only after supervisor approval)',
    academicYear: '2024/2025',
    description: null,
    order: 7,
    isVisible: true,
  ),
  TrainingScheduleItem(
    id: '',
    title:
        '2nd Supervision by Staff (Supervisors), 2nd oral interview, discussion of draft report comments, and collection of company supervisor marks sheet',
    dateRange: '24th July 2025 - 31st July 2025',
    personInCharge: 'All teaching staff (supervising)',
    academicYear: '2024/2025',
    description: null,
    order: 8,
    isVisible: true,
  ),
  TrainingScheduleItem(
    id: '',
    title:
        'Submission of Final Industrial Training Report for supervisor assessment and final marks (PDF Format)',
    dateRange: '1st August 2024 - 9th August 2024',
    personInCharge:
        'All FCI BIT2, BSE2, BSE3, & BCS2 students (failure to submit means direct retake)',
    academicYear: '2024/2025',
    description: null,
    order: 9,
    isVisible: true,
  ),
  TrainingScheduleItem(
    id: '',
    title:
        'Handing in of the Supervisor Supervision Report and entering final Industrial Training marks',
    dateRange: '9th August 2025 - 13th August 2025',
    personInCharge: 'All teaching staff (supervising)',
    academicYear: '2024/2025',
    description: null,
    order: 10,
    isVisible: true,
  ),
  TrainingScheduleItem(
    id: '',
    title:
        'Accountability of all Industrial Training activities and compiling final Industrial Training Supervision Report 2025',
    dateRange: '14th August 2025 - 15th August 2025',
    personInCharge: 'Industrial Training Coordinator',
    academicYear: '2024/2025',
    description: null,
    order: 11,
    isVisible: true,
  ),
];
