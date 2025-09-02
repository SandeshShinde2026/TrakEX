import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../models/group_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friend_provider.dart';
import '../../providers/group_provider.dart';
import 'create_group_screen.dart';
import 'group_details_screen.dart';

class ManageGroupsScreen extends StatefulWidget {
  const ManageGroupsScreen({super.key});

  @override
  State<ManageGroupsScreen> createState() => _ManageGroupsScreenState();
}

class _ManageGroupsScreenState extends State<ManageGroupsScreen> {
  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);

    debugPrint('ManageGroupsScreen: Loading groups...');
    debugPrint('ManageGroupsScreen: User authenticated: ${authProvider.isAuthenticated}');
    debugPrint('ManageGroupsScreen: User ID: ${authProvider.userModel?.id}');

    if (authProvider.isAuthenticated && authProvider.userModel != null) {
      await groupProvider.loadUserGroups(authProvider.userModel!.id);
      debugPrint('ManageGroupsScreen: Groups loaded: ${groupProvider.groups.length}');
      for (var group in groupProvider.groups) {
        debugPrint('ManageGroupsScreen: Group found: ${group.name} (${group.memberCount} members)');
      }
    } else {
      debugPrint('ManageGroupsScreen: Cannot load groups - user not authenticated or null');
    }
  }

  Future<void> _createNewGroup() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateGroupScreen()),
    );
    
    if (result == true) {
      // Refresh groups list
      _loadGroups();
    }
  }

  Future<void> _deleteGroup(GroupModel group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text('Are you sure you want to delete "${group.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final success = await groupProvider.deleteGroup(group.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
                ? 'Group deleted successfully' 
                : 'Failed to delete group'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewGroup,
            tooltip: 'Create New Group',
          ),
        ],
      ),
      body: Consumer<GroupProvider>(
        builder: (context, groupProvider, child) {
          if (groupProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (groupProvider.groups.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: _loadGroups,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppTheme.mediumSpacing),
              itemCount: groupProvider.groups.length,
              itemBuilder: (context, index) {
                final group = groupProvider.groups[index];
                return _buildGroupCard(group);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewGroup,
        child: const Icon(Icons.add),
        tooltip: 'Create New Group',
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.largeSpacing),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_add,
              size: 80,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey,
            ),
            const SizedBox(height: AppTheme.mediumSpacing),
            Text(
              'No Groups Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.smallSpacing),
            Text(
              'Create your first group to split expenses with multiple friends.\n\nGroups help you manage shared expenses like trips, dinners, or shared bills.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.largeSpacing),
            ElevatedButton.icon(
              onPressed: _createNewGroup,
              icon: const Icon(Icons.add),
              label: const Text('Create Group'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(GroupModel group) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final friendProvider = Provider.of<FriendProvider>(context, listen: false);
    final isCreator = group.isCreator(authProvider.userModel?.id ?? '');

    // Get member names
    final memberNames = <String>[];
    for (final memberId in group.memberIds) {
      if (memberId == authProvider.userModel?.id) {
        memberNames.add('You');
      } else {
        final friend = friendProvider.friends.firstWhere(
          (f) => f.id == memberId,
          orElse: () => UserModel(
            id: memberId,
            name: 'Unknown User',
            email: '',
          ),
        );
        memberNames.add(friend.name);
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.mediumSpacing),
      child: InkWell(
        onTap: () => _navigateToGroupDetails(group),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.mediumSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.group,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppTheme.smallSpacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${group.memberCount} members',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[400]
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[400]
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      if (isCreator)
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'delete') {
                              _deleteGroup(group);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete Group'),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.smallSpacing),

              // Members list
              Text(
                'Members: ${memberNames.join(', ')}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: AppTheme.smallSpacing),

              // Group info
              Row(
                children: [
                  if (isCreator)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Creator',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    'Created ${_formatDate(group.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToGroupDetails(GroupModel group) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupDetailsScreen(group: group),
      ),
    );

    if (result == true) {
      // Refresh groups list if any changes were made
      _loadGroups();
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
