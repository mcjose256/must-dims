// lib/core/extensions/model_extensions.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dims/features/placements/data/models/placement_model.dart';
import 'package:dims/features/logbook/data/models/logbook_entry_model.dart';
import 'package:dims/features/evaluations/data/models/evaluation_model.dart';
import 'package:dims/features/notifications/data/models/notification_model.dart';

// Placement Extensions
extension PlacementModelExtension on PlacementModel {
  DocumentReference? get studentRef => 
      studentRefPath != null 
          ? FirebaseFirestore.instance.doc(studentRefPath!) 
          : null;
  
  DocumentReference? get companyRef => 
      companyRefPath != null 
          ? FirebaseFirestore.instance.doc(companyRefPath!) 
          : null;
  
  DocumentReference? get supervisorRef => 
      supervisorRefPath != null 
          ? FirebaseFirestore.instance.doc(supervisorRefPath!) 
          : null;
}

// Logbook Entry Extensions
extension LogbookEntryModelExtension on LogbookEntryModel {
  DocumentReference? get studentRef => 
      studentRefPath != null 
          ? FirebaseFirestore.instance.doc(studentRefPath!) 
          : null;
  
  DocumentReference? get placementRef => 
      placementRefPath != null 
          ? FirebaseFirestore.instance.doc(placementRefPath!) 
          : null;
  
  GeoPoint? get gpsLocation => 
      (latitude != null && longitude != null)
          ? GeoPoint(latitude!, longitude!)
          : null;
}

// Evaluation Extensions
extension EvaluationModelExtension on EvaluationModel {
  DocumentReference? get placementRef => 
      placementRefPath != null 
          ? FirebaseFirestore.instance.doc(placementRefPath!) 
          : null;
  
  DocumentReference? get evaluatorRef => 
      evaluatorRefPath != null 
          ? FirebaseFirestore.instance.doc(evaluatorRefPath!) 
          : null;
}

// Notification Extensions
extension NotificationModelExtension on NotificationModel {
  DocumentReference? get userRef => 
      userRefPath != null 
          ? FirebaseFirestore.instance.doc(userRefPath!) 
          : null;
}