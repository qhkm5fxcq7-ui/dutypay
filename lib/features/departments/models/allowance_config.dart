enum AllowanceType {
  daily,
  hourly,
}

class AllowanceConfig {
  final String id;
  final String name;

  final AllowanceType type;

  final double? dayRate;
  final double? nightRate;

  final bool defaultToBasket;

  const AllowanceConfig({
    required this.id,
    required this.name,
    required this.type,
    this.dayRate,
    this.nightRate,
    this.defaultToBasket = false,
  });
}