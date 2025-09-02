import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../utils/responsive_helper.dart';

class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final double? fontSize;
  final double? iconSize;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.fontSize,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Use theme-aware colors for better consistency
    final displayColor = isDarkMode
        ? (color.computeLuminance() < 0.5
            ? Color.lerp(color, Colors.white, 0.6)! // Lighten dark colors more in dark mode
            : color)
        : color;

    // Adjust background and border opacity for better visibility
    final bgOpacity = isDarkMode ? 0.15 : 0.08;
    final borderOpacity = isDarkMode ? 0.4 : 0.25;

    final borderRadius = ResponsiveHelper.getResponsiveValue<double>(
      context: context,
      mobile: 12,
      tablet: 16,
      desktop: 20,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        height: ResponsiveHelper.getResponsiveValue<double>(
          context: context,
          mobile: 80,
          tablet: 90,
          desktop: 100,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.getResponsiveValue<double>(
            context: context,
            mobile: AppTheme.smallSpacing * 0.5,
            tablet: AppTheme.smallSpacing,
            desktop: AppTheme.smallSpacing * 1.5,
          ),
          vertical: ResponsiveHelper.getResponsiveValue<double>(
            context: context,
            mobile: AppTheme.smallSpacing * 0.75,
            tablet: AppTheme.smallSpacing,
            desktop: AppTheme.smallSpacing * 1.5,
          ),
        ),
        decoration: BoxDecoration(
          color: displayColor.withAlpha((bgOpacity * 255).round()),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: displayColor.withAlpha((borderOpacity * 255).round()),
            width: ResponsiveHelper.getResponsiveValue<double>(
              context: context,
              mobile: 1.5,
              tablet: 2.0,
              desktop: 2.5,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: displayColor,
              size: iconSize ?? ResponsiveHelper.getResponsiveValue<double>(
                context: context,
                mobile: 28,
                tablet: 32,
                desktop: 36,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveValue<double>(
              context: context,
              mobile: 4,
              tablet: 6,
              desktop: 8,
            )),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: displayColor,
                fontWeight: FontWeight.w600, // Slightly less bold for better readability
                fontSize: fontSize ?? ResponsiveHelper.getResponsiveFontSize(
                  context,
                  baseFontSize: 12,
                  tabletFactor: 1.1,
                  desktopFactor: 1.2,
                ),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
