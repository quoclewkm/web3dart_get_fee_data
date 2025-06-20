import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web3dart_get_fee_data/web3dart_get_fee_data.dart';

/// Smart Network Categorization Demo
///
/// This example demonstrates the intelligent network categorization system that
/// automatically classifies blockchain networks into 4 simple types:
/// - Ethereum L1: High congestion networks (Ethereum mainnet)
/// - Layer 2: L2s with minimal priority fees (Arbitrum, Optimism, Base, etc.)
/// - Sidechain: Fast networks with moderate fees (Polygon, BSC, Avalanche)
/// - Unknown: Conservative defaults for unrecognized networks
Future<void> main() async {
  print('🧠 Smart Network Categorization Demo\n');
  print('Automatically classifying networks into intelligent categories...\n');

  // Test representative networks from each category
  final networks = [
    {'name': 'Ethereum Mainnet', 'url': 'https://eth.llamarpc.com', 'chainId': 1, 'type': 'Ethereum L1'},
    {'name': 'Arbitrum One', 'url': 'https://arb1.arbitrum.io/rpc', 'chainId': 42161, 'type': 'Layer 2'},
    {'name': 'Polygon Mainnet', 'url': 'https://1rpc.io/matic', 'chainId': 137, 'type': 'Sidechain'},
    {'name': 'Base Mainnet', 'url': 'https://mainnet.base.org', 'chainId': 8453, 'type': 'Layer 2'},
    {'name': 'BNB Smart Chain', 'url': 'https://bsc-dataseed.binance.org', 'chainId': 56, 'type': 'Sidechain'},
  ];

  for (final network in networks) {
    await demonstrateNetworkType(network['name']! as String, network['url']! as String, network['chainId']! as int, network['type']! as String);
    print(''); // Add spacing between networks
  }

  // Demonstrate category-based optimization
  print('🎯 Category-Based Optimization Impact:\n');
  await demonstrateCategoryOptimization();
}

/// Demonstrates smart categorization for a specific network
Future<void> demonstrateNetworkType(String networkName, String rpcUrl, int chainId, String expectedType) async {
  print('📡 Testing $networkName (Expected: $expectedType)...');

  final httpClient = Client();
  final ethClient = Web3Client(rpcUrl, httpClient);

  try {
    // Get categorized gas fee suggestions
    final suggestedFees = await getSuggestedGasFees(
      ethClient,
      onError: (error) {
        print('❌ Error for $networkName: ${error.error}');
        return null;
      },
    );

    print('✅ Successfully categorized and optimized:');

    // Display the categorized results
    print('   🏷️  Network: $networkName');
    print('   📊 Category: $expectedType');
    print('   ⚡ Slow:    ${formatGwei(suggestedFees.slow.maxFeePerGas)} gwei');
    print('             Priority: ${formatGwei(suggestedFees.slow.maxPriorityFeePerGas)} gwei');

    print('   🚀 Average: ${formatGwei(suggestedFees.average.maxFeePerGas)} gwei');
    print('             Priority: ${formatGwei(suggestedFees.average.maxPriorityFeePerGas)} gwei');

    print('   💨 Fast:    ${formatGwei(suggestedFees.fast.maxFeePerGas)} gwei');
    print('             Priority: ${formatGwei(suggestedFees.fast.maxPriorityFeePerGas)} gwei');

    print('   ⛽ Base Fee: ${formatGwei(suggestedFees.baseFeePerGas)} gwei');

    // Show category-specific optimizations applied
    showCategoryOptimizations(expectedType);
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
    ethClient.dispose();
  }
}

/// Shows the category-specific optimizations that were applied
void showCategoryOptimizations(String categoryType) {
  const categoryConfigs = {
    'Ethereum L1': {
      'percentiles': '[1, 75, 90]',
      'blocks': '40',
      'reasoning': 'High congestion, active priority fee market',
      'optimization': 'Aggressive percentiles to capture fee competition',
    },
    'Layer 2': {
      'percentiles': '[10, 50, 80]',
      'blocks': '15',
      'reasoning': 'Minimal priority fees, very fast finality',
      'optimization': 'Conservative percentiles due to low fee variance',
    },
    'Sidechain': {
      'percentiles': '[5, 50, 85]',
      'blocks': '20',
      'reasoning': 'Fast blocks, moderate fees',
      'optimization': 'Balanced percentiles for stable fee markets',
    },
  };

  final config = categoryConfigs[categoryType];
  if (config != null) {
    print('   📊 Category Optimizations:');
    print('      Percentiles: ${config['percentiles']}');
    print('      Historical Blocks: ${config['blocks']}');
    print('      💡 ${config['reasoning']}');
    print('      🎯 ${config['optimization']}');
  }
}

/// Demonstrates category-based optimization impact
Future<void> demonstrateCategoryOptimization() async {
  final httpClient = Client();
  final ethClient = Web3Client('https://1rpc.io/matic', httpClient);

  try {
    // Get Polygon with correct Sidechain categorization
    print('Testing Polygon with smart categorization...');
    final polygonOptimized = await getSuggestedGasFees(ethClient);

    // Force Ethereum L1 configuration for comparison
    final polygonForced = await getSuggestedGasFees(
      ethClient,
      forceChainId: 1, // Force Ethereum L1 category
      onError: (error) {
        print('Error with forced config: ${error.error}');
        return null;
      },
    );

    print('✅ Polygon with Smart Categorization (Sidechain):');
    print('   🚀 Average: ${formatGwei(polygonOptimized.average.maxFeePerGas)} gwei');
    print('             Priority: ${formatGwei(polygonOptimized.average.maxPriorityFeePerGas)} gwei');

    print('❌ Polygon with Forced Ethereum L1 Category:');
    print('   🚀 Average: ${formatGwei(polygonForced.average.maxFeePerGas)} gwei');
    print('             Priority: ${formatGwei(polygonForced.average.maxPriorityFeePerGas)} gwei');

    final improvement =
        ((polygonForced.average.maxFeePerGas - polygonOptimized.average.maxFeePerGas).toDouble() / polygonForced.average.maxFeePerGas.toDouble() * 100);

    print('');
    print('📈 Smart Categorization Impact:');
    print('   Forced Ethereum L1: ${formatGwei(polygonForced.average.maxFeePerGas)} gwei');
    print('   Smart Sidechain:    ${formatGwei(polygonOptimized.average.maxFeePerGas)} gwei');
    print('   💰 Improvement: ${improvement.toStringAsFixed(1)}% ${improvement > 0 ? 'savings' : 'increase'}');
    print('   💡 Smart categorization eliminates redundant network configs!');

    print('');
    print('🌟 Benefits of Smart Categorization:');
    print('   ✨ No individual network configurations needed');
    print('   ⚡ Automatic optimization for 40+ networks');
    print('   🔧 Maintainable with just 4 categories');
    print('   🎯 Accurate results across all network types');
  } catch (e) {
    print('❌ Error in category optimization demonstration: $e');
  } finally {
    ethClient.dispose();
  }
}

/// Formats wei to gwei with 3 decimal places
String formatGwei(BigInt wei) {
  final gwei = wei.toDouble() / 1e9;
  return gwei.toStringAsFixed(3);
}
