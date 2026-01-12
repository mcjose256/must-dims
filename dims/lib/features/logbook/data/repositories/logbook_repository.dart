// lib/features/logbook/data/repositories/logbook_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/logbook_entry_model.dart';

final logbookRepositoryProvider = Provider<LogbookRepository>(
  (ref) => LogbookRepository(FirebaseFirestore.instance),
);

class LogbookRepository {
  final FirebaseFirestore _firestore;

  LogbookRepository(this._firestore);

  /// Creates a new logbook entry in Firestore
  Future<void> createLogbookEntry(LogbookEntryModel entry) async {
    try {
      // Use auto-generated document ID
      final docRef = _firestore.collection('logbook_entries').doc();

      final data = LogbookEntryModel.toFirestore(entry);

      // Ensure server timestamps are used when not provided
      data['createdAt'] = data['createdAt'] ?? FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      await docRef.set(data);
    } on FirebaseException catch (e) {
      throw Exception('Failed to create logbook entry: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error creating logbook entry: $e');
    }
  }

  /// Gets all logbook entries for a specific student
  /// Ordered by date descending (newest first)
  Stream<List<LogbookEntryModel>> getStudentLogbookEntries(String studentRefPath) {
    return _firestore
        .collection('logbook_entries')
        .where('studentRefPath', isEqualTo: studentRefPath)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return LogbookEntryModel.fromFirestore(doc, null);
      }).toList();
    });
  }

  /// Gets a single logbook entry by its document ID
  Future<LogbookEntryModel?> getLogbookEntryById(String entryId) async {
    try {
      final doc = await _firestore.collection('logbook_entries').doc(entryId).get();

      if (!doc.exists) return null;

      return LogbookEntryModel.fromFirestore(doc, null);
    } catch (e) {
      throw Exception('Failed to fetch logbook entry: $e');
    }
  }

  /// Updates an existing logbook entry
  Future<void> updateLogbookEntry(LogbookEntryModel updatedEntry) async {
    if (updatedEntry.id == null) {
      throw Exception('Cannot update entry without ID');
    }

    try {
      final docRef = _firestore.collection('logbook_entries').doc(updatedEntry.id);

      final data = LogbookEntryModel.toFirestore(updatedEntry);
      data['updatedAt'] = FieldValue.serverTimestamp();

      await docRef.update(data);
    } catch (e) {
      throw Exception('Failed to update logbook entry: $e');
    }
  }

  /// Deletes a logbook entry
  Future<void> deleteLogbookEntry(String entryId) async {
    try {
      await _firestore.collection('logbook_entries').doc(entryId).delete();
    } catch (e) {
      throw Exception('Failed to delete logbook entry: $e');
    }
  }
}