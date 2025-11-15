import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/theme.dart';

/// Test Authentication Screen
/// Use this to diagnose Firebase Auth and Firestore connection issues
class TestAuthScreen extends StatefulWidget {
  const TestAuthScreen({Key? key}) : super(key: key);

  @override
  State<TestAuthScreen> createState() => _TestAuthScreenState();
}

class _TestAuthScreenState extends State<TestAuthScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  List<String> _testResults = [];
  bool _isRunning = false;

  Future<void> _runDiagnostics() async {
    setState(() {
      _testResults.clear();
      _isRunning = true;
    });

    _addResult('🔍 Starting diagnostics...\n');

    // Test 1: Firebase Auth availability
    try {
      _addResult('✅ Test 1: Firebase Auth is available');
      _addResult('   Current user: ${_auth.currentUser?.uid ?? "null"}\n');
    } catch (e) {
      _addResult('❌ Test 1 FAILED: $e\n');
    }

    // Test 2: Firestore availability
    try {
      await _firestore.collection('_test').doc('_test').set({'test': true});
      await _firestore.collection('_test').doc('_test').delete();
      _addResult('✅ Test 2: Firestore connection works\n');
    } catch (e) {
      _addResult('❌ Test 2 FAILED: Firestore connection error');
      _addResult('   Error: $e\n');
    }

    // Test 3: Try to create a test user
    final testEmail = 'test_${DateTime.now().millisecondsSinceEpoch}@test.com';
    final testPassword = 'test123456';

    try {
      _addResult('🔄 Test 3: Creating test user...');
      UserCredential userCred = await _auth.createUserWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      );
      _addResult('✅ Test user created: ${userCred.user?.uid}');

      // Test 4: Try to write to Firestore
      try {
        _addResult('🔄 Test 4: Writing to Firestore...');
        await _firestore.collection('users').doc(userCred.user!.uid).set({
          'email': testEmail,
          'name': 'Test User',
          'role': 'student',
          'createdAt': FieldValue.serverTimestamp(),
          'lastSeen': FieldValue.serverTimestamp(),
          'isOnline': true,
          'communityIds': [],
          'mutedGroupChatIds': [],
        });
        _addResult('✅ Test 4: Firestore write successful\n');

        // Test 5: Read back from Firestore
        try {
          _addResult('🔄 Test 5: Reading from Firestore...');
          DocumentSnapshot doc = await _firestore
              .collection('users')
              .doc(userCred.user!.uid)
              .get();

          if (doc.exists) {
            _addResult('✅ Test 5: Firestore read successful');
            _addResult('   Data: ${doc.data()}\n');
          } else {
            _addResult('❌ Test 5 FAILED: Document not found\n');
          }
        } catch (e) {
          _addResult('❌ Test 5 FAILED: $e\n');
        }

        // Cleanup
        await _firestore.collection('users').doc(userCred.user!.uid).delete();
        await userCred.user!.delete();
        _addResult('🧹 Test user cleaned up\n');

      } catch (e) {
        _addResult('❌ Test 4 FAILED: Firestore write error');
        _addResult('   Error: $e\n');
      }

    } catch (e) {
      _addResult('❌ Test 3 FAILED: Cannot create user');
      _addResult('   Error: $e\n');

      if (e.toString().contains('PigeonUserDetails')) {
        _addResult('\n⚠️  CRITICAL: PigeonUserDetails error detected!');
        _addResult('   This is a build cache issue.');
        _addResult('   Solution: Run ./clean_rebuild.sh\n');
      }
    }

    _addResult('\n📊 DIAGNOSIS COMPLETE');
    _addResult('─' * 40);

    if (!_testResults.any((r) => r.contains('❌'))) {
      _addResult('\n✅ All tests passed!');
      _addResult('   Sign in/up should work now.');
    } else {
      _addResult('\n❌ Some tests failed.');
      _addResult('   Check the errors above.');
    }

    setState(() {
      _isRunning = false;
    });
  }

  void _addResult(String result) {
    setState(() {
      _testResults.add(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auth Diagnostics'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Column(
        children: [
          // Run button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isRunning ? null : _runDiagnostics,
                icon: Icon(_isRunning ? Icons.sync : Icons.play_arrow),
                label: Text(_isRunning ? 'Running...' : 'Run Diagnostics'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),

          // Results
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green, width: 1),
              ),
              child: _testResults.isEmpty
                  ? const Center(
                      child: Text(
                        'Click "Run Diagnostics" to start',
                        style: TextStyle(
                          color: Colors.green,
                          fontFamily: 'monospace',
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _testResults.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            _testResults[index],
                            style: TextStyle(
                              color: _testResults[index].contains('❌')
                                  ? Colors.red
                                  : _testResults[index].contains('✅')
                                      ? Colors.green
                                      : _testResults[index].contains('⚠️')
                                          ? Colors.orange
                                          : Colors.white,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
