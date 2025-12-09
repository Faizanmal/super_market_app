/// Sustainability and Environmental Impact Models for Flutter
class SustainabilityMetrics {
  final int id;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String periodType;
  
  // Waste metrics
  final double totalWaste;
  final double foodWaste;
  final double packagingWaste;
  final double recycledWaste;
  final double compostedWaste;
  final double wasteDiversionRate;
  
  // Carbon footprint
  final double totalCarbonFootprint;
  final double productCarbon;
  final double transportationCarbon;
  final double energyCarbon;
  
  // Energy
  final double totalEnergy;
  final double renewableEnergy;
  final double renewableEnergyPercentage;
  
  // Local sourcing
  final double localProductsPercentage;
  final int localSupplierCount;
  
  // Savings
  final double wasteReductionSavings;
  final double energySavings;
  
  // Overall score
  final double sustainabilityScore;

  SustainabilityMetrics({
    required this.id,
    required this.periodStart,
    required this.periodEnd,
    required this.periodType,
    required this.totalWaste,
    required this.foodWaste,
    required this.packagingWaste,
    required this.recycledWaste,
    required this.compostedWaste,
    required this.wasteDiversionRate,
    required this.totalCarbonFootprint,
    required this.productCarbon,
    required this.transportationCarbon,
    required this.energyCarbon,
    required this.totalEnergy,
    required this.renewableEnergy,
    required this.renewableEnergyPercentage,
    required this.localProductsPercentage,
    required this.localSupplierCount,
    required this.wasteReductionSavings,
    required this.energySavings,
    required this.sustainabilityScore,
  });

  factory SustainabilityMetrics.fromJson(Map<String, dynamic> json) {
    return SustainabilityMetrics(
      id: json['id'],
      periodStart: DateTime.parse(json['period_start']),
      periodEnd: DateTime.parse(json['period_end']),
      periodType: json['period_type'],
      totalWaste: double.parse(json['total_waste'].toString()),
      foodWaste: double.parse(json['food_waste'].toString()),
      packagingWaste: double.parse(json['packaging_waste'].toString()),
      recycledWaste: double.parse(json['recycled_waste'].toString()),
      compostedWaste: double.parse(json['composted_waste'].toString()),
      wasteDiversionRate: double.parse(json['waste_diversion_rate'].toString()),
      totalCarbonFootprint: double.parse(json['total_carbon_footprint'].toString()),
      productCarbon: double.parse(json['product_carbon_footprint'].toString()),
      transportationCarbon: double.parse(json['transportation_carbon'].toString()),
      energyCarbon: double.parse(json['energy_carbon'].toString()),
      totalEnergy: double.parse(json['total_energy_consumption'].toString()),
      renewableEnergy: double.parse(json['renewable_energy_usage'].toString()),
      renewableEnergyPercentage: double.parse(json['renewable_energy_percentage'].toString()),
      localProductsPercentage: double.parse(json['local_products_percentage'].toString()),
      localSupplierCount: json['local_supplier_count'],
      wasteReductionSavings: double.parse(json['waste_reduction_savings'].toString()),
      energySavings: double.parse(json['energy_savings'].toString()),
      sustainabilityScore: double.parse(json['sustainability_score'].toString()),
    );
  }

  double get totalSavings => wasteReductionSavings + energySavings;
  double get landfillWaste => totalWaste - recycledWaste - compostedWaste;
}

class WasteRecord {
  final int id;
  final String wasteType;
  final double quantity;
  final int? unitCount;
  final double monetaryValue;
  final String disposalMethod;
  final double disposalCost;
  final String reason;
  final bool preventable;
  final double carbonImpact;
  final DateTime recordedAt;

  WasteRecord({
    required this.id,
    required this.wasteType,
    required this.quantity,
    this.unitCount,
    required this.monetaryValue,
    required this.disposalMethod,
    required this.disposalCost,
    required this.reason,
    required this.preventable,
    required this.carbonImpact,
    required this.recordedAt,
  });

  factory WasteRecord.fromJson(Map<String, dynamic> json) {
    return WasteRecord(
      id: json['id'],
      wasteType: json['waste_type'],
      quantity: double.parse(json['quantity'].toString()),
      unitCount: json['unit_count'],
      monetaryValue: double.parse(json['monetary_value'].toString()),
      disposalMethod: json['disposal_method'],
      disposalCost: double.parse(json['disposal_cost'].toString()),
      reason: json['reason'],
      preventable: json['preventable'] ?? true,
      carbonImpact: double.parse(json['carbon_impact'].toString()),
      recordedAt: DateTime.parse(json['recorded_at']),
    );
  }

  String get wasteTypeDisplay {
    final types = {
      'food': 'Food Waste',
      'packaging': 'Packaging',
      'plastic': 'Plastic',
      'paper': 'Paper/Cardboard',
      'glass': 'Glass',
      'organic': 'Organic',
    };
    return types[wasteType] ?? wasteType;
  }

  String get disposalMethodDisplay {
    final methods = {
      'landfill': 'Landfill',
      'recycle': 'Recycling',
      'compost': 'Composting',
      'donation': 'Donation',
      'animal_feed': 'Animal Feed',
    };
    return methods[disposalMethod] ?? disposalMethod;
  }
}

class SustainabilityInitiative {
  final int id;
  final String name;
  final String description;
  final String category;
  final DateTime startDate;
  final DateTime? targetCompletionDate;
  final String status;
  final double progressPercentage;
  final double? targetWasteReduction;
  final double? actualWasteReduction;
  final double? targetCarbonReduction;
  final double? actualCarbonReduction;
  final double budget;
  final double actualCost;
  final double? roiPercentage;

  SustainabilityInitiative({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.startDate,
    this.targetCompletionDate,
    required this.status,
    required this.progressPercentage,
    this.targetWasteReduction,
    this.actualWasteReduction,
    this.targetCarbonReduction,
    this.actualCarbonReduction,
    required this.budget,
    required this.actualCost,
    this.roiPercentage,
  });

  factory SustainabilityInitiative.fromJson(Map<String, dynamic> json) {
    return SustainabilityInitiative(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      startDate: DateTime.parse(json['start_date']),
      targetCompletionDate: json['target_completion_date'] != null 
          ? DateTime.parse(json['target_completion_date']) 
          : null,
      status: json['status'],
      progressPercentage: double.parse(json['progress_percentage'].toString()),
      targetWasteReduction: json['target_waste_reduction_kg'] != null
          ? double.parse(json['target_waste_reduction_kg'].toString())
          : null,
      actualWasteReduction: json['actual_waste_reduction_kg'] != null
          ? double.parse(json['actual_waste_reduction_kg'].toString())
          : null,
      targetCarbonReduction: json['target_carbon_reduction_kg'] != null
          ? double.parse(json['target_carbon_reduction_kg'].toString())
          : null,
      actualCarbonReduction: json['actual_carbon_reduction_kg'] != null
          ? double.parse(json['actual_carbon_reduction_kg'].toString())
          : null,
      budget: double.parse(json['budget'].toString()),
      actualCost: double.parse(json['actual_cost'].toString()),
      roiPercentage: json['roi_percentage'] != null
          ? double.parse(json['roi_percentage'].toString())
          : null,
    );
  }

  String get categoryDisplay {
    final categories = {
      'waste_reduction': 'Waste Reduction',
      'energy_efficiency': 'Energy Efficiency',
      'water_conservation': 'Water Conservation',
      'sustainable_sourcing': 'Sustainable Sourcing',
      'packaging': 'Packaging Reduction',
    };
    return categories[category] ?? category;
  }
}

class GreenSupplierRating {
  final int supplierId;
  final String supplierName;
  final double carbonFootprintScore;
  final double renewableEnergyScore;
  final double wasteManagementScore;
  final double sustainablePackagingScore;
  final double overallRating;
  final String ratingCategory;
  final bool iso14001Certified;
  final bool carbonNeutralCertified;
  final bool organicCertified;

  GreenSupplierRating({
    required this.supplierId,
    required this.supplierName,
    required this.carbonFootprintScore,
    required this.renewableEnergyScore,
    required this.wasteManagementScore,
    required this.sustainablePackagingScore,
    required this.overallRating,
    required this.ratingCategory,
    required this.iso14001Certified,
    required this.carbonNeutralCertified,
    required this.organicCertified,
  });

  factory GreenSupplierRating.fromJson(Map<String, dynamic> json) {
    return GreenSupplierRating(
      supplierId: json['supplier_id'],
      supplierName: json['supplier_name'] ?? '',
      carbonFootprintScore: double.parse(json['carbon_footprint_score'].toString()),
      renewableEnergyScore: double.parse(json['renewable_energy_score'].toString()),
      wasteManagementScore: double.parse(json['waste_management_score'].toString()),
      sustainablePackagingScore: double.parse(json['sustainable_packaging_score'].toString()),
      overallRating: double.parse(json['overall_rating'].toString()),
      ratingCategory: json['rating_category'],
      iso14001Certified: json['iso14001_certified'] ?? false,
      carbonNeutralCertified: json['carbon_neutral_certified'] ?? false,
      organicCertified: json['organic_certified'] ?? false,
    );
  }
}
