import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

enum UserRole { 
  student, 
  supervisor, 
  admin 
}

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String uid,
    required String email,
    required UserRole role,
    String? displayName,
    String? phoneNumber,
    String? photoUrl,
    @Default(false) bool isApproved,
    DateTime? createdAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  /// Robust conversion from Firestore Document
  static UserModel fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    SnapshotOptions? options,
  ) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Document data is null');
    }

    // 1. Manually parse the Role to ensure it matches the Enum safely
    final roleStr = data['role'] as String?;
    final role = UserRole.values.firstWhere(
      (e) => e.name == roleStr,
      orElse: () => UserRole.student,
    );

    // 2. Handle Date parsing for String, Timestamp, or null
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    // 3. Construct the model manually to avoid 'json_serializable' type errors
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      role: role,
      displayName: data['displayName'],
      phoneNumber: data['phoneNumber'],
      photoUrl: data['photoUrl'],
      isApproved: data['isApproved'] ?? false,
      createdAt: parseDate(data['createdAt']),
    );
  }

  static Map<String, dynamic> toFirestore(
    UserModel user,
    SetOptions? options,
  ) {
    final json = user.toJson();
    // We remove the UID from the map because it's the Document ID
    json.remove('uid');
    
    // Convert DateTime back to a format Firestore likes (Timestamp)
    if (user.createdAt != null) {
      json['createdAt'] = Timestamp.fromDate(user.createdAt!);
    }
    
    // Ensure the role is saved as a string
    json['role'] = user.role.name;
    
    return json;
  }
}