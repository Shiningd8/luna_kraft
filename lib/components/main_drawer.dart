import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/utils/subscription_util.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';

class MainDrawer extends StatefulWidget {
  const MainDrawer({Key? key}) : super(key: key);
  
  @override
  State<MainDrawer> createState() => _MainDrawerState();
}

class _MainDrawerState extends State<MainDrawer> {
  // ... existing code ...

  @override
  Widget build(BuildContext context) {
    // ... existing code ...

    return Container(
      // ... existing code ...
      child: Column(
        // ... existing code ...
        children: [
          // ... existing menu items ...
          
          // Dream Analysis menu item
          _buildMenuItem(
            'Dream Analysis',
            Icons.psychology_outlined,
            () {
              // Check if user has access to dream analysis
              if (SubscriptionUtil.hasDreamAnalysis) {
                Navigator.of(context).pop(); // Close drawer
                context.pushNamed('DreamAnalysis');
              } else {
                // Redirect to membership page
                Navigator.of(context).pop(); // Close drawer
                context.pushNamed('MembershipPage');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Dream Analysis requires a premium subscription'),
                    backgroundColor: FlutterFlowTheme.of(context).primary,
                  ),
                );
              }
            },
          ),
          
          // ... other menu items ...
        ],
      ),
    );
  }

  Widget _buildMenuItem(String title, IconData icon, VoidCallback onPressed) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onPressed,
    );
  }
} 