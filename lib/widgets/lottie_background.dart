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
        final bgFile = appState.selectedBackground;
        final isImage = bgFile.endsWith('.png') ||
            bgFile.endsWith('.jpg') ||
            bgFile.endsWith('.jpeg');

        return Stack(
          fit: StackFit.expand,
          children: [
            // Background - either Lottie animation or Image
            Positioned.fill(
              child: isImage
                  ? Image.asset(
                      'assets/images/$bgFile',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        print('ERROR LOADING IMAGE: $error');
                        print('Stack trace: $stackTrace');
                        print('Attempted to load: assets/images/$bgFile');

                        // Fallback to a default image that we know works
                        return Image.asset(
                          'assets/images/applogo.png',
                          fit: BoxFit.cover,
                        );
                      },
                    )
                  : Lottie.asset(
                      'assets/jsons/$bgFile',
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
