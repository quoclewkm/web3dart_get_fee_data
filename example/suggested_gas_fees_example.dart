import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web3dart_get_fee_data/web3dart_get_fee_data.dart';

/// Example demonstrating the suggested gas fees feature
///
/// This example shows how to use the EIP-1559 gas fee estimation
/// functionality that provides slow, average, and fast fee tiers.
void main() async {
  // Create Web3 client
  final httpClient = Client();
  final client = Web3Client('https://eth.llamarpc.com', httpClient);

  try {
    print('🔍 Fetching suggested gas fees...\n');

    // Get suggested gas fees with default settings (20 historical blocks)
    final suggestedFees = await getSuggestedGasFees(client);

    print('📊 EIP-1559 Gas Fee Estimates:');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // Convert wei to gwei for readability
    final baseFeeGwei = _weiToGwei(suggestedFees.baseFeePerGas);
    print('⚡ Base Fee: ${baseFeeGwei.toStringAsFixed(3)} gwei');
    print('');

    // Display fee tiers
    _printFeeTier('🐌 SLOW', suggestedFees.slow, 'Cheaper, slower confirmation');
    _printFeeTier('🚶 AVERAGE', suggestedFees.average, 'Balanced cost and speed');
    _printFeeTier('🚀 FAST', suggestedFees.fast, 'More expensive, faster confirmation');

    print('\n💡 Tips:');
    print('• Use SLOW for non-urgent transactions');
    print('• Use AVERAGE for typical transactions');
    print('• Use FAST when you need quick confirmation');
    print('• Max fee includes base fee + priority fee');

    // Example with custom settings
    print('\n🔧 Custom Settings Example:');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final customFees = await getSuggestedGasFees(
      client,
      historicalBlocks: 10, // Analyze fewer blocks for faster response
      onError: (context) {
        print('⚠️  Error in ${context.operation}: ${context.error}');
        return context.fallbackValue; // Use default fallback
      },
    );

    print('Using 10 historical blocks instead of 20:');
    _printFeeTier('🚶 AVERAGE', customFees.average, 'Custom analysis');

    // Example: Setting transaction parameters
    print('\n📝 Transaction Example:');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final gasLimit = 21000; // Standard ETH transfer

    // Calculate total transaction costs
    final slowCost = suggestedFees.slow.maxFeePerGas * BigInt.from(gasLimit);
    final averageCost = suggestedFees.average.maxFeePerGas * BigInt.from(gasLimit);
    final fastCost = suggestedFees.fast.maxFeePerGas * BigInt.from(gasLimit);

    print('For a standard ETH transfer (21,000 gas):');
    print('• Slow:    ${_weiToEth(slowCost).toStringAsFixed(6)} ETH');
    print('• Average: ${_weiToEth(averageCost).toStringAsFixed(6)} ETH');
    print('• Fast:    ${_weiToEth(fastCost).toStringAsFixed(6)} ETH');

    // Show how to use these values in a transaction
    print('\n🔗 Usage in Transaction:');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('''
// Use the average tier for your transaction
final transaction = Transaction.callContract(
  contract: contract,
  function: function,
  parameters: parameters,
  maxFeePerGas: EtherAmount.fromBigInt(EtherUnit.wei, ${suggestedFees.average.maxFeePerGas}),
  maxPriorityFeePerGas: EtherAmount.fromBigInt(EtherUnit.wei, ${suggestedFees.average.maxPriorityFeePerGas}),
);
''');
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    client.dispose();
  }
}

void _printFeeTier(String name, GasFeeEstimate estimate, String description) {
  final priorityFeeGwei = _weiToGwei(estimate.maxPriorityFeePerGas);
  final maxFeeGwei = _weiToGwei(estimate.maxFeePerGas);

  print('$name ($description)');
  print('  Priority Fee: ${priorityFeeGwei.toStringAsFixed(3)} gwei');
  print('  Max Fee:      ${maxFeeGwei.toStringAsFixed(3)} gwei');
  print('');
}

double _weiToGwei(BigInt wei) {
  return wei.toInt() / 1e9;
}

double _weiToEth(BigInt wei) {
  return wei.toInt() / 1e18;
}
