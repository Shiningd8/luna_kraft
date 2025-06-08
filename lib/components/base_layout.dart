import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/components/custom_nav_bar.dart';
import '/home/home_page/home_page_widget.dart';
import '/history/history_page/history_page_widget.dart';
import '/add_post/dream_entry_selection/dream_entry_selection_widget.dart';
import '/notificationpage/notificationpage_widget.dart';
import '/profile/prof1/prof1_widget.dart';

class BaseLayout extends StatefulWidget {
  final int initialIndex;

  const BaseLayout({
    Key? key,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<BaseLayout> createState() => _BaseLayoutState();
}

class _BaseLayoutState extends State<BaseLayout> {
  late int _currentIndex;
  late PageController _pageController;
  bool _isInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeLayout();
  }

  Future<void> _initializeLayout() async {
    try {
      _currentIndex = widget.initialIndex;
      _pageController = PageController(initialPage: _currentIndex);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing BaseLayout: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to initialize app layout';
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onNavTap(int index) {
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: Colors.red)),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _isInitialized = false;
                  });
                  _initializeLayout();
                },
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              HomePageWidget(),
              HistoryPageWidget(),
              DreamEntrySelectionWidget(),
              NotificationpageWidget(),
              Prof1Widget(),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomNavBar(
              currentIndex: _currentIndex,
              onTap: _onNavTap,
            ),
          ),
        ],
      ),
    );
  }
}
