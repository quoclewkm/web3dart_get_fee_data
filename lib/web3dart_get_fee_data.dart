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
///
/// ## Quick Start
///
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
library;

export 'src/fee_data_model.dart';
export 'src/web3dart_get_fee_data_base.dart';

// TODO: Export any libraries intended for clients of this package.
