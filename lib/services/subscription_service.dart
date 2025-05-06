import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'models/subscription_product.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  // Singleton instance
  static SubscriptionService get instance => _instance;

  // InAppPurchase instance - only initialize if not in debug mode
  late final InAppPurchase _inAppPurchase;
  bool _isInAppPurchaseInitialized = false;

  // Stream subscription for purchase updates
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Available products
  List<SubscriptionProduct> _availableProducts = [];

  // Subscription product IDs from the screenshots
  static const List<String> _productIds = [
    'premium_weekly',
    'premium_monthly',
    'premium_yearly'
  ];

  // Completion handlers for purchases
  final Map<String, Completer<SubscriptionPurchaseResult>> _purchaseCompleters =
      {};

  // Streams
  final StreamController<List<SubscriptionProduct>> _productsStreamController =
      StreamController<List<SubscriptionProduct>>.broadcast();
  Stream<List<SubscriptionProduct>> get productsStream =>
      _productsStreamController.stream;

  final StreamController<bool> _isLoadingStreamController =
      StreamController<bool>.broadcast();
  Stream<bool> get isLoadingStream => _isLoadingStreamController.stream;

  // Status flags
  bool _isInitialized = false;
  bool _isLoading = false;

  // Getter for available products
  List<SubscriptionProduct> get availableProducts => _availableProducts;

  // Getter for loading status
  bool get isLoading => _isLoading;

  // Initialize the subscription service
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      _setLoading(true);

      // Check package info for debugging
      await _checkAppInstallationSource();

      // Initialize the InAppPurchase instance only once
      if (!_isInAppPurchaseInitialized) {
        _inAppPurchase = InAppPurchase.instance;
        _isInAppPurchaseInitialized = true;
        debugPrint('InAppPurchase instance initialized');
      }

      // Set up the listener only if not already set up
      if (_subscription == null) {
        final purchaseUpdated = _inAppPurchase.purchaseStream;
        _subscription = purchaseUpdated.listen(
          _onPurchaseUpdate,
          onDone: _onPurchaseDone,
          onError: _onPurchaseError,
        );
        debugPrint('Purchase stream listener set up');
      }

      // Check if the store is available
      final bool isAvailable = await _inAppPurchase.isAvailable();
      if (!isAvailable) {
        _isInitialized = false;
        _setLoading(false);
        debugPrint('Store is not available');
        return;
      }

      // Load products - only if they haven't been loaded yet or if we need to refresh
      if (_availableProducts.isEmpty) {
        await _loadProducts();
      }

      _isInitialized = true;
      _setLoading(false);
      debugPrint('SubscriptionService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing SubscriptionService: $e');
      _setLoading(false);
      _isInitialized = false;
    }
  }

  // Load available products from store
  Future<void> _loadProducts() async {
    try {
      _setLoading(true);

      debugPrint(
          'SubscriptionService: Querying product details for: $_productIds');

      // Log exact product IDs to help with debugging
      for (var id in _productIds) {
        debugPrint('Product ID being queried: "$id" (length: ${id.length})');
        // Print each character code to find invisible characters
        debugPrint('Character codes: ${id.codeUnits}');
      }

      // Query product details
      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails(_productIds.toSet());

      // Handle any errors
      if (response.error != null) {
        debugPrint('Error querying products: ${response.error}');
        _setLoading(false);
        return;
      }

      debugPrint(
          'SubscriptionService: Got response with ${response.productDetails.length} products');
      for (var product in response.productDetails) {
        debugPrint(
            'SubscriptionService: Product found - ID: ${product.id}, Title: ${product.title}, Price: ${product.price}');
      }

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint(
            'SubscriptionService: IDs not found: ${response.notFoundIDs.join(', ')}');
      }

      // Convert to our model
      _availableProducts = response.productDetails
          .map((details) => SubscriptionProduct.fromProductDetails(details))
          .toList();

      // Broadcast the products
      _productsStreamController.add(_availableProducts);

      debugPrint('Loaded ${_availableProducts.length} products');
      _setLoading(false);
    } catch (e) {
      debugPrint('Error loading products: $e');
      _setLoading(false);
    }
  }

  // Load mock products for debugging
  Future<void> _loadMockProducts() async {
    debugPrint('SubscriptionService: Loading mock products for development');

    _availableProducts = _createMockProducts();
    _productsStreamController.add(_availableProducts);

    debugPrint(
        'SubscriptionService: Loaded ${_availableProducts.length} mock products');
  }

  // Create mock products for development testing
  List<SubscriptionProduct> _createMockProducts() {
    // Determine which currency to use for mocking based on device locale
    // For real products, this will come from the store
    String currencyCode = 'USD'; // Default fallback
    String currencySymbol = '\$';

    try {
      // In a real app, you could use device locale to determine currency for debug mode
      if (Platform.localeName.contains('IN')) {
        currencyCode = 'INR';
        currencySymbol = '₹';
      } else if (Platform.localeName.contains('GB')) {
        currencyCode = 'GBP';
        currencySymbol = '£';
      } else if (Platform.localeName.contains('EU')) {
        currencyCode = 'EUR';
        currencySymbol = '€';
      }
      // Add more currency detections as needed
    } catch (e) {
      debugPrint('Error detecting locale currency: $e');
    }

    // Create pricing based on detected currency
    if (currencyCode == 'INR') {
      return [
        SubscriptionProduct(
          id: 'premium_weekly',
          title: 'Weekly Premium',
          description: 'Dream Analysis, Exclusive Themes, 150 Lunacoins',
          price: '₹239',
          rawPrice: '239',
          currencyCode: 'INR',
          currencySymbol: '₹',
        ),
        SubscriptionProduct(
          id: 'premium_monthly',
          title: 'Monthly Premium',
          description:
              'Dream Analysis, Exclusive Themes, 250 Lunacoins, Unlocked Zen Mode',
          price: '₹799',
          rawPrice: '799',
          currencyCode: 'INR',
          currencySymbol: '₹',
        ),
        SubscriptionProduct(
          id: 'premium_yearly',
          title: 'Yearly Premium',
          description:
              'Access to All Premium Features, 1000 Lunacoins, Ad-free Experience, Priority Support',
          price: '₹7,999',
          rawPrice: '7999',
          currencyCode: 'INR',
          currencySymbol: '₹',
        ),
      ];
    } else if (currencyCode == 'GBP') {
      return [
        SubscriptionProduct(
          id: 'premium_weekly',
          title: 'Weekly Premium',
          description: 'Dream Analysis, Exclusive Themes, 150 Lunacoins',
          price: '£1.99',
          rawPrice: '1.99',
          currencyCode: 'GBP',
          currencySymbol: '£',
        ),
        SubscriptionProduct(
          id: 'premium_monthly',
          title: 'Monthly Premium',
          description:
              'Dream Analysis, Exclusive Themes, 250 Lunacoins, Unlocked Zen Mode',
          price: '£7.99',
          rawPrice: '7.99',
          currencyCode: 'GBP',
          currencySymbol: '£',
        ),
        SubscriptionProduct(
          id: 'premium_yearly',
          title: 'Yearly Premium',
          description:
              'Access to All Premium Features, 1000 Lunacoins, Ad-free Experience, Priority Support',
          price: '£79.99',
          rawPrice: '79.99',
          currencyCode: 'GBP',
          currencySymbol: '£',
        ),
      ];
    } else {
      // Default USD pricing
      return [
        SubscriptionProduct(
          id: 'premium_weekly',
          title: 'Weekly Premium',
          description: 'Dream Analysis, Exclusive Themes, 150 Lunacoins',
          price: '\$2.99',
          rawPrice: '2.99',
          currencyCode: 'USD',
          currencySymbol: '\$',
        ),
        SubscriptionProduct(
          id: 'premium_monthly',
          title: 'Monthly Premium',
          description:
              'Dream Analysis, Exclusive Themes, 250 Lunacoins, Unlocked Zen Mode',
          price: '\$9.99',
          rawPrice: '9.99',
          currencyCode: 'USD',
          currencySymbol: '\$',
        ),
        SubscriptionProduct(
          id: 'premium_yearly',
          title: 'Yearly Premium',
          description:
              'Access to All Premium Features, 1000 Lunacoins, Ad-free Experience, Priority Support',
          price: '\$99.99',
          rawPrice: '99.99',
          currencyCode: 'USD',
          currencySymbol: '\$',
        ),
      ];
    }
  }

  // Reload products (for external calls)
  Future<void> reloadProducts() async {
    if (kDebugMode) {
      await _loadMockProducts();
    } else {
      await _loadProducts();
    }
  }

  // Helper to update loading state
  void _setLoading(bool value) {
    _isLoading = value;
    _isLoadingStreamController.add(value);
  }

  // Purchase a subscription
  Future<SubscriptionPurchaseResult> purchaseSubscription(
      SubscriptionProduct product) async {
    if (!_isInitialized) {
      await init();
    }

    try {
      _setLoading(true);

      // Debug product details
      debugPrint('=== PURCHASE ATTEMPT DETAILS ===');
      debugPrint('Product ID: ${product.id}');
      debugPrint('Product Title: ${product.title}');
      debugPrint('Product Price: ${product.price}');
      debugPrint('Has product details: ${product.productDetails != null}');
      debugPrint('Running in debug mode: $kDebugMode');
      debugPrint('================================');

      // Always use real purchase flow regardless of debug/release mode
      debugPrint('SubscriptionService: Starting purchase for ${product.id}');

      // Get the product details from our model
      final productDetails = product.productDetails;
      if (productDetails == null) {
        _setLoading(false);
        return SubscriptionPurchaseResult(
          success: false,
          message: 'Product details not available',
        );
      }

      // Create a completer to resolve when purchase completes
      final completer = Completer<SubscriptionPurchaseResult>();
      _purchaseCompleters[product.id] = completer;

      // Prepare purchase params
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
        applicationUserName: null,
      );

      // Start the purchase flow
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);

      // Wait for the purchase to complete
      final result = await completer.future;
      _setLoading(false);
      return result;
    } catch (e) {
      debugPrint('Error purchasing subscription: $e');
      _setLoading(false);
      return SubscriptionPurchaseResult(
        success: false,
        message: 'Error: $e',
      );
    }
  }

  // Restore purchases
  Future<List<SubscriptionPurchaseResult>> restorePurchases() async {
    if (!_isInitialized) {
      await init();
    }

    try {
      _setLoading(true);

      // Always use real restore regardless of debug/release mode
      if (Platform.isAndroid) {
        await InAppPurchase.instance.restorePurchases();
      } else {
        // iOS restore is handled through the stream automatically
        await _inAppPurchase.restorePurchases();
      }

      // Wait a moment for the purchases to be processed
      await Future.delayed(const Duration(seconds: 2));

      _setLoading(false);
      return await _getActiveSubscriptions();
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      _setLoading(false);
      return [];
    }
  }

  // Get active subscriptions
  Future<List<SubscriptionPurchaseResult>> _getActiveSubscriptions() async {
    try {
      // Always use real subscription checking
      if (Platform.isAndroid) {
        // Directly use the InAppPurchase instance for simplicity
        final purchases = await _inAppPurchase.purchaseStream.first;

        // Filter active subscriptions
        final activePurchases = purchases.where((purchase) {
          return purchase.status == PurchaseStatus.purchased ||
              purchase.status == PurchaseStatus.restored;
        }).toList();

        // Convert to our model
        return activePurchases.map((purchase) {
          return SubscriptionPurchaseResult(
            success: true,
            productId: purchase.productID,
            purchaseId: purchase.purchaseID,
            purchaseToken: purchase is GooglePlayPurchaseDetails
                ? purchase.billingClientPurchase.purchaseToken
                : null,
            purchaseTime: purchase is GooglePlayPurchaseDetails
                ? purchase.billingClientPurchase.purchaseTime
                : null,
          );
        }).toList();
      } else {
        // For iOS, this would be different and use StoreKit
        return [];
      }
    } catch (e) {
      debugPrint('Error getting active subscriptions: $e');
      return [];
    }
  }

  // Method to check if user has any active subscription
  Future<bool> hasActiveSubscription() async {
    final activeSubscriptions = await _getActiveSubscriptions();
    return activeSubscriptions.isNotEmpty;
  }

  // Check if a specific subscription is active
  Future<bool> isSubscriptionActive(String productId) async {
    final activeSubscriptions = await _getActiveSubscriptions();
    return activeSubscriptions.any((sub) => sub.productId == productId);
  }

  // Handle purchase updates from the stream
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.pending) {
        debugPrint('Purchase is pending: ${purchase.productID}');
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        // Verify the purchase on the server (implement this)
        _verifyPurchase(purchase);
      } else if (purchase.status == PurchaseStatus.error) {
        debugPrint('Purchase error: ${purchase.error}');
        _handlePurchaseError(purchase);
      } else if (purchase.status == PurchaseStatus.canceled) {
        debugPrint('Purchase canceled: ${purchase.productID}');
        _handlePurchaseCanceled(purchase);
      }

      if (purchase.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchase);
      }
    }
  }

  // Verify the purchase (you'd typically validate with your server)
  Future<void> _verifyPurchase(PurchaseDetails purchase) async {
    try {
      // This would typically involve server validation
      // For now, we'll just mark it as successful

      debugPrint('Purchase verified: ${purchase.productID}');

      // Create purchase result
      final purchaseResult = SubscriptionPurchaseResult(
        success: true,
        productId: purchase.productID,
        purchaseId: purchase.purchaseID,
        message: 'Purchase successful',
        purchaseToken: purchase is GooglePlayPurchaseDetails
            ? purchase.billingClientPurchase.purchaseToken
            : null,
        purchaseTime: purchase is GooglePlayPurchaseDetails
            ? purchase.billingClientPurchase.purchaseTime
            : null,
      );

      // Save purchase info to preferences
      await _savePurchaseInfo(purchaseResult);

      // Complete any pending completer
      if (_purchaseCompleters.containsKey(purchase.productID)) {
        _purchaseCompleters[purchase.productID]?.complete(purchaseResult);
        _purchaseCompleters.remove(purchase.productID);
      }
    } catch (e) {
      debugPrint('Error verifying purchase: $e');
      if (_purchaseCompleters.containsKey(purchase.productID)) {
        _purchaseCompleters[purchase.productID]?.complete(
          SubscriptionPurchaseResult(
            success: false,
            message: 'Error verifying purchase: $e',
            productId: purchase.productID,
          ),
        );
        _purchaseCompleters.remove(purchase.productID);
      }
    }
  }

  // Handle purchase errors
  void _handlePurchaseError(PurchaseDetails purchase) {
    final error = purchase.error;
    debugPrint('Purchase error for ${purchase.productID}: ${error?.message}');

    // Log more details about the error for better debugging
    if (error != null) {
      debugPrint('Error code: ${error.code}');
      debugPrint('Error message: ${error.message}');
      debugPrint('Error details: ${error.details}');

      if (error.message?.toLowerCase().contains('not found') == true) {
        debugPrint('TROUBLESHOOTING TIPS:');
        debugPrint(
            '1. Verify product IDs in Google Play Console match exactly with app code');
        debugPrint(
            '2. Ensure you\'re signed in with a test account added in Play Console');
        debugPrint(
            '3. Check that the app is installed from Google Play internal testing track');
        debugPrint(
            '4. Verify the app package name matches the one in Play Console');
      }
    }

    if (_purchaseCompleters.containsKey(purchase.productID)) {
      _purchaseCompleters[purchase.productID]?.complete(
        SubscriptionPurchaseResult(
          success: false,
          message: 'Purchase error: ${error?.message}',
          productId: purchase.productID,
        ),
      );
      _purchaseCompleters.remove(purchase.productID);
    }
  }

  // Handle purchase cancellations
  void _handlePurchaseCanceled(PurchaseDetails purchase) {
    debugPrint('Purchase canceled for ${purchase.productID}');

    if (_purchaseCompleters.containsKey(purchase.productID)) {
      _purchaseCompleters[purchase.productID]?.complete(
        SubscriptionPurchaseResult(
          success: false,
          message: 'Purchase was canceled',
          productId: purchase.productID,
        ),
      );
      _purchaseCompleters.remove(purchase.productID);
    }
  }

  // Save purchase info to local storage
  Future<void> _savePurchaseInfo(SubscriptionPurchaseResult purchase) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'subscription_product_id', purchase.productId ?? '');
      await prefs.setString(
          'subscription_purchase_id', purchase.purchaseId ?? '');
      await prefs.setString(
          'subscription_purchase_token', purchase.purchaseToken ?? '');
      await prefs.setInt(
          'subscription_purchase_time', purchase.purchaseTime ?? 0);
      await prefs.setBool('has_active_subscription', true);
    } catch (e) {
      debugPrint('Error saving purchase info: $e');
    }
  }

  // Callback when the purchase stream is done
  void _onPurchaseDone() {
    _subscription?.cancel();
    _subscription = null;
    debugPrint('Purchase stream closed');
  }

  // Callback when the purchase stream has an error
  void _onPurchaseError(dynamic error) {
    debugPrint('Purchase stream error: $error');
  }

  // Dispose resources
  void dispose() {
    _subscription?.cancel();
    _productsStreamController.close();
    _isLoadingStreamController.close();
    _purchaseCompleters.clear();
    debugPrint('SubscriptionService disposed');
  }

  // Check app installation source for debugging
  Future<void> _checkAppInstallationSource() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      debugPrint('=== APP INSTALLATION INFO ===');
      debugPrint('App Name: ${packageInfo.appName}');
      debugPrint('Package Name: ${packageInfo.packageName}');
      debugPrint('Version: ${packageInfo.version}');
      debugPrint('Build Number: ${packageInfo.buildNumber}');
      debugPrint('Install Source: ${await _getInstallSource()}');
      debugPrint('=============================');
    } catch (e) {
      debugPrint('Error getting package info: $e');
    }
  }

  // Get the app installation source
  Future<String> _getInstallSource() async {
    if (Platform.isAndroid) {
      try {
        // This is a simplified check - in a real app, you would use
        // a method channel to get the exact install source
        if (kDebugMode) {
          return 'Debug Mode';
        } else {
          return 'Release Build (Possibly Google Play)';
        }
      } catch (e) {
        return 'Unknown (Error: $e)';
      }
    } else {
      return 'Not Android';
    }
  }
}
