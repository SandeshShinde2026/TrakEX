import 'package:flutter/material.dart';
import '../../utils/database_setup.dart';
import '../../constants/app_theme.dart';

class DatabaseSetupScreen extends StatefulWidget {
  const DatabaseSetupScreen({super.key});

  @override
  State<DatabaseSetupScreen> createState() => _DatabaseSetupScreenState();
}

class _DatabaseSetupScreenState extends State<DatabaseSetupScreen> {
  final DatabaseSetup _databaseSetup = DatabaseSetup();
  bool _isLoading = false;
  String _statusMessage = 'Ready to setup database';
  final List<String> _logs = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Setup'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Database Setup Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_statusMessage),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _setupDatabase,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Run Database Setup'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Individual setup actions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Individual Setup Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _updateUserCollection,
                            child: const Text('Update User Collection'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _createPaymentsCollection,
                            child: const Text('Create Payments Collection'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Logs
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Logs',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Text(
                                _logs[index],
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('[${DateTime.now().toString()}] $message');
    });
  }

  Future<void> _setupDatabase() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Setting up database...';
      _addLog('Starting database setup');
    });

    try {
      await _databaseSetup.setupDatabase();
      
      setState(() {
        _statusMessage = 'Database setup completed successfully';
        _addLog('Database setup completed successfully');
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error setting up database: $e';
        _addLog('Error: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateUserCollection() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Updating user collection...';
      _addLog('Updating user collection');
    });

    try {
      await _databaseSetup.updateUserCollection();
      
      setState(() {
        _statusMessage = 'User collection updated successfully';
        _addLog('User collection updated successfully');
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error updating user collection: $e';
        _addLog('Error: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createPaymentsCollection() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Creating payments collection...';
      _addLog('Creating payments collection');
    });

    try {
      await _databaseSetup.createPaymentsCollection();
      
      setState(() {
        _statusMessage = 'Payments collection created successfully';
        _addLog('Payments collection created successfully');
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error creating payments collection: $e';
        _addLog('Error: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
