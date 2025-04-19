import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '/services/app_state.dart';

class LottieBackground extends StatelessWidget {
  final Widget child;

  const LottieBackground({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Lottie animation background
            Positioned.fill(
              child: Lottie.asset(
                'assets/jsons/${appState.selectedBackground}',
                fit: BoxFit.cover,
                repeat: true,
                animate: true,
              ),
            ),

            // Content
            child,
          ],
        );
      },
    );
  }
}
