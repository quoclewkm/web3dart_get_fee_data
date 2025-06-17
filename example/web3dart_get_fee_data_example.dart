/// Example demonstrating how to use the web3dart_get_fee_data package
/// to retrieve current Ethereum fee data from various networks.
library;

import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web3dart_get_fee_data/web3dart_get_fee_data.dart';

void main() async {
  print('🔗 Web3Dart Get Fee Data - Example\n');

  // Test multiple networks to demonstrate compatibility
  final networks = [
    {'name': 'Ethereum Mainnet', 'url': 'https://eth.llamarpc.com'},
    {'name': 'Polygon', 'url': 'https://polygon-rpc.com'},
    // Add more networks as needed
  ];

  for (final network in networks) {
    await demonstrateNetwork(network['name']!, network['url']!);
    print(''); // Add spacing between networks
  }
}

/// Demonstrates fee data retrieval for a specific network
Future<void> demonstrateNetwork(String networkName, String rpcUrl) async {
  print('📡 Testing $networkName...');

  final httpClient = Client();
  final ethClient = Web3Client(rpcUrl, httpClient);

  try {
    // Get the current fee data
    final feeData = await getFeeData(ethClient);

    print('✅ Successfully retrieved fee data:');
    print('   Raw Data: $feeData');

    // Display gas price (always available)
    if (feeData.gasPrice != null) {
      final gasPriceGwei = feeData.gasPrice! ~/ BigInt.from(1000000000);
      print('   💰 Gas Price: ${feeData.gasPrice} wei ($gasPriceGwei gwei)');
    }

    // Check for EIP-1559 support
    if (feeData.maxFeePerGas != null && feeData.maxPriorityFeePerGas != null) {
      print('   🎯 EIP-1559 Support: YES');

      final maxFeeGwei = feeData.maxFeePerGas! ~/ BigInt.from(1000000000);
      final maxPriorityGwei = feeData.maxPriorityFeePerGas! ~/ BigInt.from(1000000000);

      print('   🔥 Max Fee Per Gas: ${feeData.maxFeePerGas} wei ($maxFeeGwei gwei)');
      print('   ⚡ Max Priority Fee: ${feeData.maxPriorityFeePerGas} wei ($maxPriorityGwei gwei)');

      // Show which transaction type to use
      print('   💡 Recommendation: Use EIP-1559 transactions for better fee prediction');
    } else {
      print('   📜 EIP-1559 Support: NO (Legacy network)');
      print('   💡 Recommendation: Use legacy transactions with gasPrice');
    }
  } catch (e) {
    print('❌ Error getting fee data from $networkName:');
    if (e.toString().contains('SocketException')) {
      print('   🌐 Network connectivity issue');
    } else if (e.toString().contains('RPC')) {
      print('   🔧 RPC error: ${e.toString()}');
    } else {
      print('   🐛 Unknown error: $e');
    }
  } finally {
    // Always dispose the client when done
    ethClient.dispose();
  }
}

/// Example of how to use the fee data for creating transactions
void demonstrateTransactionUsage() {
  print('💼 Transaction Usage Examples:\n');

  print('''
  // For EIP-1559 networks:
  if (feeData.maxFeePerGas != null) {
    final transaction = Transaction.callContract(
      contract: deployedContract,
      function: contractFunction,
      parameters: [],
      maxFeePerGas: EtherAmount.fromBigInt(EtherUnit.wei, feeData.maxFeePerGas!),
      maxPriorityFeePerGas: EtherAmount.fromBigInt(EtherUnit.wei, feeData.maxPriorityFeePerGas!),
    );
  }
  
  // For legacy networks:
  else {
    final transaction = Transaction.callContract(
      contract: deployedContract,
      function: contractFunction,
      parameters: [],
      gasPrice: EtherAmount.fromBigInt(EtherUnit.wei, feeData.gasPrice!),
    );
  }
  ''');
}
