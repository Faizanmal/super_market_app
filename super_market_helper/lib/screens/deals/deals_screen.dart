/// Deals & Promotions Screen
/// Browse current deals, flash sales, and personalized offers

import 'package:flutter/material.dart';
import '../../services/customer_app_service.dart';
import '../../services/api_service.dart';

class DealsScreen extends StatefulWidget {
  const DealsScreen({super.key});

  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final CustomerAppService _customerService;
  
  List<PersonalizedOffer> _personalOffers = [];
  bool _isLoading = true;

  // Mock data for different deal types
  final List<Deal> _flashDeals = [
    Deal(
      id: '1',
      title: '50% OFF Fresh Produce',
      description: 'All organic vegetables and fruits',
      discount: '50%',
      validUntil: DateTime.now().add(const Duration(hours: 2)),
      imageUrl: null,
      category: 'Produce',
    ),
    Deal(
      id: '2',
      title: 'Buy 2 Get 1 FREE',
      description: 'On all dairy products',
      discount: 'B2G1',
      validUntil: DateTime.now().add(const Duration(hours: 5)),
      imageUrl: null,
      category: 'Dairy',
    ),
    Deal(
      id: '3',
      title: '\$5 OFF',
      description: 'Orders over \$50',
      discount: '\$5',
      validUntil: DateTime.now().add(const Duration(hours: 8)),
      imageUrl: null,
      category: 'All',
    ),
  ];

  final List<Deal> _weeklyDeals = [
    Deal(
      id: '4',
      title: '20% OFF Deli Counter',
      description: 'Fresh sliced meats and cheeses',
      discount: '20%',
      validUntil: DateTime.now().add(const Duration(days: 3)),
      imageUrl: null,
      category: 'Deli',
    ),
    Deal(
      id: '5',
      title: 'Family Meal Deal',
      description: '4 items for \$20',
      discount: '\$20',
      validUntil: DateTime.now().add(const Duration(days: 5)),
      imageUrl: null,
      category: 'Ready Meals',
    ),
    Deal(
      id: '6',
      title: '30% OFF Bakery',
      description: 'Fresh baked goods daily',
      discount: '30%',
      validUntil: DateTime.now().add(const Duration(days: 7)),
      imageUrl: null,
      category: 'Bakery',
    ),
  ];

  final List<Deal> _clearanceDeals = [
    Deal(
      id: '7',
      title: '70% OFF Near Expiry',
      description: 'Quality products at huge savings',
      discount: '70%',
      validUntil: DateTime.now().add(const Duration(days: 1)),
      imageUrl: null,
      category: 'Clearance',
      isClearance: true,
    ),
    Deal(
      id: '8',
      title: 'Last Chance Items',
      description: 'Up to 60% off selected products',
      discount: '60%',
      validUntil: DateTime.now().add(const Duration(days: 2)),
      imageUrl: null,
      category: 'Clearance',
      isClearance: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _customerService = CustomerAppService(ApiService());
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    setState(() => _isLoading = true);
    
    try {
      final offers = await _customerService.getOffers();
      setState(() {
        _personalOffers = offers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 180,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        const Text(
                          'Today\'s Best Deals',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Save big on your favorites!',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(icon: Icon(Icons.bolt), text: 'Flash'),
                Tab(icon: Icon(Icons.calendar_today), text: 'Weekly'),
                Tab(icon: Icon(Icons.person), text: 'For You'),
                Tab(icon: Icon(Icons.discount), text: 'Clearance'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildFlashDealsTab(theme),
            _buildWeeklyDealsTab(theme),
            _buildPersonalOffersTab(theme),
            _buildClearanceTab(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildFlashDealsTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Countdown banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade400, Colors.orange.shade400],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.timer, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Flash Sale Ends In',
                      style: TextStyle(color: Colors.white70),
                    ),
                    StreamBuilder(
                      stream: Stream.periodic(const Duration(seconds: 1)),
                      builder: (context, snapshot) {
                        final now = DateTime.now();
                        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
                        final diff = end.difference(now);
                        return Text(
                          '${diff.inHours.toString().padLeft(2, '0')}:${(diff.inMinutes % 60).toString().padLeft(2, '0')}:${(diff.inSeconds % 60).toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                ),
                child: const Text('Shop All'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Flash deals grid
        ..._flashDeals.map((deal) => _buildDealCard(deal, theme, isFlash: true)),
      ],
    );
  }

  Widget _buildWeeklyDealsTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'This Week\'s Specials',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ..._weeklyDeals.map((deal) => _buildDealCard(deal, theme)),
      ],
    );
  }

  Widget _buildPersonalOffersTab(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_personalOffers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_giftcard, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No personalized offers yet',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Keep shopping to unlock exclusive deals!',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _personalOffers.length,
      itemBuilder: (context, index) {
        final offer = _personalOffers[index];
        return _buildOfferCard(offer, theme);
      },
    );
  }

  Widget _buildClearanceTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.eco, color: Colors.green.shade600),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Help reduce food waste! These items are near their best-by date but still great quality.',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ..._clearanceDeals.map((deal) => _buildDealCard(deal, theme, isClearance: true)),
      ],
    );
  }

  Widget _buildDealCard(Deal deal, ThemeData theme, {bool isFlash = false, bool isClearance = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDealDetail(deal),
        child: Column(
          children: [
            // Deal banner
            Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isClearance
                      ? [Colors.amber.shade400, Colors.orange.shade400]
                      : isFlash
                          ? [Colors.red.shade400, Colors.pink.shade400]
                          : [theme.colorScheme.primary, theme.colorScheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  // Pattern overlay
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.1,
                      child: Container(
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage('https://via.placeholder.com/200'),
                            repeat: ImageRepeat.repeat,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Discount badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        deal.discount,
                        style: TextStyle(
                          color: isFlash ? Colors.red : theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  // Category badge
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        deal.category,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Deal content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deal.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(deal.description, style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Ends ${_formatTimeRemaining(deal.validUntil)}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _showDealDetail(deal),
                        child: const Text('View Deal'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferCard(PersonalizedOffer offer, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  offer.offerType == 'percentage' ? '${offer.value.toInt()}%' : '\$${offer.value.toInt()}',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(offer.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(offer.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    'Code: ${offer.code}',
                    style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  void _showDealDetail(Deal deal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    deal.discount,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    deal.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(deal.description),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.access_time, size: 20),
                const SizedBox(width: 8),
                Text('Expires ${_formatTimeRemaining(deal.validUntil)}'),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Browsing deal products...')),
                  );
                },
                icon: const Icon(Icons.shopping_bag),
                label: const Text('Shop Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeRemaining(DateTime validUntil) {
    final diff = validUntil.difference(DateTime.now());
    if (diff.inDays > 0) {
      return 'in ${diff.inDays} day${diff.inDays > 1 ? 's' : ''}';
    } else if (diff.inHours > 0) {
      return 'in ${diff.inHours} hour${diff.inHours > 1 ? 's' : ''}';
    } else {
      return 'in ${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''}';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class Deal {
  final String id;
  final String title;
  final String description;
  final String discount;
  final DateTime validUntil;
  final String? imageUrl;
  final String category;
  final bool isClearance;

  Deal({
    required this.id,
    required this.title,
    required this.description,
    required this.discount,
    required this.validUntil,
    this.imageUrl,
    required this.category,
    this.isClearance = false,
  });
}
