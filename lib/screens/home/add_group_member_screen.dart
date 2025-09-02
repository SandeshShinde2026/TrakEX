import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../models/group_model.dart';
import '../../models/user_model.dart';
import '../../providers/friend_provider.dart';
import '../../providers/group_provider.dart';

class AddGroupMemberScreen extends StatefulWidget {
  final GroupModel group;

  const AddGroupMemberScreen({
    super.key,
    required this.group,
  });

  @override
  State<AddGroupMemberScreen> createState() => _AddGroupMemberScreenState();
}

class _AddGroupMemberScreenState extends State<AddGroupMemberScreen> {
  final _searchController = TextEditingController();
  List<UserModel> _filteredFriends = [];
  List<UserModel> _selectedFriends = [];
  String _searchQuery = '';
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateFilteredFriends();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _updateFilteredFriends();
    });
  }

  void _updateFilteredFriends() {
    final friendProvider = Provider.of<FriendProvider>(context, listen: false);
    
    // Get friends who are not already in the group
    final availableFriends = friendProvider.friends
        .where((friend) => !widget.group.memberIds.contains(friend.id))
        .toList();

    if (_searchQuery.isEmpty) {
      _filteredFriends = availableFriends;
    } else {
      _filteredFriends = availableFriends
          .where((friend) =>
              friend.name.toLowerCase().contains(_searchQuery) ||
              friend.email.toLowerCase().contains(_searchQuery))
          .toList();
    }
  }

  void _toggleFriendSelection(UserModel friend) {
    setState(() {
      if (_selectedFriends.contains(friend)) {
        _selectedFriends.remove(friend);
      } else {
        _selectedFriends.add(friend);
      }
    });
  }

  Future<void> _addSelectedMembers() async {
    if (_selectedFriends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one friend to add'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isAdding = true;
    });

    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    int successCount = 0;
    int totalCount = _selectedFriends.length;

    for (final friend in _selectedFriends) {
      final success = await groupProvider.addMemberToGroup(widget.group.id, friend.id);
      if (success) {
        successCount++;
      }
    }

    setState(() {
      _isAdding = false;
    });

    if (mounted) {
      if (successCount == totalCount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully added $successCount member${successCount > 1 ? 's' : ''}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else if (successCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added $successCount of $totalCount members'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add members. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final friendProvider = Provider.of<FriendProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Members'),
        actions: [
          TextButton(
            onPressed: _isAdding ? null : _addSelectedMembers,
            child: _isAdding
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Add'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.mediumSpacing),
                child: Row(
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
                      ),
                    ),
                    const SizedBox(width: AppTheme.smallSpacing),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.group.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${widget.group.memberCount} current members',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppTheme.mediumSpacing),

            // Selected Friends Section
            if (_selectedFriends.isNotEmpty) ...[
              Text(
                'Selected Friends (${_selectedFriends.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.smallSpacing),
              
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedFriends.length,
                  itemBuilder: (context, index) {
                    final friend = _selectedFriends[index];
                    return Container(
                      margin: const EdgeInsets.only(right: AppTheme.smallSpacing),
                      child: Chip(
                        avatar: CircleAvatar(
                          backgroundImage: friend.photoUrl != null
                              ? NetworkImage(friend.photoUrl!)
                              : null,
                          child: friend.photoUrl == null
                              ? Text(friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?')
                              : null,
                        ),
                        label: Text(friend.name),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () => _toggleFriendSelection(friend),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: AppTheme.mediumSpacing),
            ],

            // Search Bar
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Friends',
                hintText: 'Search by name or email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            
            const SizedBox(height: AppTheme.mediumSpacing),

            // Available Friends List
            Expanded(
              child: _buildAvailableFriendsList(friendProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableFriendsList(FriendProvider friendProvider) {
    // Get friends who are not already in the group
    final availableFriends = friendProvider.friends
        .where((friend) => !widget.group.memberIds.contains(friend.id))
        .toList();

    if (availableFriends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: AppTheme.mediumSpacing),
            Text(
              'All Friends Already Added',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.smallSpacing),
            const Text(
              'All your friends are already members of this group',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_filteredFriends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: AppTheme.mediumSpacing),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'No friends found matching "$_searchQuery"'
                  : 'No available friends',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredFriends.length,
      itemBuilder: (context, index) {
        final friend = _filteredFriends[index];
        final isSelected = _selectedFriends.contains(friend);
        
        return Card(
          margin: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: friend.photoUrl != null
                  ? NetworkImage(friend.photoUrl!)
                  : null,
              child: friend.photoUrl == null
                  ? Text(friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?')
                  : null,
            ),
            title: Text(friend.name),
            subtitle: Text(friend.email),
            trailing: Checkbox(
              value: isSelected,
              onChanged: (_) => _toggleFriendSelection(friend),
            ),
            onTap: () => _toggleFriendSelection(friend),
          ),
        );
      },
    );
  }
}
