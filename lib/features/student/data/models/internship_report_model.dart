import 'package:cloud_firestore/cloud_firestore.dart';

class InternshipReportModel {
  final String id;
  final String studentId;
  final String placementId;
  final String fileName;
  final String fileUrl;
  final String status;
  final String? supervisorFeedback;
  final String? reviewedBy;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const InternshipReportModel({
    required this.id,
    required this.studentId,
    required this.placementId,
    required this.fileName,
    required this.fileUrl,
    required this.status,
    this.supervisorFeedback,
    this.reviewedBy,
    this.submittedAt,
    this.reviewedAt,
    this.createdAt,
    this.updatedAt,
  });

  bool get isSubmitted => status.toLowerCase() == 'submitted';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';

  InternshipReportModel copyWith({
    String? id,
    String? studentId,
    String? placementId,
    String? fileName,
    String? fileUrl,
    String? status,
    String? supervisorFeedback,
    bool clearSupervisorFeedback = false,
    String? reviewedBy,
    bool clearReviewedBy = false,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    bool clearReviewedAt = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InternshipReportModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      placementId: placementId ?? this.placementId,
      fileName: fileName ?? this.fileName,
      fileUrl: fileUrl ?? this.fileUrl,
      status: status ?? this.status,
      supervisorFeedback: clearSupervisorFeedback
          ? null
          : supervisorFeedback ?? this.supervisorFeedback,
      reviewedBy: clearReviewedBy ? null : reviewedBy ?? this.reviewedBy,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: clearReviewedAt ? null : reviewedAt ?? this.reviewedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static InternshipReportModel fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    SnapshotOptions? options,
  ) {
    final data = doc.data() ?? <String, dynamic>{};

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return InternshipReportModel(
      id: doc.id,
      studentId: data['studentId'] as String? ?? '',
      placementId: data['placementId'] as String? ?? '',
      fileName: data['fileName'] as String? ?? '',
      fileUrl: data['fileUrl'] as String? ?? '',
      status: data['status'] as String? ?? 'submitted',
      supervisorFeedback: data['supervisorFeedback'] as String?,
      reviewedBy: data['reviewedBy'] as String?,
      submittedAt: parseDate(data['submittedAt']),
      reviewedAt: parseDate(data['reviewedAt']),
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'placementId': placementId,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'status': status,
      'supervisorFeedback': supervisorFeedback,
      'reviewedBy': reviewedBy,
      'submittedAt':
          submittedAt != null ? Timestamp.fromDate(submittedAt!) : null,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}
