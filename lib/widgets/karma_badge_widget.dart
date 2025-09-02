import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../models/karma_model.dart';

class KarmaBadgeWidget extends StatelessWidget {
  final KarmaBadgeLevel badgeLevel;
  final String badgeEmoji;
  final String nickname;
  final String badgeName;
  final int totalPoints;
  final bool showDetails;
  final bool isCompact;

  const KarmaBadgeWidget({
    super.key,
    required this.badgeLevel,
    required this.badgeEmoji,
    required this.nickname,
    required this.badgeName,
    required this.totalPoints,
    this.showDetails = false,
    this.isCompact = false,
  });

  // Get color based on badge level
  Color _getBadgeColor(BuildContext context) {
    switch (badgeLevel) {
      case KarmaBadgeLevel.topRepayer:
        return Colors.green.shade600;
      case KarmaBadgeLevel.reliableBuddy:
        return Colors.blue.shade600;
      case KarmaBadgeLevel.okayishRepayer:
        return Colors.amber.shade700;
      case KarmaBadgeLevel.slowPayer:
        return Colors.orange.shade800;
      case KarmaBadgeLevel.leastTrusted:
        return Colors.red.shade700;
    }
  }

  // Get description based on badge level
  String _getDescription() {
    switch (badgeLevel) {
      case KarmaBadgeLevel.topRepayer:
        return 'Lightning-fast repayments, everyone loves lending to this legend';
      case KarmaBadgeLevel.reliableBuddy:
        return 'Smooth and timely, no drama, always comes through';
      case KarmaBadgeLevel.okayishRepayer:
        return 'Means well, tries hard, but sometimes cuts it close';
      case KarmaBadgeLevel.slowPayer:
        return 'Frequently forgets or delays payments — needs reminders';
      case KarmaBadgeLevel.leastTrusted:
        return 'Danger zone — promises a lot, repays rarely. Handle with caution!';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Compact version just shows the badge emoji
    if (isCompact) {
      return Tooltip(
        message: '$badgeName - $nickname\n${_getDescription()}',
        child: Text(
          badgeEmoji,
          style: const TextStyle(fontSize: 16),
        ),
      );
    }

    // Standard version shows badge with name
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final badgeColor = _getBadgeColor(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withAlpha(isDarkMode ? 30 : 15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: badgeColor.withAlpha(isDarkMode ? 100 : 50),
          width: 1,
        ),
      ),
      child: showDetails
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      badgeEmoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        badgeName,
                        style: TextStyle(
                          color: isDarkMode ? badgeColor.withAlpha(240) : badgeColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          letterSpacing: 0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    nickname,
                    style: TextStyle(
                      color: isDarkMode ? badgeColor.withAlpha(220) : badgeColor.withAlpha(200),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withAlpha(isDarkMode ? 50 : 30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$totalPoints pts',
                    style: TextStyle(
                      color: isDarkMode ? badgeColor.withAlpha(240) : badgeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _getDescription(),
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  badgeEmoji,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    badgeName,
                    style: TextStyle(
                      color: isDarkMode ? badgeColor.withAlpha(240) : badgeColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      letterSpacing: 0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
    );
  }
}
