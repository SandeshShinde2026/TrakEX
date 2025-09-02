import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../models/friend_request_model.dart';
import '../../models/karma_model.dart';
import '../../models/debt_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/debt_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/friend_provider.dart';
import '../../providers/karma_provider.dart';
import '../../providers/in_app_notification_provider.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/karma_badge_widget.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../providers/ad_provider.dart';
import '../../services/reminder_service.dart';
import 'add_friend_screen.dart';
import 'friend_detail_screen.dart';
import 'friend_profile_screen.dart';
import 'create_group_screen.dart';
import 'manage_groups_screen.dart';

// Enum for group expense filter
enum GroupExpenseFilter {
  all,
  theyOwe,
  youOwe,
}

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<UserModel> _filteredFriends = [];
  List<Map<String, dynamic>> _filteredYouOwe = [];
  List<Map<String, dynamic>> _filteredOwedToYou = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // Updated to 4 tabs
    _searchController.addListener(_onSearchChanged);

    // Load friends and requests when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Debounce the search to avoid excessive filtering
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
        _filterFriends();
      });
    });
  }

  void _filterFriends() {
    final friendProvider = Provider.of<FriendProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated) return;

    final userId = authProvider.userModel!.id;

    // Filter main friends list
    if (_searchQuery.isEmpty) {
      _filteredFriends = List.from(friendProvider.friends);
    } else {
      _filteredFriends = friendProvider.friends.where((friend) {
        return friend.name.toLowerCase().contains(_searchQuery) ||
               friend.email.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    // Filter "You Owe" list
    final friendsUserOwes = friendProvider.getFriendsUserOwes(userId);
    if (_searchQuery.isEmpty) {
      _filteredYouOwe = List.from(friendsUserOwes);
    } else {
      _filteredYouOwe = friendsUserOwes.where((item) {
        final friend = item['friend'] as UserModel;
        return friend.name.toLowerCase().contains(_searchQuery) ||
               friend.email.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    // Filter "Owed to You" list
    final friendsWhoOwe = friendProvider.getFriendsWhoOwe(userId);
    if (_searchQuery.isEmpty) {
      _filteredOwedToYou = List.from(friendsWhoOwe);
    } else {
      _filteredOwedToYou = friendsWhoOwe.where((item) {
        final friend = item['friend'] as UserModel;
        return friend.name.toLowerCase().contains(_searchQuery) ||
               friend.email.toLowerCase().contains(_searchQuery);
      }).toList();
    }
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final friendProvider = Provider.of<FriendProvider>(context, listen: false);

    if (authProvider.isAuthenticated) {
      await friendProvider.loadFriends(authProvider.userModel!.id);
      await friendProvider.loadFriendRequests(authProvider.userModel!.id);
      _filterFriends();
    }
  }

  void _showGroupOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppTheme.mediumSpacing),

            Text(
              'Group Options',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.mediumSpacing),

            // Create Group Option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.group_add, color: Colors.green),
              ),
              title: const Text('Create New Group'),
              subtitle: const Text('Create a group with your friends'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateGroupScreen()),
                ).then((_) => _loadData());
              },
            ),

            // Manage Groups Option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.settings, color: Colors.blue),
              ),
              title: const Text('Manage Groups'),
              subtitle: const Text('View and manage your existing groups'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ManageGroupsScreen()),
                ).then((_) => _loadData());
              },
            ),

            const SizedBox(height: AppTheme.mediumSpacing),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final friendProvider = Provider.of<FriendProvider>(context);

    // Show loading indicator if data is loading
    if (friendProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Get the count of pending requests
    final pendingRequestsCount = friendProvider.receivedRequests.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        automaticallyImplyLeading: false,
        actions: [
          // Karma Leaderboard button
          IconButton(
            icon: const Icon(Icons.emoji_events),
            onPressed: () {
              Navigator.pushNamed(context, '/karma_leaderboard');
            },
            tooltip: 'Karma Leaderboard',
          ),
          // Request button with badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  _showRequestsDialog(context);
                },
              ),
              if (pendingRequestsCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      pendingRequestsCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: StickyBannerAdWidget(
        adLocation: 'dashboard', // Reuse dashboard ads for friends screen
        child: Column(
          children: [
            // Tab bar
            TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
            unselectedLabelColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[400]
                : Colors.grey[600],
            indicatorColor: Theme.of(context).primaryColor,
            indicatorWeight: 3,
            labelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 14,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey[600],
            ),
            tabs: const [
              Tab(text: 'Friends'),
              Tab(text: 'You Owe'),
              Tab(text: 'They Owe'),
              Tab(text: 'Splits'),
            ],
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFriendsTab(),
                _buildYouOweTab(),
                _buildTheyOweTab(),
                _buildSplitsTab(),   // New tab for group expenses
              ],
            ),
          ),

        ],
      ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Groups FAB
          FloatingActionButton(
            heroTag: "groups_fab",
            onPressed: () {
              _showGroupOptions(context);
            },
            tooltip: 'Group Options',
            child: const Icon(Icons.group, size: 24),
          ),
          const SizedBox(height: 8),
          // Add Friend FAB
          FloatingActionButton(
            heroTag: "add_friend_fab",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddFriendScreen()),
              ).then((_) => _loadData());
            },
            tooltip: 'Add Friend',
            child: const Icon(Icons.person_add, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsTab() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.mediumSpacing),
      child: Column(
        children: [
          // Search bar
          _buildSearchBar(),
          const SizedBox(height: AppTheme.mediumSpacing),

          // Friends list
          Expanded(
            child: _buildFriendsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
    final friendProvider = Provider.of<FriendProvider>(context);

    if (friendProvider.friends.isEmpty) {
      // No friends yet
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: AppTheme.mediumSpacing),
            Text(
              'No friends yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.mediumGray,
              ),
            ),
            const SizedBox(height: AppTheme.smallSpacing),
            Text(
              'Tap the + button to add friends',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else if (_filteredFriends.isEmpty && _searchQuery.isNotEmpty) {
      // No search results
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: AppTheme.mediumSpacing),
            Text(
              'No matching friends',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.mediumGray,
              ),
            ),
            const SizedBox(height: AppTheme.smallSpacing),
            Text(
              'No friends found matching "$_searchQuery"',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else {
      // Show friends list
      return ListView.builder(
        itemCount: _filteredFriends.length,
        itemBuilder: (context, index) {
          return _buildFriendItem(_filteredFriends[index]);
        },
      );
    }
  }

  void _showRequestsDialog(BuildContext context) {
    final friendProvider = Provider.of<FriendProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
        ),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with close button
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.mediumSpacing,
                  vertical: AppTheme.smallSpacing,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withAlpha(25),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.mediumRadius),
                    topRight: Radius.circular(AppTheme.mediumRadius),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Friend Requests',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.mediumSpacing),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (friendProvider.receivedRequests.isNotEmpty) ...[
                          // Received Requests Section
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.smallSpacing,
                              vertical: AppTheme.smallSpacing / 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withAlpha(13),
                              borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.arrow_downward, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Received Requests',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.smallSpacing),

                          // Received Requests List
                          ...friendProvider.receivedRequests.map((request) =>
                            _buildImprovedRequestItem(
                              context,
                              request,
                              isReceived: true,
                            ),
                          ),

                          const SizedBox(height: AppTheme.mediumSpacing),
                        ],

                        if (friendProvider.sentRequests.isNotEmpty) ...[
                          // Sent Requests Section
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.smallSpacing,
                              vertical: AppTheme.smallSpacing / 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withAlpha(13),
                              borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.arrow_upward, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Sent Requests',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.smallSpacing),

                          // Sent Requests List
                          ...friendProvider.sentRequests.map((request) =>
                            _buildImprovedRequestItem(
                              context,
                              request,
                              isReceived: false,
                            ),
                          ),
                        ],

                        // Empty State
                        if (friendProvider.receivedRequests.isEmpty &&
                            friendProvider.sentRequests.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppTheme.largeSpacing),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.people_outline,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: AppTheme.mediumSpacing),
                                  Text(
                                    'No friend requests',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: AppTheme.mediumGray,
                                    ),
                                  ),
                                  const SizedBox(height: AppTheme.smallSpacing),
                                  Text(
                                    'When you send or receive friend requests, they will appear here',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.mediumGray,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
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
      ),
    );
  }

  Widget _buildFriendItem(UserModel friend) {
    // Get responsive values
    final avatarSize = ResponsiveHelper.getResponsiveValue<double>(
      context: context,
      mobile: 40,
      tablet: 48,
      desktop: 56,
    );

    final titleFontSize = ResponsiveHelper.getResponsiveFontSize(
      context,
      baseFontSize: 16,
    );

    final subtitleFontSize = ResponsiveHelper.getResponsiveFontSize(
      context,
      baseFontSize: 14,
    );

    final cardPadding = ResponsiveHelper.getResponsiveValue<EdgeInsetsGeometry>(
      context: context,
      mobile: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      tablet: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      desktop: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    );

    // Get karma badge info
    final karmaProvider = Provider.of<KarmaProvider>(context, listen: false);

    return FutureBuilder<Map<String, dynamic>>(
      future: karmaProvider.getUserBadgeInfo(friend.id),
      builder: (context, snapshot) {
        // Default badge info if not loaded yet
        final badgeEmoji = snapshot.hasData ? snapshot.data!['badgeEmoji'] : '⚫';

        return Card(
          margin: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveSpacing(context) / 2),
          child: Padding(
            padding: cardPadding,
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.getResponsiveSpacing(context) / 2,
                vertical: ResponsiveHelper.getResponsiveSpacing(context) / 4,
              ),
              leading: GestureDetector(
                onTap: () {
                  // Navigate to friend profile screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FriendProfileScreen(friend: friend),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: avatarSize / 2,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: friend.photoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(avatarSize / 2),
                          child: Image.network(
                            friend.photoUrl!,
                            width: avatarSize,
                            height: avatarSize,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.person,
                              color: Colors.white,
                              size: avatarSize / 2,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.person,
                          color: Colors.white,
                          size: avatarSize / 2,
                        ),
                ),
              ),
              title: Row(
                children: [
                  Text(
                    friend.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    badgeEmoji,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              subtitle: Text(
                friend.email,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: subtitleFontSize,
                ),
              ),
              // No amount displayed in the main Friends tab
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.person_remove, color: Colors.red),
                    onPressed: () => _showRemoveFriendDialog(friend),
                    tooltip: 'Remove Friend',
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () {
                // Navigate to friend details
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FriendDetailScreen(friend: friend),
                  ),
                ).then((_) => _loadData());
              },
            ),
          ),
        );
      },
    );
  }

  void _showRemoveFriendDialog(UserModel friend) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
        ),
        title: const Text('Remove Friend'),
        content: Text(
          'Are you sure you want to remove ${friend.name} from your friends list? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _removeFriend(friend);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeFriend(UserModel friend) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final friendProvider = Provider.of<FriendProvider>(context, listen: false);

    if (!authProvider.isAuthenticated) return;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final success = await friendProvider.removeFriend(
        authProvider.userModel!.id,
        friend.id,
      );

      // Hide loading indicator
      if (mounted) Navigator.of(context).pop();

      if (success) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${friend.name} has been removed from your friends list. All related debt data has been cleared.'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }

        // Reload data to refresh the UI
        await _loadData();

        // Also refresh all provider data to update dashboard and other screens
        if (mounted) {
          final debtProvider = Provider.of<DebtProvider>(context, listen: false);
          final friendProvider = Provider.of<FriendProvider>(context, listen: false);
          final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);

          debugPrint('FriendsScreen: Starting comprehensive data refresh after friend removal');

          // Clear any cached debt data first
          debtProvider.clearError();
          debtProvider.forceClearCache();

          // Reload all debt data with proper error handling
          try {
            await Future.wait([
              debtProvider.loadLentDebts(authProvider.userModel!.id),
              debtProvider.loadBorrowedDebts(authProvider.userModel!.id),
              friendProvider.loadFriends(authProvider.userModel!.id),
              expenseProvider.loadUserExpenses(authProvider.userModel!.id),
            ]);

            debugPrint('FriendsScreen: All providers refreshed successfully after friend removal');

            // Force a small delay to ensure all data is processed
            await Future.delayed(const Duration(milliseconds: 500));

            debugPrint('FriendsScreen: Data refresh complete - dashboard should now show updated summary');

          } catch (e) {
            debugPrint('FriendsScreen: Error refreshing providers after friend removal: $e');
          }
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove ${friend.name}. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Hide loading indicator if still showing
      if (mounted) Navigator.of(context).pop();

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildImprovedRequestItem(
    BuildContext context,
    FriendRequestModel request,
    {required bool isReceived}
  ) {
    final friendProvider = Provider.of<FriendProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    // Determine the name to display (no email)
    final name = isReceived ? request.senderName ?? 'Unknown' : request.receiverName ?? 'Unknown';
    final photoUrl = isReceived ? request.senderPhotoUrl : request.receiverPhotoUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.smallSpacing),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              radius: 20,
              child: photoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        photoUrl,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white),
                      ),
                    )
                  : const Icon(Icons.person, color: Colors.white),
            ),

            const SizedBox(width: AppTheme.smallSpacing),

            // Name
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Action buttons
            if (isReceived)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Accept button
                  Material(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                      onTap: () async {
                        await friendProvider.acceptFriendRequest(request.id);
                        await friendProvider.loadFriends(authProvider.userModel!.id);
                        await friendProvider.loadFriendRequests(authProvider.userModel!.id);
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Reject button
                  Material(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                      onTap: () async {
                        await friendProvider.rejectFriendRequest(request.id);
                        await friendProvider.loadFriendRequests(authProvider.userModel!.id);
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              // Cancel button
              ElevatedButton(
                onPressed: () async {
                  await friendProvider.cancelFriendRequest(request.id);
                  await friendProvider.loadFriendRequests(authProvider.userModel!.id);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade800
                      : Colors.grey.shade200,
                  foregroundColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.smallSpacing,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                  ),
                ),
                child: const Text('Cancel'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildYouOweTab() {
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAuthenticated) {
      return const Center(child: Text('Please log in to view your debts'));
    }

    // Use filtered list instead of direct provider access
    if (_filteredYouOwe.isEmpty && _searchQuery.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
        child: Column(
          children: [
            // Search bar
            _buildSearchBar(),

            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.arrow_upward,
                      size: 64,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: AppTheme.mediumSpacing),
                    Text(
                      'You don\'t owe anyone',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade300
                            : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: AppTheme.smallSpacing),
                    Text(
                      'When you owe money to friends, it will appear here',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else if (_filteredYouOwe.isEmpty && _searchQuery.isNotEmpty) {
      // No search results
      return Padding(
        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
        child: Column(
          children: [
            // Search bar
            _buildSearchBar(),

            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.search_off,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: AppTheme.mediumSpacing),
                    Text(
                      'No matching friends',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade300
                            : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: AppTheme.smallSpacing),
                    Text(
                      'No friends found matching "$_searchQuery"',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppTheme.mediumSpacing),
      child: Column(
        children: [
          // Search bar
          _buildSearchBar(),

          const SizedBox(height: AppTheme.mediumSpacing),

          // Friends list
          Expanded(
            child: ListView.builder(
              itemCount: _filteredYouOwe.length,
              itemBuilder: (context, index) {
                final item = _filteredYouOwe[index];
                final friend = item['friend'] as UserModel;
                final amount = item['amount'] as double;

                return Card(
                  margin: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
                  child: ListTile(
                    leading: GestureDetector(
                      onTap: () {
                        // Navigate to friend profile screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FriendProfileScreen(friend: friend),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        child: friend.photoUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.network(
                                  friend.photoUrl!,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white),
                                ),
                              )
                            : const Icon(Icons.person, color: Colors.white),
                      ),
                    ),
                    title: Text(friend.name),
                    subtitle: Text('You owe (Direct)'),
                    trailing: Text(
                      '${AppConstants.currencySymbol}${amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FriendDetailScreen(friend: friend),
                        ),
                      ).then((_) => _loadData());
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Reusable search bar widget
  Widget _buildSearchBar() {
    // Get responsive values
    final padding = ResponsiveHelper.getResponsiveValue<EdgeInsetsGeometry>(
      context: context,
      mobile: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      tablet: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      desktop: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );

    final fontSize = ResponsiveHelper.getResponsiveFontSize(
      context,
      baseFontSize: 14,
    );

    final iconSize = ResponsiveHelper.getResponsiveValue<double>(
      context: context,
      mobile: 20,
      tablet: 22,
      desktop: 24,
    );

    return Container(
      width: ResponsiveHelper.getResponsiveWidth(context),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade700
              : Colors.grey.shade300,
        ),
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade800
            : Colors.grey.shade50,
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(fontSize: fontSize),
        decoration: InputDecoration(
          hintText: 'Search friends',
          hintStyle: TextStyle(fontSize: fontSize),
          prefixIcon: Icon(Icons.search, size: iconSize),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, size: iconSize),
                  onPressed: () {
                    _searchController.clear();
                    // Explicitly trigger search update when cleared
                    setState(() {
                      _searchQuery = '';
                      _filterFriends();
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: padding,
        ),
        textInputAction: TextInputAction.search,
        onSubmitted: (_) {
          // This will trigger when user presses the search button on keyboard
          FocusScope.of(context).unfocus();
        },
      ),
    );
  }

  Widget _buildTheyOweTab() {
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAuthenticated) {
      return const Center(child: Text('Please log in to view money owed to you'));
    }

    // Use filtered list instead of direct provider access
    if (_filteredOwedToYou.isEmpty && _searchQuery.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
        child: Column(
          children: [
            // Search bar
            _buildSearchBar(),

            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.arrow_downward,
                      size: 64,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: AppTheme.mediumSpacing),
                    Text(
                      'No one owes you money',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade300
                            : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: AppTheme.smallSpacing),
                    Text(
                      'When friends owe you money, it will appear here',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else if (_filteredOwedToYou.isEmpty && _searchQuery.isNotEmpty) {
      // No search results
      return Padding(
        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
        child: Column(
          children: [
            // Search bar
            _buildSearchBar(),

            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.search_off,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: AppTheme.mediumSpacing),
                    Text(
                      'No matching friends',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade300
                            : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: AppTheme.smallSpacing),
                    Text(
                      'No friends found matching "$_searchQuery"',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppTheme.mediumSpacing),
      child: Column(
        children: [
          // Search bar
          _buildSearchBar(),

          const SizedBox(height: AppTheme.mediumSpacing),

          // Friends list
          Expanded(
            child: ListView.builder(
              itemCount: _filteredOwedToYou.length,
              itemBuilder: (context, index) {
                final item = _filteredOwedToYou[index];
                final friend = item['friend'] as UserModel;
                final amount = item['amount'] as double;

                return Card(
                  margin: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
                  child: ListTile(
                    leading: GestureDetector(
                      onTap: () {
                        // Navigate to friend profile screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FriendProfileScreen(friend: friend),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        child: friend.photoUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.network(
                                  friend.photoUrl!,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white),
                                ),
                              )
                            : const Icon(Icons.person, color: Colors.white),
                      ),
                    ),
                    title: Text(friend.name),
                    subtitle: Text('Owes you (Direct)'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${AppConstants.currencySymbol}${amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _sendDirectDebtReminder(context, friend, amount),
                          icon: const Icon(Icons.notifications_active, size: 20),
                          color: Colors.orange,
                          tooltip: 'Send Reminder',
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          padding: const EdgeInsets.all(4),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FriendDetailScreen(friend: friend),
                        ),
                      ).then((_) => _loadData());
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  // Group expense filter state
  GroupExpenseFilter _groupExpenseFilter = GroupExpenseFilter.all;

  Widget _buildSplitsTab() {
    final authProvider = Provider.of<AuthProvider>(context);
    final friendProvider = Provider.of<FriendProvider>(context);

    if (!authProvider.isAuthenticated) {
      return const Center(child: Text('Please log in to view your group expenses'));
    }

    final userId = authProvider.userModel!.id;
    final allGroupExpenses = friendProvider.getFriendsWithGroupExpenses(userId);

    // Filter group expenses based on selected filter
    List<Map<String, dynamic>> groupExpenses = [];
    switch (_groupExpenseFilter) {
      case GroupExpenseFilter.all:
        groupExpenses = allGroupExpenses;
        break;
      case GroupExpenseFilter.theyOwe:
        groupExpenses = allGroupExpenses.where((item) => item['isOwed'] == true).toList();
        break;
      case GroupExpenseFilter.youOwe:
        groupExpenses = allGroupExpenses.where((item) => item['isOwed'] == false).toList();
        break;
    }

    if (allGroupExpenses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
        child: Column(
          children: [
            // Search bar
            _buildSearchBar(),

            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.group,
                      size: 64,
                      color: Colors.purple,
                    ),
                    const SizedBox(height: AppTheme.mediumSpacing),
                    Text(
                      'No Group Expenses',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade300
                            : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: AppTheme.smallSpacing),
                    Text(
                      'Group expenses split with friends will appear here',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.mediumSpacing),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to add expense screen
                        Navigator.pushNamed(context, '/add_expense');
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Group Expense'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Display group expenses
    return Padding(
      padding: const EdgeInsets.all(AppTheme.mediumSpacing),
      child: Column(
        children: [
          // Search bar
          _buildSearchBar(),

          const SizedBox(height: AppTheme.mediumSpacing),

          // Filter buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildGroupExpenseFilterButton(
                'All',
                Icons.list,
                _groupExpenseFilter == GroupExpenseFilter.all,
                () => setState(() => _groupExpenseFilter = GroupExpenseFilter.all),
              ),
              _buildGroupExpenseFilterButton(
                'They Owe',
                Icons.arrow_downward,
                _groupExpenseFilter == GroupExpenseFilter.theyOwe,
                () => setState(() => _groupExpenseFilter = GroupExpenseFilter.theyOwe),
              ),
              _buildGroupExpenseFilterButton(
                'You Owe',
                Icons.arrow_upward,
                _groupExpenseFilter == GroupExpenseFilter.youOwe,
                () => setState(() => _groupExpenseFilter = GroupExpenseFilter.youOwe),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.mediumSpacing),

          // Group expenses list
          Expanded(
            child: groupExpenses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _groupExpenseFilter == GroupExpenseFilter.theyOwe
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          size: 64,
                          color: _groupExpenseFilter == GroupExpenseFilter.theyOwe
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(height: AppTheme.mediumSpacing),
                        Text(
                          _groupExpenseFilter == GroupExpenseFilter.theyOwe
                              ? 'No friends owe you for group expenses'
                              : 'You don\'t owe anyone for group expenses',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade300
                                : Colors.grey.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: groupExpenses.length,
                    itemBuilder: (context, index) {
                      final item = groupExpenses[index];
                      final friend = item['friend'] as UserModel;
                      final amount = item['amount'] as double;
                      final isOwed = item['isOwed'] as bool;

                      return Card(
                        margin: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
                        child: ListTile(
                          leading: GestureDetector(
                            onTap: () {
                              // Navigate to friend profile screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FriendProfileScreen(friend: friend),
                                ),
                              );
                            },
                            child: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor,
                              child: friend.photoUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Image.network(
                                        friend.photoUrl!,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.person, color: Colors.white),
                            ),
                          ),
                          title: Text(friend.name),
                          subtitle: Text(isOwed ? 'Owes you (Group)' : 'You owe (Group)'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${AppConstants.currencySymbol}${amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isOwed ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              if (isOwed) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () => _sendGroupExpenseReminder(context, friend, amount),
                                  icon: const Icon(Icons.notifications_active, size: 20),
                                  color: Colors.orange,
                                  tooltip: 'Send Reminder',
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                ),
                              ],
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FriendDetailScreen(friend: friend),
                              ),
                            ).then((_) => _loadData());
                          },
                        ),
                      );
                    },
                  ),
          ),

          // Add group expense button
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.mediumSpacing),
            child: ElevatedButton.icon(
              onPressed: () {
                // Navigate to add expense screen
                Navigator.pushNamed(context, '/add_expense');
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Group Expense'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupExpenseFilterButton(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.smallRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.mediumSpacing,
          vertical: AppTheme.smallSpacing,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withAlpha(30)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.smallRadius),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Send reminder for direct debt
  void _sendDirectDebtReminder(BuildContext context, UserModel friend, double amount) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final inAppProvider = Provider.of<InAppNotificationProvider>(context, listen: false);
    final reminderService = ReminderService();

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Sending reminder...'),
          ],
        ),
      ),
    );

    try {
      // Create a temporary debt model for the reminder
      // Note: This is a simplified approach. In a real app, you'd want to get the actual debt details
      final tempDebt = DebtModel(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        creditorId: authProvider.userModel!.id,
        debtorId: friend.id,
        amount: amount,
        description: 'Direct debt reminder',
        createdAt: DateTime.now(),
        status: PaymentStatus.pending,
        paymentMethod: PaymentMethod.other,
        debtType: DebtType.direct,
      );

      final success = await reminderService.sendDebtReminder(
        debt: tempDebt,
        friend: friend,
        currentUser: authProvider.userModel!,
        inAppProvider: inAppProvider,
      );

      // Hide loading dialog
      if (context.mounted) Navigator.pop(context);

      // Show result message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                ? '📱 Payment reminder sent to ${friend.name}!'
                : 'Failed to send reminder. Please try again.',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Hide loading dialog
      if (context.mounted) Navigator.pop(context);

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending reminder: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Send reminder for group expense
  void _sendGroupExpenseReminder(BuildContext context, UserModel friend, double amount) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final inAppProvider = Provider.of<InAppNotificationProvider>(context, listen: false);
    final reminderService = ReminderService();

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Sending reminder...'),
          ],
        ),
      ),
    );

    try {
      // Create a temporary group debt model for the reminder
      final tempGroupDebt = DebtModel(
        id: 'temp_group_${DateTime.now().millisecondsSinceEpoch}',
        creditorId: authProvider.userModel!.id,
        debtorId: friend.id,
        amount: amount,
        description: 'Group expense reminder',
        createdAt: DateTime.now(),
        status: PaymentStatus.pending,
        paymentMethod: PaymentMethod.other,
        debtType: DebtType.groupExpense,
      );

      final success = await reminderService.sendGroupExpenseReminder(
        groupDebt: tempGroupDebt,
        friend: friend,
        currentUser: authProvider.userModel!,
        inAppProvider: inAppProvider,
      );

      // Hide loading dialog
      if (context.mounted) Navigator.pop(context);

      // Show result message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                ? '📱 Group expense reminder sent to ${friend.name}!'
                : 'Failed to send reminder. Please try again.',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Hide loading dialog
      if (context.mounted) Navigator.pop(context);

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending reminder: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}