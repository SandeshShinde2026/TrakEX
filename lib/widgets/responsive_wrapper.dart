import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

/// A responsive wrapper widget that adapts its layout based on screen size
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool useHorizontalPadding;
  final bool useVerticalPadding;
  final double? maxWidth;
  final double? minHeight;
  final Alignment alignment;
  final bool centerContent;
  final Color? backgroundColor;
  final BoxDecoration? decoration;

  const ResponsiveWrapper({
    Key? key,
    required this.child,
    this.padding,
    this.useHorizontalPadding = true,
    this.useVerticalPadding = true,
    this.maxWidth,
    this.minHeight,
    this.alignment = Alignment.topCenter,
    this.centerContent = false,
    this.backgroundColor,
    this.decoration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine padding based on screen size
    final responsivePadding = padding ??
        (useHorizontalPadding && useVerticalPadding
            ? ResponsiveHelper.getResponsivePadding(context)
            : useHorizontalPadding
                ? ResponsiveHelper.getResponsiveHorizontalPadding(context)
                : useVerticalPadding
                    ? ResponsiveHelper.getResponsiveVerticalPadding(context)
                    : EdgeInsets.zero);

    // Calculate max width based on screen size if not provided
    final effectiveMaxWidth = maxWidth ?? ResponsiveHelper.getResponsiveWidth(context);

    // Build the responsive container
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: effectiveMaxWidth,
        minHeight: minHeight ?? 0,
      ),
      alignment: alignment,
      decoration: decoration,
      color: backgroundColor,
      child: Padding(
        padding: responsivePadding,
        child: centerContent ? Center(child: child) : child,
      ),
    );
  }
}

/// A responsive scaffold that adapts its layout based on screen size
class ResponsiveScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color? backgroundColor;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final bool resizeToAvoidBottomInset;
  final bool centerContent;
  final EdgeInsetsGeometry? padding;

  const ResponsiveScaffold({
    Key? key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.backgroundColor,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.resizeToAvoidBottomInset = true,
    this.centerContent = false,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: ResponsiveWrapper(
        padding: padding,
        centerContent: centerContent,
        child: body,
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      endDrawer: endDrawer,
      backgroundColor: backgroundColor,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}

/// A responsive grid that adapts its column count based on screen size
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? forceGridCount;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final Axis scrollDirection;

  const ResponsiveGrid({
    Key? key,
    required this.children,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
    this.forceGridCount,
    this.shrinkWrap = false,
    this.physics,
    this.padding,
    this.controller,
    this.scrollDirection = Axis.vertical,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gridCount = forceGridCount ?? ResponsiveHelper.getResponsiveGridCount(context);
    
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: runSpacing,
        childAspectRatio: 1.0,
      ),
      itemCount: children.length,
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding ?? ResponsiveHelper.getResponsivePadding(context),
      controller: controller,
      scrollDirection: scrollDirection,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// A responsive row/column that adapts its layout based on screen size
class ResponsiveRowColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final bool forceRow;
  final bool forceColumn;
  final double spacing;
  final bool matchParentWidth;

  const ResponsiveRowColumn({
    Key? key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.forceRow = false,
    this.forceColumn = false,
    this.spacing = 8.0,
    this.matchParentWidth = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final useRow = forceRow || (!forceColumn && (ResponsiveHelper.isTablet(context) || ResponsiveHelper.isDesktop(context)));
    
    if (useRow) {
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        children: _addSpacing(children, spacing, isRow: true),
      );
    } else {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: matchParentWidth ? CrossAxisAlignment.stretch : crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        children: _addSpacing(children, spacing, isRow: false),
      );
    }
  }
  
  List<Widget> _addSpacing(List<Widget> widgets, double spacing, {required bool isRow}) {
    if (widgets.isEmpty) return [];
    if (widgets.length == 1) return widgets;
    
    final result = <Widget>[];
    for (int i = 0; i < widgets.length; i++) {
      result.add(widgets[i]);
      if (i < widgets.length - 1) {
        result.add(isRow ? SizedBox(width: spacing) : SizedBox(height: spacing));
      }
    }
    return result;
  }
}
