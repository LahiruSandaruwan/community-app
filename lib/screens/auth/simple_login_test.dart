import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';

/// Simple Login Test - Minimal code to isolate the issue
class SimpleLoginTest extends StatefulWidget {
  const SimpleLoginTest({Key? key}) : super(key: key);

  @override
  State<SimpleLoginTest> createState() => _SimpleLoginTestState();
}

class _SimpleLoginTestState extends State<SimpleLoginTest> {
  final _emailController = TextEditingController(text: 'test@test.com');
  final _passwordController = TextEditingController(text: 'test123456');
  final _nameController = TextEditingController(text: 'Test User');

  String _status = 'Ready to test';
  bool _isLoading = false;
  Color _statusColor = Colors.blue;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _log(String message, {Color color = Colors.white}) {
    setState(() {
      _status = message;
      _statusColor = color;
    });
    print(message);
  }

  Future<void> _testSignUp() async {
    setState(() => _isLoading = true);
    _log('Starting sign up test...', color: Colors.blue);

    try {
      // Step 1: Check Firebase initialization
      _log('Step 1: Checking Firebase...', color: Colors.blue);
      await Future.delayed(const Duration(milliseconds: 500));

      final app = Firebase.app();
      _log('✅ Firebase initialized: ${app.name}', color: Colors.green);

      // Step 2: Try to create user in Firebase Auth
      _log('Step 2: Creating Firebase Auth user...', color: Colors.blue);
      await Future.delayed(const Duration(milliseconds: 500));

      final auth = FirebaseAuth.instance;
      UserCredential userCred;

      try {
        userCred = await auth.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
        _log('✅ Auth user created: ${userCred.user?.uid}', color: Colors.green);
      } catch (e) {
        if (e.toString().contains('email-already-in-use')) {
          _log('Email exists, trying to sign in instead...', color: Colors.orange);
          userCred = await auth.signInWithEmailAndPassword(
            email: _emailController.text,
            password: _passwordController.text,
          );
          _log('✅ Signed in existing user: ${userCred.user?.uid}', color: Colors.green);
        } else {
          throw e;
        }
      }

      // Step 3: Try to write to Firestore
      _log('Step 3: Writing to Firestore...', color: Colors.blue);
      await Future.delayed(const Duration(milliseconds: 500));

      final firestore = FirebaseFirestore.instance;
      await firestore.collection('users').doc(userCred.user!.uid).set({
        'email': _emailController.text,
        'name': _nameController.text,
        'role': 'student',
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
        'isOnline': true,
        'communityIds': [],
        'mutedGroupChatIds': [],
      });
      _log('✅ Firestore write successful!', color: Colors.green);

      // Step 4: Try to read from Firestore
      _log('Step 4: Reading from Firestore...', color: Colors.blue);
      await Future.delayed(const Duration(milliseconds: 500));

      final doc = await firestore.collection('users').doc(userCred.user!.uid).get();
      if (doc.exists && doc.data() != null) {
        _log('✅ Firestore read successful!', color: Colors.green);
        _log('Data: ${doc.data()}', color: Colors.white);
      } else {
        _log('❌ Document not found after write!', color: Colors.red);
      }

      // Success!
      _log('✅ ALL TESTS PASSED! Sign in should work.', color: Colors.green);

    } on FirebaseAuthException catch (e) {
      _log('❌ Firebase Auth Error: ${e.code}', color: Colors.red);
      _log('Message: ${e.message}', color: Colors.red);

      if (e.code == 'network-request-failed') {
        _log('⚠️ Network error. Check internet connection.', color: Colors.orange);
      } else if (e.code == 'operation-not-allowed') {
        _log('⚠️ Email/Password auth not enabled in Firebase Console!', color: Colors.orange);
      }
    } on FirebaseException catch (e) {
      _log('❌ Firebase Error: ${e.code}', color: Colors.red);
      _log('Message: ${e.message}', color: Colors.red);

      if (e.code == 'permission-denied') {
        _log('⚠️ Firestore permission denied! Check security rules.', color: Colors.orange);
      }
    } catch (e) {
      _log('❌ Error: $e', color: Colors.red);

      if (e.toString().contains('PigeonUserDetails')) {
        _log('⚠️ Build cache error! Run: flutter clean', color: Colors.orange);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testSignIn() async {
    setState(() => _isLoading = true);
    _log('Testing sign in...', color: Colors.blue);

    try {
      final auth = FirebaseAuth.instance;
      final userCred = await auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      _log('✅ Sign in successful: ${userCred.user?.uid}', color: Colors.green);

      // Check Firestore
      final firestore = FirebaseFirestore.instance;
      final doc = await firestore.collection('users').doc(userCred.user!.uid).get();

      if (doc.exists && doc.data() != null) {
        _log('✅ User profile found in Firestore!', color: Colors.green);
      } else {
        _log('❌ User profile missing in Firestore!', color: Colors.red);
      }
    } on FirebaseAuthException catch (e) {
      _log('❌ Sign in failed: ${e.code}', color: Colors.red);
      _log('Message: ${e.message}', color: Colors.red);
    } catch (e) {
      _log('❌ Error: $e', color: Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkFirebaseConfig() async {
    setState(() => _isLoading = true);
    _log('Checking Firebase configuration...', color: Colors.blue);

    try {
      // Check Firebase app
      final app = Firebase.app();
      _log('✅ Firebase app: ${app.name}', color: Colors.green);
      _log('Options: ${app.options.projectId}', color: Colors.white);

      // Check Auth
      final auth = FirebaseAuth.instance;
      _log('✅ Firebase Auth available', color: Colors.green);
      _log('Current user: ${auth.currentUser?.uid ?? "null"}', color: Colors.white);

      // Check Firestore
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('_test').doc('_test').set({'test': true});
      await firestore.collection('_test').doc('_test').delete();
      _log('✅ Firestore connection works!', color: Colors.green);

      _log('✅ Configuration is correct!', color: Colors.green);
    } catch (e) {
      _log('❌ Configuration error: $e', color: Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Login Test'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            Card(
              color: Colors.blue.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'This is a simplified test to isolate the sign-in issue. '
                  'Try each button and watch the status messages below.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Email field
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Password field
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),

            // Name field
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Test buttons
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _checkFirebaseConfig,
              icon: const Icon(Icons.settings),
              label: const Text('1. Check Firebase Config'),
            ),
            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testSignUp,
              icon: const Icon(Icons.person_add),
              label: const Text('2. Test Sign Up'),
            ),
            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testSignIn,
              icon: const Icon(Icons.login),
              label: const Text('3. Test Sign In'),
            ),
            const SizedBox(height: 24),

            // Status display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _statusColor, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (_isLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      else
                        Icon(Icons.info, color: _statusColor, size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'Status:',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _status,
                    style: TextStyle(
                      color: _statusColor,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
