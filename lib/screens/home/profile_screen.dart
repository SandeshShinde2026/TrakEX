import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friend_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/karma_provider.dart';
import '../../constants/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../utils/validators.dart';
import '../auth/user_details_screen.dart';
import '../settings/theme_settings_screen.dart';
import '../settings/notification_settings_screen.dart';
import '../settings/privacy_settings_screen.dart';
import '../settings/help_support_screen.dart';
import '../settings/about_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isEditing = false;
  bool _isCheckingUsername = false;
  String? _usernameError;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadUserStats();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    if (user != null) {
      _nameController.text = user.name;
      final username = user.additionalData?['username']?.toString() ?? '';
      _usernameController.text = username;
    }
  }

  Future<void> _loadUserStats() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userModel != null) {
      final userId = authProvider.userModel!.id;

      // Get providers before async operations
      final friendProvider = Provider.of<FriendProvider>(context, listen: false);
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
      final karmaProvider = Provider.of<KarmaProvider>(context, listen: false);

      // Load data
      await Future.wait([
        friendProvider.loadFriends(userId),
        expenseProvider.loadUserExpenses(userId),
        karmaProvider.loadUserKarma(userId),
      ]);
    }
  }

  Future<void> _checkUsernameAvailability(String username) async {
    if (username.isEmpty || username.length < 3) {
      setState(() {
        _usernameError = null;
        _isCheckingUsername = false;
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _usernameError = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.userModel?.id;

      final isAvailable = await _authService.isUsernameAvailable(
        username,
        currentUserId: currentUserId,
      );

      if (mounted) {
        setState(() {
          _isCheckingUsername = false;
          _usernameError = isAvailable ? null : 'Username is already taken';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingUsername = false;
          _usernameError = 'Error checking username availability';
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate() && _usernameError == null) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.userModel;

      if (user != null) {
        // Update additional data with new username
        final currentAdditionalData = user.additionalData ?? {};
        final updatedAdditionalData = {
          ...currentAdditionalData,
          'username': _usernameController.text.trim(),
        };

        final updatedUser = user.copyWith(
          name: _nameController.text.trim(),
          additionalData: updatedAdditionalData,
        );

        final success = await authProvider.updateProfile(updatedUser);

        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.error ?? 'Update failed'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          setState(() {
            _isEditing = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with Profile Header
          SliverAppBar(
            expandedHeight: 260, // Reduced from 280 to fix overflow
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Theme.of(context).primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildProfileHeader(user),
            ),
            title: _isEditing ? const Text('Edit Profile') : const Text('Profile'),
            actions: [
              if (!_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                ),
            ],
          ),

          // Profile Content
          SliverToBoxAdapter(
            child: RefreshIndicator(
              onRefresh: _loadUserStats,
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.mediumSpacing),
                child: Column(
                  children: [
                    if (_isEditing)
                      _buildEditForm(user)
                    else ...[
                      _buildUserStats(user),
                      const SizedBox(height: AppTheme.mediumSpacing),
                      _buildUserDetails(user),
                      const SizedBox(height: AppTheme.mediumSpacing),
                    ],
                    _buildSettingsSection(),
                    const SizedBox(height: AppTheme.mediumSpacing),
                    _buildLogoutButton(),
                    const SizedBox(height: AppTheme.mediumSpacing), // Extra bottom padding
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Profile Header for SliverAppBar
  Widget _buildProfileHeader(UserModel user) {
    final additionalData = user.additionalData;
    final username = additionalData?['username']?.toString() ?? '';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.mediumSpacing),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50), // Reduced space for app bar

              // Profile Picture with initials
              CircleAvatar(
                radius: 45, // Slightly smaller
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Text(
                  _getInitials(user.name),
                  style: const TextStyle(
                    fontSize: 28, // Slightly smaller
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.smallSpacing), // Reduced spacing

              // User Name
              Text(
                user.name,
                style: const TextStyle(
                  fontSize: 22, // Slightly smaller
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // Username
              if (username.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  '@$username',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Email
              const SizedBox(height: 2),
              Text(
                user.email,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Get initials from name
  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return 'U';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  // User Statistics Cards
  Widget _buildUserStats(UserModel user) {
    return Consumer3<FriendProvider, ExpenseProvider, KarmaProvider>(
      builder: (context, friendProvider, expenseProvider, karmaProvider, child) {
        // Get actual counts from providers
        final friendsCount = friendProvider.friends.length;
        final karmaPoints = karmaProvider.userKarma?.totalPoints ?? 0;

        // Calculate total expenses
        final totalExpenses = expenseProvider.expenses
            .where((expense) => expense.userId == user.id)
            .fold(0.0, (sum, expense) => sum + expense.amount);

        // Format total expenses for display
        final expensesDisplay = totalExpenses > 999
            ? '${(totalExpenses / 1000).toStringAsFixed(1)}K'
            : totalExpenses.toStringAsFixed(0);

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.mediumSpacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Quick Stats',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.mediumSpacing),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Friends',
                        '$friendsCount',
                        Icons.people,
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Karma',
                        '$karmaPoints',
                        Icons.star,
                        Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Expenses',
                        '₹$expensesDisplay',
                        Icons.receipt_long,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.smallSpacing),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // User Details Card
  Widget _buildUserDetails(UserModel user) {
    final additionalData = user.additionalData;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.mediumSpacing),

            if (additionalData != null) ...[
              // Age and Gender
              if (additionalData['age'] != null || additionalData['gender'] != null)
                _buildDetailRow(
                  Icons.cake,
                  'Age & Gender',
                  '${additionalData['age'] ?? 'Not set'} • ${additionalData['gender'] ?? 'Not set'}',
                ),

              // Phone
              if (additionalData['phone'] != null && additionalData['phone'].toString().isNotEmpty)
                _buildDetailRow(
                  Icons.phone,
                  'Phone',
                  additionalData['phone'].toString(),
                ),

              // Occupation
              if (additionalData['occupation'] != null && additionalData['occupation'].toString().isNotEmpty)
                _buildDetailRow(
                  Icons.work,
                  'Occupation',
                  additionalData['occupation'].toString(),
                ),

              // UPI ID
              if (user.upiId != null && user.upiId!.isNotEmpty)
                _buildDetailRow(
                  Icons.payment,
                  'UPI ID',
                  user.upiVisible ? user.upiId! : 'Hidden',
                ),
            ],

            // Join Date (if available)
            _buildDetailRow(
              Icons.calendar_today,
              'Member Since',
              'Recently', // This can be calculated from user creation date
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Settings Section
  Widget _buildSettingsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.smallSpacing),

            _buildSettingsOption(
              context,
              'Edit Profile Details',
              Icons.person_add,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserDetailsScreen(isNewUser: false),
                  ),
                );
              },
            ),

            _buildSettingsOption(
              context,
              'Notification Settings',
              Icons.notifications,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationSettingsScreen(),
                  ),
                );
              },
            ),

            _buildSettingsOption(
              context,
              'Privacy Settings',
              Icons.privacy_tip,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacySettingsScreen(),
                  ),
                );
              },
            ),

            _buildSettingsOption(
              context,
              'App Theme',
              Icons.color_lens,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ThemeSettingsScreen(),
                  ),
                );
              },
            ),

            _buildSettingsOption(
              context,
              'Help & Support',
              Icons.help,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HelpSupportScreen(),
                  ),
                );
              },
            ),

            _buildSettingsOption(
              context,
              'About',
              Icons.info,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AboutScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Logout Button
  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          _showLogoutConfirmation(context);
        },
        icon: const Icon(Icons.logout, size: 18),
        label: const Text('Logout'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
          ),
          elevation: 2,
        ),
      ),
    );
  }



  Widget _buildEditForm(UserModel user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.edit,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Edit Profile',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.mediumSpacing),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: Validators.validateName,
              ),
              const SizedBox(height: AppTheme.mediumSpacing),

              // Username Field with real-time validation
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixIcon: const Icon(Icons.alternate_email),
                  border: const OutlineInputBorder(),
                  suffixIcon: _isCheckingUsername
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _usernameError == null && _usernameController.text.isNotEmpty
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                  errorText: _usernameError,
                ),
                onChanged: (value) {
                  // Debounce username checking
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (_usernameController.text == value && value.isNotEmpty) {
                      _checkUsernameAvailability(value);
                    }
                  });
                },
                validator: Validators.validateUsername,
              ),
              const SizedBox(height: AppTheme.largeSpacing),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = false;
                          _nameController.text = user.name;
                          final username = user.additionalData?['username']?.toString() ?? '';
                          _usernameController.text = username;
                          _usernameError = null;
                        });
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.mediumSpacing),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _updateProfile,
                      child: const Text('Save Changes'),
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

  Widget _buildSettingsOption(
    BuildContext context,
    String title,
    IconData icon, {
    required VoidCallback onTap,
    Color? color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        side: BorderSide(color: Colors.grey.withAlpha(50), width: 0.5),
      ),
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(horizontal: 0, vertical: -1),
        leading: Icon(
          icon,
          color: color ?? Theme.of(context).primaryColor,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 14,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
      ),
    );
  }

  Future<void> _showLogoutConfirmation(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () {
                Navigator.of(context).pop();
                Provider.of<AuthProvider>(context, listen: false).signOut();
              },
            ),
          ],
        );
      },
    );
  }
}
