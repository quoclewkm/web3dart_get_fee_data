import 'package:web3dart_get_fee_data/src/fee_data_model.dart';

/// Enhanced analytics functions for gas fee analysis.
///
/// These functions provide additional insights like network congestion,
/// fee trends, historical ranges, and wait time estimates.
/// Currently moved here to keep the main fee calculation simple.
///
/// ## Usage Example:
///
/// To use these enhanced analytics with the main `getSuggestedGasFees` function:
///
/// ```dart
/// import 'package:web3dart/web3dart.dart';
/// import 'package:web3dart_get_fee_data/web3dart_get_fee_data.dart';
/// import 'package:web3dart_get_fee_data/src/fee_analytics.dart';
///
/// Future<void> main() async {
///   final client = Web3Client('https://eth.llamarpc.com', Client());
///
///   // Get basic fee data
///   final basicFees = await getSuggestedGasFees(client);
///
///   // Get enhanced analytics separately
///   final feeHistoryResponse = await client.makeRPCCall('eth_feeHistory', [
///     '0x14', // 20 blocks
///     'pending',
///     [1, 50, 99],
///   ]);
///
///   final feeHistory = _parseFeeHistory(feeHistoryResponse, 20);
///
///   // Calculate enhanced metrics
///   final networkCongestion = calculateNetworkCongestion(feeHistory);
///   final priorityTrend = analyzePriorityFeeTrend(feeHistory);
///   final baseTrend = analyzeBaseFeeTrend(feeHistory);
///   final historicalRange = calculateHistoricalPriorityRange(feeHistory);
///   final waitTimes = estimateWaitTimes(networkCongestion);
///
///   // Create enhanced fee estimates with wait times
///   final enhancedSlow = GasFeeEstimate(
///     maxPriorityFeePerGas: basicFees.slow.maxPriorityFeePerGas,
///     maxFeePerGas: basicFees.slow.maxFeePerGas,
///     minWaitTimeEstimate: waitTimes['slowMin'],
///     maxWaitTimeEstimate: waitTimes['slowMax'],
///   );
///
///   print('Network Congestion: ${(networkCongestion * 100).toStringAsFixed(1)}%');
///   print('Priority Fee Trend: $priorityTrend');
///   print('Wait Time (slow): ${waitTimes['slowMin']! ~/ 1000}-${waitTimes['slowMax']! ~/ 1000}s');
/// }
/// ```

/// Calculates network congestion level based on gas used ratios.
///
/// Returns a value between 0.0 (no congestion) and 1.0 (maximum congestion).
double calculateNetworkCongestion(List<HistoricalBlock> blocks) {
  if (blocks.isEmpty) return 0.5;

  final totalGasUsedRatio = blocks.fold<double>(0.0, (sum, block) => sum + block.gasUsedRatio);

  return totalGasUsedRatio / blocks.length;
}

/// Analyzes the trend direction for priority fees.
FeeTrend analyzePriorityFeeTrend(List<HistoricalBlock> blocks) {
  if (blocks.length < 3) return FeeTrend.stable;

  // Compare average of first third vs last third
  final firstThird = blocks.take(blocks.length ~/ 3).toList();
  final lastThird = blocks.skip(blocks.length * 2 ~/ 3).toList();

  final firstAvg = _calculateAveragePriorityFee(firstThird, 1); // 50th percentile
  final lastAvg = _calculateAveragePriorityFee(lastThird, 1);

  final change = (lastAvg - firstAvg).abs();
  final threshold = firstAvg ~/ BigInt.from(10); // 10% threshold

  if (change < threshold) return FeeTrend.stable;

  return lastAvg > firstAvg ? FeeTrend.up : FeeTrend.down;
}

/// Analyzes the trend direction for base fees.
FeeTrend analyzeBaseFeeTrend(List<HistoricalBlock> blocks) {
  if (blocks.length < 3) return FeeTrend.stable;

  // Compare average of first third vs last third
  final firstThird = blocks.take(blocks.length ~/ 3);
  final lastThird = blocks.skip(blocks.length * 2 ~/ 3);

  final firstAvg = firstThird.fold<BigInt>(BigInt.zero, (sum, block) => sum + block.baseFeePerGas) ~/ BigInt.from(firstThird.length);

  final lastAvg = lastThird.fold<BigInt>(BigInt.zero, (sum, block) => sum + block.baseFeePerGas) ~/ BigInt.from(lastThird.length);

  final change = (lastAvg - firstAvg).abs();
  final threshold = firstAvg ~/ BigInt.from(10); // 10% threshold

  if (change < threshold) return FeeTrend.stable;

  return lastAvg > firstAvg ? FeeTrend.up : FeeTrend.down;
}

/// Calculates the historical range of priority fees.
List<BigInt> calculateHistoricalPriorityRange(List<HistoricalBlock> blocks) {
  if (blocks.isEmpty) return [BigInt.zero, BigInt.zero];

  BigInt min = BigInt.parse('9' * 20); // Large initial value
  BigInt max = BigInt.zero;

  for (final block in blocks) {
    for (final fee in block.priorityFeePerGas) {
      if (fee < min) min = fee;
      if (fee > max) max = fee;
    }
  }

  return [min, max];
}

/// Calculates the historical range of base fees.
List<BigInt> calculateHistoricalBaseFeeRange(List<HistoricalBlock> blocks) {
  if (blocks.isEmpty) return [BigInt.zero, BigInt.zero];

  BigInt min = blocks.first.baseFeePerGas;
  BigInt max = blocks.first.baseFeePerGas;

  for (final block in blocks) {
    if (block.baseFeePerGas < min) min = block.baseFeePerGas;
    if (block.baseFeePerGas > max) max = block.baseFeePerGas;
  }

  return [min, max];
}

/// Estimates wait times based on network congestion and fee tier.
///
/// Returns a map with wait time estimates in milliseconds.
/// Based on typical Ethereum block times (~12 seconds) and congestion analysis.
Map<String, int> estimateWaitTimes(double congestion) {
  // Base block time is ~12 seconds (12000 ms)
  final baseBlockTime = 12000;

  // Congestion multiplier: higher congestion = longer wait times
  final congestionMultiplier = 1.0 + congestion;

  // Estimate blocks needed for each tier
  // Fast: 1-2 blocks, Average: 1-3 blocks, Slow: 2-4 blocks
  final fastMinBlocks = 1;
  final fastMaxBlocks = (2 * congestionMultiplier).ceil();

  final averageMinBlocks = fastMinBlocks;
  final averageMaxBlocks = (3 * congestionMultiplier).ceil();

  final slowMinBlocks = (2 * congestionMultiplier).ceil();
  final slowMaxBlocks = (4 * congestionMultiplier).ceil();

  return {
    'fastMin': fastMinBlocks * baseBlockTime,
    'fastMax': fastMaxBlocks * baseBlockTime,
    'averageMin': averageMinBlocks * baseBlockTime,
    'averageMax': averageMaxBlocks * baseBlockTime,
    'slowMin': slowMinBlocks * baseBlockTime,
    'slowMax': slowMaxBlocks * baseBlockTime,
  };
}

/// Helper function to calculate average priority fee for a specific percentile across blocks.
BigInt _calculateAveragePriorityFee(List<HistoricalBlock> blocks, int percentileIndex) {
  if (blocks.isEmpty) {
    return BigInt.from(1e9); // 1 gwei fallback
  }

  BigInt sum = BigInt.zero;
  int validBlocks = 0;

  for (final block in blocks) {
    if (block.priorityFeePerGas.length > percentileIndex) {
      sum += block.priorityFeePerGas[percentileIndex];
      validBlocks++;
    }
  }

  if (validBlocks == 0) {
    return BigInt.from(1e9); // 1 gwei fallback
  }

  return sum ~/ BigInt.from(validBlocks);
}
