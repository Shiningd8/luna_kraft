import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/foundation.dart';

class RevenueCatDebugScreen extends StatefulWidget {
  @override
  _RevenueCatDebugScreenState createState() => _RevenueCatDebugScreenState();
}

class _RevenueCatDebugScreenState extends State<RevenueCatDebugScreen> {
  String _debugInfo = 'Loading...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _debugRevenueCat();
  }

  Future<void> _debugRevenueCat() async {
    setState(() {
      _isLoading = true;
      _debugInfo = 'Debugging RevenueCat configuration...\n\n';
    });

    try {
      // Initialize RevenueCat if not already done
      try {
        await Purchases.configure(PurchasesConfiguration('appl_aUbICkbeGteMFoiMsBOJzdjVoTE'));
        _addDebugInfo('✅ RevenueCat configured successfully');
      } catch (e) {
        _addDebugInfo('⚠️ RevenueCat already configured or error: $e');
      }

      // Get customer info
      try {
        final customerInfo = await Purchases.getCustomerInfo();
        _addDebugInfo('📱 Customer Info:');
        _addDebugInfo('   - App User ID: ${customerInfo.originalAppUserId}');
        _addDebugInfo('   - Active Entitlements: ${customerInfo.entitlements.active.keys.join(', ')}');
        
        if (customerInfo.entitlements.active.isNotEmpty) {
          customerInfo.entitlements.active.forEach((key, entitlement) {
            _addDebugInfo('   - $key: Product ${entitlement.productIdentifier}, Active: ${entitlement.isActive}');
          });
        } else {
          _addDebugInfo('   - No active entitlements');
        }
      } catch (e) {
        _addDebugInfo('❌ Error getting customer info: $e');
      }

      // Get offerings
      try {
        final offerings = await Purchases.getOfferings();
        _addDebugInfo('\n📦 Offerings:');
        _addDebugInfo('   - Total offerings: ${offerings.all.length}');
        _addDebugInfo('   - Current offering: ${offerings.current?.identifier ?? 'None'}');
        _addDebugInfo('   - Available offering IDs: ${offerings.all.keys.join(', ')}');

        offerings.all.forEach((offeringId, offering) {
          _addDebugInfo('\n🎁 Offering: $offeringId');
          _addDebugInfo('   - Description: ${offering.serverDescription}');
          _addDebugInfo('   - Packages: ${offering.availablePackages.length}');
          
          offering.availablePackages.forEach((package) {
            final product = package.storeProduct;
            _addDebugInfo('   📦 Package: ${package.identifier}');
            _addDebugInfo('      - Product ID: ${product.identifier}');
            _addDebugInfo('      - Title: ${product.title}');
            _addDebugInfo('      - Price: ${product.priceString}');
            _addDebugInfo('      - Category: ${product.productCategory}');
          });
        });
      } catch (e) {
        _addDebugInfo('❌ Error getting offerings: $e');
      }

      // Test specific product lookup
      _addDebugInfo('\n🔍 Testing specific product lookup:');
      try {
        final offerings = await Purchases.getOfferings();
        
        // Look for ios.premium_yearly specifically
        bool foundYearly = false;
        offerings.all.forEach((offeringId, offering) {
          offering.availablePackages.forEach((package) {
            if (package.storeProduct.identifier == 'ios.premium_yearly') {
              foundYearly = true;
              _addDebugInfo('✅ Found ios.premium_yearly in offering: $offeringId');
              _addDebugInfo('   - Package: ${package.identifier}');
              _addDebugInfo('   - Title: ${package.storeProduct.title}');
              _addDebugInfo('   - Price: ${package.storeProduct.priceString}');
            }
          });
        });
        
        if (!foundYearly) {
          _addDebugInfo('❌ ios.premium_yearly NOT found in any offering');
        }
      } catch (e) {
        _addDebugInfo('❌ Error testing product lookup: $e');
      }

    } catch (e) {
      _addDebugInfo('❌ General error: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _addDebugInfo(String info) {
    setState(() {
      _debugInfo += '$info\n';
    });
    debugPrint(info);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('RevenueCat Debug'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _debugRevenueCat,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            if (_isLoading)
              Center(child: CircularProgressIndicator()),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _debugInfo,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _testYearlyPurchase,
              child: Text('Test Yearly Purchase'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testYearlyPurchase() async {
    _addDebugInfo('\n🧪 Testing yearly purchase...');
    
    try {
      final offerings = await Purchases.getOfferings();
      Package? yearlyPackage;
      
      // Find the yearly package
      offerings.all.forEach((offeringId, offering) {
        offering.availablePackages.forEach((package) {
          if (package.storeProduct.identifier == 'ios.premium_yearly') {
            yearlyPackage = package;
            _addDebugInfo('✅ Found yearly package in offering: $offeringId');
          }
        });
      });
      
      if (yearlyPackage == null) {
        _addDebugInfo('❌ Yearly package not found');
        return;
      }
      
      _addDebugInfo('🛒 Attempting purchase...');
      final customerInfo = await Purchases.purchasePackage(yearlyPackage!);
      
      _addDebugInfo('✅ Purchase completed!');
      _addDebugInfo('   - Active entitlements: ${customerInfo.entitlements.active.keys.join(', ')}');
      
      customerInfo.entitlements.active.forEach((key, entitlement) {
        _addDebugInfo('   - $key: ${entitlement.productIdentifier}, Active: ${entitlement.isActive}');
      });
      
    } catch (e) {
      _addDebugInfo('❌ Purchase failed: $e');
      
      if (e.toString().contains('INVALID_RECEIPT')) {
        _addDebugInfo('🔍 This is the receipt validation error we\'re trying to fix');
      }
    }
  }
} 