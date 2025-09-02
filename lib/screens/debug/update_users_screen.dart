import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/update_users.dart';

class UpdateUsersScreen extends StatefulWidget {
  const UpdateUsersScreen({super.key});

  @override
  State<UpdateUsersScreen> createState() => _UpdateUsersScreenState();
}

class _UpdateUsersScreenState extends State<UpdateUsersScreen> {
  bool _isLoading = false;
  String _result = '';

  Future<void> _updateAllUsers() async {
    setState(() {
      _isLoading = true;
      _result = 'Updating all users...';
    });

    try {
      final result = await UpdateUsersUtil.updateAllUsers();
      
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateCurrentUser() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (!authProvider.isAuthenticated) {
      setState(() {
        _result = 'Error: You must be logged in to update your user profile';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _result = 'Updating current user...';
    });

    try {
      final result = await UpdateUsersUtil.updateUser(authProvider.userModel!.id);
      
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Users'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'This utility will update users in the database to add missing fields required for search functionality.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: AppTheme.mediumSpacing),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _updateCurrentUser,
              child: const Text('Update Current User'),
            ),
            
            const SizedBox(height: AppTheme.smallSpacing),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _updateAllUsers,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('Update All Users'),
            ),
            
            const SizedBox(height: AppTheme.mediumSpacing),
            
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_result.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(AppTheme.mediumSpacing),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                ),
                child: Text(_result),
              ),
          ],
        ),
      ),
    );
  }
}
