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

  /// Creates a new [GasFeeEstimate] instance.
  GasFeeEstimate({required this.maxPriorityFeePerGas, required this.maxFeePerGas});

  @override
  String toString() => 'GasFeeEstimate(maxPriorityFeePerGas: $maxPriorityFeePerGas, maxFeePerGas: $maxFeePerGas)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GasFeeEstimate && runtimeType == other.runtimeType && maxPriorityFeePerGas == other.maxPriorityFeePerGas && maxFeePerGas == other.maxFeePerGas;

  @override
  int get hashCode => maxPriorityFeePerGas.hashCode ^ maxFeePerGas.hashCode;
}

/// Provides suggested gas fees with slow, average, and fast options based on EIP-1559.
///
/// This follows the methodology described in Alchemy's documentation for building
/// gas fee estimators using historical fee data from `eth_feeHistory`.
class SuggestedGasFees {
  /// Conservative fee estimate for slower confirmation times.
  ///
  /// Based on the 1st percentile of priority fees from recent blocks.
  /// Generally takes longer to confirm but costs less.
  final GasFeeEstimate slow;

  /// Standard fee estimate for average confirmation times.
  ///
  /// Based on the 50th percentile (median) of priority fees from recent blocks.
  /// Balanced between cost and confirmation speed.
  final GasFeeEstimate average;

  /// Aggressive fee estimate for faster confirmation times.
  ///
  /// Based on the 99th percentile of priority fees from recent blocks.
  /// Generally confirms faster but costs more.
  final GasFeeEstimate fast;

  /// The current base fee per gas in wei from the latest block.
  ///
  /// This is the minimum fee required for transaction inclusion and is
  /// automatically burned by the network (not paid to miners).
  final BigInt baseFeePerGas;

  /// Creates a new [SuggestedGasFees] instance.
  SuggestedGasFees({required this.slow, required this.average, required this.fast, required this.baseFeePerGas});

  @override
  String toString() => 'SuggestedGasFees(slow: $slow, average: $average, fast: $fast, baseFeePerGas: $baseFeePerGas)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SuggestedGasFees &&
          runtimeType == other.runtimeType &&
          slow == other.slow &&
          average == other.average &&
          fast == other.fast &&
          baseFeePerGas == other.baseFeePerGas;

  @override
  int get hashCode => slow.hashCode ^ average.hashCode ^ fast.hashCode ^ baseFeePerGas.hashCode;
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
