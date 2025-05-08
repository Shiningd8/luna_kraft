import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/utils/color_utils.dart';

class CustomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  State<CustomNavBar> createState() => _CustomNavBarState();
}

class _CustomNavBarState extends State<CustomNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 80,
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isDarkMode
            ? FlutterFlowTheme.of(context).secondaryBackground.withOpacity(0.8)
            : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: ColorUtils.getShadowColor(context,
                opacity: isDarkMode ? 0.1 : 0.08),
            blurRadius: isDarkMode ? 10 : 8,
            offset: Offset(0, isDarkMode ? 5 : 3),
          ),
        ],
        border: Border.all(
          color: FlutterFlowTheme.of(context).primary.withOpacity(0.08),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(0, Icons.home_outlined, Icons.home),
          _buildNavItem(1, Icons.search_outlined, Icons.search),
          _buildNavItem(2, Icons.add_circle_outline, Icons.add_circle),
          _buildNavItem(3, Icons.diamond_outlined, Icons.diamond),
          _buildNavItem(4, Icons.person_outline, Icons.person),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData unselectedIcon, IconData selectedIcon) {
    final isSelected = widget.currentIndex == index;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        widget.onTap(index);
        _controller.forward().then((_) => _controller.reverse());
      },
      child: Container(
        width: 60,
        height: 60,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isSelected)
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDarkMode
                      ? FlutterFlowTheme.of(context).primary.withOpacity(0.1)
                      : FlutterFlowTheme.of(context).primary.withOpacity(0.08),
                ),
              ),
            ScaleTransition(
              scale: isSelected ? _scaleAnimation : AlwaysStoppedAnimation(1.0),
              child: Icon(
                isSelected ? selectedIcon : unselectedIcon,
                color: isSelected
                    ? FlutterFlowTheme.of(context).primary
                    : FlutterFlowTheme.of(context).secondaryText,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
