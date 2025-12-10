/// Loyalty Dashboard Screen
/// Shows loyalty card, points, tiers, and offers

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/customer_app_service.dart';
import '../../services/api_service.dart';

class LoyaltyDashboardScreen extends StatefulWidget {
  const LoyaltyDashboardScreen({super.key});

  @override
  State<LoyaltyDashboardScreen> createState() => _LoyaltyDashboardScreenState();
}

class _LoyaltyDashboardScreenState extends State<LoyaltyDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final CustomerAppService _customerService;
  late final TabController _tabController;
  
  LoyaltyCard? _card;
  List<PersonalizedOffer> _offers = [];
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _customerService = CustomerAppService(ApiService());
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final results = await Future.wait([
      _customerService.getLoyaltyCard(),
      _customerService.getOffers(),
      _customerService.getLoyaltyTransactions(),
    ]);
    
    setState(() {
      _card = results[0] as LoyaltyCard?;
      _offers = results[1] as List<PersonalizedOffer>;
      _transactions = results[2] as List<Map<String, dynamic>>;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // App bar with loyalty card
                SliverAppBar(
                  expandedHeight: 280,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: _buildLoyaltyCard(theme),
                  ),
                  bottom: TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Offers'),
                      Tab(text: 'History'),
                    ],
                  ),
                ),
                
                // Tab content
                SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(theme),
                      _buildOffersTab(theme),
                      _buildHistoryTab(theme),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLoyaltyCard(ThemeData theme) {
    if (_card == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Text('No loyalty card found', style: TextStyle(color: Colors.white)),
        ),
      );
    }
    
    final tierColors = {
      'bronze': [Colors.brown.shade400, Colors.brown.shade600],
      'silver': [Colors.grey.shade400, Colors.grey.shade600],
      'gold': [Colors.amber.shade400, Colors.amber.shade600],
      'platinum': [Colors.blueGrey.shade300, Colors.blueGrey.shade500],
      'diamond': [Colors.blue.shade300, Colors.purple.shade400],
    };
    
    final colors = tierColors[_card!.tier] ?? [Colors.blue, Colors.purple];
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'SuperMart Rewards',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _card!.tierDisplay,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                _card!.cardNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Points Balance', style: TextStyle(color: Colors.white70)),
                      Text(
                        '${_card!.pointsBalance}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.qr_code, color: Colors.white, size: 40),
                    onPressed: _showQRCode,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Tier progress
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next tier: ${_getNextTier(_card!.tier)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: _card!.tierProgress,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Quick actions
        Text('Quick Actions', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.redeem,
                label: 'Redeem Points',
                onTap: _showRedeemDialog,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.share,
                label: 'Refer a Friend',
                onTap: _showReferralDialog,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Stats
        Text('Your Stats', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Lifetime\nPoints', '${_card?.lifetimePoints ?? 0}'),
                _buildStat('Current\nBalance', '${_card?.pointsBalance ?? 0}'),
                _buildStat('Member\nSince', '2024'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Tier benefits
        Text('Tier Benefits', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        ..._getTierBenefits().map((benefit) => ListTile(
          leading: const Icon(Icons.check_circle, color: Colors.green),
          title: Text(benefit),
        )),
      ],
    );
  }

  Widget _buildOffersTab(ThemeData theme) {
    if (_offers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No offers available', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _offers.length,
      itemBuilder: (context, index) {
        final offer = _offers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _showOfferDetail(offer),
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
                        _getOfferValue(offer),
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
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
                          'Valid until ${_formatDate(offer.validUntil)}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: offer.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copied!')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab(ThemeData theme) {
    if (_transactions.isEmpty) {
      return const Center(child: Text('No transactions yet'));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final tx = _transactions[index];
        final isEarned = tx['type'] == 'earn' || tx['type'] == 'bonus';
        
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isEarned ? Colors.green.shade100 : Colors.red.shade100,
            child: Icon(
              isEarned ? Icons.add : Icons.remove,
              color: isEarned ? Colors.green : Colors.red,
            ),
          ),
          title: Text(tx['description'] ?? ''),
          subtitle: Text(tx['date'] ?? ''),
          trailing: Text(
            '${isEarned ? '+' : ''}${tx['points']}',
            style: TextStyle(
              color: isEarned ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  void _showQRCode() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan at Checkout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'QR: ${_card?.barcode ?? ''}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(_card?.cardNumber ?? ''),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showRedeemDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Redeem Points'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Points available: ${_card?.pointsBalance ?? 0}'),
            const SizedBox(height: 16),
            const Text('500 points = \$5.00 discount'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Redemption coming soon!')),
              );
            },
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
  }

  void _showReferralDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refer a Friend'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Share your code and earn 500 points when they sign up!'),
            SizedBox(height: 16),
            SelectableText(
              'REFER123',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: 'REFER123'));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Code copied!')),
              );
            },
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
        ],
      ),
    );
  }

  void _showOfferDetail(PersonalizedOffer offer) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(offer.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(offer.description),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Code: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(offer.code, style: const TextStyle(fontSize: 18)),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: offer.code));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copied!')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Valid until ${_formatDate(offer.validUntil)}'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Use Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getNextTier(String current) {
    const tiers = ['bronze', 'silver', 'gold', 'platinum', 'diamond'];
    final index = tiers.indexOf(current);
    if (index < tiers.length - 1) {
      return tiers[index + 1].substring(0, 1).toUpperCase() + tiers[index + 1].substring(1);
    }
    return 'Maximum';
  }

  List<String> _getTierBenefits() {
    return [
      'Earn 1 point per \$1 spent',
      'Exclusive member-only deals',
      'Birthday bonus points',
      'Early access to sales',
    ];
  }

  String _getOfferValue(PersonalizedOffer offer) {
    switch (offer.offerType) {
      case 'percentage':
        return '${offer.value.toInt()}%';
      case 'fixed':
        return '\$${offer.value.toInt()}';
      case 'bogo':
        return 'BOGO';
      default:
        return 'DEAL';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
