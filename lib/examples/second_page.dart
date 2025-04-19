import 'package:flutter/material.dart';
import 'package:luna_kraft/flutter_flow/flutter_flow_theme.dart';

class SecondPage extends StatelessWidget {
  const SecondPage({Key? key, required this.title}) : super(key: key);

  static const String routeName = 'second-page';
  static const String routePath = '/second-page';

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: FlutterFlowTheme.of(context).primary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Second Page',
              style: FlutterFlowTheme.of(context).headlineLarge,
            ),
            const SizedBox(height: 32),
            Text(
              'Transition: $title',
              style: FlutterFlowTheme.of(context).bodyLarge,
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: FlutterFlowTheme.of(context).primary,
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
