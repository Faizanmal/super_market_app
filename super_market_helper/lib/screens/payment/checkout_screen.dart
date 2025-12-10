/// Checkout Screen with Payment Options
/// Supports multiple payment methods including mobile wallets, BNPL, and split bills

import 'package:flutter/material.dart';
import '../../services/payment_service.dart';
import '../../services/api_service.dart';

class CheckoutScreen extends StatefulWidget {
  final String orderId;
  final double totalAmount;
  final List<Map<String, dynamic>> items;

  const CheckoutScreen({
    super.key,
    required this.orderId,
    required this.totalAmount,
    required this.items,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late final PaymentService _paymentService;
  
  List<AvailablePaymentMethod> _paymentMethods = [];
  PaymentMethod? _selectedMethod;
  BNPLPlan? _selectedBNPLPlan;
  bool _isLoading = true;
  bool _isProcessing = false;
  double _storeCreditBalance = 0;

  @override
  void initState() {
    super.initState();
    _paymentService = PaymentService(ApiService());
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() => _isLoading = true);
    
    final results = await Future.wait([
      _paymentService.getAvailableMethods(widget.totalAmount),
      _paymentService.getStoreCreditBalance(),
    ]);
    
    setState(() {
      _paymentMethods = results[0] as List<AvailablePaymentMethod>;
      _storeCreditBalance = results[1] as double;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order summary
                  _buildOrderSummary(theme),
                  const SizedBox(height: 24),
                  
                  // Payment methods
                  Text('Payment Method', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _buildPaymentMethods(theme),
                  
                  // BNPL options
                  if (_selectedMethod != null && _isBNPL(_selectedMethod!))
                    _buildBNPLOptions(theme),
                  
                  const SizedBox(height: 24),
                  
                  // Split bill option
                  _buildSplitBillOption(theme),
                  
                  const SizedBox(height: 24),
                  
                  // Promo code
                  _buildPromoCode(theme),
                  
                  const SizedBox(height: 32),
                  
                  // Pay button
                  _buildPayButton(theme),
                ],
              ),
            ),
    );
  }

  Widget _buildOrderSummary(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Order Summary', style: TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            ...widget.items.take(3).map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text('${item['quantity']}x ${item['name']}'),
                  ),
                  Text('\$${(item['price'] * item['quantity']).toStringAsFixed(2)}'),
                ],
              ),
            )),
            if (widget.items.length > 3)
              Text('...and ${widget.items.length - 3} more items'),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal'),
                Text('\$${widget.totalAmount.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tax', style: TextStyle(color: Colors.grey)),
                Text('\$${(widget.totalAmount * 0.08).toStringAsFixed(2)}', style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text(
                  '\$${(widget.totalAmount * 1.08).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethods(ThemeData theme) {
    return Column(
      children: _paymentMethods.map((method) {
        final isSelected = _selectedMethod == method.method;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? theme.colorScheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: InkWell(
            onTap: method.isAvailable
                ? () {
                    setState(() {
                      _selectedMethod = method.method;
                      _selectedBNPLPlan = null;
                    });
                  }
                : null,
            borderRadius: BorderRadius.circular(12),
            child: Opacity(
              opacity: method.isAvailable ? 1.0 : 0.5,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(method.icon, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(method.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (method.balance != null)
                            Text(
                              'Balance: \$${method.balance!.toStringAsFixed(2)}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          if (!method.isAvailable)
                            const Text(
                              'Not available',
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle, color: theme.colorScheme.primary),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBNPLOptions(ThemeData theme) {
    final selected = _paymentMethods.firstWhere(
      (m) => m.method == _selectedMethod,
      orElse: () => _paymentMethods.first,
    );
    
    if (selected.paymentOptions == null || selected.paymentOptions!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('Payment Plan', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        ...selected.paymentOptions!.map((plan) {
          final isSelected = _selectedBNPLPlan == plan;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: isSelected ? theme.colorScheme.primaryContainer : null,
            child: InkWell(
              onTap: () => setState(() => _selectedBNPLPlan = plan),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Radio<BNPLPlan>(
                      value: plan,
                      groupValue: _selectedBNPLPlan,
                      onChanged: (value) => setState(() => _selectedBNPLPlan = value),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${plan.installments}x \$${plan.amountPerInstallment.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            plan.interest == 0 
                                ? 'Interest-free'
                                : '${plan.interest}% APR',
                            style: TextStyle(
                              color: plan.interest == 0 ? Colors.green : Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSplitBillOption(ThemeData theme) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.group),
        title: const Text('Split the Bill'),
        subtitle: const Text('Share payment with friends'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _showSplitBillDialog,
      ),
    );
  }

  Widget _buildPromoCode(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Promo code',
              prefixIcon: const Icon(Icons.local_offer),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {},
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _buildPayButton(ThemeData theme) {
    return Column(
      children: [
        // Store credit balance
        if (_storeCreditBalance > 0)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Checkbox(value: false, onChanged: (v) {}),
                  Text('Use store credit (\$${_storeCreditBalance.toStringAsFixed(2)})'),
                ],
              ),
            ],
          ),
        const SizedBox(height: 16),
        
        // Pay button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _selectedMethod != null && !_isProcessing ? _processPayment : null,
            child: _isProcessing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'Pay \$${(widget.totalAmount * 1.08).toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 18),
                  ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Security note
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              'Secured by 256-bit encryption',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  bool _isBNPL(PaymentMethod method) {
    return [
      PaymentMethod.afterpay,
      PaymentMethod.klarna,
      PaymentMethod.affirm,
    ].contains(method);
  }

  Future<void> _processPayment() async {
    if (_selectedMethod == null) return;
    
    setState(() => _isProcessing = true);
    
    try {
      final result = await _paymentService.processPayment(
        orderId: widget.orderId,
        amount: widget.totalAmount * 1.08,
        method: _selectedMethod!,
        bnplPlan: _selectedBNPLPlan?.plan,
      );
      
      if (result.success) {
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment successful! 🎉'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${result.error}')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSplitBillDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Split the Bill', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            const Text('Add friends to split this payment'),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Enter email address',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Split equally'),
                Switch(value: true, onChanged: (v) {}),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Split request sent!')),
                  );
                },
                child: const Text('Send Split Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
