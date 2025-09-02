import 'package:flutter/material.dart';

/// Helper class for responsive design
class ResponsiveHelper {
  /// Screen width breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Screen size breakpoints for small mobile devices
  static const double smallMobileBreakpoint = 360;

  /// Check if the current screen size is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Check if the current screen is a small mobile device
  static bool isSmallMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < smallMobileBreakpoint;
  }

  /// Check if the current screen size is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Check if the current screen size is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  /// Get screen width
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Get safe area padding
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// Get responsive value based on screen size
  static T getResponsiveValue<T>({
    required BuildContext context,
    required T mobile,
    T? smallMobile,
    T? tablet,
    T? desktop,
  }) {
    final width = MediaQuery.of(context).size.width;

    if (width >= tabletBreakpoint && desktop != null) {
      return desktop;
    } else if (width >= mobileBreakpoint && tablet != null) {
      return tablet;
    } else if (width < smallMobileBreakpoint && smallMobile != null) {
      return smallMobile;
    } else {
      return mobile;
    }
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    return getResponsiveValue(
      context: context,
      smallMobile: const EdgeInsets.all(4.0),
      mobile: const EdgeInsets.all(8.0),
      tablet: const EdgeInsets.all(16.0),
      desktop: const EdgeInsets.all(24.0),
    );
  }

  /// Get responsive horizontal padding based on screen size
  static EdgeInsets getResponsiveHorizontalPadding(BuildContext context) {
    return getResponsiveValue(
      context: context,
      smallMobile: const EdgeInsets.symmetric(horizontal: 8.0),
      mobile: const EdgeInsets.symmetric(horizontal: 16.0),
      tablet: const EdgeInsets.symmetric(horizontal: 24.0),
      desktop: const EdgeInsets.symmetric(horizontal: 32.0),
    );
  }

  /// Get responsive vertical padding based on screen size
  static EdgeInsets getResponsiveVerticalPadding(BuildContext context) {
    return getResponsiveValue(
      context: context,
      smallMobile: const EdgeInsets.symmetric(vertical: 4.0),
      mobile: const EdgeInsets.symmetric(vertical: 8.0),
      tablet: const EdgeInsets.symmetric(vertical: 12.0),
      desktop: const EdgeInsets.symmetric(vertical: 16.0),
    );
  }

  /// Get responsive font size based on screen size
  static double getResponsiveFontSize(
    BuildContext context, {
    required double baseFontSize,
    double? smallMobileFactor,
    double? tabletFactor,
    double? desktopFactor,
  }) {
    smallMobileFactor ??= 0.85;
    tabletFactor ??= 1.2;
    desktopFactor ??= 1.5;

    if (isDesktop(context)) {
      return baseFontSize * desktopFactor;
    } else if (isTablet(context)) {
      return baseFontSize * tabletFactor;
    } else if (isSmallMobile(context)) {
      return baseFontSize * smallMobileFactor;
    } else {
      return baseFontSize;
    }
  }

  /// Get responsive item count for grid based on screen size
  static int getResponsiveGridCount(BuildContext context) {
    return getResponsiveValue(
      context: context,
      smallMobile: 1,
      mobile: 1,
      tablet: 2,
      desktop: 3,
    );
  }

  /// Get responsive spacing based on screen size
  static double getResponsiveSpacing(BuildContext context) {
    return getResponsiveValue(
      context: context,
      smallMobile: 4.0,
      mobile: 8.0,
      tablet: 16.0,
      desktop: 24.0,
    );
  }

  /// Get responsive icon size based on screen size
  static double getResponsiveIconSize(BuildContext context) {
    return getResponsiveValue(
      context: context,
      smallMobile: 16.0,
      mobile: 24.0,
      tablet: 28.0,
      desktop: 32.0,
    );
  }

  /// Get responsive button height based on screen size
  static double getResponsiveButtonHeight(BuildContext context) {
    return getResponsiveValue(
      context: context,
      smallMobile: 36.0,
      mobile: 44.0,
      tablet: 48.0,
      desktop: 52.0,
    );
  }

  /// Get responsive width for containers based on screen size
  static double getResponsiveWidth(BuildContext context, {double percentage = 1.0}) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (isDesktop(context)) {
      // On desktop, limit the width to a percentage of the screen
      return screenWidth * (percentage > 0.8 ? 0.8 : percentage);
    } else if (isTablet(context)) {
      // On tablet, use a bit more width
      return screenWidth * (percentage > 0.9 ? 0.9 : percentage);
    } else {
      // On mobile, use full width or the specified percentage
      return screenWidth * percentage;
    }
  }

  /// Get responsive height for containers based on screen size
  static double getResponsiveHeight(BuildContext context, {double percentage = 0.3}) {
    final screenHeight = MediaQuery.of(context).size.height;

    if (isDesktop(context)) {
      return screenHeight * percentage;
    } else if (isTablet(context)) {
      return screenHeight * percentage;
    } else {
      return screenHeight * percentage;
    }
  }

  /// Get responsive widget based on screen size
  static Widget getResponsiveWidget({
    required BuildContext context,
    required Widget mobile,
    Widget? smallMobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    if (isDesktop(context) && desktop != null) {
      return desktop;
    } else if (isTablet(context) && tablet != null) {
      return tablet;
    } else if (isSmallMobile(context) && smallMobile != null) {
      return smallMobile;
    } else {
      return mobile;
    }
  }

  /// Get responsive layout for row/column based on screen size
  static Widget getResponsiveLayout({
    required BuildContext context,
    required List<Widget> children,
    bool useRow = false,
  }) {
    final isRowLayout = useRow || isTablet(context) || isDesktop(context);

    if (isRowLayout) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }
  }
}
