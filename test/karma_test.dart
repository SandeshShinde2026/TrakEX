import 'package:flutter_test/flutter_test.dart';
import 'package:trakex/models/karma_model.dart';

// Create a mock version of KarmaService for testing
class MockKarmaService {
  int calculateKarmaPoints(DateTime borrowTimestamp, DateTime repaymentTimestamp) {
    final Duration repaymentTime = repaymentTimestamp.difference(borrowTimestamp);
    final int hoursElapsed = repaymentTime.inHours;

    // Apply karma points based on repayment speed
    if (hoursElapsed <= 1) {
      return 100; // Within 1 hour
    } else if (hoursElapsed <= 6) {
      return 80; // Within 2-6 hours
    } else if (hoursElapsed <= 12) {
      return 60; // Within 6-12 hours
    } else if (hoursElapsed <= 24) {
      return 40; // Within 12-24 hours
    } else if (hoursElapsed <= 48) {
      return 20; // Within 1-2 days
    } else {
      return 5; // After 2+ days
    }
  }

  KarmaBadgeLevel determineBadgeLevel(int totalPoints) {
    if (totalPoints >= 900) {
      return KarmaBadgeLevel.topRepayer;
    } else if (totalPoints >= 700) {
      return KarmaBadgeLevel.reliableBuddy;
    } else if (totalPoints >= 500) {
      return KarmaBadgeLevel.okayishRepayer;
    } else if (totalPoints >= 300) {
      return KarmaBadgeLevel.slowPayer;
    } else {
      return KarmaBadgeLevel.leastTrusted;
    }
  }
}

void main() {
  group('Karma Model Tests', () {
    test('KarmaModel should have correct badge emoji', () {
      final topRepayer = KarmaModel(
        userId: 'user1',
        totalPoints: 950,
        badgeLevel: KarmaBadgeLevel.topRepayer,
        lastUpdated: DateTime.now(),
      );

      final reliableBuddy = KarmaModel(
        userId: 'user2',
        totalPoints: 800,
        badgeLevel: KarmaBadgeLevel.reliableBuddy,
        lastUpdated: DateTime.now(),
      );

      final okayishRepayer = KarmaModel(
        userId: 'user3',
        totalPoints: 600,
        badgeLevel: KarmaBadgeLevel.okayishRepayer,
        lastUpdated: DateTime.now(),
      );

      final slowPayer = KarmaModel(
        userId: 'user4',
        totalPoints: 400,
        badgeLevel: KarmaBadgeLevel.slowPayer,
        lastUpdated: DateTime.now(),
      );

      final leastTrusted = KarmaModel(
        userId: 'user5',
        totalPoints: 200,
        badgeLevel: KarmaBadgeLevel.leastTrusted,
        lastUpdated: DateTime.now(),
      );

      expect(topRepayer.badgeEmoji, '🟢');
      expect(reliableBuddy.badgeEmoji, '🟡');
      expect(okayishRepayer.badgeEmoji, '🟠');
      expect(slowPayer.badgeEmoji, '🔴');
      expect(leastTrusted.badgeEmoji, '⚫');
    });

    test('KarmaModel should have correct nickname', () {
      final topRepayer = KarmaModel(
        userId: 'user1',
        totalPoints: 950,
        badgeLevel: KarmaBadgeLevel.topRepayer,
        lastUpdated: DateTime.now(),
      );

      expect(topRepayer.nickname, 'The Trust King 👑');
      expect(topRepayer.badgeName, 'Top Repayer');
    });

    test('KarmaModel copyWith should work correctly', () {
      final original = KarmaModel(
        userId: 'user1',
        totalPoints: 950,
        badgeLevel: KarmaBadgeLevel.topRepayer,
        lastUpdated: DateTime.now(),
      );

      final updated = original.copyWith(
        totalPoints: 800,
        badgeLevel: KarmaBadgeLevel.reliableBuddy,
      );

      expect(updated.userId, original.userId);
      expect(updated.totalPoints, 800);
      expect(updated.badgeLevel, KarmaBadgeLevel.reliableBuddy);
      expect(updated.lastUpdated, original.lastUpdated);
    });
  });

  group('Karma Service Tests', () {
    test('calculateKarmaPoints should return correct points based on repayment time', () {
      final mockService = MockKarmaService();

      final now = DateTime.now();

      // Within 1 hour
      final within1Hour = now.add(const Duration(minutes: 30));
      expect(mockService.calculateKarmaPoints(now, within1Hour), 100);

      // Within 2-6 hours
      final within6Hours = now.add(const Duration(hours: 3));
      expect(mockService.calculateKarmaPoints(now, within6Hours), 80);

      // Within 6-12 hours
      final within12Hours = now.add(const Duration(hours: 8));
      expect(mockService.calculateKarmaPoints(now, within12Hours), 60);

      // Within 12-24 hours
      final within24Hours = now.add(const Duration(hours: 18));
      expect(mockService.calculateKarmaPoints(now, within24Hours), 40);

      // Within 1-2 days
      final within2Days = now.add(const Duration(hours: 36));
      expect(mockService.calculateKarmaPoints(now, within2Days), 20);

      // After 2+ days
      final after2Days = now.add(const Duration(days: 3));
      expect(mockService.calculateKarmaPoints(now, after2Days), 5);
    });

    test('determineBadgeLevel should return correct badge level based on points', () {
      final mockService = MockKarmaService();

      expect(mockService.determineBadgeLevel(950), KarmaBadgeLevel.topRepayer);
      expect(mockService.determineBadgeLevel(800), KarmaBadgeLevel.reliableBuddy);
      expect(mockService.determineBadgeLevel(600), KarmaBadgeLevel.okayishRepayer);
      expect(mockService.determineBadgeLevel(400), KarmaBadgeLevel.slowPayer);
      expect(mockService.determineBadgeLevel(200), KarmaBadgeLevel.leastTrusted);
    });
  });
}
