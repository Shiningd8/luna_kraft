// Don't import in_app_purchase to avoid conflict with RevenueCat

class SubscriptionProduct {
  final String id;
  final String title;
  final String description;
  final String price;
  final String rawPrice;
  final String currencyCode;
  final String currencySymbol;
  // Removed ProductDetails to avoid dependency on in_app_purchase

  SubscriptionProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.rawPrice,
    required this.currencyCode,
    required this.currencySymbol,
  });

  // Factory method removed as it depended on ProductDetails

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'rawPrice': rawPrice,
      'currencyCode': currencyCode,
      'currencySymbol': currencySymbol,
    };
  }
}

class SubscriptionPurchaseResult {
  final bool success;
  final String? message;
  final String? productId;
  final String? purchaseId;
  final String? purchaseToken;
  final int? purchaseTime;
  final bool isSubscription;

  SubscriptionPurchaseResult({
    required this.success,
    this.message,
    this.productId,
    this.purchaseId,
    this.purchaseToken,
    this.purchaseTime,
    this.isSubscription = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'message': message,
      'productId': productId,
      'purchaseId': purchaseId,
      'purchaseToken': purchaseToken,
      'purchaseTime': purchaseTime,
      'isSubscription': isSubscription,
    };
  }
}
