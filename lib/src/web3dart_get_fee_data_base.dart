import 'package:web3dart/web3dart.dart';
import 'package:web3dart_get_fee_data/src/fee_data_model.dart';

/// Retrieves current fee data from an Ethereum network.
///
/// This function mirrors the behavior of ethers.js `getFeeData()`, providing
/// both legacy gas price information and EIP-1559 fee parameters when available.
///
/// The function automatically detects whether the network supports EIP-1559:
/// - If supported: Returns [FeeData] with [maxFeePerGas] and [maxPriorityFeePerGas]
/// - If not supported: Returns [FeeData] with legacy [gasPrice] only
///
/// **Parameters:**
/// - [client]: A connected [Web3Client] instance for the target Ethereum network
/// - [onError]: Optional callback for custom error handling. Receives the error context
///   and can return a custom fallback value or rethrow the error.
///
/// **Returns:**
/// A [FeeData] object containing the current fee information:
/// - `gasPrice`: Always provided, represents the current gas price in wei
/// - `maxFeePerGas`: Provided for EIP-1559 compatible networks (calculated as 2 * baseFee + priorityFee)
/// - `maxPriorityFeePerGas`: Provided for EIP-1559 compatible networks
///
/// **Throws:**
/// - [RPCError]: If the RPC call fails
/// - [FormatException]: If the response format is invalid
/// - [Exception]: For network connectivity issues
///
/// **Example:**
/// ```dart
/// final client = Web3Client('https://eth.llamarpc.com', Client());
/// final feeData = await getFeeData(client);
///
/// if (feeData.maxFeePerGas != null) {
///   print('EIP-1559 supported: ${feeData.maxFeePerGas} wei');
/// } else {
///   print('Legacy gas price: ${feeData.gasPrice} wei');
/// }
/// ```
///
/// **Example with custom error handling:**
/// ```dart
/// final feeData = await getFeeData(
///   client,
///   onError: (context) {
///     print('Error in ${context.operation}: ${context.error}');
///     print('Stack trace: ${context.stackTrace}');
///     return context.fallbackValue ?? BigInt.from(2e9); // Custom 2 gwei fallback
///   }
/// );
/// ```
Future<FeeData> getFeeData(Web3Client client, {BigInt? Function(ErrorContext context)? onError}) async {
  // Always get basic gas price and block info
  final gasPrice = await client.getGasPrice();
  final latestBlock = await client.getBlockInformation();

  BigInt? maxPriorityFeePerGas;
  BigInt? maxFeePerGas;

  // Check if network supports EIP-1559 (has baseFeePerGas in block)
  final baseFeePerGas = latestBlock.baseFeePerGas;
  if (baseFeePerGas != null) {
    try {
      final priorityFeeResponse = await client.makeRPCCall('eth_maxPriorityFeePerGas');
      maxPriorityFeePerGas = priorityFeeResponse is String ? BigInt.tryParse(priorityFeeResponse.substring(2), radix: 16) : null;
    } catch (error, stackTrace) {
      // Enhanced fallback strategy for networks that don't support eth_maxPriorityFeePerGas
      // Many networks like Arbitrum, zkSync return zero priority fees
      // Others may need a small fallback value
      final defaultFallback = BigInt.from(1e9.toInt());

      if (onError != null) {
        final context = ErrorContext(
          operation: 'eth_maxPriorityFeePerGas',
          error: error,
          stackTrace: stackTrace,
          fallbackValue: defaultFallback,
          gasPrice: gasPrice.getInWei,
          baseFeePerGas: baseFeePerGas.getInWei,
        );
        maxPriorityFeePerGas = onError(context) ?? defaultFallback;
      } else {
        maxPriorityFeePerGas = defaultFallback;
      }
    }
    if (maxPriorityFeePerGas != null) {
      maxFeePerGas = baseFeePerGas.getInWei * BigInt.two + maxPriorityFeePerGas;
    }
  }

  return FeeData(gasPrice.getInWei, maxFeePerGas, maxPriorityFeePerGas);
}

/// Context information provided to error callbacks.
class ErrorContext {
  /// The operation that failed (e.g., 'eth_maxPriorityFeePerGas').
  final String operation;

  /// The original error that occurred.
  final dynamic error;

  /// The stack trace when the error occurred.
  final StackTrace stackTrace;

  /// The default fallback value that would be used.
  final BigInt? fallbackValue;

  /// Current gas price in wei.
  final BigInt gasPrice;

  /// Current base fee per gas in wei (for EIP-1559 networks).
  final BigInt? baseFeePerGas;

  ErrorContext({required this.operation, required this.error, required this.stackTrace, this.fallbackValue, required this.gasPrice, this.baseFeePerGas});

  @override
  String toString() =>
      'ErrorContext(operation: $operation, error: $error, fallbackValue: $fallbackValue, gasPrice: $gasPrice, baseFeePerGas: $baseFeePerGas, stackTrace: $stackTrace)';
}

/// Calculates a fallback priority fee when eth_maxPriorityFeePerGas is not supported.
///
/// Strategy:
/// 1. First try zero priority fee (many networks like Arbitrum, zkSync use this)
/// 2. If that seems too low, use 2.5% of gas price with minimum 0.5 gwei
/// 3. Cap at maximum 5 gwei to prevent excessive fees
// BigInt _calculateFallbackPriorityFee(BigInt gasPriceWei) {
//   // For very low gas price networks, use zero priority fee
//   if (gasPriceWei <= BigInt.from(2e9)) {
//     // <= 2 gwei
//     return BigInt.zero;
//   }

//   // Calculate 2.5% of gas price
//   final dynamicFee = gasPriceWei * BigInt.from(25) ~/ BigInt.from(1000);

//   // Minimum 0.5 gwei, maximum 5 gwei
//   final minFee = BigInt.from(5e8); // 0.5 gwei
//   final maxFee = BigInt.from(5e9); // 5 gwei

//   if (dynamicFee < minFee) return minFee;
//   if (dynamicFee > maxFee) return maxFee;

//   return dynamicFee;
// }
