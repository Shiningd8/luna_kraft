import 'package:in_app_purchase/in_app_purchase.dart';

class SubscriptionProduct {
  final String id;
  final String title;
  final String description;
  final String price;
  final String rawPrice;
  final String currencyCode;
  final String currencySymbol;
  final ProductDetails? productDetails;

  SubscriptionProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.rawPrice,
    required this.currencyCode,
    required this.currencySymbol,
    this.productDetails,
  });

  factory SubscriptionProduct.fromProductDetails(ProductDetails details) {
    String rawPrice = '0.00';
    String currencyCode = 'USD';
    String currencySymbol = '\$';

    if (details.currencyCode != null) {
      currencyCode = details.currencyCode!;
    }

    if (details.currencySymbol != null) {
      currencySymbol = details.currencySymbol!;
    }

    if (details.rawPrice != null) {
      rawPrice = details.rawPrice.toString();
    }

    return SubscriptionProduct(
      id: details.id,
      title: details.title,
      description: details.description,
      price: details.price,
      rawPrice: rawPrice,
      currencyCode: currencyCode,
      currencySymbol: currencySymbol,
      productDetails: details,
    );
  }

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
