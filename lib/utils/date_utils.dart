import 'package:intl/intl.dart';

class AppDateUtils {
  // Format date to string
  static String formatDate(DateTime date, String format) {
    return DateFormat(format).format(date);
  }

  // Parse string to date
  static DateTime? parseDate(String dateStr, String format) {
    try {
      return DateFormat(format).parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  // Get start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Get end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  // Get start of week
  static DateTime startOfWeek(DateTime date) {
    // Assuming week starts on Monday
    final diff = date.weekday - 1;
    return startOfDay(date.subtract(Duration(days: diff)));
  }

  // Get end of week
  static DateTime endOfWeek(DateTime date) {
    // Assuming week ends on Sunday
    final diff = 7 - date.weekday;
    return endOfDay(date.add(Duration(days: diff)));
  }

  // Get start of month
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  // Get end of month
  static DateTime endOfMonth(DateTime date) {
    return endOfDay(DateTime(date.year, date.month + 1, 0));
  }

  // Get start of year
  static DateTime startOfYear(DateTime date) {
    return DateTime(date.year, 1, 1);
  }

  // Get end of year
  static DateTime endOfYear(DateTime date) {
    return endOfDay(DateTime(date.year, 12, 31));
  }

  // Get date range for period
  static Map<String, DateTime> getDateRangeForPeriod(String period, DateTime date) {
    switch (period.toLowerCase()) {
      case 'weekly':
        return {
          'start': startOfWeek(date),
          'end': endOfWeek(date),
        };
      case 'monthly':
        return {
          'start': startOfMonth(date),
          'end': endOfMonth(date),
        };
      case 'yearly':
        return {
          'start': startOfYear(date),
          'end': endOfYear(date),
        };
      default:
        return {
          'start': startOfMonth(date),
          'end': endOfMonth(date),
        };
    }
  }

  // Get formatted date range
  static String getFormattedDateRange(DateTime start, DateTime end, String format) {
    return '${formatDate(start, format)} - ${formatDate(end, format)}';
  }

  // Get relative time (e.g., "2 days ago", "in 3 hours")
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? '1 year ago' : '$years years ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    } else if (difference.inDays > 0) {
      return difference.inDays == 1 ? '1 day ago' : '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return difference.inHours == 1 ? '1 hour ago' : '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return difference.inMinutes == 1 ? '1 minute ago' : '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  // Get time until due date
  static String getTimeUntilDueDate(DateTime dueDate) {
    final now = DateTime.now();
    
    if (dueDate.isBefore(now)) {
      final difference = now.difference(dueDate);
      
      if (difference.inDays > 0) {
        return difference.inDays == 1 ? 'Overdue by 1 day' : 'Overdue by ${difference.inDays} days';
      } else {
        return 'Due today';
      }
    } else {
      final difference = dueDate.difference(now);
      
      if (difference.inDays > 0) {
        return difference.inDays == 1 ? 'Due in 1 day' : 'Due in ${difference.inDays} days';
      } else if (difference.inHours > 0) {
        return difference.inHours == 1 ? 'Due in 1 hour' : 'Due in ${difference.inHours} hours';
      } else {
        return 'Due soon';
      }
    }
  }
}
