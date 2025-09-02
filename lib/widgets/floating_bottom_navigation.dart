import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_theme.dart';

class FloatingBottomNavigation extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<FloatingNavItem> items;

  const FloatingBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  State<FloatingBottomNavigation> createState() => _FloatingBottomNavigationState();
}

class _FloatingBottomNavigationState extends State<FloatingBottomNavigation>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(25),
        color: Colors.transparent,
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).cardColor,
                Theme.of(context).cardColor.withOpacity(0.9),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              widget.items.length,
              (index) => _buildNavItem(index),
            ),
          ),
        ),
      ),
    ).animate().slideY(
      begin: 1,
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
    );
  }

  Widget _buildNavItem(int index) {
    final item = widget.items[index];
    final isSelected = index == widget.currentIndex;

    return GestureDetector(
      onTap: () {
        _animationController.forward().then((_) {
          _animationController.reverse();
        });
        widget.onTap(index);
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isSelected ? _scaleAnimation.value : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: isSelected
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : Colors.transparent,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.transparent,
                    ),
                    child: Icon(
                      item.icon,
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).iconTheme.color?.withOpacity(0.6),
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                    ),
                    child: Text(item.label),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).animate(target: isSelected ? 1 : 0).scale(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }
}

class FloatingNavItem {
  final IconData icon;
  final String label;
  final Color? color;

  const FloatingNavItem({
    required this.icon,
    required this.label,
    this.color,
  });
}

// Curved bottom navigation with floating effect
class CurvedFloatingBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<FloatingNavItem> items;

  const CurvedFloatingBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: List.generate(items.length, (index) {
              return Expanded(
                child: _buildCurvedNavItem(context, index),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildCurvedNavItem(BuildContext context, int index) {
    final item = items[index];
    final isSelected = index == currentIndex;

    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.transparent,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(isSelected ? 8 : 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.transparent,
              ),
              child: Icon(
                item.icon,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).iconTheme.color?.withOpacity(0.6),
                size: isSelected ? 22 : 20,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isSelected ? 11 : 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    ).animate(target: isSelected ? 1 : 0).scale(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }
}

// Glass morphism bottom navigation
class GlassMorphismBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<FloatingNavItem> items;

  const GlassMorphismBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withOpacity(0.8),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: List.generate(items.length, (index) {
              return Expanded(
                child: _buildGlassNavItem(context, index),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassNavItem(BuildContext context, int index) {
    final item = items[index];
    final isSelected = index == currentIndex;

    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        height: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? Theme.of(context).primaryColor.withOpacity(0.2)
                    : Colors.transparent,
                border: isSelected
                    ? Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.5),
                        width: 2,
                      )
                    : null,
              ),
              child: Icon(
                item.icon,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).iconTheme.color?.withOpacity(0.6),
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    ).animate(target: isSelected ? 1 : 0).shimmer(
      duration: const Duration(milliseconds: 500),
      color: Theme.of(context).primaryColor.withOpacity(0.3),
    );
  }
}
