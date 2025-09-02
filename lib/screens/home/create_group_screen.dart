import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friend_provider.dart';
import '../../providers/group_provider.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  final _searchController = TextEditingController();
  
  List<UserModel> _selectedFriends = [];
  List<UserModel> _filteredFriends = [];
  String _searchQuery = '';
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    
    // Initialize filtered friends
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateFilteredFriends();
    });
  }

  @override
  void dispose() {
    _groupNameController.dispose();
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
    
    if (_searchQuery.isEmpty) {
      _filteredFriends = friendProvider.friends
          .where((friend) => !_selectedFriends.contains(friend))
          .toList();
    } else {
      _filteredFriends = friendProvider.friends
          .where((friend) => 
              !_selectedFriends.contains(friend) &&
              (friend.name.toLowerCase().contains(_searchQuery) ||
               friend.email.toLowerCase().contains(_searchQuery)))
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
      _updateFilteredFriends();
    });
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFriends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one friend'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);

    final memberIds = _selectedFriends.map((friend) => friend.id).toList();
    
    final group = await groupProvider.createGroup(
      name: _groupNameController.text.trim(),
      createdBy: authProvider.userModel!.id,
      memberIds: memberIds,
    );

    setState(() {
      _isCreating = false;
    });

    if (group != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Group "${group.name}" created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create group. Please try again.'),
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
        title: const Text('Create Group'),
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _createGroup,
            child: _isCreating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group Name Input
              TextFormField(
                controller: _groupNameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  hintText: 'Enter group name (e.g., College Friends)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.group),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a group name';
                  }
                  if (value.trim().length < 2) {
                    return 'Group name must be at least 2 characters';
                  }
                  return null;
                },
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

              // Friends List
              Expanded(
                child: _buildFriendsList(friendProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFriendsList(FriendProvider friendProvider) {
    if (friendProvider.friends.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: AppTheme.mediumSpacing),
            Text(
              'No friends available',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            Text(
              'Add friends first to create groups',
              style: TextStyle(color: Colors.grey, fontSize: 14),
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
                  : 'All friends are already selected',
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
        
        return ListTile(
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
        );
      },
    );
  }
}
