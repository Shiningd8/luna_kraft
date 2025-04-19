import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:luna_kraft/flutter_flow/flutter_flow_theme.dart';
import 'package:luna_kraft/flutter_flow/nav/nav.dart';
import 'package:luna_kraft/utils/page_transitions.dart';
import 'package:luna_kraft/utils/custom_page_transitions.dart';
import 'package:luna_kraft/utils/route_transitions.dart';
import 'package:page_transition/page_transition.dart';
import 'package:luna_kraft/examples/second_page.dart';

class TransitionsDemoPage extends StatelessWidget {
  const TransitionsDemoPage({Key? key}) : super(key: key);

  static const String routeName = 'transitions-demo';
  static const String routePath = '/transitions-demo';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Page Transitions Demo'),
        backgroundColor: FlutterFlowTheme.of(context).primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('Standard Transitions'),
            const SizedBox(height: 16),

            // Standard transitions using GoRouter
            _buildTransitionButton(
              context,
              'Fade Transition',
              () => _navigateToSecondPage(
                context,
                'Fade Transition',
                TransitionInfo(
                  hasTransition: true,
                  transitionType: PageTransitionType.fade,
                  duration: const Duration(milliseconds: 400),
                ),
              ),
            ),

            _buildTransitionButton(
              context,
              'Slide Right to Left',
              () => _navigateToSecondPage(
                context,
                'Slide Transition',
                TransitionInfo(
                  hasTransition: true,
                  transitionType: PageTransitionType.rightToLeft,
                  duration: const Duration(milliseconds: 300),
                ),
              ),
            ),

            _buildTransitionButton(
              context,
              'Scale Transition',
              () => _navigateToSecondPage(
                context,
                'Scale Transition',
                TransitionInfo(
                  hasTransition: true,
                  transitionType: PageTransitionType.scale,
                  alignment: Alignment.center,
                  duration: const Duration(milliseconds: 350),
                ),
              ),
            ),

            _buildSectionTitle('Using AppPageTransitions Helper'),
            const SizedBox(height: 16),

            // Using our helper class
            _buildTransitionButton(
              context,
              'Fade (Helper)',
              () => _navigateToSecondPage(
                context,
                'Fade (Helper)',
                AppPageTransitions.fadeTransition(),
              ),
            ),

            _buildTransitionButton(
              context,
              'Slide (Helper)',
              () => _navigateToSecondPage(
                context,
                'Slide (Helper)',
                AppPageTransitions.slideTransition(),
              ),
            ),

            _buildTransitionButton(
              context,
              'Scale (Helper)',
              () => _navigateToSecondPage(
                context,
                'Scale (Helper)',
                AppPageTransitions.scaleTransition(),
              ),
            ),

            _buildTransitionButton(
              context,
              'Bottom to Top (Helper)',
              () => _navigateToSecondPage(
                context,
                'Bottom to Top (Helper)',
                AppPageTransitions.bottomToTopTransition(),
              ),
            ),

            _buildSectionTitle('Custom Combined Transitions'),
            const SizedBox(height: 16),

            // Using SmoothPageRoute
            _buildTransitionButton(
              context,
              'Smooth Combined Animation',
              () => context.pushSmoothPage(
                page: SecondPage(title: 'Smooth Combined Animation'),
              ),
            ),

            _buildTransitionButton(
              context,
              'Smooth (Fade + Scale)',
              () => context.pushSmoothPage(
                page: SecondPage(title: 'Fade + Scale'),
                fadeIn: true,
                scaleUp: true,
                slideIn: false,
              ),
            ),

            _buildTransitionButton(
              context,
              'Slide Up From Bottom',
              () => context.pushSmoothPage(
                page: SecondPage(title: 'Slide Up From Bottom'),
                fadeIn: true,
                scaleUp: false,
                slideIn: true,
                slideFromBottom: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTransitionButton(
    BuildContext context,
    String title,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
          foregroundColor: FlutterFlowTheme.of(context).primaryText,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(title),
      ),
    );
  }

  void _navigateToSecondPage(
    BuildContext context,
    String title,
    TransitionInfo transitionInfo,
  ) {
    context.pushNamed(
      SecondPage.routeName,
      queryParameters: {'title': title},
      extra: <String, dynamic>{
        kTransitionInfoKey: transitionInfo,
      },
    );
  }
}
