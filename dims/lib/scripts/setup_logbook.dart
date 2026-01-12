// lib/scripts/setup_logbook.dart
// Quick setup script to create logbook_entries collection + sample document
// Run with: dart run lib/scripts/setup_logbook.dart

import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  print('''
DIMS - Quick Setup: logbook_entries Collection
==============================================
This script creates the collection 'logbook_entries'
and adds one realistic sample entry.
''');

  // ── CONFIGURATION ──────────────────────────────────────────────────────────
  // CHANGE THESE VALUES ↓↓↓
  const String projectId = 'dims-must';          // Your Firebase project ID
  const String webApiKey = '196272608738E'; // ← Must replace!

  if (webApiKey == 'YOUR_WEB_API_KEY_HERE') {
    print('❌ ERROR: Web API Key is missing!');
    print('How to get it:');
    print('  1. Go to https://console.firebase.google.com/project/$projectId/settings/general');
    print('  2. Scroll to "Your apps" → Web app (add one if missing)');
    print('  3. Copy "Web API Key" and paste it above');
    exit(1);
  }

  final client = HttpClient();
  final baseUrl = 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';

  try {
    print('→ Creating collection: logbook_entries');
    print('→ Adding sample entry...');

    await createDocument(
      client: client,
      baseUrl: baseUrl,
      collection: 'logbook_entries',
      documentId: null, // ← null = auto-generated ID
      fields: {
        'studentRefPath': {'stringValue': 'students/example-student-uid-123'},
        'placementRefPath': {'stringValue': 'placements/example-placement-001'},
        'date': {
          'timestampValue': DateTime.now().toUtc().toIso8601String(),
        },
        'dayNumber': {'integerValue': '5'},
        'tasksPerformed': {
          'stringValue': 'Developed user authentication module and integrated Firebase Auth',
        },
        'challenges': {
          'stringValue': 'Faced issues with token refresh on web platform',
        },
        'skillsLearned': {
          'stringValue': 'Learned secure password handling and Riverpod state management',
        },
        'hoursWorked': {'doubleValue': 7.5},
        'status': {'stringValue': 'draft'},
        'createdAt': {
          'timestampValue': DateTime.now().toUtc().toIso8601String(),
        },
        'updatedAt': {
          'timestampValue': DateTime.now().toUtc().toIso8601String(),
        },
      },
    );

    print('\n═══════════════════════════════════════════════');
    print('✓ SUCCESS: logbook_entries collection is ready!');
    print('═══════════════════════════════════════════════');
    print('Check it here:');
    print('https://console.firebase.google.com/project/$projectId/firestore/data/~2Flogbook_entries');
    print('\nNext: Make sure your app uses .collection("logbook_entries")');
  } catch (e, stack) {
    print('\n✗ ERROR OCCURRED: $e');
    print('Stack trace:\n$stack');
    exit(1);
  } finally {
    client.close();
  }

  exit(0);
}

/// Creates a Firestore document using REST API
Future<void> createDocument({
  required HttpClient client,
  required String baseUrl,
  required String collection,
  String? documentId,
  required Map<String, dynamic> fields,
}) async {
  try {
    final url = documentId != null
        ? '$baseUrl/$collection/$documentId'
        : '$baseUrl/$collection?'; // note the ? for auto-ID

    final uri = Uri.parse(url);
    final request = documentId != null
        ? await client.patchUrl(uri) // update if exists
        : await client.postUrl(uri); // create new

    request.headers.set('Content-Type', 'application/json');

    final body = jsonEncode({'fields': fields});
    request.write(body);

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode >= 200 && response.statusCode < 300) {
      print('  ✓ Document created successfully');
    } else {
      print('  ✗ Failed: HTTP ${response.statusCode}');
      print('  Response body:\n$responseBody');
      exit(1);
    }
  } catch (e) {
    print('  ✗ Error during document creation: $e');
    rethrow;
  }
}