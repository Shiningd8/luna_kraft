import '/flutter_flow/flutter_flow_util.dart';
import 'membership_page_widget.dart' show MembershipPageWidget;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class MembershipPageModel extends FlutterFlowModel<MembershipPageWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for Carousel widget.
  CarouselSliderController? carouselController;
  int carouselCurrentIndex = 1;

  @override
  void initState(BuildContext context) {
    // No need to initialize dreamModeToggle
  }

  @override
  void dispose() {
    // No need to dispose dreamModeToggle
  }
}
