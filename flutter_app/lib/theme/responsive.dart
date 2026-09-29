import 'package:flutter/material.dart';

class Responsive {
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide < 600;
  }

  static bool isSmallPhone(BuildContext context) {
    return MediaQuery.of(context).size.width < 380;
  }

  static bool isTablet(BuildContext context) {
    final shortest = MediaQuery.of(context).size.shortestSide;
    return shortest >= 600 && shortest < 900;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide >= 900;
  }

  /// Calculates dynamic product grid crossAxisCount based on screen width
  static int gridColumnCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 6;
    if (width > 900) return 5;
    if (width > 650) return 4;
    if (width > 480) return 3;
    return 2; // Default phone portrait
  }

  /// Calculates dynamic banner height based on orientation & device size
  static double bannerHeight(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final isLand = isLandscape(context);
    if (isLand) {
      return (height * 0.42).clamp(130.0, 200.0);
    }
    return 160.0;
  }

  /// Centers and limits content width on wide screens / landscape for optimal readability
  static Widget maxContainer({
    required BuildContext context,
    required Widget child,
    double maxWidth = 600,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
