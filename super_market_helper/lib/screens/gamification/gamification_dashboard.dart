import 'package:flutter/material.dart';
import '../../models/gamification_model.dart' as gm;
import '../../services/gamification_service.dart';
import 'package:intl/intl.dart';

class GamificationDashboard extends StatefulWidget {
  const GamificationDashboard({Key? key}) : super(key: key);

  @override
  State<GamificationDashboard> createState() => _GamificationDashboardState();
}

class _GamificationDashboardState extends State<GamificationDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GamificationService _service = GamificationService();
  
  gm.GamificationProfile? _profile;
  List<gm.GamificationProfile> _leaderboard = [];
  List<gm.Badge> _allBadges = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final profile = await _service.getMyProfile();
      final leaderboard = await _service.getLeaderboard();
      final badges = await _service.getBadges();
      
      if (mounted) {
        setState(() {
          _profile = profile;
          _leaderboard = leaderboard;
          _allBadges = badges;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Premium Colors
    final primaryColor = Theme.of(context).primaryColor;
    final accentColor = Colors.amber;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Performance'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Progress', icon: Icon(Icons.person)),
            Tab(text: 'Leaderboard', icon: Icon(Icons.leaderboard)),
            Tab(text: 'Badges', icon: Icon(Icons.verified)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? const Center(child: Text('Failed to load profile'))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildProgressTab(primaryColor, accentColor),
                    _buildLeaderboardTab(),
                    _buildBadgesTab(),
                  ],
                ),
    );
  }

  Widget _buildProgressTab(Color primary, Color accent) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Level Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [primary, primary.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Text(
                      '${_profile!.currentLevel}',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Level ${_profile!.currentLevel} Staff',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_profile!.totalPoints} Total Points',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 24),
                  // XP Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('XP Progress', style: TextStyle(color: Colors.white)),
                          Text('${_profile!.currentXp} / ${_profile!.xpToNextLevel} XP', style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _profile!.progressToNextLevel,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation(accent),
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _profile!.recentTransactions.length,
            itemBuilder: (context, index) {
              final tx = _profile!.recentTransactions[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: tx.isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    child: Icon(
                      tx.isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      color: tx.isPositive ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Text(tx.description),
                  subtitle: Text(DateFormat('MMM d, h:mm a').format(tx.createdAt ?? DateTime.now())),
                  trailing: Text(
                    '${tx.isPositive ? '+' : ''}${tx.points} pts',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: tx.isPositive ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _leaderboard.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final profile = _leaderboard[index];
        final isMe = profile.userName == _profile?.userName; // Simplified check
        
        return Card(
          color: isMe ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: index < 3 ? Colors.amber : Colors.grey[300],
              foregroundColor: index < 3 ? Colors.white : Colors.black,
              child: Text('${index + 1}'),
            ),
            title: Text(
              profile.userName ?? 'Unknown',
              style: TextStyle(fontWeight: isMe ? FontWeight.bold : FontWeight.normal),
            ),
            subtitle: Text('Level ${profile.currentLevel}'),
            trailing: Chip(
              label: Text('${profile.totalPoints} pts'),
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadgesTab() {
    // Merge earned badges with all badges details
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _allBadges.length,
      itemBuilder: (context, index) {
        final badge = _allBadges[index];
        final earnedBadge = _profile!.earnedBadges.firstWhere(
          (ub) => ub.badgeDetails?.name == badge.name,
          orElse: () => gm.UserBadge(),
        );
        final isEarned = earnedBadge.earnedAt != null;
        
        return Opacity(
          opacity: isEarned ? 1.0 : 0.5,
          child: Card(
            elevation: isEarned ? 4 : 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.verified_outlined, // Placeholder, would map icon string to IconData
                    size: 40,
                    color: isEarned ? Colors.amber : Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    badge.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 4),
                  if (isEarned)
                    Text(
                      DateFormat('MMM d').format(earnedBadge.earnedAt!),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
