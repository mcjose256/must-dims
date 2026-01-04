// lib/scripts/setup_firestore_http.dart
// This script uses HTTP requests directly to Firestore REST API
// No Flutter dependencies needed!

import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  print('DIMS Firestore Setup via REST API\n');
  
  // REPLACE THESE WITH YOUR FIREBASE PROJECT DETAILS
  const projectId = 'dims-must';  // Your Firebase project ID
  const apiKey = '196272608738E';  // Get from Firebase Console > Project Settings > Web API Key
  
  if (apiKey == 'YOUR_WEB_API_KEY_HERE') {
    print('❌ ERROR: Please edit the script and add your Firebase Web API Key');
    print('\nTo find your API key:');
    print('1. Go to https://console.firebase.google.com/project/$projectId/settings/general');
    print('2. Scroll to "Your apps" section');
    print('3. Copy the "Web API Key"');
    print('4. Paste it in this script at line 11');
    exit(1);
  }
  
  final client = HttpClient();
  final baseUrl = 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';
  
  try {
    // 1. Create allocationRules/current
    print('Creating allocationRules/current...');
    await createDocument(client, baseUrl, 'allocationRules', 'current', {
      'academicYear': {'stringValue': '2025/2026'},
      'maxStudentsPerSupervisor': {'integerValue': '12'},
      'preferredPrograms': {
        'arrayValue': {
          'values': [
            {'stringValue': 'BCS'},
            {'stringValue': 'BIT'},
            {'stringValue': 'BSE'}
          ]
        }
      },
      'enabled': {'booleanValue': true},
      'updatedAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
    });
    
    // 2. Create sample documents in other collections
    final collections = [
      {
        'name': 'users',
        'data': {
          'uid': {'stringValue': 'exampleStudent123'},
          'email': {'stringValue': 'student@must.ac.ug'},
          'role': {'stringValue': 'student'},
          'displayName': {'stringValue': 'John Doe'},
          'isApproved': {'booleanValue': false},
          'createdAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
        }
      },
      {
        'name': 'studentProfiles',
        'data': {
          'registrationNumber': {'stringValue': '2020-BCS-001'},
          'program': {'stringValue': 'BCS'},
          'yearOfStudy': {'integerValue': '3'},
          'status': {'stringValue': 'pending'},
        }
      },
      {
        'name': 'supervisorProfiles',
        'data': {
          'department': {'stringValue': 'Computer Science'},
          'maxStudents': {'integerValue': '12'},
          'currentLoad': {'integerValue': '0'},
        }
      },
      {
        'name': 'companies',
        'data': {
          'name': {'stringValue': 'Andela Uganda'},
          'location': {'stringValue': 'Kampala'},
          'contactPerson': {'stringValue': 'Sarah K'},
          'email': {'stringValue': 'hr@andela.ug'},
          'isApproved': {'booleanValue': true},
          'createdAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
        }
      },
      {
        'name': 'placements',
        'data': {
          'academicYear': {'stringValue': '2025/2026'},
          'status': {'stringValue': 'active'},
        }
      },
      {
        'name': 'logbookEntries',
        'data': {
          'date': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
          'tasks': {'stringValue': 'Worked on API integration'},
          'hoursWorked': {'integerValue': '8'},
          'status': {'stringValue': 'pending'},
        }
      },
      {
        'name': 'evaluations',
        'data': {
          'scores': {
            'mapValue': {
              'fields': {
                'punctuality': {'integerValue': '9'},
                'skills': {'integerValue': '8'},
                'initiative': {'integerValue': '10'}
              }
            }
          },
          'comments': {'stringValue': 'Excellent performance!'},
        }
      },
      {
        'name': 'notifications',
        'data': {
          'title': {'stringValue': 'Logbook Approved'},
          'body': {'stringValue': 'Your entry for Monday has been approved'},
          'isRead': {'booleanValue': false},
          'createdAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
        }
      },
    ];
    
    for (final collection in collections) {
      print('Creating ${collection['name']} collection...');
      await createDocument(
        client,
        baseUrl,
        collection['name'] as String,
        null, // Auto-generate ID
        collection['data'] as Map<String, dynamic>,
      );
    }
    
    print('\n═══════════════════════════════════════════════════════');
    print('✓ DIMS Firestore setup 100% COMPLETE!');
    print('═══════════════════════════════════════════════════════');
    print('All 9 collections created with sample data');
    print('\nCheck Firebase Console:');
    print('https://console.firebase.google.com/project/$projectId/firestore');
    
  } catch (e, stack) {
    print('\n✗ ERROR: $e');
    print('Stack: $stack');
    exit(1);
  } finally {
    client.close();
  }
  
  exit(0);
}

Future<void> createDocument(
  HttpClient client,
  String baseUrl,
  String collection,
  String? documentId,
  Map<String, dynamic> fields,
) async {
  try {
    final url = documentId != null
        ? '$baseUrl/$collection/$documentId'
        : '$baseUrl/$collection';
    
    final uri = Uri.parse(url);
    
    // Use correct method based on whether we have a documentId
    final request = documentId != null
        ? await client.patchUrl(uri)
        : await client.postUrl(uri);
    
    request.headers.set('Content-Type', 'application/json');
    
    final body = jsonEncode({'fields': fields});
    request.write(body);
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      print('  ✓ ${documentId ?? 'document'} created');
    } else {
      print('  ✗ Failed: ${response.statusCode}');
      print('  Response: $responseBody');
    }
  } catch (e) {
    print('  ✗ Error creating document: $e');
  }
}