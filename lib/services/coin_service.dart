import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'dart:async';
import 'models/coin_product.dart';
import '../auth/firebase_auth/auth_util.dart';
import '../backend/backend.dart';
import 'dart:io' show Platform;
import '../config/purchase_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CoinService {
  static final CoinService instance = CoinService._private();
  // Use late final so we only initialize once
  late final InAppPurchase _inAppPurchase;
  bool _isInAppPurchaseInitialized = false;

  bool _isInitialized = false;
  bool _isLoading = false;

  // Stream controllers
  final StreamController<bool> _isLoadingStreamController =
      StreamController<bool>.broadcast();
  final StreamController<List<CoinProduct>> _productsStreamController =
      StreamController<List<CoinProduct>>.broadcast();

  // Purchase result controller
  final StreamController<CoinPurchaseResult> _purchaseResultsController =
      StreamController<CoinPurchaseResult>.broadcast();
  Stream<CoinPurchaseResult> get purchaseResultsStream =>
      _purchaseResultsController.stream;

  // Available products
  List<CoinProduct> _availableProducts = [];

  // Subscription for purchase updates
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  // Getters
  Stream<bool> get isLoadingStream => _isLoadingStreamController.stream;
  Stream<List<CoinProduct>> get productsStream =>
      _productsStreamController.stream;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  List<CoinProduct> get availableProducts => _availableProducts;

  // Private constructor
  CoinService._private();

  // Initialize the service
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      debugPrint('CoinService.init(): Initializing coin service');
      _setLoading(true);

      // Initialize the InAppPurchase instance only once
      if (!_isInAppPurchaseInitialized) {
        _inAppPurchase = InAppPurchase.instance;
        _isInAppPurchaseInitialized = true;
        debugPrint('CoinService: InAppPurchase instance initialized');
      }

      // Initialize the purchase platform
      final isAvailable = await _inAppPurchase.isAvailable();
      if (!isAvailable) {
        debugPrint('CoinService.init(): Store is not available');
        _setLoading(false);
        return;
      }

      // Set up purchase subscription if not already set up
      if (_purchaseSubscription == null) {
        _purchaseSubscription = _inAppPurchase.purchaseStream
            .listen(_handlePurchaseUpdates, onDone: () {
          _purchaseSubscription?.cancel();
        }, onError: (error) {
          debugPrint('CoinService.init(): Purchase stream error - $error');
        });
        debugPrint('CoinService: Purchase stream listener set up');
      }

      // Load products only if they haven't been loaded yet
      if (_availableProducts.isEmpty) {
        await _loadProducts();
      }

      _isInitialized = true;
      _setLoading(false);
      debugPrint('CoinService.init(): Service initialized successfully');
    } catch (e) {
      debugPrint('CoinService.init(): Error initializing service - $e');
      _setLoading(false);
    }
  }

  // Load available products
  Future<void> _loadProducts() async {
    // In debug mode, use mock products for easier testing
    if (kDebugMode) {
      await _loadMockProducts();
      return;
    }

    try {
      debugPrint('CoinService._loadProducts(): Loading coin products');

      // Define product IDs from image (lunacoin_100, lunacoin_500, lunacoin_1000)
      final productIds = <String>{
        'lunacoin_100',
        'lunacoin_500',
        'lunacoin_1000',
      };

      // Load products from store
      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails(productIds);

      if (response.error != null) {
        debugPrint(
            'CoinService._loadProducts(): Error querying products - ${response.error}');
        return;
      }

      if (response.productDetails.isEmpty) {
        debugPrint('CoinService._loadProducts(): No products found');
        return;
      }

      // Convert to CoinProduct objects
      _availableProducts = response.productDetails.map((details) {
        int amount = 0;
        String bonus = '';

        if (details.id == 'lunacoin_100') {
          amount = 100;
        } else if (details.id == 'lunacoin_500') {
          amount = 500;
          bonus = 'BEST VALUE';
        } else if (details.id == 'lunacoin_1000') {
          amount = 1000;
          bonus = 'MOST POPULAR';
        }

        return CoinProduct.fromProductDetails(
          details,
          coinAmount: amount,
          bonus: bonus,
        );
      }).toList();

      // Sort by amount
      _availableProducts.sort((a, b) => a.amount.compareTo(b.amount));

      // Notify listeners
      _productsStreamController.add(_availableProducts);

      debugPrint(
          'CoinService._loadProducts(): Loaded ${_availableProducts.length} products');
    } catch (e) {
      debugPrint('CoinService._loadProducts(): Error loading products - $e');
    }
  }

  // Load mock products for testing
  Future<void> _loadMockProducts() async {
    debugPrint('CoinService._loadMockProducts(): Loading mock coin products');

    // Create mock products with simple data
    _availableProducts = [
      CoinProduct(
        id: 'lunacoin_100',
        title: '100 Luna Coins',
        amount: 100,
        price: '\$1.99',
        rawPrice: '1.99',
        currencyCode: 'USD',
        currencySymbol: '\$',
      ),
      CoinProduct(
        id: 'lunacoin_500',
        title: '500 Luna Coins',
        amount: 500,
        price: '\$6.99',
        rawPrice: '6.99',
        currencyCode: 'USD',
        currencySymbol: '\$',
        bonus: 'BEST VALUE',
      ),
      CoinProduct(
        id: 'lunacoin_1000',
        title: '1000 Luna Coins',
        amount: 1000,
        price: '\$9.99',
        rawPrice: '9.99',
        currencyCode: 'USD',
        currencySymbol: '\$',
        bonus: 'MOST POPULAR',
      ),
    ];

    // Notify listeners
    _productsStreamController.add(_availableProducts);

    debugPrint(
        'CoinService._loadMockProducts(): Loaded ${_availableProducts.length} mock products');
  }

  // Handle purchase updates
  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        debugPrint(
            'CoinService._handlePurchaseUpdates(): Purchase pending - ${purchaseDetails.productID}');
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          debugPrint(
              'CoinService._handlePurchaseUpdates(): Purchase error - ${purchaseDetails.error}');

          // Special handling for Google Play Store errors
          if (purchaseDetails is GooglePlayPurchaseDetails) {
            debugPrint(
                'Google Play error code: ${purchaseDetails.error?.code}');
            debugPrint(
                'Google Play error message: ${purchaseDetails.error?.message}');

            // Check if it's a common play store error
            if (purchaseDetails.error?.message
                    ?.contains('BillingResponse.ITEM_ALREADY_OWNED') ==
                true) {
              // Item already owned but not consumed - try to consume it or grant coins anyway
              try {
                debugPrint('Item already owned, trying to credit coins anyway');
                int coinAmount =
                    await _creditCoinsToUser(purchaseDetails.productID);

                _broadcastPurchaseResult(
                  CoinPurchaseResult(
                    success: true,
                    productId: purchaseDetails.productID,
                    coinAmount: coinAmount,
                    purchaseId:
                        purchaseDetails.purchaseID ?? 'recovered-purchase',
                    message: 'Purchase recovered successfully',
                  ),
                );
                continue;
              } catch (e) {
                debugPrint('Failed to recover purchase: $e');
              }
            }
          }

          // Broadcast error message
          _broadcastPurchaseResult(
            CoinPurchaseResult(
              success: false,
              productId: purchaseDetails.productID,
              message:
                  'Purchase error: ${purchaseDetails.error?.message ?? 'Unknown error'}',
            ),
          );
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          debugPrint(
              'CoinService._handlePurchaseUpdates(): Purchase successful - ${purchaseDetails.productID}');

          try {
            // Validate purchase
            bool isValid = await _validatePurchase(purchaseDetails);

            if (isValid) {
              // Credit coins to the user account
              int coinAmount =
                  await _creditCoinsToUser(purchaseDetails.productID);

              // Broadcast success
              _broadcastPurchaseResult(
                CoinPurchaseResult(
                  success: true,
                  productId: purchaseDetails.productID,
                  coinAmount: coinAmount,
                  purchaseId: purchaseDetails.purchaseID,
                  message: 'Purchase successful',
                ),
              );
            } else {
              debugPrint(
                  'CoinService._handlePurchaseUpdates(): Invalid purchase detected');

              // Broadcast error
              _broadcastPurchaseResult(
                CoinPurchaseResult(
                  success: false,
                  productId: purchaseDetails.productID,
                  message: 'Invalid purchase detected',
                ),
              );
            }
          } catch (e) {
            debugPrint(
                'CoinService._handlePurchaseUpdates(): Error processing purchase - $e');

            // Broadcast error
            _broadcastPurchaseResult(
              CoinPurchaseResult(
                success: false,
                productId: purchaseDetails.productID,
                message: 'Error processing purchase: $e',
              ),
            );
          }
        } else if (purchaseDetails.status == PurchaseStatus.canceled) {
          debugPrint('CoinService._handlePurchaseUpdates(): Purchase canceled');

          // Broadcast cancellation
          _broadcastPurchaseResult(
            CoinPurchaseResult(
              success: false,
              productId: purchaseDetails.productID,
              message: 'Purchase was canceled',
            ),
          );
        }

        if (purchaseDetails.pendingCompletePurchase) {
          try {
            await _inAppPurchase.completePurchase(purchaseDetails);
            debugPrint(
                'CoinService._handlePurchaseUpdates(): Purchase completed successfully');
          } catch (e) {
            debugPrint(
                'CoinService._handlePurchaseUpdates(): Error completing purchase - $e');
          }
        }
      }
    }
  }

  // Validate purchase - can be expanded for security checks
  Future<bool> _validatePurchase(PurchaseDetails purchaseDetails) async {
    // For now, simply check if we have a valid purchase with an ID
    return purchaseDetails.status == PurchaseStatus.purchased &&
        purchaseDetails.purchaseID != null;
  }

  // Method to broadcast purchase results
  void _broadcastPurchaseResult(CoinPurchaseResult result) {
    _purchaseResultsController.add(result);
  }

  // Credit coins to user account
  Future<int> _creditCoinsToUser(String productId) async {
    try {
      // Get the amount of coins for this product
      int coinAmount = 0;

      if (productId == 'lunacoin_100') {
        coinAmount = 100;
      } else if (productId == 'lunacoin_500') {
        coinAmount = 500;
      } else if (productId == 'lunacoin_1000') {
        coinAmount = 1000;
      }

      if (coinAmount <= 0) {
        debugPrint(
            'CoinService._creditCoinsToUser(): Invalid coin amount for $productId');
        return 0;
      }

      try {
        // First try direct Firestore update (more reliable in release mode)
        if (currentUserReference != null) {
          // Get the user document directly from Firestore
          final userDoc = await FirebaseFirestore.instance
              .doc(currentUserReference!.path)
              .get();

          if (!userDoc.exists) {
            throw Exception('User document not found');
          }

          // Get current coin balance safely
          final userData = userDoc.data();
          if (userData == null) {
            throw Exception('User data is null');
          }

          // Check if field is 'lunaCoins' or 'luna_coins'
          int currentCoins = 0;
          if (userData.containsKey('lunaCoins')) {
            currentCoins =
                userData['lunaCoins'] is int ? userData['lunaCoins'] as int : 0;
          } else if (userData.containsKey('luna_coins')) {
            currentCoins = userData['luna_coins'] is int
                ? userData['luna_coins'] as int
                : 0;
          }

          final newCoins = currentCoins + coinAmount;

          // Update both possible field names to ensure compatibility
          await FirebaseFirestore.instance
              .doc(currentUserReference!.path)
              .update({
            'lunaCoins': newCoins,
            'luna_coins': newCoins,
            'lastPurchaseDate': FieldValue.serverTimestamp(),
          });

          // Try to add purchase history, but don't fail if it doesn't work
          try {
            await FirebaseFirestore.instance
                .doc(currentUserReference!.path)
                .update({
              'purchaseHistory': FieldValue.arrayUnion([
                {
                  'productId': productId,
                  'amount': coinAmount,
                  'timestamp': Timestamp.now(),
                  'type': 'coin_purchase'
                }
              ])
            });
          } catch (e) {
            debugPrint('Error updating purchase history (non-critical): $e');
          }

          debugPrint(
              'CoinService._creditCoinsToUser(): Credited $coinAmount coins to user. New balance: $newCoins');
          return coinAmount;
        }
      } catch (e) {
        debugPrint(
            'Direct Firestore update failed, falling back to UserRecord: $e');
        // Fall back to UserRecord method
      }

      // Fallback: Use UserRecord (original method)
      final userDoc = await UserRecord.getDocumentOnce(currentUserReference!);
      if (userDoc == null) {
        debugPrint('CoinService._creditCoinsToUser(): User not found');
        return 0;
      }

      // Calculate the new balance
      final currentCoins = userDoc.lunaCoins ?? 0;
      final newCoins = currentCoins + coinAmount;

      // Update user document
      await userDoc.reference.update({
        'lunaCoins': newCoins,
      });

      debugPrint(
          'CoinService._creditCoinsToUser(): Credited $coinAmount coins to user. New balance: $newCoins');

      return coinAmount;
    } catch (e) {
      debugPrint(
          'CoinService._creditCoinsToUser(): Error crediting coins - $e');
      return 0;
    }
  }

  // Purchase coins
  Future<CoinPurchaseResult> purchaseCoins(CoinProduct product) async {
    if (!_isInitialized) {
      await init();
    }

    try {
      _setLoading(true);

      debugPrint(
          'CoinService.purchaseCoins(): Starting purchase - ${product.id}');

      // Get the product details
      final productDetails = product.productDetails;
      if (productDetails == null) {
        _setLoading(false);
        return CoinPurchaseResult(
          success: false,
          message: 'Product details not found',
        );
      }

      // Check if we're using a mock product
      if (productDetails is MockProductDetails) {
        // Handle mock purchase for testing
        await Future.delayed(Duration(seconds: 1));
        int coinAmount = await _creditCoinsToUser(product.id);

        _setLoading(false);

        // Broadcast success
        _broadcastPurchaseResult(
          CoinPurchaseResult(
            success: true,
            productId: product.id,
            coinAmount: coinAmount,
            purchaseId:
                'mock-purchase-${DateTime.now().millisecondsSinceEpoch}',
            message: 'Mock purchase successful',
          ),
        );

        return CoinPurchaseResult(
          success: true,
          productId: product.id,
          coinAmount: product.amount,
          message: 'Mock purchase successful',
        );
      }

      // Prepare purchase params
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
        applicationUserName: null,
      );

      // Make the purchase - launch Google Play Store
      bool launchedPurchase = false;

      try {
        // On Android, specifically handle the purchase launch
        if (Platform.isAndroid) {
          // Set application-specific properties
          if (_inAppPurchase is InAppPurchaseAndroidPlatformAddition) {
            final InAppPurchaseAndroidPlatformAddition androidAddition =
                _inAppPurchase.getPlatformAddition<
                    InAppPurchaseAndroidPlatformAddition>();

            // Set billing client parameters if needed
            await androidAddition.isAlternativeBillingOnlyAvailable();

            // Launch the purchase flow
            launchedPurchase = await _inAppPurchase.buyConsumable(
              purchaseParam: purchaseParam,
            );
          } else {
            // Fallback if platform addition isn't available
            launchedPurchase = await _inAppPurchase.buyConsumable(
              purchaseParam: purchaseParam,
            );
          }
        } else {
          // For non-Android platforms
          launchedPurchase = await _inAppPurchase.buyConsumable(
            purchaseParam: purchaseParam,
          );
        }
      } catch (e) {
        debugPrint('Error launching purchase: $e');
        _setLoading(false);
        return CoinPurchaseResult(
          success: false,
          message: 'Error launching purchase: $e',
        );
      }

      _setLoading(false);

      if (!launchedPurchase) {
        return CoinPurchaseResult(
          success: false,
          message: 'Failed to launch purchase flow',
        );
      }

      // Return a preliminary success since the purchase flow has been started
      // The actual purchase result will be handled in _handlePurchaseUpdates
      return CoinPurchaseResult(
        success: true,
        productId: product.id,
        coinAmount: product.amount,
        message: 'Purchase started successfully',
      );
    } catch (e) {
      _setLoading(false);
      debugPrint('CoinService.purchaseCoins(): Error purchasing coins - $e');
      return CoinPurchaseResult(
        success: false,
        message: 'Error: $e',
      );
    }
  }

  // Reload products
  Future<void> reloadProducts() async {
    // Always reload real products
    await _loadProducts();
  }

  // Helper to update loading state
  void _setLoading(bool value) {
    _isLoading = value;
    _isLoadingStreamController.add(value);
  }

  // Dispose resources
  void dispose() {
    _purchaseSubscription?.cancel();
    _isLoadingStreamController.close();
    _productsStreamController.close();
    _purchaseResultsController.close();
    _isInitialized = false;
    debugPrint('CoinService.dispose(): Resources disposed');
  }
}

// Mock implementation of ProductDetails for testing
class MockProductDetails implements ProductDetails {
  @override
  final String id;

  @override
  final String title;

  @override
  final String description;

  @override
  final String price;

  @override
  final double rawPrice;

  @override
  final String currencyCode;

  @override
  final String currencySymbol;

  MockProductDetails({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.rawPrice,
    required this.currencyCode,
    required this.currencySymbol,
  });
}
