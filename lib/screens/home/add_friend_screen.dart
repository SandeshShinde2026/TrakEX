import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../constants/app_theme.dart';
import '../../models/user_model.dart';
import '../../models/friend_request_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friend_provider.dart';
import '../../services/contact_integration_service.dart';

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  bool _isSearching = false;
  String _searchQuery = '';
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _removeOverlay();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel(); // Cancel any active debounce timer
    super.dispose();
  }

  // Debounce timer for search
  Timer? _debounce;

  void _onSearchChanged() {
    // Cancel previous timer if it exists
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    setState(() {
      _searchQuery = _searchController.text;
      _isSearching = _searchQuery.isNotEmpty;
    });

    if (_isSearching) {
      // Set a new timer to delay the search
      _debounce = Timer(const Duration(milliseconds: 500), () {
        _performSearch();
      });
    } else {
      _removeOverlay();
    }
  }

  Future<void> _performSearch() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final friendProvider = Provider.of<FriendProvider>(context, listen: false);

    debugPrint('Performing search with query: "$_searchQuery"');

    // Perform search with any query length
    await friendProvider.searchUsers(_searchQuery, authProvider.userModel!.id);

    debugPrint('Search completed, found ${friendProvider.searchResults.length} results');

    // Print each result for debugging
    for (var user in friendProvider.searchResults) {
      debugPrint('Result: ${user.name} (${user.email}), ID: ${user.id}');
    }

    // Show dropdown with search results
    if (mounted) {
      // Force a rebuild to ensure the UI updates
      setState(() {
        // This will trigger a rebuild
      });

      // Update the overlay
      _updateOverlay();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _updateOverlay() {
    // Remove existing overlay if any
    _removeOverlay();

    // Don't show overlay if not searching
    if (!_isSearching) {
      return;
    }

    // Use a post-frame callback to ensure the render object is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if the widget is still mounted
      if (!mounted) return;

      // Create new overlay even if results are empty to show "No users found" message
      _overlayEntry = OverlayEntry(
        builder: (context) => _buildSearchResultsDropdown(),
      );

      // Add overlay to the screen
      if (_overlayEntry != null) {
        Overlay.of(context).insert(_overlayEntry!);
      }
    });
  }

  Widget _buildSearchResultsDropdown() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final friendProvider = Provider.of<FriendProvider>(context, listen: false);
    final size = MediaQuery.of(context).size;

    // Use fixed dimensions for simplicity and reliability
    final searchFieldSize = Size(size.width - 32, 56);

    return Positioned(
      width: searchFieldSize.width,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        offset: Offset(0.0, searchFieldSize.height + 5.0),
        child: Material(
          elevation: 4.0,
          borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: size.height * 0.4, // Limit height to 40% of screen
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26), // 0.1 * 255 = 26
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: friendProvider.searchResults.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(AppTheme.mediumSpacing),
                    child: const Text(
                      'No users found',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Found ${friendProvider.searchResults.length} users',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      Flexible(
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: friendProvider.searchResults.length,
                          itemBuilder: (context, index) {
                            final user = friendProvider.searchResults[index];
                            return _buildDropdownItem(user, authProvider, friendProvider);
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownItem(
    UserModel user,
    AuthProvider authProvider,
    FriendProvider friendProvider,
  ) {
    return InkWell(
      onTap: () {
        // Close dropdown
        _removeOverlay();

        // Show user details
        _showUserDetailsDialog(user, authProvider, friendProvider);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.mediumSpacing,
          vertical: AppTheme.smallSpacing,
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              radius: 20,
              child: user.photoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        user.photoUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white),
                      ),
                    )
                  : const Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: AppTheme.smallSpacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user.email,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserDetailsDialog(
    UserModel user,
    AuthProvider authProvider,
    FriendProvider friendProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                radius: 40,
                child: user.photoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: Image.network(
                          user.photoUrl!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 40),
                        ),
                      )
                    : const Icon(Icons.person, color: Colors.white, size: 40),
              ),
            ),
            const SizedBox(height: AppTheme.mediumSpacing),
            Text('Email: ${user.email}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FutureBuilder<FriendRequestModel?>(
            future: friendProvider.checkExistingRequest(
              authProvider.userModel!.id,
              user.id,
            ),
            builder: (context, snapshot) {
              final existingRequest = snapshot.data;
              final bool isFriend = friendProvider.isFriend(user.id);

              if (isFriend) {
                return TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Already Friends'),
                );
              }

              if (existingRequest != null) {
                if (existingRequest.senderId == authProvider.userModel!.id) {
                  // Current user sent the request
                  if (existingRequest.status == FriendRequestStatus.pending) {
                    return TextButton(
                      onPressed: () async {
                        await friendProvider.cancelFriendRequest(existingRequest.id);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      child: const Text('Cancel Request'),
                    );
                  }
                } else {
                  // Request received from this user
                  if (existingRequest.status == FriendRequestStatus.pending) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () async {
                            await friendProvider.acceptFriendRequest(existingRequest.id);
                            await friendProvider.loadFriends(authProvider.userModel!.id);
                            if (context.mounted) Navigator.of(context).pop();
                          },
                          child: const Text('Accept'),
                        ),
                        TextButton(
                          onPressed: () async {
                            await friendProvider.rejectFriendRequest(existingRequest.id);
                            if (context.mounted) Navigator.of(context).pop();
                          },
                          child: const Text('Reject'),
                        ),
                      ],
                    );
                  }
                }
              }

              // No existing request
              return TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _sendFriendRequest(context, user, authProvider, friendProvider);
                },
                child: const Text('Add Friend'),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final friendProvider = Provider.of<FriendProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Friend'),
        actions: [
          IconButton(
            onPressed: _showContactPicker,
            icon: const Icon(Icons.contacts),
            tooltip: 'Add from Contacts',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.mediumSpacing),
            child: CompositedTransformTarget(
              link: _layerLink,
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Search by name or email',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _isSearching
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _isSearching = false;
                              _searchQuery = '';
                            });
                            _removeOverlay();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                  ),
                ),
                onSubmitted: (_) => _performSearch(),
              ),
            ),
          ),

          if (friendProvider.isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.search,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: AppTheme.mediumSpacing),
                    const Text(
                      'Search for friends',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: AppTheme.smallSpacing),
                    const Text(
                      'Enter a name or email to find friends\nor tap the contacts icon to add from your contacts',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    if (_isSearching && friendProvider.searchResults.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: AppTheme.mediumSpacing),
                        child: Text(
                          'No users found',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }



  // Show contact picker
  Future<void> _showContactPicker() async {
    try {
      final contactFriend = await ContactIntegrationService().showContactPicker(context);

      if (contactFriend != null && mounted) {
        // If the contact has an email, search for them in the app
        if (contactFriend.email != null) {
          _searchController.text = contactFriend.email!;
          _performSearch();
        } else if (contactFriend.phoneNumber != null) {
          // Try searching by phone number
          _searchController.text = contactFriend.phoneNumber!;
          _performSearch();
        } else {
          // Show message that contact doesn't have email or phone
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${contactFriend.name} doesn\'t have an email or phone number to search with'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accessing contacts: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendFriendRequest(
    BuildContext context,
    UserModel receiver,
    AuthProvider authProvider,
    FriendProvider friendProvider,
  ) async {
    // Store context-related values before the async gap
    final currentUser = authProvider.userModel!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final success = await friendProvider.sendFriendRequest(
      currentUser.id,
      receiver.id,
      currentUser.name,
      currentUser.email,
      currentUser.photoUrl,
      receiver.name,
      receiver.email,
      receiver.photoUrl,
    );

    // Check if widget is still mounted before showing snackbar
    if (!mounted) return;

    if (success) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Friend request sent')),
      );
    } else if (friendProvider.error != null) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(friendProvider.error!)),
      );
    }
  }
}
