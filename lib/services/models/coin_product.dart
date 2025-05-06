import 'package:in_app_purchase/in_app_purchase.dart';

class CoinProduct {
  final String id;
  final String title;
  final int amount;
  final String price;
  final String rawPrice;
  final String currencyCode;
  final String currencySymbol;
  final String? bonus;
  final ProductDetails? productDetails;

  CoinProduct({
    required this.id,
    required this.title,
    required this.amount,
    required this.price,
    required this.rawPrice,
    required this.currencyCode,
    required this.currencySymbol,
    this.bonus,
    this.productDetails,
  });

  factory CoinProduct.fromProductDetails(ProductDetails details,
      {int? coinAmount, String? bonus}) {
    String rawPrice = '0.00';
    String currencyCode = 'USD';
    String currencySymbol = '\$';

    // Extract coin amount from product ID if not provided
    coinAmount ??= _extractCoinAmount(details.id);

    if (details.currencyCode != null) {
      currencyCode = details.currencyCode!;
    }

    if (details.currencySymbol != null) {
      currencySymbol = details.currencySymbol!;
    }

    if (details.rawPrice != null) {
      rawPrice = details.rawPrice.toString();
    }

    return CoinProduct(
      id: details.id,
      title: details.title,
      amount: coinAmount,
      price: details.price,
      rawPrice: rawPrice,
      currencyCode: currencyCode,
      currencySymbol: currencySymbol,
      bonus: bonus,
      productDetails: details,
    );
  }

  // Helper to extract coin amount from product ID
  static int _extractCoinAmount(String productId) {
    // Try to parse the number from the product ID
    try {
      final regex = RegExp(r'(\d+)');
      final match = regex.firstMatch(productId);
      if (match != null) {
        return int.parse(match.group(1)!);
      }
    } catch (e) {
      print('Error extracting coin amount: $e');
    }
    return 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'price': price,
      'rawPrice': rawPrice,
      'currencyCode': currencyCode,
      'currencySymbol': currencySymbol,
      'bonus': bonus,
    };
  }
}

class CoinPurchaseResult {
  final bool success;
  final String? message;
  final String? productId;
  final int? coinAmount;
  final String? purchaseId;
  final String? purchaseToken;
  final int? purchaseTime;

  CoinPurchaseResult({
    required this.success,
    this.message,
    this.productId,
    this.coinAmount,
    this.purchaseId,
    this.purchaseToken,
    this.purchaseTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'message': message,
      'productId': productId,
      'coinAmount': coinAmount,
      'purchaseId': purchaseId,
      'purchaseToken': purchaseToken,
      'purchaseTime': purchaseTime,
    };
  }
}
