import 'package:cloud_firestore/cloud_firestore.dart';

class TrainingScheduleItem {
  final String id;
  final String title;
  final String dateRange;
  final String personInCharge;
  final String academicYear;
  final String? description;
  final int order;
  final bool isVisible;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TrainingScheduleItem({
    required this.id,
    required this.title,
    required this.dateRange,
    required this.personInCharge,
    required this.academicYear,
    this.description,
    required this.order,
    required this.isVisible,
    this.createdAt,
    this.updatedAt,
  });

  TrainingScheduleItem copyWith({
    String? id,
    String? title,
    String? dateRange,
    String? personInCharge,
    String? academicYear,
    String? description,
    int? order,
    bool? isVisible,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TrainingScheduleItem(
      id: id ?? this.id,
      title: title ?? this.title,
      dateRange: dateRange ?? this.dateRange,
      personInCharge: personInCharge ?? this.personInCharge,
      academicYear: academicYear ?? this.academicYear,
      description: description ?? this.description,
      order: order ?? this.order,
      isVisible: isVisible ?? this.isVisible,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static TrainingScheduleItem fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    String? normalizeOptionalText(dynamic value) {
      if (value == null) return null;
      final trimmed = value.toString().trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    return TrainingScheduleItem(
      id: doc.id,
      title: (data['title'] as String? ?? '').trim(),
      dateRange: (data['dateRange'] as String? ?? '').trim(),
      personInCharge: (data['personInCharge'] as String? ?? '').trim(),
      academicYear: (data['academicYear'] as String? ?? '').trim(),
      description: normalizeOptionalText(data['description']),
      order: (data['order'] as num?)?.toInt() ?? 0,
      isVisible: data['isVisible'] as bool? ?? true,
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{
      'title': title.trim(),
      'dateRange': dateRange.trim(),
      'personInCharge': personInCharge.trim(),
      'academicYear': academicYear.trim(),
      'order': order,
      'isVisible': isVisible,
    };

    final normalizedDescription = description?.trim();
    if (normalizedDescription != null && normalizedDescription.isNotEmpty) {
      map['description'] = normalizedDescription;
    }

    if (createdAt != null) {
      map['createdAt'] = Timestamp.fromDate(createdAt!);
    }

    if (updatedAt != null) {
      map['updatedAt'] = Timestamp.fromDate(updatedAt!);
    }

    return map;
  }
}
