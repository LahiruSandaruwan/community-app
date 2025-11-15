import 'package:flutter/material.dart';
// Migration functionality disabled - using PocketBase now
// import '../../utils/firestore_migration.dart';
import '../../utils/theme.dart';

/// Admin screen to run database migrations
/// DEPRECATED: Migration functionality disabled after moving to PocketBase
class MigrationScreen extends StatefulWidget {
  const MigrationScreen({Key? key}) : super(key: key);

  @override
  State<MigrationScreen> createState() => _MigrationScreenState();
}

class _MigrationScreenState extends State<MigrationScreen> {
  bool _isRunning = false;
  String _status = 'Migration feature disabled (moved to PocketBase)';
  bool _completed = false;

  Future<void> _runMigrations() async {
    setState(() {
      _isRunning = true;
      _status = 'Migration feature is disabled...';
      _completed = false;
    });

    // Migration functionality disabled - using PocketBase now
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isRunning = false;
      _status = 'Migration feature is no longer available (app uses PocketBase)';
      _completed = false;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Migration feature disabled - app now uses PocketBase'),
        backgroundColor: AppTheme.warningColor,
      ),
    );

    /* ORIGINAL FIRESTORE MIGRATION CODE (DISABLED)
    try {
      await FirestoreMigration.runAllMigrations();

      setState(() {
        _isRunning = false;
        _status = 'All migrations completed successfully!';
        _completed = true;
      });
    } catch (e) {
      setState(() {
        _isRunning = false;
        _status = 'Migration failed: ${e.toString()}';
        _completed = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
    */
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Migrations'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Warning card
            Card(
              color: AppTheme.warningColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.warning, color: AppTheme.warningColor),
                        SizedBox(width: 8),
                        Text(
                          'Admin Only',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.warningColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This screen is for running database migrations. '
                      'Only run this if you know what you\'re doing.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'What this does:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text('• Migration feature disabled'),
                    SizedBox(height: 8),
                    Text('• App now uses PocketBase instead of Firestore'),
                    SizedBox(height: 8),
                    Text('• This screen is kept for reference only'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Status display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _completed
                    ? AppTheme.successColor.withOpacity(0.1)
                    : AppTheme.primaryLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _completed
                      ? AppTheme.successColor
                      : AppTheme.primaryColor,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  if (_isRunning)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      _completed ? Icons.check_circle : Icons.info_outline,
                      color: _completed
                          ? AppTheme.successColor
                          : AppTheme.primaryColor,
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _status,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Run button
            ElevatedButton.icon(
              onPressed: _isRunning ? null : _runMigrations,
              icon: Icon(_isRunning ? Icons.sync : Icons.play_arrow),
              label: Text(_isRunning ? 'Running...' : 'Run Migrations'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppTheme.primaryColor,
              ),
            ),

            const SizedBox(height: 16),

            // Instructions
            if (_completed)
              Card(
                color: AppTheme.successColor.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Next steps:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text('1. Close the app completely'),
                      SizedBox(height: 8),
                      Text('2. Clear app data or uninstall/reinstall'),
                      SizedBox(height: 8),
                      Text('3. Run: flutter clean && flutter run'),
                      SizedBox(height: 8),
                      Text('4. Try logging in again'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
