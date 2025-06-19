import 'package:web3dart/web3dart.dart';
import 'package:web3dart_get_fee_data/src/fee_data_model.dart';
import 'package:web3dart_get_fee_data/src/web3dart_get_fee_data_base.dart' show ErrorContext;

/// Retrieves suggested gas fees with slow, average, and fast options using EIP-1559.
///
/// This function implements the methodology described in Alchemy's documentation
/// for building gas fee estimators using `eth_feeHistory`. It analyzes historical
/// priority fees from recent blocks to calculate appropriate fee estimates.
///
/// **Parameters:**
/// - [client]: A connected [Web3Client] instance for the target Ethereum network
/// - [historicalBlocks]: Number of historical blocks to analyze (default: 20)
/// - [onError]: Optional callback for custom error handling. Receives the error context
///   and can return a custom fallback value or rethrow the error.
///
/// **Returns:**
/// A [SuggestedGasFees] object containing three fee tiers:
/// - `slow`: Conservative estimate (1st percentile) - cheaper but slower confirmation
/// - `average`: Standard estimate (50th percentile) - balanced cost and speed
/// - `fast`: Aggressive estimate (99th percentile) - more expensive but faster confirmation
///
/// **Methodology:**
/// 1. Fetches fee history for the specified number of blocks
/// 2. Calculates 1st, 50th, and 99th percentiles of priority fees
/// 3. Averages these percentiles across all analyzed blocks
/// 4. Adds current base fee to create complete fee estimates
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
/// ```
///
/// **Example with custom parameters:**
/// ```dart
/// final suggestedFees = await getSuggestedGasFees(
///   client,
///   historicalBlocks: 10,
///   onError: (context) {
///     print('Error: ${context.error}');
///     return context.fallbackValue;
///   }
/// );
/// ```
Future<SuggestedGasFees> getSuggestedGasFees(Web3Client client, {int historicalBlocks = 20, BigInt? Function(ErrorContext context)? onError}) async {
  try {
    // Get fee history with 1st, 50th, and 99th percentiles
    final feeHistoryResponse = await client.makeRPCCall('eth_feeHistory', [
      '0x${historicalBlocks.toRadixString(16)}', // number of blocks
      'pending', // newest block
      [1, 50, 99], // percentiles
    ]);

    // Get current pending block for base fee
    final pendingBlockResponse = await client.makeRPCCall('eth_getBlockByNumber', ['pending', false]);

    // Parse the responses
    final feeHistory = _parseFeeHistory(feeHistoryResponse, historicalBlocks);
    final baseFeePerGas = _parseBaseFeeFromBlock(pendingBlockResponse);

    // Calculate average priority fees for each percentile
    final slowPriorityFee = _calculateAveragePriorityFee(feeHistory, 0); // 1st percentile
    final averagePriorityFee = _calculateAveragePriorityFee(feeHistory, 1); // 50th percentile
    final fastPriorityFee = _calculateAveragePriorityFee(feeHistory, 2); // 99th percentile

    // Calculate max fee per gas (base fee + priority fee)
    // Using the pending block's base fee for calculation
    final slowMaxFee = baseFeePerGas + slowPriorityFee;
    final averageMaxFee = baseFeePerGas + averagePriorityFee;
    final fastMaxFee = baseFeePerGas + fastPriorityFee;

    return SuggestedGasFees(
      slow: GasFeeEstimate(maxPriorityFeePerGas: slowPriorityFee, maxFeePerGas: slowMaxFee),
      average: GasFeeEstimate(maxPriorityFeePerGas: averagePriorityFee, maxFeePerGas: averageMaxFee),
      fast: GasFeeEstimate(maxPriorityFeePerGas: fastPriorityFee, maxFeePerGas: fastMaxFee),
      baseFeePerGas: baseFeePerGas,
    );
  } catch (error, stackTrace) {
    // Enhanced fallback strategy
    final defaultSlowFee = BigInt.from(1e9); // 1 gwei
    final defaultAverageFee = BigInt.from(15e8); // 1.5 gwei
    final defaultFastFee = BigInt.from(2e9); // 2 gwei
    final defaultBaseFee = BigInt.from(20e9); // 20 gwei

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
          slow: GasFeeEstimate(maxPriorityFeePerGas: fallbackFee ~/ BigInt.from(2), maxFeePerGas: defaultBaseFee + (fallbackFee ~/ BigInt.from(2))),
          average: GasFeeEstimate(maxPriorityFeePerGas: fallbackFee, maxFeePerGas: defaultBaseFee + fallbackFee),
          fast: GasFeeEstimate(maxPriorityFeePerGas: fallbackFee * BigInt.from(2), maxFeePerGas: defaultBaseFee + (fallbackFee * BigInt.from(2))),
          baseFeePerGas: defaultBaseFee,
        );
      }
    }

    // Default fallback values
    return SuggestedGasFees(
      slow: GasFeeEstimate(maxPriorityFeePerGas: defaultSlowFee, maxFeePerGas: defaultBaseFee + defaultSlowFee),
      average: GasFeeEstimate(maxPriorityFeePerGas: defaultAverageFee, maxFeePerGas: defaultBaseFee + defaultAverageFee),
      fast: GasFeeEstimate(maxPriorityFeePerGas: defaultFastFee, maxFeePerGas: defaultBaseFee + defaultFastFee),
      baseFeePerGas: defaultBaseFee,
    );
  }
}

/// Parses the fee history response from eth_feeHistory into structured data.
List<HistoricalBlock> _parseFeeHistory(dynamic feeHistory, int expectedBlocks) {
  final Map<String, dynamic> history = feeHistory as Map<String, dynamic>;

  final oldestBlock = int.parse(history['oldestBlock'] as String, radix: 16);
  final baseFeePerGasHex = history['baseFeePerGas'] as List<dynamic>;
  final gasUsedRatio = history['gasUsedRatio'] as List<dynamic>;
  final reward = history['reward'] as List<dynamic>;

  final blocks = <HistoricalBlock>[];

  for (int i = 0; i < expectedBlocks; i++) {
    final blockNumber = oldestBlock + i;
    final baseFee = BigInt.parse((baseFeePerGasHex[i] as String).substring(2), radix: 16);
    final gasRatio = (gasUsedRatio[i] as num).toDouble();

    final rewardsList = reward[i] as List<dynamic>;
    final priorityFees = rewardsList.map((hexString) => BigInt.parse((hexString as String).substring(2), radix: 16)).toList();

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

  return BigInt.parse(baseFeeHex.substring(2), radix: 16);
}

/// Calculates the average priority fee for a specific percentile across all blocks.
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
