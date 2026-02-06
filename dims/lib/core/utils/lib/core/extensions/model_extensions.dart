// lib/core/extensions/model_extensions.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dims/features/placements/data/models/placement_model.dart';
import 'package:dims/features/logbook/data/models/logbook_entry_model.dart';
import 'package:dims/features/evaluations/data/models/evaluation_model.dart';
import 'package:dims/features/notifications/data/models/notification_model.dart';

// Placement Extensions
extension PlacementModelExtension on PlacementModel {
  DocumentReference? get studentRef => 
      studentRefPath != null ? FirebaseFirestore.instance.doc(studentRefPath!) : null;
  
  DocumentReference? get companyRef => 
      companyRefPath != null ? FirebaseFirestore.instance.doc(companyRefPath!) : null;
  
  DocumentReference? get supervisorRef => 
      supervisorRefPath != null ? FirebaseFirestore.instance.doc(supervisorRefPath!) : null;
}

// Logbook Entry Extensions
extension LogbookEntryModelExtension on LogbookEntryModel {
  // studentRefPath exists in your model
  DocumentReference? get studentRef => 
      studentRefPath.isNotEmpty ? FirebaseFirestore.instance.doc(studentRefPath) : null;
  
  // placementRefPath exists in your model
  DocumentReference? get placementRef => 
      placementRefPath.isNotEmpty ? FirebaseFirestore.instance.doc(placementRefPath) : null;
  
  // These now work because we added them back to the model above
  GeoPoint? get gpsLocation => 
      (latitude != null && longitude != null)
          ? GeoPoint(latitude!, longitude!)
          : null;
}

// Evaluation Extensions
extension EvaluationModelExtension on EvaluationModel {
  // In the updated EvaluationModel, we use studentId and supervisorId
  // We point them to the correct Firestore collection paths
  DocumentReference get studentRef => 
      FirebaseFirestore.instance.collection('students').doc(studentId);
  
  DocumentReference get supervisorRef => 
      FirebaseFirestore.instance.collection('supervisorProfiles').doc(supervisorId);
}

// Notification Extensions
extension NotificationModelExtension on NotificationModel {
  DocumentReference? get userRef => 
      userRefPath != null ? FirebaseFirestore.instance.doc(userRefPath!) : null;
}