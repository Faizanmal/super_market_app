/// Marketing Dashboard Screen
/// For staff/admin to manage campaigns and view marketing analytics

import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class MarketingDashboardScreen extends StatefulWidget {
  const MarketingDashboardScreen({super.key});

  @override
  State<MarketingDashboardScreen> createState() => _MarketingDashboardScreenState();
}

class _MarketingDashboardScreenState extends State<MarketingDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  
  // Mock campaign data
  final List<Campaign> _campaigns = [
    Campaign(
      id: '1',
      name: 'Holiday Sale 2024',
      type: 'email',
      status: 'running',
      recipients: 15000,
      sent: 12500,
      opened: 4200,
      clicked: 1800,
      converted: 450,
    ),
    Campaign(
      id: '2',
      name: 'Flash Friday Deals',
      type: 'push',
      status: 'scheduled',
      recipients: 8000,
      sent: 0,
      opened: 0,
      clicked: 0,
      converted: 0,
    ),
    Campaign(
      id: '3',
      name: 'Weekend Special SMS',
      type: 'sms',
      status: 'completed',
      recipients: 5000,
      sent: 5000,
      opened: 0,
      clicked: 2100,
      converted: 780,
    ),
  ];

  final List<ABTest> _abTests = [
    ABTest(
      id: '1',
      name: 'Homepage Banner A/B',
      status: 'running',
      variantAName: 'Red Banner',
      variantBName: 'Blue Banner',
      variantAConversions: 234,
      variantBConversions: 287,
      variantAViews: 5000,
      variantBViews: 5000,
    ),
    ABTest(
      id: '2',
      name: 'Checkout Button Text',
      status: 'completed',
      variantAName: 'Buy Now',
      variantBName: 'Add to Cart',
      variantAConversions: 890,
      variantBConversions: 756,
      variantAViews: 10000,
      variantBViews: 10000,
      winner: 'A',
    ),
  ];

  final List<CustomerSegment> _segments = [
    CustomerSegment(id: '1', name: 'VIP Customers', memberCount: 1250, avgSpend: 450.00),
    CustomerSegment(id: '2', name: 'Frequent Shoppers', memberCount: 5430, avgSpend: 180.00),
    CustomerSegment(id: '3', name: 'New Customers', memberCount: 890, avgSpend: 45.00),
    CustomerSegment(id: '4', name: 'At-Risk Churners', memberCount: 340, avgSpend: 120.00),
    CustomerSegment(id: '5', name: 'Organic Enthusiasts', memberCount: 2100, avgSpend: 220.00),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketing Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.campaign), text: 'Campaigns'),
            Tab(icon: Icon(Icons.science), text: 'A/B Tests'),
            Tab(icon: Icon(Icons.people), text: 'Segments'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCampaignsTab(theme),
          _buildABTestsTab(theme),
          _buildSegmentsTab(theme),
          _buildAnalyticsTab(theme),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateCampaignDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Campaign'),
      ),
    );
  }

  Widget _buildCampaignsTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary cards
        Row(
          children: [
            Expanded(child: _buildSummaryCard('Active', '3', Colors.green, Icons.play_circle)),
            const SizedBox(width: 12),
            Expanded(child: _buildSummaryCard('Scheduled', '2', Colors.orange, Icons.schedule)),
            const SizedBox(width: 12),
            Expanded(child: _buildSummaryCard('Completed', '15', Colors.blue, Icons.check_circle)),
          ],
        ),
        const SizedBox(height: 24),
        
        // Campaign list
        Text('All Campaigns', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        ..._campaigns.map((campaign) => _buildCampaignCard(campaign, theme)),
      ],
    );
  }

  Widget _buildABTestsTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Active A/B Tests', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        ..._abTests.map((test) => _buildABTestCard(test, theme)),
      ],
    );
  }

  Widget _buildSegmentsTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // RFM overview
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Customer Segments', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: Row(
                    children: _segments.map((segment) => Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              width: 40,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: _getSegmentColor(segment.name).withOpacity(0.7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: segment.memberCount / 6000,
                                child: Container(color: _getSegmentColor(segment.name)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(segment.memberCount / 1000).toStringAsFixed(1)}k',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Segment list
        ..._segments.map((segment) => _buildSegmentCard(segment, theme)),
      ],
    );
  }

  Widget _buildAnalyticsTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Key metrics
        Row(
          children: [
            Expanded(child: _buildMetricCard('Email Open Rate', '33.6%', '+2.1%', true)),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard('Click Rate', '14.4%', '+0.8%', true)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildMetricCard('Conversion Rate', '3.6%', '-0.2%', false)),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard('Revenue/Email', '\$0.42', '+\$0.05', true)),
          ],
        ),
        const SizedBox(height: 24),
        
        // Campaign performance chart placeholder
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Campaign Performance', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: CustomPaint(
                    painter: SimpleChartPainter(theme: theme),
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Top performing campaigns
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Top Performing Campaigns', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ..._campaigns.take(3).map((c) => ListTile(
                  leading: Icon(_getCampaignIcon(c.type)),
                  title: Text(c.name),
                  subtitle: Text('${c.conversionRate.toStringAsFixed(1)}% conversion'),
                  trailing: Text('\$${(c.converted * 25).toStringAsFixed(0)}'),
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignCard(Campaign campaign, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(_getCampaignIcon(campaign.type)),
        title: Text(campaign.name),
        subtitle: Text('${campaign.sent} sent • ${campaign.openRate.toStringAsFixed(1)}% open rate'),
        trailing: _buildStatusChip(campaign.status),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Funnel metrics
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildFunnelStep('Sent', campaign.sent, null),
                    const Icon(Icons.arrow_forward, color: Colors.grey),
                    _buildFunnelStep('Opened', campaign.opened, campaign.openRate),
                    const Icon(Icons.arrow_forward, color: Colors.grey),
                    _buildFunnelStep('Clicked', campaign.clicked, campaign.clickRate),
                    const Icon(Icons.arrow_forward, color: Colors.grey),
                    _buildFunnelStep('Converted', campaign.converted, campaign.conversionRate),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.analytics),
                        label: const Text('View Report'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.copy),
                        label: const Text('Duplicate'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildABTestCard(ABTest test, ThemeData theme) {
    final aRate = test.variantAViews > 0 ? (test.variantAConversions / test.variantAViews * 100) : 0.0;
    final bRate = test.variantBViews > 0 ? (test.variantBConversions / test.variantBViews * 100) : 0.0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(test.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                _buildStatusChip(test.status),
              ],
            ),
            const SizedBox(height: 16),
            
            // Variant comparison
            Row(
              children: [
                Expanded(
                  child: _buildVariantCard(
                    test.variantAName,
                    aRate,
                    test.variantAConversions,
                    test.winner == 'A',
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('vs', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildVariantCard(
                    test.variantBName,
                    bRate,
                    test.variantBConversions,
                    test.winner == 'B',
                    Colors.purple,
                  ),
                ),
              ],
            ),
            
            if (test.winner != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text(
                      'Winner: ${test.winner == 'A' ? test.variantAName : test.variantBName}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVariantCard(String name, double rate, int conversions, bool isWinner, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: isWinner ? Border.all(color: Colors.green, width: 2) : null,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isWinner) const Icon(Icons.check_circle, color: Colors.green, size: 16),
              Text(name, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text('${rate.toStringAsFixed(2)}%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text('$conversions conversions', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSegmentCard(CustomerSegment segment, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getSegmentColor(segment.name).withOpacity(0.2),
          child: Icon(Icons.people, color: _getSegmentColor(segment.name)),
        ),
        title: Text(segment.name),
        subtitle: Text('Avg. spend: \$${segment.avgSpend.toStringAsFixed(0)}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${segment.memberCount}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const Text('members', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Create campaign for ${segment.name}')),
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, String change, bool isPositive) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPositive ? Colors.green.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    change,
                    style: TextStyle(
                      color: isPositive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFunnelStep(String label, int value, double? rate) {
    return Column(
      children: [
        Text('$value', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        if (rate != null)
          Text('${rate.toStringAsFixed(1)}%', style: TextStyle(fontSize: 10, color: Colors.blue.shade400)),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    final colors = {
      'running': Colors.green,
      'scheduled': Colors.orange,
      'completed': Colors.blue,
      'paused': Colors.grey,
      'draft': Colors.grey,
    };
    
    return Chip(
      label: Text(status.toUpperCase(), style: TextStyle(color: colors[status], fontSize: 10)),
      backgroundColor: colors[status]?.withOpacity(0.1),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }

  IconData _getCampaignIcon(String type) {
    switch (type) {
      case 'email': return Icons.email;
      case 'sms': return Icons.sms;
      case 'push': return Icons.notifications;
      default: return Icons.campaign;
    }
  }

  Color _getSegmentColor(String name) {
    if (name.contains('VIP')) return Colors.amber;
    if (name.contains('Frequent')) return Colors.green;
    if (name.contains('New')) return Colors.blue;
    if (name.contains('Risk')) return Colors.red;
    return Colors.purple;
  }

  void _showCreateCampaignDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create Campaign', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Campaign Name')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(value: 'email', child: Text('Email')),
                DropdownMenuItem(value: 'sms', child: Text('SMS')),
                DropdownMenuItem(value: 'push', child: Text('Push Notification')),
              ],
              onChanged: (_) {},
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Target Segment'),
              items: _segments.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
              onChanged: (_) {},
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Campaign created!')),
                  );
                },
                child: const Text('Create Campaign'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// Data models
class Campaign {
  final String id;
  final String name;
  final String type;
  final String status;
  final int recipients;
  final int sent;
  final int opened;
  final int clicked;
  final int converted;

  Campaign({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.recipients,
    required this.sent,
    required this.opened,
    required this.clicked,
    required this.converted,
  });

  double get openRate => sent > 0 ? (opened / sent * 100) : 0;
  double get clickRate => opened > 0 ? (clicked / opened * 100) : 0;
  double get conversionRate => clicked > 0 ? (converted / clicked * 100) : 0;
}

class ABTest {
  final String id;
  final String name;
  final String status;
  final String variantAName;
  final String variantBName;
  final int variantAConversions;
  final int variantBConversions;
  final int variantAViews;
  final int variantBViews;
  final String? winner;

  ABTest({
    required this.id,
    required this.name,
    required this.status,
    required this.variantAName,
    required this.variantBName,
    required this.variantAConversions,
    required this.variantBConversions,
    required this.variantAViews,
    required this.variantBViews,
    this.winner,
  });
}

class CustomerSegment {
  final String id;
  final String name;
  final int memberCount;
  final double avgSpend;

  CustomerSegment({
    required this.id,
    required this.name,
    required this.memberCount,
    required this.avgSpend,
  });
}

class SimpleChartPainter extends CustomPainter {
  final ThemeData theme;

  SimpleChartPainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = theme.colorScheme.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    final points = [0.2, 0.4, 0.3, 0.6, 0.5, 0.7, 0.65];
    
    for (var i = 0; i < points.length; i++) {
      final x = i * (size.width / (points.length - 1));
      final y = size.height - (points[i] * size.height);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Fill under the line
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    paint
      ..style = PaintingStyle.fill
      ..color = theme.colorScheme.primary.withOpacity(0.1);
    canvas.drawPath(fillPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
