import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_theme.dart';
import '../../models/group_model.dart';
import '../../models/user_model.dart';
import '../../models/expense_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friend_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/expense_provider.dart';
import 'add_group_member_screen.dart';

class GroupDetailsScreen extends StatefulWidget {
  final GroupModel group;

  const GroupDetailsScreen({
    super.key,
    required this.group,
  });

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late GroupModel _currentGroup;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentGroup = widget.group;
    _loadGroupExpenses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupExpenses() async {
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    await expenseProvider.loadGroupExpenses(_currentGroup.id);
  }

  Future<void> _refreshGroup() async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final updatedGroup = await groupProvider.getGroupByIdFromServer(_currentGroup.id);
    if (updatedGroup != null) {
      setState(() {
        _currentGroup = updatedGroup;
      });
    }
  }

  Future<void> _addMember() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddGroupMemberScreen(group: _currentGroup),
      ),
    );

    if (result == true) {
      await _refreshGroup();
    }
  }

  Future<void> _removeMember(String memberId, String memberName) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Don't allow removing the creator
    if (memberId == _currentGroup.createdBy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot remove the group creator'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove $memberName from the group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final success = await groupProvider.removeMemberFromGroup(_currentGroup.id, memberId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
                ? '$memberName removed from group' 
                : 'Failed to remove member'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        
        if (success) {
          await _refreshGroup();
        }
      }
    }
  }

  Future<void> _editGroupName() async {
    final controller = TextEditingController(text: _currentGroup.name);
    
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Group Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Group Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != _currentGroup.name) {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final success = await groupProvider.updateGroup(
        groupId: _currentGroup.id,
        name: newName,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
                ? 'Group name updated' 
                : 'Failed to update group name'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        
        if (success) {
          await _refreshGroup();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isCreator = _currentGroup.isCreator(authProvider.userModel?.id ?? '');

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentGroup.name),
        actions: [
          if (isCreator)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit_name':
                    _editGroupName();
                    break;
                  case 'add_member':
                    _addMember();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit_name',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit Name'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'add_member',
                  child: Row(
                    children: [
                      Icon(Icons.person_add),
                      SizedBox(width: 8),
                      Text('Add Member'),
                    ],
                  ),
                ),
              ],
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.info_outline)),
            Tab(text: 'Members', icon: Icon(Icons.people)),
            Tab(text: 'Expenses', icon: Icon(Icons.receipt_long)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildMembersTab(isCreator),
          _buildExpensesTab(),
        ],
      ),
      floatingActionButton: isCreator
          ? FloatingActionButton(
              onPressed: _addMember,
              child: const Icon(Icons.person_add),
              tooltip: 'Add Member',
            )
          : null,
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.mediumSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.mediumSpacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.group,
                          color: Theme.of(context).primaryColor,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: AppTheme.mediumSpacing),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentGroup.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_currentGroup.memberCount} members',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.mediumSpacing),
                  const Divider(),
                  const SizedBox(height: AppTheme.smallSpacing),
                  
                  // Group Stats
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Created',
                          _formatDate(_currentGroup.createdAt),
                          Icons.calendar_today,
                        ),
                      ),
                      const SizedBox(width: AppTheme.smallSpacing),
                      Expanded(
                        child: Consumer<ExpenseProvider>(
                          builder: (context, expenseProvider, child) {
                            final groupExpenses = expenseProvider.expenses
                                .where((e) => e.isGroupExpense && e.groupId == _currentGroup.id)
                                .length;
                            return _buildStatCard(
                              'Expenses',
                              groupExpenses.toString(),
                              Icons.receipt,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppTheme.mediumSpacing),
          
          // Recent Activity
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.smallSpacing),
          
          Consumer<ExpenseProvider>(
            builder: (context, expenseProvider, child) {
              final groupExpenses = expenseProvider.expenses
                  .where((e) => e.isGroupExpense && e.groupId == _currentGroup.id)
                  .take(5)
                  .toList();
                  
              if (groupExpenses.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.largeSpacing),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: AppTheme.smallSpacing),
                        Text(
                          'No group expenses yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              return Column(
                children: groupExpenses.map((expense) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.receipt,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    title: Text(expense.description.isNotEmpty 
                        ? expense.description 
                        : expense.category),
                    subtitle: Text(
                      '${AppConstants.currencySymbol}${expense.amount.toStringAsFixed(2)} • ${_formatDate(expense.date)}',
                    ),
                    trailing: Text(
                      '${expense.participants.length} people',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMembersTab(bool isCreator) {
    final friendProvider = Provider.of<FriendProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.mediumSpacing),
      itemCount: _currentGroup.memberIds.length,
      itemBuilder: (context, index) {
        final memberId = _currentGroup.memberIds[index];
        final isCurrentUser = memberId == authProvider.userModel?.id;
        final isGroupCreator = memberId == _currentGroup.createdBy;

        // Get member details
        String memberName;
        String memberEmail;
        String? memberPhotoUrl;

        if (isCurrentUser) {
          memberName = authProvider.userModel?.name ?? 'You';
          memberEmail = authProvider.userModel?.email ?? '';
          memberPhotoUrl = authProvider.userModel?.photoUrl;
        } else {
          final friend = friendProvider.friends.firstWhere(
            (f) => f.id == memberId,
            orElse: () => UserModel(
              id: memberId,
              name: 'Unknown User',
              email: '',
            ),
          );
          memberName = friend.name;
          memberEmail = friend.email;
          memberPhotoUrl = friend.photoUrl;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: memberPhotoUrl != null
                  ? NetworkImage(memberPhotoUrl)
                  : null,
              child: memberPhotoUrl == null
                  ? Text(memberName.isNotEmpty ? memberName[0].toUpperCase() : '?')
                  : null,
            ),
            title: Row(
              children: [
                Text(isCurrentUser ? 'You' : memberName),
                const SizedBox(width: 8),
                if (isGroupCreator)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Creator',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Text(memberEmail),
            trailing: isCreator && !isCurrentUser && !isGroupCreator
                ? PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'remove') {
                        _removeMember(memberId, memberName);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'remove',
                        child: Row(
                          children: [
                            Icon(Icons.person_remove, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Remove'),
                          ],
                        ),
                      ),
                    ],
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildExpensesTab() {
    return Consumer<ExpenseProvider>(
      builder: (context, expenseProvider, child) {
        final groupExpenses = expenseProvider.expenses
            .where((e) => e.isGroupExpense && e.groupId == _currentGroup.id)
            .toList();

        if (groupExpenses.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.largeSpacing),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: AppTheme.mediumSpacing),
                  Text(
                    'No Group Expenses',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.smallSpacing),
                  Text(
                    'Group expenses will appear here when members add them',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppTheme.mediumSpacing),
          itemCount: groupExpenses.length,
          itemBuilder: (context, index) {
            final expense = groupExpenses[index];
            return _buildExpenseCard(expense);
          },
        );
      },
    );
  }

  Widget _buildExpenseCard(ExpenseModel expense) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final friendProvider = Provider.of<FriendProvider>(context, listen: false);

    // Find the payer
    final payer = expense.participants.firstWhere(
      (p) => p['isPayer'] == true,
      orElse: () => {'userId': expense.userId, 'name': 'Unknown'},
    );

    String payerName;
    if (payer['userId'] == authProvider.userModel?.id) {
      payerName = 'You';
    } else {
      final friend = friendProvider.friends.firstWhere(
        (f) => f.id == payer['userId'],
        orElse: () => UserModel(id: payer['userId'], name: 'Unknown', email: ''),
      );
      payerName = friend.name;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.mediumSpacing),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          child: Icon(
            Icons.receipt,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          expense.description.isNotEmpty ? expense.description : expense.category,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Paid by $payerName'),
            Text(
              '${AppConstants.currencySymbol}${expense.amount.toStringAsFixed(2)} • ${_formatDate(expense.date)}',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.grey[600],
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.mediumSpacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Split Details:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTheme.smallSpacing),
                ...expense.participants.map((participant) {
                  String participantName;
                  if (participant['userId'] == authProvider.userModel?.id) {
                    participantName = 'You';
                  } else {
                    final friend = friendProvider.friends.firstWhere(
                      (f) => f.id == participant['userId'],
                      orElse: () => UserModel(
                        id: participant['userId'],
                        name: 'Unknown',
                        email: '',
                      ),
                    );
                    participantName = friend.name;
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(participantName),
                        Text(
                          '${AppConstants.currencySymbol}${participant['share'].toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.mediumSpacing),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Theme.of(context).primaryColor,
            size: 24,
          ),
          const SizedBox(height: AppTheme.smallSpacing),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
