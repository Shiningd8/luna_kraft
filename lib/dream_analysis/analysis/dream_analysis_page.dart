import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dream_analysis_simple.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

class DreamAnalysisPage extends StatelessWidget {
  static const String routeName = 'DreamAnalysis';
  static const String routePath = '/dream-analysis';

  const DreamAnalysisPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState(context);
        }

        if (!snapshot.hasData) {
          return _buildSignInPrompt(context);
        }

        // User is logged in, now check if they have at least 5 dreams
        return FutureBuilder<QuerySnapshot>(
          future: _fetchUserDreams(snapshot.data!.uid),
          builder: (context, dreamsSnapshot) {
            if (dreamsSnapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState(context);
            }

            if (dreamsSnapshot.hasError) {
              return _buildErrorState(context, dreamsSnapshot.error);
            }

            // Count the user's dreams
            final int dreamCount = dreamsSnapshot.data?.docs.length ?? 0;

            // Check if the user has at least 5 dreams
            if (dreamCount < 5) {
              return _buildMinimumDreamsRequirement(context, dreamCount);
            }

            // User has enough dreams, show the analysis
            return DreamAnalysisSimple();
          },
        );
      },
    );
  }

  Future<QuerySnapshot> _fetchUserDreams(String userId) {
    return FirebaseFirestore.instance
        .collection('posts')
        .where('poster',
            isEqualTo:
                FirebaseFirestore.instance.collection('User').doc(userId))
        .get();
  }

  Widget _buildLoadingState(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF050A30),
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            FlutterFlowTheme.of(context).primary,
          ),
        ),
      ),
    );
  }

  Widget _buildSignInPrompt(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF050A30),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_circle,
              size: 64,
              color: Colors.white,
            ),
            SizedBox(height: 16),
            Text(
              'Please sign in to view your dream analysis',
              style: FlutterFlowTheme.of(context).titleMedium.copyWith(
                    color: Colors.white,
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.go('/sign-in');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: FlutterFlowTheme.of(context).primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Sign In'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object? error) {
    return Scaffold(
      backgroundColor: Color(0xFF050A30),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              'Error loading dream analysis',
              style: FlutterFlowTheme.of(context).titleMedium.copyWith(
                    color: Colors.white,
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                error.toString(),
                style: FlutterFlowTheme.of(context).bodyMedium.copyWith(
                      color: Colors.white70,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: FlutterFlowTheme.of(context).primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimumDreamsRequirement(
      BuildContext context, int currentCount) {
    return Scaffold(
      backgroundColor: Color(0xFF050A30),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Dream Analysis',
          style: FlutterFlowTheme.of(context).headlineMedium.copyWith(
                color: Colors.white,
              ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.psychology,
                size: 80,
                color: FlutterFlowTheme.of(context).primary.withOpacity(0.7),
              ),
              SizedBox(height: 24),
              Text(
                'Minimum 5 Dreams Required',
                style: FlutterFlowTheme.of(context).headlineSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'You currently have $currentCount ${currentCount == 1 ? 'dream' : 'dreams'}. Add ${5 - currentCount} more to unlock your personalized dream analysis!',
                style: FlutterFlowTheme.of(context).bodyLarge.copyWith(
                      color: Colors.white70,
                    ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              _buildDreamProgressIndicator(context, currentCount),
              SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  context.pushNamed('DreamEntrySelection');
                },
                icon: Icon(Icons.add_circle_outline),
                label: Text('Add New Dream'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FlutterFlowTheme.of(context).primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Return to Home'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDreamProgressIndicator(BuildContext context, int currentCount) {
    final double progress = currentCount / 5.0;

    return Column(
      children: [
        Stack(
          children: [
            // Background track
            Container(
              width: 250,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            // Progress indicator
            Container(
              width: 250 * progress,
              height: 20,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    FlutterFlowTheme.of(context).primary,
                    FlutterFlowTheme.of(context).secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color:
                        FlutterFlowTheme.of(context).primary.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final bool isCompleted = index < currentCount;
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 8),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? FlutterFlowTheme.of(context).primary
                    : Colors.white.withOpacity(0.1),
                border: Border.all(
                  color: isCompleted
                      ? FlutterFlowTheme.of(context).primary
                      : Colors.white.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: isCompleted
                    ? [
                        BoxShadow(
                          color: FlutterFlowTheme.of(context)
                              .primary
                              .withOpacity(0.3),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: isCompleted ? Colors.white : Colors.white70,
                    fontWeight:
                        isCompleted ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
