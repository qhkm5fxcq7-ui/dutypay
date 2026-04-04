import '../models/allowance_calculation_input.dart';
import '../models/allowance_calculation_result.dart';
import '../models/allowance_config.dart';

class AllowanceEngine {
  const AllowanceEngine();

  AllowanceCalculationResult calculate({
    required AllowanceConfig config,
    required AllowanceCalculationInput input,
  }) {
    final amount = _calculateAmount(config: config, input: input);

    return AllowanceCalculationResult(
      allowanceId: config.id,
      allowanceName: config.name,
      amount: amount,
      goesToBasket: input.sendToBasket,
    );
  }

  double _calculateAmount({
    required AllowanceConfig config,
    required AllowanceCalculationInput input,
  }) {
    switch (config.type) {
      case AllowanceType.daily:
        return config.dayRate ?? 0;

      case AllowanceType.hourly:
        final dayRate = config.dayRate ?? 0;
        final nightRate = config.nightRate ?? dayRate;

        return (input.dayHours * dayRate) + (input.nightHours * nightRate);
    }
  }
}