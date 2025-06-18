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

  // Demonstrate custom error handling
  print('🎯 Custom Error Handling Examples:\n');
  await demonstrateCustomErrorHandling();
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

/// Demonstrates custom error handling with onError callbacks
Future<void> demonstrateCustomErrorHandling() async {
  final httpClient = Client();
  final ethClient = Web3Client('https://eth.llamarpc.com', httpClient);

  try {
    print('📋 Example 1: Zero Priority Fee Strategy');
    final zeroFeeData = await getFeeData(
      ethClient,
      onError: (context) {
        print('   🔧 Using zero priority fee for ${context.operation}');
        return BigInt.zero;
      },
    );
    print('   ✅ Result: ${zeroFeeData.maxPriorityFeePerGas} wei priority fee\n');

    print('📋 Example 2: Percentage-based Strategy');
    final percentageFeeData = await getFeeData(
      ethClient,
      onError: (context) {
        final customFee = context.gasPrice ~/ BigInt.from(20); // 5% of gas price
        print('   🔧 Using 5% of gas price: $customFee wei');
        return customFee;
      },
    );
    print('   ✅ Result: ${percentageFeeData.maxPriorityFeePerGas} wei priority fee\n');

    print('📋 Example 3: Logging and Default Fallback');
    final loggedFeeData = await getFeeData(
      ethClient,
      onError: (context) {
        print('   📊 Error Context:');
        print('      Operation: ${context.operation}');
        print('      Error: ${context.error}');
        print('      Stack Trace: ${context.stackTrace}');
        print('      Gas Price: ${context.gasPrice} wei');
        print('      Base Fee: ${context.baseFeePerGas} wei');
        print('      Default Fallback: ${context.fallbackValue} wei');
        print('   🔧 Using default fallback');
        return null; // Use default fallback
      },
    );
    print('   ✅ Result: ${loggedFeeData.maxPriorityFeePerGas} wei priority fee\n');

    print('📋 Example 4: High Priority Strategy');
    final highPriorityFeeData = await getFeeData(
      ethClient,
      onError: (context) {
        print('   🔧 Using high priority fee for fast confirmation');
        return BigInt.from(5e9); // 5 gwei
      },
    );
    print('   ✅ Result: ${highPriorityFeeData.maxPriorityFeePerGas} wei priority fee\n');
  } catch (e) {
    print('❌ Error in custom error handling demo: $e');
  } finally {
    ethClient.dispose();
    httpClient.close();
  }

  print('💡 Benefits of onError callback:');
  print('   • Custom fallback strategies per application needs');
  print('   • Detailed error logging and monitoring');
  print('   • Network-specific optimizations');
  print('   • Backward compatibility with existing code');
}
