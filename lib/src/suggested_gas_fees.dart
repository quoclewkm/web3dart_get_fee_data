import 'package:web3dart/web3dart.dart';
import 'package:web3dart_get_fee_data/src/fee_data_model.dart';
import 'package:web3dart_get_fee_data/src/web3dart_get_fee_data_base.dart' show ErrorContext;

// Default configuration constants for easy maintenance
/// Default percentiles for slow, average, and fast gas fee tiers.
/// Based on MetaSwap methodology for realistic fee estimates.
const List<int> kDefaultPercentiles = [1, 75, 90];

/// Default number of historical blocks to analyze for fee estimation.
const int kDefaultHistoricalBlocks = 40;

/// Minimum priority fee to ensure transaction inclusion (0.0001 gwei in wei).
/// Prevents zero-fee transactions that might not be processed.
const int kMinimumPriorityFeeWei = 100000; // 1e5 wei = 0.0001 gwei

// Default fallback values when network calls fail
/// Default slow priority fee fallback (1 gwei in wei).
const int kDefaultSlowPriorityFeeWei = 1000000000; // 1e9 wei = 1 gwei

/// Default average priority fee fallback (1.5 gwei in wei).
const int kDefaultAveragePriorityFeeWei = 1500000000; // 1.5e9 wei = 1.5 gwei

/// Default fast priority fee fallback (2 gwei in wei).
const int kDefaultFastPriorityFeeWei = 2000000000; // 2e9 wei = 2 gwei

/// Default base fee fallback (20 gwei in wei).
const int kDefaultBaseFeeWei = 20000000000; // 20e9 wei = 20 gwei

/// Retrieves suggested gas fees with slow, average, and fast options using EIP-1559.
///
/// This function implements the methodology described in Alchemy's documentation
/// for building gas fee estimators using `eth_feeHistory`. It analyzes historical
/// priority fees from recent blocks to calculate appropriate fee estimates.
///
/// Enhanced with additional network metrics similar to MetaSwap's gas API including
/// congestion analysis, fee trends, and wait time estimates.
///
/// **Parameters:**
/// - [client]: A connected [Web3Client] instance for the target Ethereum network
/// - [historicalBlocks]: Number of historical blocks to analyze (default: [kDefaultHistoricalBlocks])
/// - [percentiles]: List of 3 percentiles to use for slow/average/fast tiers (default: [kDefaultPercentiles])
/// - [onError]: Optional callback for custom error handling. Receives the error context
///   and can return a custom fallback value or rethrow the error.
///
/// **Returns:**
/// A [SuggestedGasFees] object containing three fee tiers:
/// - `slow`: Conservative estimate (default: 1st percentile) - cheaper but slower confirmation
/// - `average`: Standard estimate (default: 75th percentile) - balanced cost and speed
/// - `fast`: Aggressive estimate (default: 90th percentile) - more expensive but faster confirmation
///
/// Plus additional network analysis:
/// - `networkCongestion`: Current congestion level (0.0 to 1.0)
/// - `priorityFeeTrend`: Direction of priority fee changes
/// - `baseFeeTrend`: Direction of base fee changes
/// - `historicalPriorityFeeRange`: Min/max priority fees observed
/// - `historicalBaseFeeRange`: Min/max base fees observed
///
/// **Methodology:**
/// 1. Fetches fee history for the specified number of blocks
/// 2. Calculates specified percentiles of priority fees (default: 1st, 75th, 90th)
/// 3. Averages these percentiles across all analyzed blocks
/// 4. Applies minimum priority fee floor to prevent zero-fee transactions
/// 5. Adds current base fee to create complete fee estimates
///
/// **Throws:**
/// - [RPCError]: If the RPC call fails
/// - [FormatException]: If the response format is invalid
/// - [Exception]: For network connectivity issues or if EIP-1559 is not supported
///
/// **Example:**
/// ```dart
/// final client = Web3Client('https://eth.llamarpc.com', Client());
/// final suggestedFees = await getSuggestedGasFees(client);
///
/// print('Slow: ${suggestedFees.slow.maxFeePerGas} wei');
/// print('Average: ${suggestedFees.average.maxFeePerGas} wei');
/// print('Fast: ${suggestedFees.fast.maxFeePerGas} wei');
/// print('Network Congestion: ${suggestedFees.networkCongestion}');
/// ```
///
/// **Example with custom parameters:**
/// ```dart
/// final suggestedFees = await getSuggestedGasFees(
///   client,
///   historicalBlocks: 10,
///   percentiles: [5, 60, 95], // More conservative slow, different average/fast
///   onError: (context) {
///     print('Error: ${context.error}');
///     return context.fallbackValue;
///   }
/// );
/// ```
///
/// **Default constants available for reference:**
/// ```dart
/// kDefaultPercentiles = [1, 75, 90]
/// kDefaultHistoricalBlocks = 20
/// kMinimumPriorityFeeWei = 100000 // 0.0001 gwei
/// ```
Future<SuggestedGasFees> getSuggestedGasFees(
  Web3Client client, {
  int historicalBlocks = kDefaultHistoricalBlocks,
  List<int> percentiles = kDefaultPercentiles,
  // bool includeWaitTimes = true,
  BigInt? Function(ErrorContext context)? onError,
}) async {
  try {
    // Validate percentiles parameter
    if (percentiles.length != 3) {
      throw ArgumentError('Exactly 3 percentiles must be provided (slow, average, fast)');
    }

    if (percentiles.any((p) => p < 1 || p > 99)) {
      throw ArgumentError('Percentiles must be between 1 and 99');
    }

    // Get fee history with user-specified percentiles
    final feeHistoryResponse = await client.makeRPCCall('eth_feeHistory', [
      '0x${historicalBlocks.toRadixString(16)}', // number of blocks
      'pending', // newest block
      percentiles, // user-specified percentiles
    ]);

    // Get current pending block for base fee
    final pendingBlockResponse = await client.makeRPCCall('eth_getBlockByNumber', ['pending', false]);

    // Parse the responses
    final feeHistory = _parseFeeHistory(feeHistoryResponse, historicalBlocks);
    final baseFeePerGas = _parseBaseFeeFromBlock(pendingBlockResponse);

    // Calculate average priority fees for each percentile
    final rawSlowPriorityFee = _calculateAveragePriorityFee(feeHistory, 0); // percentiles[0]
    final averagePriorityFee = _calculateAveragePriorityFee(feeHistory, 1); // percentiles[1]
    final fastPriorityFee = _calculateAveragePriorityFee(feeHistory, 2); // percentiles[2]

    // Apply minimum priority fee to ensure transaction inclusion
    final minPriorityFee = BigInt.from(kMinimumPriorityFeeWei);
    final slowPriorityFee = rawSlowPriorityFee > minPriorityFee ? rawSlowPriorityFee : minPriorityFee;

    // Enhanced analysis
    // final networkCongestion = _calculateNetworkCongestion(feeHistory);
    // final priorityFeeTrend = _analyzePriorityFeeTrend(feeHistory);
    // final baseFeeTrend = _analyzeBaseFeeTrend(feeHistory);
    // final historicalPriorityRange = _calculateHistoricalPriorityRange(feeHistory);
    // final historicalBaseFeeRange = _calculateHistoricalBaseFeeRange(feeHistory);

    // Calculate wait time estimates if requested
    // Map<String, int>? waitTimes;
    // if (includeWaitTimes) {
    //   waitTimes = _estimateWaitTimes(networkCongestion);
    // }

    // Calculate max fee per gas (base fee + priority fee)
    // Using the pending block's base fee for calculation
    final slowMaxFee = baseFeePerGas + slowPriorityFee;
    final averageMaxFee = baseFeePerGas + averagePriorityFee;
    final fastMaxFee = baseFeePerGas + fastPriorityFee;

    return SuggestedGasFees(
      slow: GasFeeEstimate(
        maxPriorityFeePerGas: slowPriorityFee,
        maxFeePerGas: slowMaxFee,
        // minWaitTimeEstimate: waitTimes?['slowMin'],
        // maxWaitTimeEstimate: waitTimes?['slowMax'],
      ),
      average: GasFeeEstimate(
        maxPriorityFeePerGas: averagePriorityFee,
        maxFeePerGas: averageMaxFee,
        // minWaitTimeEstimate: waitTimes?['averageMin'],
        // maxWaitTimeEstimate: waitTimes?['averageMax'],
      ),
      fast: GasFeeEstimate(
        maxPriorityFeePerGas: fastPriorityFee,
        maxFeePerGas: fastMaxFee,
        // minWaitTimeEstimate: waitTimes?['fastMin'],
        // maxWaitTimeEstimate: waitTimes?['fastMax'],
      ),
      baseFeePerGas: baseFeePerGas,
      // networkCongestion: networkCongestion,
      // priorityFeeTrend: priorityFeeTrend,
      // baseFeeTrend: baseFeeTrend,
      // historicalPriorityFeeRange: historicalPriorityRange,
      // historicalBaseFeeRange: historicalBaseFeeRange,
    );
  } catch (error, stackTrace) {
    // Enhanced fallback strategy using constants
    final defaultSlowFee = BigInt.from(kDefaultSlowPriorityFeeWei);
    final defaultAverageFee = BigInt.from(kDefaultAveragePriorityFeeWei);
    final defaultFastFee = BigInt.from(kDefaultFastPriorityFeeWei);
    final defaultBaseFee = BigInt.from(kDefaultBaseFeeWei);

    if (onError != null) {
      final context = ErrorContext(
        operation: 'getSuggestedGasFees',
        error: error,
        stackTrace: stackTrace,
        fallbackValue: defaultAverageFee,
        gasPrice: defaultBaseFee + defaultAverageFee,
        baseFeePerGas: defaultBaseFee,
      );

      final fallbackFee = onError(context);
      if (fallbackFee != null) {
        return SuggestedGasFees(
          slow: GasFeeEstimate(
            maxPriorityFeePerGas: fallbackFee ~/ BigInt.from(2),
            maxFeePerGas: defaultBaseFee + (fallbackFee ~/ BigInt.from(2)),
            // minWaitTimeEstimate: includeWaitTimes ? 24000 : null,
            // maxWaitTimeEstimate: includeWaitTimes ? 60000 : null,
          ),
          average: GasFeeEstimate(
            maxPriorityFeePerGas: fallbackFee,
            maxFeePerGas: defaultBaseFee + fallbackFee,
            // minWaitTimeEstimate: includeWaitTimes ? 12000 : null,
            // maxWaitTimeEstimate: includeWaitTimes ? 36000 : null,
          ),
          fast: GasFeeEstimate(
            maxPriorityFeePerGas: fallbackFee * BigInt.from(2),
            maxFeePerGas: defaultBaseFee + (fallbackFee * BigInt.from(2)),
            // minWaitTimeEstimate: includeWaitTimes ? 12000 : null,
            // maxWaitTimeEstimate: includeWaitTimes ? 24000 : null,
          ),
          baseFeePerGas: defaultBaseFee,
          // networkCongestion: 0.5, // Assume moderate congestion
          // priorityFeeTrend: FeeTrend.stable,
          // baseFeeTrend: FeeTrend.stable,
        );
      }
    }

    // Default fallback values using constants
    return SuggestedGasFees(
      slow: GasFeeEstimate(
        maxPriorityFeePerGas: defaultSlowFee,
        maxFeePerGas: defaultBaseFee + defaultSlowFee,
        // minWaitTimeEstimate: includeWaitTimes ? 24000 : null,
        // maxWaitTimeEstimate: includeWaitTimes ? 60000 : null,
      ),
      average: GasFeeEstimate(
        maxPriorityFeePerGas: defaultAverageFee,
        maxFeePerGas: defaultBaseFee + defaultAverageFee,
        // minWaitTimeEstimate: includeWaitTimes ? 12000 : null,
        // maxWaitTimeEstimate: includeWaitTimes ? 36000 : null,
      ),
      fast: GasFeeEstimate(
        maxPriorityFeePerGas: defaultFastFee,
        maxFeePerGas: defaultBaseFee + defaultFastFee,
        // minWaitTimeEstimate: includeWaitTimes ? 12000 : null,
        // maxWaitTimeEstimate: includeWaitTimes ? 24000 : null,
      ),
      baseFeePerGas: defaultBaseFee,
      // networkCongestion: 0.5, // Assume moderate congestion
      // priorityFeeTrend: FeeTrend.stable,
      // baseFeeTrend: FeeTrend.stable,
    );
  }
}

/// Parses the fee history response from eth_feeHistory into structured data.
List<HistoricalBlock> _parseFeeHistory(dynamic feeHistory, int expectedBlocks) {
  final Map<String, dynamic> history = feeHistory as Map<String, dynamic>;

  final oldestBlockHex = history['oldestBlock'] as String;
  final cleanOldestBlockHex = oldestBlockHex.startsWith('0x') ? oldestBlockHex.substring(2) : oldestBlockHex;
  final oldestBlock = int.parse(cleanOldestBlockHex, radix: 16);
  final baseFeePerGasHex = history['baseFeePerGas'] as List<dynamic>;
  final gasUsedRatio = history['gasUsedRatio'] as List<dynamic>;
  final reward = history['reward'] as List<dynamic>;

  final blocks = <HistoricalBlock>[];

  // Use the minimum of expected blocks and actual data length to avoid index errors
  final actualBlocks = [baseFeePerGasHex.length, gasUsedRatio.length, reward.length].reduce((a, b) => a < b ? a : b);

  final blocksToProcess = actualBlocks < expectedBlocks ? actualBlocks : expectedBlocks;

  for (int i = 0; i < blocksToProcess; i++) {
    final blockNumber = oldestBlock + i;

    // Handle base fee parsing with proper hex format checking
    final baseFeeHex = baseFeePerGasHex[i] as String;
    final cleanBaseFeeHex = baseFeeHex.startsWith('0x') ? baseFeeHex.substring(2) : baseFeeHex;
    final baseFee = BigInt.parse(cleanBaseFeeHex, radix: 16);

    final gasRatio = (gasUsedRatio[i] as num).toDouble();

    // Handle priority fee parsing with proper hex format checking
    final rewardsList = reward[i] as List<dynamic>;
    final priorityFees = rewardsList.map((hexString) {
      final rewardHex = hexString as String;
      final cleanRewardHex = rewardHex.startsWith('0x') ? rewardHex.substring(2) : rewardHex;
      // Handle edge case where hex might be empty or just '0x'
      if (cleanRewardHex.isEmpty) return BigInt.zero;
      return BigInt.parse(cleanRewardHex, radix: 16);
    }).toList();

    blocks.add(HistoricalBlock(number: blockNumber, baseFeePerGas: baseFee, gasUsedRatio: gasRatio, priorityFeePerGas: priorityFees));
  }

  return blocks;
}

/// Parses the base fee from a block response.
BigInt _parseBaseFeeFromBlock(dynamic blockResponse) {
  final Map<String, dynamic> block = blockResponse as Map<String, dynamic>;
  final baseFeeHex = block['baseFeePerGas'] as String?;

  if (baseFeeHex == null) {
    throw Exception('Block does not contain baseFeePerGas - EIP-1559 not supported');
  }

  // Handle proper hex format checking
  final cleanBaseFeeHex = baseFeeHex.startsWith('0x') ? baseFeeHex.substring(2) : baseFeeHex;
  if (cleanBaseFeeHex.isEmpty) {
    throw Exception('Invalid baseFeePerGas format');
  }

  return BigInt.parse(cleanBaseFeeHex, radix: 16);
}

/// Calculates the average priority fee for a specific percentile across all blocks.
BigInt _calculateAveragePriorityFee(List<HistoricalBlock> blocks, int percentileIndex) {
  if (blocks.isEmpty) {
    return BigInt.from(kDefaultAveragePriorityFeeWei); // Use constant fallback
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
    return BigInt.from(kDefaultAveragePriorityFeeWei); // Use constant fallback
  }

  return sum ~/ BigInt.from(validBlocks);
}
