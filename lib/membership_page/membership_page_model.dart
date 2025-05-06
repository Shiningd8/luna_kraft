import 'package:flutter/material.dart';
import 'membership_page_widget.dart';

class MembershipPageModel extends ChangeNotifier {
  // State fields
  bool _isLoading = false;
  ScrollController _scrollController = ScrollController();
  AnimationController? _animationController;

  // Getters
  bool get isLoading => _isLoading;
  ScrollController get scrollController => _scrollController;
  AnimationController? get animationController => _animationController;

  // Setters
  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  set animationController(AnimationController? value) {
    _animationController = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController?.dispose();
    super.dispose();
  }
}
