import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../models/karma_model.dart';
import '../../providers/karma_provider.dart';
import '../../widgets/karma_badge_widget.dart';
import 'friend_detail_screen.dart';

class FriendProfileScreen extends StatefulWidget {
  final UserModel friend;

  const FriendProfileScreen({
    super.key,
    required this.friend,
  });

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  Map<String, dynamic>? _karmaBadgeInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadKarmaBadgeInfo();
  }

  Future<void> _loadKarmaBadgeInfo() async {
    try {
      final karmaProvider = Provider.of<KarmaProvider>(context, listen: false);
      final badgeInfo = await karmaProvider.getUserBadgeInfo(widget.friend.id);

      setState(() {
        _karmaBadgeInfo = badgeInfo;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading karma badge info: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getInitials(String name) {
    List<String> nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (nameParts.isNotEmpty) {
      return nameParts[0][0].toUpperCase();
    }
    return 'U';
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Profile Header
          SliverAppBar(
            expandedHeight: 280,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Theme.of(context).primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildProfileHeader(),
            ),
            title: Text(widget.friend.name),
          ),

          // Profile Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.mediumSpacing),
              child: Column(
                children: [
                  _buildProfileDetails(),
                  const SizedBox(height: AppTheme.mediumSpacing),
                  _buildKarmaSection(),
                  const SizedBox(height: AppTheme.mediumSpacing),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
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
              const SizedBox(height: 50),

              // Profile Picture
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: widget.friend.photoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.network(
                          widget.friend.photoUrl!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Text(
                            _getInitials(widget.friend.name),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    : Text(
                        _getInitials(widget.friend.name),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),

              const SizedBox(height: AppTheme.mediumSpacing),

              // Name
              Text(
                widget.friend.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppTheme.smallSpacing),

              // Email
              Text(
                widget.friend.email,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileDetails() {
    final additionalData = widget.friend.additionalData;
    final username = additionalData?['username']?.toString() ?? '';
    final age = additionalData?['age']?.toString() ?? '';
    final upiId = additionalData?['upiId']?.toString() ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile Details',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.mediumSpacing),

            if (username.isNotEmpty) ...[
              _buildDetailRow('Username', '@$username'),
              const SizedBox(height: AppTheme.smallSpacing),
            ],

            if (age.isNotEmpty) ...[
              _buildDetailRow('Age', '$age years'),
              const SizedBox(height: AppTheme.smallSpacing),
            ],

            if (upiId.isNotEmpty) ...[
              _buildDetailRow('UPI ID', upiId),
              const SizedBox(height: AppTheme.smallSpacing),
            ],

            // Remove Member Since as UserModel doesn't have createdAt field
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }

  Widget _buildKarmaSection() {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppTheme.mediumSpacing),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_karmaBadgeInfo == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Karma Badge',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.mediumSpacing),
            
            Center(
              child: KarmaBadgeWidget(
                badgeLevel: _karmaBadgeInfo!['badgeLevel'] ?? KarmaBadgeLevel.leastTrusted,
                badgeEmoji: _karmaBadgeInfo!['badgeEmoji'] ?? '⚫',
                nickname: _karmaBadgeInfo!['nickname'] ?? 'The Ghost Debtor 👻',
                badgeName: _karmaBadgeInfo!['badgeName'] ?? 'Least Trusted',
                totalPoints: _karmaBadgeInfo!['totalPoints'] ?? 0,
                isCompact: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to friend detail screen for debt management
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FriendDetailScreen(friend: widget.friend),
                ),
              );
            },
            icon: const Icon(Icons.account_balance_wallet),
            label: const Text('View Debts & Transactions'),
          ),
        ),
        
        const SizedBox(height: AppTheme.smallSpacing),
        
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/karma_leaderboard');
            },
            icon: const Icon(Icons.emoji_events),
            label: const Text('View Karma Leaderboard'),
          ),
        ),
      ],
    );
  }
}
