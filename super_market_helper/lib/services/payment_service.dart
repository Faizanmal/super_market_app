/// Payment Service
/// Handles mobile payments, BNPL, and split bills
library;

import 'api_service.dart';

enum PaymentMethod {
  creditCard,
  debitCard,
  googlePay,
  applePay,
  samsungPay,
  paypal,
  afterpay,
  klarna,
  affirm,
  storeCredit,
  loyaltyPoints,
}

extension PaymentMethodExt on PaymentMethod {
  String get value {
    switch (this) {
      case PaymentMethod.creditCard:
        return 'credit_card';
      case PaymentMethod.debitCard:
        return 'debit_card';
      case PaymentMethod.googlePay:
        return 'google_pay';
      case PaymentMethod.applePay:
        return 'apple_pay';
      case PaymentMethod.samsungPay:
        return 'samsung_pay';
      case PaymentMethod.paypal:
        return 'paypal';
      case PaymentMethod.afterpay:
        return 'bnpl_afterpay';
      case PaymentMethod.klarna:
        return 'bnpl_klarna';
      case PaymentMethod.affirm:
        return 'bnpl_affirm';
      case PaymentMethod.storeCredit:
        return 'store_credit';
      case PaymentMethod.loyaltyPoints:
        return 'loyalty_points';
    }
  }

  String get displayName {
    switch (this) {
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.debitCard:
        return 'Debit Card';
      case PaymentMethod.googlePay:
        return 'Google Pay';
      case PaymentMethod.applePay:
        return 'Apple Pay';
      case PaymentMethod.samsungPay:
        return 'Samsung Pay';
      case PaymentMethod.paypal:
        return 'PayPal';
      case PaymentMethod.afterpay:
        return 'Afterpay';
      case PaymentMethod.klarna:
        return 'Klarna';
      case PaymentMethod.affirm:
        return 'Affirm';
      case PaymentMethod.storeCredit:
        return 'Store Credit';
      case PaymentMethod.loyaltyPoints:
        return 'Loyalty Points';
    }
  }

  String get icon {
    switch (this) {
      case PaymentMethod.creditCard:
      case PaymentMethod.debitCard:
        return '💳';
      case PaymentMethod.googlePay:
        return '📱';
      case PaymentMethod.applePay:
        return '🍎';
      case PaymentMethod.samsungPay:
        return '📱';
      case PaymentMethod.paypal:
        return '🅿️';
      case PaymentMethod.afterpay:
      case PaymentMethod.klarna:
      case PaymentMethod.affirm:
        return '🔄';
      case PaymentMethod.storeCredit:
        return '🏪';
      case PaymentMethod.loyaltyPoints:
        return '⭐';
    }
  }
}

class AvailablePaymentMethod {
  final PaymentMethod method;
  final String name;
  final String icon;
  final bool isAvailable;
  final double? balance;
  final List<BNPLPlan>? paymentOptions;

  AvailablePaymentMethod({
    required this.method,
    required this.name,
    required this.icon,
    required this.isAvailable,
    this.balance,
    this.paymentOptions,
  });
}

class BNPLPlan {
  final String plan;
  final int installments;
  final String frequency;
  final double amountPerInstallment;
  final double interest;

  BNPLPlan({
    required this.plan,
    required this.installments,
    required this.frequency,
    required this.amountPerInstallment,
    required this.interest,
  });

  factory BNPLPlan.fromJson(Map<String, dynamic> json) {
    return BNPLPlan(
      plan: json['plan'] ?? '',
      installments: json['installments'] ?? 1,
      frequency: json['frequency'] ?? 'monthly',
      amountPerInstallment: (json['amount_per_installment'] ?? 0).toDouble(),
      interest: (json['interest'] ?? 0).toDouble(),
    );
  }
}

class PaymentResult {
  final bool success;
  final String? paymentId;
  final String? clientSecret;
  final String? checkoutUrl;
  final String? error;

  PaymentResult({
    required this.success,
    this.paymentId,
    this.clientSecret,
    this.checkoutUrl,
    this.error,
  });

  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    return PaymentResult(
      success: json['success'] ?? json['error'] == null,
      paymentId: json['payment_id'],
      clientSecret: json['client_secret'],
      checkoutUrl: json['checkout_url'],
      error: json['error'],
    );
  }
}

class SplitPayment {
  final String id;
  final String orderId;
  final double totalAmount;
  final String status;
  final List<SplitParticipant> participants;

  SplitPayment({
    required this.id,
    required this.orderId,
    required this.totalAmount,
    required this.status,
    required this.participants,
  });

  factory SplitPayment.fromJson(Map<String, dynamic> json) {
    return SplitPayment(
      id: json['id'] ?? '',
      orderId: json['order_id'] ?? '',
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      participants: (json['participants'] as List?)
              ?.map((p) => SplitParticipant.fromJson(p))
              .toList() ??
          [],
    );
  }
}

class SplitParticipant {
  final String userId;
  final String email;
  final double amount;
  final bool hasPaid;

  SplitParticipant({
    required this.userId,
    required this.email,
    required this.amount,
    required this.hasPaid,
  });

  factory SplitParticipant.fromJson(Map<String, dynamic> json) {
    return SplitParticipant(
      userId: json['user_id'] ?? '',
      email: json['email'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      hasPaid: json['has_paid'] ?? false,
    );
  }
}

class PaymentService {
  final ApiService _apiService;

  PaymentService(this._apiService);

  /// Get available payment methods for an amount
  Future<List<AvailablePaymentMethod>> getAvailableMethods(double amount) async {
    try {
      final response = await _apiService.get(
        '/api/payments/methods/',
        queryParams: {' amount': amount.toString()},
      );
      
      final methods = <AvailablePaymentMethod>[];
      // Handle response that could be List or Map
      final list = response is List ? response : (response['results'] ?? response['methods'] ?? []);
      for (final m in list) {
        final methodStr = m['method'] as String;
        PaymentMethod? method;
        
        switch (methodStr) {
          case 'credit_card':
            method = PaymentMethod.creditCard;
            break;
          case 'debit_card':
            method = PaymentMethod.debitCard;
            break;
          case 'google_pay':
            method = PaymentMethod.googlePay;
            break;
          case 'apple_pay':
            method = PaymentMethod.applePay;
            break;
          case 'bnpl_afterpay':
            method = PaymentMethod.afterpay;
            break;
          case 'bnpl_klarna':
            method = PaymentMethod.klarna;
            break;
          case 'store_credit':
            method = PaymentMethod.storeCredit;
            break;
        }

        if (method != null) {
          methods.add(AvailablePaymentMethod(
            method: method,
            name: m['name'] ?? method.displayName,
            icon: m['icon'] ?? method.icon,
            isAvailable: m['available'] ?? false,
            balance: m['balance']?.toDouble(),
            paymentOptions: (m['payment_options'] as List?)
                ?.map((o) => BNPLPlan.fromJson(o))
                .toList(),
          ));
        }
      }
      return methods;
    } catch (e) {
      // Return default methods
      return [
        AvailablePaymentMethod(
          method: PaymentMethod.creditCard,
          name: 'Credit Card',
          icon: '💳',
          isAvailable: true,
        ),
        AvailablePaymentMethod(
          method: PaymentMethod.googlePay,
          name: 'Google Pay',
          icon: '📱',
          isAvailable: true,
        ),
      ];
    }
  }

  /// Process a payment
  Future<PaymentResult> processPayment({
    required String orderId,
    required double amount,
    required PaymentMethod method,
    String? paymentToken,
    String? bnplPlan,
  }) async {
    try {
      final response = await _apiService.post('/api/payments/process/', body: {
        'order_id': orderId,
        '  amount': amount,
        'payment_method': method.value,
        if (paymentToken != null) 'payment_token': paymentToken,
        if (bnplPlan != null) 'plan': bnplPlan,
      });
      return PaymentResult.fromJson(response);
    } catch (e) {
      return PaymentResult(success: false, error: e.toString());
    }
  }

  /// Get store credit balance
  Future<double> getStoreCreditBalance() async {
    try {
      final response = await _apiService.get('/api/payments/store-credit/balance/');
      return (response['balance'] ?? 0).toDouble();
    } catch (e) {
      return 0;
    }
  }

  /// Create a split payment
  Future<SplitPayment> createSplitPayment({
    required String orderId,
    required double totalAmount,
    required List<Map<String, dynamic>> participants,
    String splitType = 'equal',
  }) async {
    final response = await _apiService.post('/api/payments/split/create/', body: {
      'order_id': orderId,
      'total_amount': totalAmount,
      'participants': participants,
      'split_type': splitType,
    });
    return SplitPayment.fromJson(response);
  }

  /// Get split payment status
  Future<SplitPayment> getSplitStatus(String splitId) async {
    final response = await _apiService.get('/api/payments/split/$splitId/status/');
    return SplitPayment.fromJson(response);
  }

  /// Create a gift card
  Future<Map<String, dynamic>> createGiftCard(double amount) async {
    final response = await _apiService.post('/api/payments/gift-cards/create/', body: {
      'amount': amount,
    });
    return response;
  }

  /// Redeem a gift card
  Future<Map<String, dynamic>> redeemGiftCard(String cardNumber, String pin) async {
    final response = await _apiService.post('/api/payments/gift-cards/redeem/', body: {
      'card_number': cardNumber,
      'pin': pin,
    });
    return response;
  }
}
