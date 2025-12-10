/// Customer App Service
/// Handles loyalty, orders, reviews, recipes, and navigation

import 'api_service.dart';

/// Customer Profile
class CustomerProfile {
  final String id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final List<String> dietaryPreferences;
  final List<String> allergens;

  CustomerProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    this.dateOfBirth,
    this.dietaryPreferences = const [],
    this.allergens = const [],
  });

  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    return CustomerProfile(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      phoneNumber: json['phone_number'],
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'])
          : null,
      dietaryPreferences: List<String>.from(json['dietary_preferences'] ?? []),
      allergens: List<String>.from(json['allergens'] ?? []),
    );
  }
}

/// Loyalty Card
class LoyaltyCard {
  final String cardNumber;
  final String barcode;
  final int pointsBalance;
  final int lifetimePoints;
  final String tier;
  final String tierDisplay;

  LoyaltyCard({
    required this.cardNumber,
    required this.barcode,
    required this.pointsBalance,
    required this.lifetimePoints,
    required this.tier,
    required this.tierDisplay,
  });

  factory LoyaltyCard.fromJson(Map<String, dynamic> json) {
    return LoyaltyCard(
      cardNumber: json['card_number'] ?? '',
      barcode: json['barcode'] ?? '',
      pointsBalance: json['points_balance'] ?? 0,
      lifetimePoints: json['lifetime_points'] ?? 0,
      tier: json['tier'] ?? 'bronze',
      tierDisplay: json['tier_display'] ?? 'Bronze',
    );
  }

  double get tierProgress {
    final thresholds = {'bronze': 5000, 'silver': 20000, 'gold': 50000, 'platinum': 100000};
    final currentThreshold = thresholds[tier] ?? 5000;
    return (lifetimePoints / currentThreshold).clamp(0.0, 1.0);
  }
}

/// Personalized Offer
class PersonalizedOffer {
  final String id;
  final String title;
  final String description;
  final String offerType;
  final double value;
  final String code;
  final DateTime validUntil;
  final bool isValid;

  PersonalizedOffer({
    required this.id,
    required this.title,
    required this.description,
    required this.offerType,
    required this.value,
    required this.code,
    required this.validUntil,
    required this.isValid,
  });

  factory PersonalizedOffer.fromJson(Map<String, dynamic> json) {
    return PersonalizedOffer(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      offerType: json['offer_type'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
      code: json['code'] ?? '',
      validUntil: DateTime.tryParse(json['valid_until'] ?? '') ?? DateTime.now(),
      isValid: json['is_valid'] ?? false,
    );
  }
}

/// Customer Order
class CustomerOrder {
  final String id;
  final String orderNumber;
  final String status;
  final String statusDisplay;
  final String orderType;
  final double totalAmount;
  final DateTime createdAt;
  final List<OrderItem> items;

  CustomerOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.statusDisplay,
    required this.orderType,
    required this.totalAmount,
    required this.createdAt,
    this.items = const [],
  });

  factory CustomerOrder.fromJson(Map<String, dynamic> json) {
    return CustomerOrder(
      id: json['id']?.toString() ?? '',
      orderNumber: json['order_number'] ?? '',
      status: json['status'] ?? '',
      statusDisplay: json['status_display'] ?? '',
      orderType: json['order_type'] ?? '',
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      items: (json['items'] as List?)
              ?.map((i) => OrderItem.fromJson(i))
              .toList() ?? [],
    );
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product']?.toString() ?? '',
      productName: json['product_name'] ?? '',
      quantity: json['quantity'] ?? 1,
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      totalPrice: (json['total_price'] ?? 0).toDouble(),
    );
  }
}

/// Recipe
class Recipe {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String? videoUrl;
  final int prepTime;
  final int cookTime;
  final int totalTime;
  final int servings;
  final String difficulty;
  final String mealType;
  final String? cuisine;
  final List<String> tags;

  Recipe({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.videoUrl,
    required this.prepTime,
    required this.cookTime,
    required this.totalTime,
    required this.servings,
    required this.difficulty,
    required this.mealType,
    this.cuisine,
    this.tags = const [],
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'],
      videoUrl: json['video_url'],
      prepTime: json['prep_time'] ?? 0,
      cookTime: json['cook_time'] ?? 0,
      totalTime: json['total_time'] ?? 0,
      servings: json['servings'] ?? 4,
      difficulty: json['difficulty'] ?? 'medium',
      mealType: json['meal_type'] ?? '',
      cuisine: json['cuisine'],
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
}

/// Customer App Service
class CustomerAppService {
  final ApiService _apiService;

  CustomerAppService(this._apiService);

  // === Profile ===
  Future<CustomerProfile> getProfile() async {
    final response = await _apiService.get('/api/customer/profile/me/');
    return CustomerProfile.fromJson(response);
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    await _apiService.patch('/api/customer/profile/me/', body: data);
  }

  // === Loyalty ===
  Future<LoyaltyCard?> getLoyaltyCard() async {
    try {
      final response = await _apiService.get('/api/customer/loyalty/card/');
      return LoyaltyCard.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getLoyaltyTransactions() async {
    try {
      final response = await _apiService.get('/api/customer/loyalty/transactions/');
      final list = response is List ? response : response['results'] ?? [];
      return List<Map<String, dynamic>>.from(list);
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> redeemPoints(int points) async {
    final response = await _apiService.post(
      '/api/customer/loyalty/redeem/',
      body: {'points': points},
    );
    return response;
  }

  // === Offers ===
  Future<List<PersonalizedOffer>> getOffers() async {
    try {
      final response = await _apiService.get('/api/customer/offers/');
      final list = response is List ? response : response['results'] ?? [];
      return list.map<PersonalizedOffer>((o) => PersonalizedOffer.fromJson(o)).toList();
    } catch (e) {
      return [];
    }
  }

  // === Orders ===
  Future<List<CustomerOrder>> getOrders() async {
    try {
      final response = await _apiService.get('/api/customer/orders/');
      final list = response is List ? response : response['results'] ?? [];
      return list.map<CustomerOrder>((o) => CustomerOrder.fromJson(o)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<CustomerOrder> createOrder(Map<String, dynamic> orderData) async {
    final response = await _apiService.post('/api/customer/orders/', body: orderData);
    return CustomerOrder.fromJson(response);
  }

  Future<void> cancelOrder(String orderId) async {
    await _apiService.post('/api/customer/orders/$orderId/cancel/', body: {});
  }

  // === Reviews ===
  Future<void> submitReview({
    required String productId,
    required int rating,
    String? title,
    String? review,
  }) async {
    await _apiService.post('/api/customer/reviews/', body: {
      'product': productId,
      'rating': rating,
      if (title != null) 'title': title,
      if (review != null) 'review': review,
    });
  }

  Future<List<Map<String, dynamic>>> getProductReviews(String productId) async {
    try {
      final response = await _apiService.get(
        '/api/customer/reviews/',
        queryParams: {'product_id': productId},
      );
      final list = response is List ? response : response['results'] ?? [];
      return List<Map<String, dynamic>>.from(list);
    } catch (e) {
      return [];
    }
  }

  // === Recipes ===
  Future<List<Recipe>> getRecipes({
    String? mealType,
    String? difficulty,
    String? search,
  }) async {
    try {
      final response = await _apiService.get('/api/customer/recipes/', queryParams: {
        if (mealType != null) 'meal_type': mealType,
        if (difficulty != null) 'difficulty': difficulty,
        if (search != null) 'search': search,
      });
      final list = response is List ? response : response['results'] ?? [];
      return list.map<Recipe>((r) => Recipe.fromJson(r)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Recipe> getRecipeDetail(String recipeId) async {
    final response = await _apiService.get('/api/customer/recipes/$recipeId/');
    return Recipe.fromJson(response);
  }

  Future<void> saveRecipe(String recipeId) async {
    await _apiService.post('/api/customer/recipes/$recipeId/save/', body: {});
  }

  Future<List<Recipe>> getSavedRecipes() async {
    try {
      final response = await _apiService.get('/api/customer/recipes/saved/');
      final list = response is List ? response : response['results'] ?? [];
      return list.map<Recipe>((r) => Recipe.fromJson(r)).toList();
    } catch (e) {
      return [];
    }
  }

  // === Navigation ===
  Future<Map<String, dynamic>> findProductLocation(
    String productId,
    String storeId,
  ) async {
    final response = await _apiService.get('/api/customer/navigation/find_product/', queryParams: {
      'product_id': productId,
      'store_id': storeId,
    });
    return response;
  }

  Future<List<Map<String, dynamic>>> getStoreAisles(String storeId) async {
    try {
      final response = await _apiService.get(
        '/api/customer/navigation/aisles/',
        queryParams: {'store_id': storeId},
      );
      final list = response is List ? response : response['results'] ?? [];
      return List<Map<String, dynamic>>.from(list);
    } catch (e) {
      return [];
    }
  }

  // === Referrals ===
  Future<Map<String, dynamic>> getReferralCode() async {
    final response = await _apiService.get('/api/customer/referrals/code/');
    return response;
  }

  Future<Map<String, dynamic>> getReferralStats() async {
    final response = await _apiService.get('/api/customer/referrals/stats/');
    return response;
  }
}
