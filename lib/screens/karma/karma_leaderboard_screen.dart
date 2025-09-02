import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/karma_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friend_provider.dart';
import '../../providers/karma_provider.dart';

class KarmaLeaderboardScreen extends StatefulWidget {
  const KarmaLeaderboardScreen({super.key});

  @override
  State<KarmaLeaderboardScreen> createState() => _KarmaLeaderboardScreenState();
}

class _KarmaLeaderboardScreenState extends State<KarmaLeaderboardScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load data after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLeaderboard();
    });
  }

  Future<void> _loadLeaderboard() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('Loading karma leaderboard...');
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final friendProvider = Provider.of<FriendProvider>(context, listen: false);
      final karmaProvider = Provider.of<KarmaProvider>(context, listen: false);

      if (authProvider.userModel == null) {
        debugPrint('User model is null!');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // Load friends if not already loaded
      if (friendProvider.friends.isEmpty) {
        await friendProvider.loadFriends(authProvider.userModel!.id);
      }

      // Get friend IDs
      final friendIds = friendProvider.friends.map((friend) => friend.id).toList();

      // Load karma leaderboard
      await karmaProvider.loadKarmaLeaderboard(authProvider.userModel!.id, friendIds);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading leaderboard: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading leaderboard: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Karma Leaderboard',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: _showKarmaInfoDialog,
            tooltip: 'Karma Points Info',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadLeaderboard,
            tooltip: 'Refresh leaderboard',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  void _showKarmaInfoDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryColor = isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'How to Earn Karma Points',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Points are earned for both direct debts and shared expense repayments:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: secondaryColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),

              // Points breakdown
              _buildPointRow('Within 1 hour', 100),
              _buildPointRow('Within 2-6 hours', 80),
              _buildPointRow('Within 6-12 hours', 60),
              _buildPointRow('Within 12-24 hours', 40),
              _buildPointRow('Within 1-2 days', 20),
              _buildPointRow('After 2+ days', 5),

              const SizedBox(height: 24),

              // Badge levels
              Text(
                'Badge Levels:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              _buildBadgeRow('🤑 Top Repayer', '900+ points'),
              _buildBadgeRow('😎 Reliable Buddy', '700-899 points'),
              _buildBadgeRow('😬 Okayish Repayer', '500-699 points'),
              _buildBadgeRow('😵‍💫 Slow Payer', '300-499 points'),
              _buildBadgeRow('🤡 Least Trusted', '<300 points'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildPointRow(String timeFrame, int points) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color pointColor = points >= 80
        ? Colors.green.shade600
        : points >= 60
            ? Colors.blue.shade600
            : points >= 40
                ? Colors.amber.shade700
                : points >= 20
                    ? Colors.orange.shade700
                    : Colors.red.shade600;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              timeFrame,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: pointColor.withAlpha(isDarkMode ? 40 : 30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$points points',
              style: TextStyle(
                color: isDarkMode ? pointColor.withAlpha(240) : pointColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeRow(String badge, String points) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              badge,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800,
              ),
            ),
          ),
          Text(
            points,
            style: TextStyle(
              color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final karmaProvider = Provider.of<KarmaProvider>(context);
    final leaderboard = karmaProvider.leaderboard;

    if (leaderboard.isEmpty) {
      return _buildEmptyState();
    }

    return _buildLeaderboard(leaderboard);
  }

  Widget _buildEmptyState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor = isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_rounded,
              size: 72,
              color: isDarkMode ? Colors.amber.shade300 : Colors.amber.shade600,
            ),
            const SizedBox(height: 24),
            Text(
              'No Karma Data Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start repaying debts to earn karma points!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadLeaderboard,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboard(List<Map<String, dynamic>> leaderboard) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: leaderboard.length + 1, // +1 for the header
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildLeaderboardHeader();
        }

        final userRank = index;
        final userData = leaderboard[index - 1];
        final isCurrentUser = userData['isCurrentUser'] ?? false;

        return _buildLeaderboardItem(
          rank: userRank,
          name: userData['name'] ?? 'Unknown',
          photoUrl: userData['photoUrl'],
          badgeLevel: userData['badgeLevel'] ?? KarmaBadgeLevel.leastTrusted,
          badgeEmoji: userData['badgeEmoji'] ?? '🤡',
          nickname: userData['nickname'] ?? 'The Clown Collector',
          badgeName: userData['badgeName'] ?? 'Least Trusted',
          totalPoints: userData['totalPoints'] ?? 0,
          isCurrentUser: isCurrentUser,
        );
      },
    );
  }

  Widget _buildLeaderboardHeader() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Karma Leaderboard',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                Text(
                  'Tap ⓘ for info',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }



  Widget _buildLeaderboardItem({
    required int rank,
    required String name,
    String? photoUrl,
    required KarmaBadgeLevel badgeLevel,
    required String badgeEmoji,
    required String nickname,
    required String badgeName,
    required int totalPoints,
    required bool isCurrentUser,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final rankColor = _getRankColor(rank);
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryColor = isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCurrentUser
              ? Theme.of(context).primaryColor.withAlpha(75)
              : isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
          width: 1,
        ),
      ),
      color: isCurrentUser
          ? Theme.of(context).primaryColor.withAlpha(12)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Rank
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: rankColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // User photo
            CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).primaryColor,
              child: photoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(
                        photoUrl,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 18),
                      ),
                    )
                  : const Icon(Icons.person, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),

            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 4),
                        Text(
                          '(You)',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                            color: secondaryColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        badgeEmoji,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          badgeName,
                          style: TextStyle(
                            color: secondaryColor,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Points column - right aligned
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.white.withAlpha(20) : Theme.of(context).primaryColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDarkMode ? Colors.white.withAlpha(50) : Theme.of(context).primaryColor.withAlpha(50),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '$totalPoints pts',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Theme.of(context).primaryColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber.shade600; // Gold
      case 2:
        return Colors.blueGrey.shade400; // Silver
      case 3:
        return Colors.brown.shade400; // Bronze
      default:
        return Theme.of(context).primaryColor; // Regular
    }
  }
}
