import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/services/subscription_manager.dart';
import 'package:intl/intl.dart';

/// A card that displays the user's subscription information
class SubscriptionInfoCard extends StatelessWidget {
  final bool
      showDetails; // Whether to show detailed information or just a summary

  const SubscriptionInfoCard({
    Key? key,
    this.showDetails = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Listen to subscription status changes
    return StreamBuilder<SubscriptionStatus>(
      stream: SubscriptionManager.instance.subscriptionStatus,
      builder: (context, snapshot) {
        final subscriptionStatus = snapshot.data;
        final isSubscribed = subscriptionStatus?.isSubscribed ?? false;

        if (!isSubscribed) {
          return _buildNotSubscribedCard(context);
        }

        return _buildSubscribedCard(context, subscriptionStatus!);
      },
    );
  }

  // Card for users without an active subscription
  Widget _buildNotSubscribedCard(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAliasWithSaveLayer,
      color: FlutterFlowTheme.of(context).primaryBackground,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.star_border_outlined,
                  color: FlutterFlowTheme.of(context).secondaryText,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'Free Plan',
                  style: FlutterFlowTheme.of(context).titleMedium,
                ),
              ],
            ),
            if (showDetails) ...[
              SizedBox(height: 16),
              Text(
                'Upgrade to Premium to access exclusive features:',
                style: FlutterFlowTheme.of(context).bodyMedium,
              ),
              SizedBox(height: 8),
              _buildFeatureList(context, [
                'Dream Analysis',
                'Exclusive Themes',
                'Bonus Luna Coins',
                'Ad-Free Experience',
              ]),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Navigate to membership page
                  Navigator.pushNamed(context, 'MembershipPage');
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: FlutterFlowTheme.of(context).primary,
                  minimumSize: Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Upgrade to Premium'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Card for users with an active subscription
  Widget _buildSubscribedCard(BuildContext context, SubscriptionStatus status) {
    // Get formatted expiry date
    final expiryDate = status.expiryDate;
    final formattedDate = expiryDate != null
        ? DateFormat('MMM dd, yyyy').format(expiryDate)
        : 'Unknown';

    // Get subscription tier name
    final tierName = _formatSubscriptionName(status.subscriptionTier ?? '');

    // Get days remaining
    final daysLeft = SubscriptionManager.instance.daysLeft;

    return Card(
      clipBehavior: Clip.antiAliasWithSaveLayer,
      color: FlutterFlowTheme.of(context).primaryBackground,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  tierName,
                  style: FlutterFlowTheme.of(context).titleMedium.copyWith(
                        color: Colors.amber,
                      ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: FlutterFlowTheme.of(context).secondaryText,
                  size: 16,
                ),
                SizedBox(width: 4),
                Text(
                  'Expires: $formattedDate ($daysLeft days left)',
                  style: FlutterFlowTheme.of(context).bodySmall,
                ),
              ],
            ),
            if (showDetails) ...[
              SizedBox(height: 16),
              Text(
                'Your premium benefits:',
                style: FlutterFlowTheme.of(context).bodyMedium,
              ),
              SizedBox(height: 8),
              _buildFeatureList(
                context,
                status.benefits.map(_formatBenefitName).toList(),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Navigate to membership page to manage subscription
                  Navigator.pushNamed(context, 'MembershipPage');
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: FlutterFlowTheme.of(context).primary,
                  minimumSize: Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Manage Subscription'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper to build a feature list
  Widget _buildFeatureList(BuildContext context, List<String> features) {
    return Column(
      children: features
          .map((feature) => Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: FlutterFlowTheme.of(context).primary,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: FlutterFlowTheme.of(context).bodySmall,
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  // Format the subscription name for display
  String _formatSubscriptionName(String subscriptionId) {
    if (subscriptionId.contains('weekly') || subscriptionId == 'ios.premium_weekly_sub') {
      return 'Premium Weekly';
    } else if (subscriptionId.contains('monthly') || subscriptionId == 'ios.premium_monthly') {
      return 'Premium Monthly';
    } else if (subscriptionId.contains('yearly') || subscriptionId == 'ios.premium_yearly') {
      return 'Premium Yearly';
    } else {
      return 'Premium';
    }
  }

  // Format benefit name for display
  String _formatBenefitName(String benefitId) {
    switch (benefitId) {
      case 'dream_analysis':
        return 'Dream Analysis';
      case 'exclusive_themes':
        return 'Exclusive Themes';
      case 'bonus_coins_150':
        return '150 Bonus Luna Coins';
      case 'bonus_coins_250':
        return '250 Bonus Luna Coins';
      case 'bonus_coins_1000':
        return '1000 Bonus Luna Coins';
      case 'zen_mode':
        return 'Zen Mode';
      case 'ad_free':
        return 'Ad-Free Experience';
      case 'priority_support':
        return 'Priority Support';
      default:
        return benefitId.replaceAll('_', ' ').capitalize();
    }
  }
}

// Extension to capitalize the first letter of each word
extension StringExtension on String {
  String capitalize() {
    return split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }
}
