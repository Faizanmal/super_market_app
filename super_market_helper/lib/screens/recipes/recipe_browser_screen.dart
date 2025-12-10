/// Recipe Browser Screen
/// Browse and discover recipes with ingredient linking

import 'package:flutter/material.dart';
import '../../services/customer_app_service.dart';
import '../../services/api_service.dart';

class RecipeBrowserScreen extends StatefulWidget {
  const RecipeBrowserScreen({super.key});

  @override
  State<RecipeBrowserScreen> createState() => _RecipeBrowserScreenState();
}

class _RecipeBrowserScreenState extends State<RecipeBrowserScreen> {
  late final CustomerAppService _customerService;
  
  List<Recipe> _recipes = [];
  List<Recipe> _savedRecipes = [];
  String? _selectedMealType;
  String? _selectedDifficulty;
  bool _isLoading = true;
  bool _showSavedOnly = false;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _mealTypes = ['breakfast', 'lunch', 'dinner', 'snack', 'dessert'];
  final List<String> _difficulties = ['easy', 'medium', 'hard'];

  @override
  void initState() {
    super.initState();
    _customerService = CustomerAppService(ApiService());
    _loadRecipes();
    _loadSavedRecipes();
  }

  Future<void> _loadRecipes() async {
    setState(() => _isLoading = true);
    
    final recipes = await _customerService.getRecipes(
      mealType: _selectedMealType,
      difficulty: _selectedDifficulty,
      search: _searchController.text.isEmpty ? null : _searchController.text,
    );
    
    setState(() {
      _recipes = recipes;
      _isLoading = false;
    });
  }

  Future<void> _loadSavedRecipes() async {
    final saved = await _customerService.getSavedRecipes();
    setState(() => _savedRecipes = saved);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayRecipes = _showSavedOnly ? _savedRecipes : _recipes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipes'),
        actions: [
          IconButton(
            icon: Icon(_showSavedOnly ? Icons.bookmark : Icons.bookmark_border),
            onPressed: () {
              setState(() => _showSavedOnly = !_showSavedOnly);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search recipes...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _loadRecipes(),
                ),
              ),
              const SizedBox(height: 12),
              
              // Filter chips
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Meal type dropdown
                    PopupMenuButton<String>(
                      child: Chip(
                        label: Text(_selectedMealType?.toUpperCase() ?? 'Meal Type'),
                        avatar: const Icon(Icons.restaurant_menu, size: 16),
                      ),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: null, child: Text('All')),
                        ..._mealTypes.map((type) => PopupMenuItem(
                          value: type,
                          child: Text(type.substring(0, 1).toUpperCase() + type.substring(1)),
                        )),
                      ],
                      onSelected: (value) {
                        setState(() => _selectedMealType = value);
                        _loadRecipes();
                      },
                    ),
                    const SizedBox(width: 8),
                    
                    // Difficulty dropdown
                    PopupMenuButton<String>(
                      child: Chip(
                        label: Text(_selectedDifficulty?.toUpperCase() ?? 'Difficulty'),
                        avatar: const Icon(Icons.trending_up, size: 16),
                      ),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: null, child: Text('All')),
                        ..._difficulties.map((diff) => PopupMenuItem(
                          value: diff,
                          child: Text(diff.substring(0, 1).toUpperCase() + diff.substring(1)),
                        )),
                      ],
                      onSelected: (value) {
                        setState(() => _selectedDifficulty = value);
                        _loadRecipes();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : displayRecipes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _showSavedOnly ? Icons.bookmark_border : Icons.restaurant_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _showSavedOnly ? 'No saved recipes' : 'No recipes found',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: displayRecipes.length,
                  itemBuilder: (context, index) {
                    final recipe = displayRecipes[index];
                    return _buildRecipeCard(recipe);
                  },
                ),
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    final theme = Theme.of(context);
    final isSaved = _savedRecipes.any((r) => r.id == recipe.id);
    
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showRecipeDetail(recipe),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primaryContainer,
                    theme.colorScheme.secondaryContainer,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.restaurant,
                      size: 40,
                      color: theme.colorScheme.onPrimaryContainer.withOpacity(0.5),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: Colors.white,
                      ),
                      onPressed: () async {
                        await _customerService.saveRecipe(recipe.id);
                        _loadSavedRecipes();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Recipe saved!')),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.timer, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.totalTime} min',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const Spacer(),
                        _buildDifficultyBadge(recipe.difficulty),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyBadge(String difficulty) {
    final colors = {
      'easy': Colors.green,
      'medium': Colors.orange,
      'hard': Colors.red,
    };
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors[difficulty]?.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        difficulty.substring(0, 1).toUpperCase() + difficulty.substring(1),
        style: TextStyle(
          fontSize: 10,
          color: colors[difficulty],
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showRecipeDetail(Recipe recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          final theme = Theme.of(context);
          
          return Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Title
                Text(
                  recipe.title,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                
                // Meta info
                Row(
                  children: [
                    _buildMetaChip(Icons.timer, '${recipe.totalTime} min'),
                    const SizedBox(width: 8),
                    _buildMetaChip(Icons.people, '${recipe.servings} servings'),
                    const SizedBox(width: 8),
                    _buildDifficultyBadge(recipe.difficulty),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Description
                Text(recipe.description),
                const SizedBox(height: 24),
                
                // Tags
                if (recipe.tags.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    children: recipe.tags.map((tag) => Chip(
                      label: Text(tag),
                      visualDensity: VisualDensity.compact,
                    )).toList(),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Video link
                if (recipe.videoUrl != null && recipe.videoUrl!.isNotEmpty) ...[
                  Card(
                    color: theme.colorScheme.primaryContainer,
                    child: ListTile(
                      leading: const Icon(Icons.play_circle_filled),
                      title: const Text('Watch Video Tutorial'),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () {
                        // Open video
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Opening video...')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Add to cart button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ingredients added to shopping list!')),
                      );
                    },
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Add Ingredients to Cart'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
