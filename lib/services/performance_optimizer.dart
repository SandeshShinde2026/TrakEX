import 'dart:async';
import 'package:flutter/material.dart';

class PerformanceOptimizer {
  // Optimize app performance with simplified UI
  static void optimizeApp() {
    // Reduce unnecessary rebuilds
    _optimizeWidgetRebuild();

    // Optimize memory usage
    _optimizeMemoryUsage();

    // Optimize animations
    _optimizeAnimations();

    // Optimize image loading
    _optimizeImageLoading();
  }

  // Reduce widget rebuilds by using const constructors and keys
  static void _optimizeWidgetRebuild() {
    // This is handled in the UI components by using const constructors
    // and proper widget keys where necessary
  }

  // Optimize memory usage
  static void _optimizeMemoryUsage() {
    // Clear image cache periodically
    PaintingBinding.instance.imageCache.clear();

    // Limit image cache size
    PaintingBinding.instance.imageCache.maximumSize = 50;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // 50 MB
  }

  // Optimize animations for better performance
  static void _optimizeAnimations() {
    // Disable animations on low-end devices if needed
    // This can be implemented based on device performance
  }

  // Optimize image loading
  static void _optimizeImageLoading() {
    // Use appropriate image formats and sizes
    // Implement lazy loading for images
  }

  // Debounce function for search and input fields
  static Timer? _debounceTimer;

  static void debounce(
    Duration duration,
    VoidCallback callback,
  ) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(duration, callback);
  }

  // Optimize list performance with pagination
  static Widget buildOptimizedList({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    int pageSize = 20,
  }) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      // Add physics for better scrolling performance
      physics: const BouncingScrollPhysics(),
      // Cache extent for better performance
      cacheExtent: 500,
    );
  }

  // Optimize card widgets for better performance
  static Widget buildOptimizedCard({
    required Widget child,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
  }) {
    return Card(
      elevation: 0, // Remove shadows for better performance
      margin: margin ?? const EdgeInsets.all(8),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  // Optimize text widgets
  static Widget buildOptimizedText(
    String text, {
    TextStyle? style,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.ellipsis,
      // Optimize text rendering
      textWidthBasis: TextWidthBasis.longestLine,
    );
  }

  // Optimize icon widgets
  static Widget buildOptimizedIcon(
    IconData icon, {
    double? size,
    Color? color,
  }) {
    return Icon(
      icon,
      size: size ?? 24,
      color: color,
      // Use outlined icons for better performance
    );
  }

  // Optimize button widgets
  static Widget buildOptimizedButton({
    required String text,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        elevation: 0, // Remove shadows
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      child: Text(text),
    );
  }

  // Optimize input fields
  static Widget buildOptimizedTextField({
    required String labelText,
    TextEditingController? controller,
    ValueChanged<String>? onChanged,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.all(16),
      ),
      // Optimize text input performance
      enableSuggestions: false,
      autocorrect: false,
    );
  }

  // Optimize loading indicators
  static Widget buildOptimizedLoadingIndicator({
    String? message,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            strokeWidth: 2, // Thinner stroke for better performance
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message),
          ],
        ],
      ),
    );
  }

  // Optimize empty state widgets
  static Widget buildOptimizedEmptyState({
    required String message,
    IconData? icon,
    VoidCallback? onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Memory cleanup
  static void cleanup() {
    // Clear image cache
    PaintingBinding.instance.imageCache.clear();

    // Cancel any pending debounce timers
    _debounceTimer?.cancel();
  }
}
