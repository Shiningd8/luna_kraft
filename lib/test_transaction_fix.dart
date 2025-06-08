import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'services/purchase_service.dart';

class TransactionFixTestPage extends StatefulWidget {
  @override
  _TransactionFixTestPageState createState() => _TransactionFixTestPageState();
}

class _TransactionFixTestPageState extends State<TransactionFixTestPage> {
  String _debugInfo = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transaction Fix Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Transaction Queue Diagnostics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _clearTransactionQueue,
              child: Text('Clear Transaction Queue'),
            ),
            SizedBox(height: 8),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _diagnoseTransactions,
              child: Text('Diagnose Transaction Issues'),
            ),
            SizedBox(height: 8),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _testYearlyPurchase,
              child: Text('Test Yearly Purchase'),
            ),
            SizedBox(height: 8),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _refreshRevenueCat,
              child: Text('Refresh RevenueCat'),
            ),
            SizedBox(height: 16),
            
            if (_isLoading)
              Center(child: CircularProgressIndicator()),
            
            Expanded(
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _debugInfo.isEmpty ? 'No debug info yet...' : _debugInfo,
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _clearTransactionQueue() async {
    setState(() {
      _isLoading = true;
      _debugInfo = '';
    });

    _addDebugInfo('🧹 Clearing transaction queue...');
    
    try {
      await PurchaseService.clearTransactionQueueIssues();
      _addDebugInfo('✅ Transaction queue cleared successfully');
    } catch (e) {
      _addDebugInfo('❌ Error clearing transaction queue: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _diagnoseTransactions() async {
    setState(() {
      _isLoading = true;
    });

    _addDebugInfo('\n🔍 Starting transaction diagnosis...');
    
    try {
      await PurchaseService.diagnoseTransactionIssues();
      _addDebugInfo('✅ Diagnosis completed');
    } catch (e) {
      _addDebugInfo('❌ Error during diagnosis: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testYearlyPurchase() async {
    setState(() {
      _isLoading = true;
    });

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
        _addDebugInfo('🔧 Try clearing the transaction queue and retrying');
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _refreshRevenueCat() async {
    setState(() {
      _isLoading = true;
    });

    _addDebugInfo('\n🔄 Refreshing RevenueCat...');
    
    try {
      // Clear caches
      await Purchases.invalidateCustomerInfoCache();
      await Future.delayed(Duration(milliseconds: 1000));
      
      // Get fresh data
      final customerInfo = await Purchases.getCustomerInfo();
      final offerings = await Purchases.getOfferings();
      
      _addDebugInfo('✅ RevenueCat refreshed successfully');
      _addDebugInfo('   - Customer ID: ${customerInfo.originalAppUserId}');
      _addDebugInfo('   - Active entitlements: ${customerInfo.entitlements.active.length}');
      _addDebugInfo('   - Available offerings: ${offerings.all.length}');
      
    } catch (e) {
      _addDebugInfo('❌ Error refreshing RevenueCat: $e');
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
} 