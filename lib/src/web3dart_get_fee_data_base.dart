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
Future<FeeData> getFeeData(Web3Client client) async {
  final latestBlock = await client.getBlockInformation();
  final gasPrice = await client.getGasPrice();
  final priorityFeeResponse = await client.makeRPCCall('eth_maxPriorityFeePerGas');

  BigInt? maxPriorityFeePerGas;
  BigInt? maxFeePerGas;

  final baseFeePerGas = latestBlock.baseFeePerGas;
  if (baseFeePerGas != null && priorityFeeResponse is String) {
    maxPriorityFeePerGas = BigInt.tryParse(priorityFeeResponse.substring(2), radix: 16) ?? BigInt.from(1_000_000_000);
    maxFeePerGas = (baseFeePerGas.getInWei * BigInt.two) + maxPriorityFeePerGas;
  }

  return FeeData(gasPrice.getInWei, maxFeePerGas, maxPriorityFeePerGas);
}
