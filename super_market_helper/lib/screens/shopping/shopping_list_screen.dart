import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/shopping_list_model.dart';
import '../../services/local_storage_service.dart';
import '../../services/api_service.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final LocalStorageService _storage = LocalStorageService();
  final ApiService _apiService = ApiService();
  final _uuid = const Uuid();

  List<ShoppingList> _lists = <ShoppingList>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShoppingLists();
  }

  Future<void> _loadShoppingLists() async {
    setState(() => _isLoading = true);
    
    try {
      // Try loading from API first, fallback to local storage
      try {
        _lists = await _apiService.getShoppingLists();
      } catch (e) {
        // Fallback to local storage
        _lists = await _storage.getShoppingLists();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading lists: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createNewList() async {
    final nameController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Shopping List'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'List Name',
            hintText: 'Enter list name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      final newList = ShoppingList(
        id: _uuid.v4(),
        name: nameController.text,
        status: 'active',
        items: [],
        createdAt: DateTime.now(),
      );

      try {
        await _storage.saveShoppingList(newList);
        await _loadShoppingLists();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Shopping list created')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteList(ShoppingList list) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Shopping List'),
        content: Text('Delete "${list.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _storage.deleteShoppingList(list.id);
        await _loadShoppingLists();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Shopping list deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Lists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadShoppingLists,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _lists.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadShoppingLists,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _lists.length,
                    itemBuilder: (context, index) {
                      final list = _lists[index];
                      return _buildListCard(list);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewList,
        icon: const Icon(Icons.add),
        label: const Text('New List'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Shopping Lists',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first shopping list',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard(ShoppingList list) {
    final completionPercent = list.completionPercentage;
    final isCompleted = list.status == 'completed';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _openListDetails(list),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      list.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  if (isCompleted)
                    const Icon(Icons.check_circle, color: Colors.green)
                  else
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'delete') {
                          _deleteList(list);
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.list, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${list.completedItems}/${list.totalItems} items',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                  Icon(Icons.attach_money, size: 16,
                      color: Colors.grey.shade600),
                  Text(
                    '\$${list.estimatedTotal.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: completionPercent / 100,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted ? Colors.green : Colors.blue,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${completionPercent.toStringAsFixed(0)}% complete',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openListDetails(ShoppingList list) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShoppingListDetailScreen(list: list),
      ),
    ).then((_) => _loadShoppingLists());
  }
}

class ShoppingListDetailScreen extends StatefulWidget {
  final ShoppingList list;

  const ShoppingListDetailScreen({super.key, required this.list});

  @override
  State<ShoppingListDetailScreen> createState() =>
      _ShoppingListDetailScreenState();
}

class _ShoppingListDetailScreenState extends State<ShoppingListDetailScreen> {
  final LocalStorageService _storage = LocalStorageService();
  final _uuid = const Uuid();
  late ShoppingList _list;

  @override
  void initState() {
    super.initState();
    _list = widget.list;
  }

  Future<void> _addItem() async {
    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final priceController = TextEditingController(text: '0.00');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Item Name'),
              autofocus: true,
            ),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: priceController,
              decoration:
                  const InputDecoration(labelText: 'Estimated Price'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      final newItem = ShoppingListItem(
        id: _uuid.v4(),
        itemName: nameController.text,
        quantity: int.tryParse(quantityController.text) ?? 1,
        estimatedPrice: double.tryParse(priceController.text) ?? 0.0,
        createdAt: DateTime.now(),
      );

      setState(() {
        _list.items.add(newItem);
      });

      await _storage.updateShoppingList(_list);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item added')),
        );
      }
    }
  }

  Future<void> _toggleItem(ShoppingListItem item) async {
    setState(() {
      item.isPurchased = !item.isPurchased;
    });
    await _storage.updateShoppingList(_list);
  }

  Future<void> _deleteItem(ShoppingListItem item) async {
    setState(() {
      _list.items.remove(item);
    });
    await _storage.updateShoppingList(_list);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item removed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingItems =
        _list.items.where((item) => !item.isPurchased).toList();
    final purchasedItems =
        _list.items.where((item) => item.isPurchased).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_list.name),
      ),
      body: _list.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_basket_outlined,
                      size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No items yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (pendingItems.isNotEmpty) ...[
                  const Text(
                    'To Buy',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...pendingItems.map((item) => _buildItemTile(item)),
                ],
                if (purchasedItems.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Purchased',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...purchasedItems.map((item) => _buildItemTile(item)),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildItemTile(ShoppingListItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Checkbox(
          value: item.isPurchased,
          onChanged: (_) => _toggleItem(item),
        ),
        title: Text(
          item.itemName,
          style: TextStyle(
            decoration:
                item.isPurchased ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          '${item.quantity} x \$${item.estimatedPrice.toStringAsFixed(2)} = \$${item.estimatedCost.toStringAsFixed(2)}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deleteItem(item),
        ),
      ),
    );
  }
}
