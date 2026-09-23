class ProductionPlan {
  const ProductionPlan({required this.quantity, required this.materialPerUnit, required this.dyePerUnit, required this.batchCapacity});
  final int quantity;
  final double materialPerUnit;
  final double dyePerUnit;
  final int batchCapacity;
  double get materialTotal => quantity * materialPerUnit;
  double get dyeTotal => quantity * dyePerUnit;
  int get batches => batchCapacity <= 0 ? quantity : (quantity / batchCapacity).ceil();
}
