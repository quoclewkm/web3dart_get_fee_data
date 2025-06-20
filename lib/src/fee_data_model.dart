/// Represents Ethereum fee data including legacy gas price and EIP-1559 fee parameters.
///
/// This class mirrors the structure of ethers.js FeeData, providing compatibility
/// with both legacy transactions (using [gasPrice]) and EIP-1559 transactions
/// (using [maxFeePerGas] and [maxPriorityFeePerGas]).
///
/// For EIP-1559 transactions:
/// - [maxFeePerGas]: The maximum total fee per gas unit willing to pay
/// - [maxPriorityFeePerGas]: The maximum priority fee (tip) per gas unit
///
/// For legacy transactions:
/// - [gasPrice]: The gas price per unit
class FeeData {
  /// The legacy gas price in wei.
  ///
  /// This is used for pre-EIP-1559 transactions and as a fallback
  /// when EIP-1559 is not supported by the network.
  final BigInt? gasPrice;

  /// The maximum fee per gas in wei for EIP-1559 transactions.
  ///
  /// This represents the maximum total amount (base fee + priority fee)
  /// that the user is willing to pay per gas unit.
  final BigInt? maxFeePerGas;

  /// The maximum priority fee per gas in wei for EIP-1559 transactions.
  ///
  /// This represents the maximum tip amount per gas unit that the user
  /// is willing to pay to incentivize miners to include their transaction.
  final BigInt? maxPriorityFeePerGas;

  /// Creates a new [FeeData] instance.
  ///
  /// At least one of [gasPrice] or both [maxFeePerGas] and [maxPriorityFeePerGas]
  /// should be provided, depending on the transaction type and network support.
  FeeData(this.gasPrice, this.maxFeePerGas, this.maxPriorityFeePerGas);

  @override
  String toString() => 'FeeData(gasPrice: $gasPrice, maxFeePerGas: $maxFeePerGas, maxPriorityFeePerGas: $maxPriorityFeePerGas)';
}

/// Represents a single gas fee estimate with both priority fee and max fee.
///
/// Used for providing different speed tiers (slow, average, fast) for EIP-1559 transactions.
class GasFeeEstimate {
  /// The priority fee per gas in wei for this estimate.
  ///
  /// This is the tip amount per gas unit that incentivizes miners to include the transaction.
  final BigInt maxPriorityFeePerGas;

  /// The maximum total fee per gas in wei for this estimate.
  ///
  /// This includes both the base fee and priority fee. It represents the maximum
  /// total amount that the user is willing to pay per gas unit.
  final BigInt maxFeePerGas;

  /// Minimum estimated wait time in milliseconds for this fee tier.
  ///
  /// This is an estimate of the shortest time it might take for the transaction
  /// to be confirmed when using this fee level.
  final int? minWaitTimeEstimate;

  /// Maximum estimated wait time in milliseconds for this fee tier.
  ///
  /// This is an estimate of the longest time it might take for the transaction
  /// to be confirmed when using this fee level.
  final int? maxWaitTimeEstimate;

  /// Creates a new [GasFeeEstimate] instance.
  GasFeeEstimate({required this.maxPriorityFeePerGas, required this.maxFeePerGas, this.minWaitTimeEstimate, this.maxWaitTimeEstimate});

  @override
  String toString() =>
      'GasFeeEstimate(maxPriorityFeePerGas: $maxPriorityFeePerGas, maxFeePerGas: $maxFeePerGas, minWaitTime: $minWaitTimeEstimate, maxWaitTime: $maxWaitTimeEstimate)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GasFeeEstimate &&
          runtimeType == other.runtimeType &&
          maxPriorityFeePerGas == other.maxPriorityFeePerGas &&
          maxFeePerGas == other.maxFeePerGas &&
          minWaitTimeEstimate == other.minWaitTimeEstimate &&
          maxWaitTimeEstimate == other.maxWaitTimeEstimate;

  @override
  int get hashCode => maxPriorityFeePerGas.hashCode ^ maxFeePerGas.hashCode ^ (minWaitTimeEstimate?.hashCode ?? 0) ^ (maxWaitTimeEstimate?.hashCode ?? 0);
}

/// Represents fee trend direction.
enum FeeTrend {
  /// Fees are trending upward.
  up,

  /// Fees are trending downward.
  down,

  /// Fees are stable (no clear trend).
  stable,
}

/// Provides suggested gas fees with slow, average, and fast options based on EIP-1559.
///
/// This follows the methodology described in Alchemy's documentation for building
/// gas fee estimators using historical fee data from `eth_feeHistory`.
/// Enhanced with additional network metrics similar to MetaSwap's gas API.
class SuggestedGasFees {
  /// Conservative fee estimate for slower confirmation times.
  ///
  /// Based on the 1st percentile of priority fees from recent blocks.
  /// Generally takes longer to confirm but costs less.
  final GasFeeEstimate slow;

  /// Standard fee estimate for average confirmation times.
  ///
  /// Based on the 75th percentile of priority fees from recent blocks.
  /// Balanced between cost and confirmation speed.
  final GasFeeEstimate average;

  /// Aggressive fee estimate for faster confirmation times.
  ///
  /// Based on the 90th percentile of priority fees from recent blocks.
  /// Generally confirms faster but costs more.
  final GasFeeEstimate fast;

  /// The current base fee per gas in wei from the latest block.
  ///
  /// This is the minimum fee required for transaction inclusion and is
  /// automatically burned by the network (not paid to miners).
  final BigInt baseFeePerGas;

  /// Network congestion level as a ratio between 0.0 and 1.0.
  ///
  /// - 0.0: No congestion (empty blocks)
  /// - 0.5: Moderate congestion (half-full blocks)
  /// - 1.0: Maximum congestion (full blocks)
  ///
  /// This metric helps users understand current network conditions.
  final double? networkCongestion;

  /// Current trend direction for priority fees.
  ///
  /// Indicates whether priority fees are generally increasing, decreasing,
  /// or remaining stable based on recent block analysis.
  final FeeTrend? priorityFeeTrend;

  /// Current trend direction for base fees.
  ///
  /// Indicates whether base fees are generally increasing, decreasing,
  /// or remaining stable based on recent block analysis.
  final FeeTrend? baseFeeTrend;

  /// Historical range of priority fees observed in analyzed blocks.
  ///
  /// Provides context for current fee levels. Format: [min, max] in wei.
  final List<BigInt>? historicalPriorityFeeRange;

  /// Historical range of base fees observed in analyzed blocks.
  ///
  /// Provides context for current base fee levels. Format: [min, max] in wei.
  final List<BigInt>? historicalBaseFeeRange;

  /// Creates a new [SuggestedGasFees] instance.
  SuggestedGasFees({
    required this.slow,
    required this.average,
    required this.fast,
    required this.baseFeePerGas,
    this.networkCongestion,
    this.priorityFeeTrend,
    this.baseFeeTrend,
    this.historicalPriorityFeeRange,
    this.historicalBaseFeeRange,
  });

  @override
  String toString() =>
      'SuggestedGasFees(slow: $slow, average: $average, fast: $fast, baseFeePerGas: $baseFeePerGas, congestion: $networkCongestion, priorityTrend: $priorityFeeTrend, baseTrend: $baseFeeTrend)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SuggestedGasFees &&
          runtimeType == other.runtimeType &&
          slow == other.slow &&
          average == other.average &&
          fast == other.fast &&
          baseFeePerGas == other.baseFeePerGas &&
          networkCongestion == other.networkCongestion &&
          priorityFeeTrend == other.priorityFeeTrend &&
          baseFeeTrend == other.baseFeeTrend;

  @override
  int get hashCode =>
      slow.hashCode ^
      average.hashCode ^
      fast.hashCode ^
      baseFeePerGas.hashCode ^
      (networkCongestion?.hashCode ?? 0) ^
      (priorityFeeTrend?.hashCode ?? 0) ^
      (baseFeeTrend?.hashCode ?? 0);
}

/// Historical fee data for a single block used in fee estimation calculations.
class HistoricalBlock {
  /// The block number.
  final int number;

  /// The base fee per gas for this block in wei.
  final BigInt baseFeePerGas;

  /// The ratio of gas used to gas limit for this block (0.0 to 1.0).
  ///
  /// A value of 1.0 means the block was completely full.
  final double gasUsedRatio;

  /// Priority fees per gas at requested percentiles for transactions in this block.
  ///
  /// The array corresponds to the percentiles requested in the `eth_feeHistory` call.
  /// For example, if percentiles [1, 50, 99] were requested, this array will contain
  /// the 1st, 50th, and 99th percentile priority fees.
  final List<BigInt> priorityFeePerGas;

  /// Creates a new [HistoricalBlock] instance.
  HistoricalBlock({required this.number, required this.baseFeePerGas, required this.gasUsedRatio, required this.priorityFeePerGas});

  @override
  String toString() => 'HistoricalBlock(number: $number, baseFeePerGas: $baseFeePerGas, gasUsedRatio: $gasUsedRatio, priorityFeePerGas: $priorityFeePerGas)';
}
