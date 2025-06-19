/// A comprehensive Dart package for retrieving Ethereum fee data.
///
/// This package provides functionality to get current gas prices and fee data
/// from Ethereum networks, including full support for EIP-1559 transactions.
///
/// ## Features
///
/// - **EIP-1559 Support**: Get `maxFeePerGas` and `maxPriorityFeePerGas` for modern transactions
/// - **Legacy Compatibility**: Fallback to traditional `gasPrice` for older networks
/// - **Automatic Detection**: Seamlessly handles both EIP-1559 and legacy networks
/// - **Custom Error Handling**: Optional `onError` callback for custom fallback strategies
/// - **ethers.js Compatible**: API designed to match ethers.js `getFeeData()` behavior
/// - **Suggested Gas Fees**: Get slow, average, and fast fee estimates using EIP-1559 methodology
///
/// ## Quick Start
///
/// ### Basic Fee Data
/// ```dart
/// import 'package:web3dart/web3dart.dart';
/// import 'package:web3dart_get_fee_data/web3dart_get_fee_data.dart';
/// import 'package:http/http.dart';
///
/// final client = Web3Client('https://eth.llamarpc.com', Client());
/// final feeData = await getFeeData(client);
///
/// print('Gas Price: ${feeData.gasPrice} wei');
/// if (feeData.maxFeePerGas != null) {
///   print('Max Fee Per Gas: ${feeData.maxFeePerGas} wei');
///   print('Max Priority Fee: ${feeData.maxPriorityFeePerGas} wei');
/// }
/// ```
///
/// ### Suggested Gas Fees (EIP-1559)
/// ```dart
/// final suggestedFees = await getSuggestedGasFees(client);
///
/// print('Slow: ${suggestedFees.slow.maxFeePerGas} wei');
/// print('Average: ${suggestedFees.average.maxFeePerGas} wei');
/// print('Fast: ${suggestedFees.fast.maxFeePerGas} wei');
/// print('Base Fee: ${suggestedFees.baseFeePerGas} wei');
/// ```
///
/// ## Custom Error Handling
///
/// ```dart
/// final feeData = await getFeeData(
///   client,
///   onError: (context) {
///     print('Failed ${context.operation}: ${context.error}');
///     print('Stack trace: ${context.stackTrace}');
///     // Return custom fallback or null to use default
///     return BigInt.from(2e9); // 2 gwei
///   }
/// );
/// ```
///
/// ## Suggested Gas Fees Methodology
///
/// The `getSuggestedGasFees` function implements the EIP-1559 fee estimation
/// methodology described in [Alchemy's documentation](https://www.alchemy.com/docs/how-to-build-a-gas-fee-estimator-using-eip-1559):
///
/// 1. **Historical Analysis**: Analyzes recent blocks using `eth_feeHistory`
/// 2. **Percentile Calculation**: Uses 1st, 50th, and 99th percentiles of priority fees
/// 3. **Speed Tiers**: Provides three options:
///    - `slow`: Conservative (1st percentile) - cheaper but slower
///    - `average`: Standard (50th percentile) - balanced cost and speed
///    - `fast`: Aggressive (99th percentile) - more expensive but faster
/// 4. **Base Fee Addition**: Combines priority fees with current base fee
///
/// ### Custom Parameters
/// ```dart
/// final suggestedFees = await getSuggestedGasFees(
///   client,
///   historicalBlocks: 10, // Analyze fewer blocks for faster response
///   onError: (context) {
///     print('Error in ${context.operation}: ${context.error}');
///     return context.fallbackValue; // Use default fallback
///   }
/// );
/// ```
library;

export 'src/fee_data_model.dart';
export 'src/suggested_gas_fees.dart';
export 'src/web3dart_get_fee_data_base.dart';

// TODO: Export any libraries intended for clients of this package.
