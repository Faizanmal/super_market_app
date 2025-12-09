import '../models/supplier_models.dart';
import '../core/api_client.dart';

class SupplierService {
  final ApiClient _apiClient;

  SupplierService(this._apiClient);

  // Supplier Management
  Future<List<Supplier>> getSuppliers({String? search, bool? isActive}) async {
    final queryParams = <String, String>{};
    if (search != null) queryParams['search'] = search;
    if (isActive != null) queryParams['is_active'] = isActive.toString();

    final response = await _apiClient.get('/api/suppliers/', queryParameters: queryParams);
    return (response as List).map((json) => Supplier.fromJson(json)).toList();
  }

  Future<Supplier> getSupplier(int id) async {
    final response = await _apiClient.get('/api/suppliers/$id/');
    return Supplier.fromJson(response);
  }

  Future<Supplier> createSupplier(Map<String, dynamic> supplierData) async {
    final response = await _apiClient.post('/api/suppliers/', data: supplierData);
    return Supplier.fromJson(response);
  }

  Future<Supplier> updateSupplier(int id, Map<String, dynamic> supplierData) async {
    final response = await _apiClient.patch('/api/suppliers/$id/', data: supplierData);
    return Supplier.fromJson(response);
  }

  Future<void> deleteSupplier(int id) async {
    await _apiClient.delete('/api/suppliers/$id/');
  }

  // Performance Management
  Future<SupplierPerformance> getPerformance(int supplierId) async {
    final response = await _apiClient.get('/api/suppliers/$supplierId/performance/');
    return SupplierPerformance.fromJson(response);
  }

  Future<List<SupplierPerformance>> getAllPerformances({String? period}) async {
    final queryParams = <String, String>{};
    if (period != null) queryParams['period'] = period;

    final response = await _apiClient.get('/api/suppliers/performances/', queryParameters: queryParams);
    return (response as List).map((json) => SupplierPerformance.fromJson(json)).toList();
  }

  Future<void> updatePerformanceScore(int supplierId, Map<String, dynamic> scoreData) async {
    await _apiClient.post('/api/suppliers/$supplierId/update_performance/', data: scoreData);
  }

  // Automated Reorder Rules
  Future<List<AutomatedReorderRule>> getReorderRules({int? productId, int? supplierId, bool? isActive}) async {
    final queryParams = <String, String>{};
    if (productId != null) queryParams['product_id'] = productId.toString();
    if (supplierId != null) queryParams['supplier_id'] = supplierId.toString();
    if (isActive != null) queryParams['is_active'] = isActive.toString();

    final response = await _apiClient.get('/api/reorder-rules/', queryParameters: queryParams);
    return (response as List).map((json) => AutomatedReorderRule.fromJson(json)).toList();
  }

  Future<AutomatedReorderRule> getReorderRule(int id) async {
    final response = await _apiClient.get('/api/reorder-rules/$id/');
    return AutomatedReorderRule.fromJson(response);
  }

  Future<AutomatedReorderRule> createReorderRule(Map<String, dynamic> ruleData) async {
    final response = await _apiClient.post('/api/reorder-rules/', data: ruleData);
    return AutomatedReorderRule.fromJson(response);
  }

  Future<AutomatedReorderRule> updateReorderRule(int id, Map<String, dynamic> ruleData) async {
    final response = await _apiClient.patch('/api/reorder-rules/$id/', data: ruleData);
    return AutomatedReorderRule.fromJson(response);
  }

  Future<void> deleteReorderRule(int id) async {
    await _apiClient.delete('/api/reorder-rules/$id/');
  }

  Future<void> activateReorderRule(int id) async {
    await _apiClient.post('/api/reorder-rules/$id/activate/');
  }

  Future<void> deactivateReorderRule(int id) async {
    await _apiClient.post('/api/reorder-rules/$id/deactivate/');
  }

  Future<void> testReorderRule(int id) async {
    await _apiClient.post('/api/reorder-rules/$id/test/');
  }

  Future<Map<String, dynamic>> checkReorderRules() async {
    final response = await _apiClient.post('/api/reorder-rules/check_all/');
    return response as Map<String, dynamic>;
  }

  // Contracts
  Future<List<SupplierContract>> getContracts({int? supplierId, String? status}) async {
    final queryParams = <String, String>{};
    if (supplierId != null) queryParams['supplier_id'] = supplierId.toString();
    if (status != null) queryParams['status'] = status;

    final response = await _apiClient.get('/api/supplier-contracts/', queryParameters: queryParams);
    return (response as List).map((json) => SupplierContract.fromJson(json)).toList();
  }

  Future<SupplierContract> getContract(int id) async {
    final response = await _apiClient.get('/api/supplier-contracts/$id/');
    return SupplierContract.fromJson(response);
  }

  Future<SupplierContract> createContract(Map<String, dynamic> contractData) async {
    final response = await _apiClient.post('/api/supplier-contracts/', data: contractData);
    return SupplierContract.fromJson(response);
  }

  Future<SupplierContract> updateContract(int id, Map<String, dynamic> contractData) async {
    final response = await _apiClient.patch('/api/supplier-contracts/$id/', data: contractData);
    return SupplierContract.fromJson(response);
  }

  Future<List<SupplierContract>> getExpiringContracts({int? days}) async {
    final queryParams = <String, String>{};
    if (days != null) queryParams['days'] = days.toString();

    final response = await _apiClient.get('/api/supplier-contracts/expiring/', queryParameters: queryParams);
    return (response as List).map((json) => SupplierContract.fromJson(json)).toList();
  }

  // Communication
  Future<void> sendMessage(int supplierId, Map<String, dynamic> messageData) async {
    await _apiClient.post('/api/suppliers/$supplierId/send_message/', data: messageData);
  }

  Future<List<Map<String, dynamic>>> getCommunicationHistory(int supplierId) async {
    final response = await _apiClient.get('/api/suppliers/$supplierId/communications/');
    return (response as List).cast<Map<String, dynamic>>();
  }
}
