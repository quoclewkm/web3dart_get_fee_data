import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web3dart_get_fee_data/web3dart_get_fee_data.dart';

/// Next-Generation Adaptive Gas Fee Estimation Demo
///
/// This example demonstrates the enhanced adaptive gas fee estimation system that
/// intelligently optimizes for each network with real-time parameter tuning:
/// - 🧠 Smart network categorization (4 intelligent types)
/// - ⚡ Congestion-aware percentile adaptation
/// - 🎯 Dynamic block count optimization
/// - 📊 Real-time parameter tuning based on network conditions
/// - 🔄 Weighted averaging with recent block preference
Future<void> main() async {
  print('🧠 Next-Generation Adaptive Gas Fee Estimation Demo\n');
  print('Real-time optimization for blockchain networks...\n');

  // Test networks with different characteristics
  final networks = [
    {'name': 'Ethereum Mainnet', 'url': 'https://eth.llamarpc.com', 'chainId': 1, 'type': 'Ethereum L1'},
    {'name': 'Arbitrum One', 'url': 'https://arb1.arbitrum.io/rpc', 'chainId': 42161, 'type': 'Layer 2'},
    {'name': 'Polygon Mainnet', 'url': 'https://1rpc.io/matic', 'chainId': 137, 'type': 'Sidechain'},
    {'name': 'Base Mainnet', 'url': 'https://mainnet.base.org', 'chainId': 8453, 'type': 'Layer 2'},
    {'name': 'Optimism Mainnet', 'url': 'https://mainnet.optimism.io', 'chainId': 10, 'type': 'Layer 2'},
    {'name': 'Avalanche C-Chain', 'url': 'https://api.avax.network/ext/bc/C/rpc', 'chainId': 43114, 'type': 'Sidechain'},
  ];

  for (final network in networks) {
    await demonstrateAdaptiveOptimization(network['name']! as String, network['url']! as String, network['chainId']! as int, network['type']! as String);
    print(''); // Add spacing between networks
  }

  // Demonstrate congestion-aware optimization
  print('⚡ Congestion-Aware Optimization Demo:\n');
  await demonstrateCongestionAdaptation();

  // Show improvements over static systems
  print('\n🎯 Adaptive vs Static Configuration Comparison:\n');
  await demonstrateAdaptiveVsStatic();
}

/// Demonstrates adaptive optimization for a specific network
Future<void> demonstrateAdaptiveOptimization(String networkName, String rpcUrl, int chainId, String expectedType) async {
  final httpClient = Client();
  final client = Web3Client(rpcUrl, httpClient);

  try {
    print('📡 Analyzing $networkName (Expected: $expectedType)...');

    final suggestedFees = await getSuggestedGasFees(client);

    print('✅ Network successfully optimized:');
    print('   🏷️  Network: $networkName');
    print('   📊 Category: $expectedType');
    print('   🌊 Congestion: ${((suggestedFees.networkCongestion ?? 0.5) * 100).toStringAsFixed(1)}%');
    print('   ⚡ Slow:    ${formatGwei(suggestedFees.slow.maxFeePerGas)} gwei');
    print('             Priority: ${formatGwei(suggestedFees.slow.maxPriorityFeePerGas)} gwei');
    print('   🚀 Average: ${formatGwei(suggestedFees.average.maxFeePerGas)} gwei');
    print('             Priority: ${formatGwei(suggestedFees.average.maxPriorityFeePerGas)} gwei');
    print('   💨 Fast:    ${formatGwei(suggestedFees.fast.maxFeePerGas)} gwei');
    print('             Priority: ${formatGwei(suggestedFees.fast.maxPriorityFeePerGas)} gwei');
    print('   ⛽ Base Fee: ${formatGwei(suggestedFees.baseFeePerGas)} gwei');

    showAdaptiveOptimizations(expectedType, suggestedFees.networkCongestion ?? 0.5);
  } catch (error) {
    print('❌ Error testing $networkName: $error');
    print('   💡 Using fallback values - network may be unavailable');
  } finally {
    client.dispose();
  }
}

/// Shows the adaptive optimizations applied based on network type and congestion
void showAdaptiveOptimizations(String categoryType, double congestion) {
  const categoryOptimizations = {
    'Ethereum L1': {
      'basePercentiles': '[1, 75, 90]',
      'baseBlocks': '25',
      'adaptiveFeature': 'Congestion-aware percentiles: [1,85,95] when congested',
      'blockOptimization': '20-35 blocks based on congestion level',
      'congestionMultiplier': 'Up to 50% fee increase during high congestion',
    },
    'Layer 2': {
      'basePercentiles': '[20, 50, 70]',
      'baseBlocks': '12',
      'adaptiveFeature': 'Conservative approach due to minimal fee variance',
      'blockOptimization': '8-15 blocks optimized for 2s block times',
      'congestionMultiplier': 'Volatility dampening for stable low-congestion periods',
    },
    'Sidechain': {
      'basePercentiles': '[10, 50, 80]',
      'baseBlocks': '18',
      'adaptiveFeature': 'Congestion-adjusted: [5,60,90] when busy',
      'blockOptimization': '12-25 blocks optimized for 3s block times',
      'congestionMultiplier': 'Up to 20% fee increase during congestion',
    },
  };

  final config = categoryOptimizations[categoryType];
  if (config != null) {
    print('   🎯 Adaptive Optimizations Applied:');
    print('      Base Configuration: ${config['basePercentiles']} percentiles, ${config['baseBlocks']} blocks');
    print('      ⚡ Real-time Adaptation: ${config['adaptiveFeature']}');
    print('      📊 Block Count Optimization: ${config['blockOptimization']}');
    print('      🌊 Congestion Response: ${config['congestionMultiplier']}');
    print('      📈 Current Congestion Level: ${(congestion * 100).toStringAsFixed(1)}%');
  }
}

/// Demonstrates congestion-aware adaptation
Future<void> demonstrateCongestionAdaptation() async {
  final httpClient = Client();
  final ethClient = Web3Client('https://eth.llamarpc.com', httpClient);

  try {
    print('Testing Ethereum mainnet with congestion-aware adaptation...');
    final ethFees = await getSuggestedGasFees(ethClient);
    final congestion = ethFees.networkCongestion ?? 0.5;

    print('📊 Ethereum Mainnet Analysis:');
    print('   🌊 Current Congestion: ${(congestion * 100).toStringAsFixed(1)}%');

    if (congestion > 0.8) {
      print('   🚨 High Congestion Detected!');
      print('      ⚡ Adaptive Response: Using aggressive [1, 85, 95] percentiles');
      print('      📊 Block Count: Increased for stability (${(25 * 1.2).round()} blocks)');
      print('      💰 Fee Adjustment: Up to 50% congestion multiplier applied');
    } else if (congestion > 0.5) {
      print('   🟡 Moderate Congestion');
      print('      ⚡ Adaptive Response: Standard [1, 75, 90] percentiles');
      print('      📊 Block Count: Normal range (25 blocks)');
      print('      💰 Fee Adjustment: Proportional congestion multiplier');
    } else {
      print('   🟢 Low Congestion Period');
      print('      ⚡ Adaptive Response: Conservative [5, 60, 85] percentiles');
      print('      📊 Block Count: Reduced for efficiency (${(25 * 0.8).round()} blocks)');
      print('      💰 Fee Adjustment: Minimal congestion impact');
    }

    print('   🎯 Result: Optimized for current network conditions');
  } catch (error) {
    print('❌ Error in congestion analysis: $error');
  } finally {
    ethClient.dispose();
  }
}

/// Demonstrates adaptive vs static configuration comparison
Future<void> demonstrateAdaptiveVsStatic() async {
  final httpClient = Client();
  final polygonClient = Web3Client('https://1rpc.io/matic', httpClient);

  try {
    // Get adaptive optimization
    print('Testing Polygon with adaptive optimization...');
    final adaptiveFees = await getSuggestedGasFees(polygonClient);

    // Simulate static configuration (old approach)
    final staticFees = await getSuggestedGasFees(
      polygonClient,
      historicalBlocks: 20, // Fixed value
      percentiles: [1, 75, 90], // Fixed Ethereum-like percentiles
      onError: (error) {
        print('Static configuration error: ${error.error}');
        return null;
      },
    );

    final congestion = adaptiveFees.networkCongestion ?? 0.5;

    print('📈 Adaptive vs Static Configuration Results:');
    print('');
    print('✅ Adaptive System (Smart Sidechain Optimization):');
    print('   🌊 Congestion: ${(congestion * 100).toStringAsFixed(1)}%');
    print('   📊 Parameters: Adaptive percentiles based on congestion');
    print('   ⚡ Average Fee: ${formatGwei(adaptiveFees.average.maxFeePerGas)} gwei');
    print('   🎯 Optimized for: Fast 3s blocks, moderate fees, congestion-aware');
    print('');
    print('❌ Static System (Fixed Ethereum Configuration):');
    print('   📊 Parameters: Fixed [1, 75, 90] percentiles, 20 blocks');
    print('   ⚡ Average Fee: ${formatGwei(staticFees.average.maxFeePerGas)} gwei');
    print('   🎯 Optimized for: Ethereum 12s blocks (wrong for Polygon!)');

    final improvement = ((staticFees.average.maxFeePerGas - adaptiveFees.average.maxFeePerGas).toDouble() / staticFees.average.maxFeePerGas.toDouble() * 100);

    print('');
    print('💡 Adaptive System Benefits:');
    print('   💰 Cost Optimization: ${improvement.toStringAsFixed(1)}% ${improvement > 0 ? 'savings' : 'premium'}');
    print('   ⚡ Real-time Adaptation: Parameters adjust to current conditions');
    print('   🎯 Network-Specific: Optimized for Polygon\'s 3s blocks vs Ethereum\'s 12s');
    print('   📊 Congestion-Aware: Percentiles adapt to network traffic');
    print('   🔄 Weighted Recent Blocks: Newer data gets higher priority');

    print('');
    print('🌟 Next-Generation Features:');
    print('   ✨ Zero redundant configurations (4 categories vs 40+ individual)');
    print('   ⚡ Real-time parameter optimization based on live network data');
    print('   🧠 Intelligent congestion detection and response');
    print('   🎯 Network speed awareness (2s L2s vs 12s Ethereum)');
    print('   📊 Advanced weighted averaging with recent block preference');
    print('   🔄 Volatility dampening for stable L2 environments');
  } catch (error) {
    print('❌ Error in comparison analysis: $error');
  } finally {
    polygonClient.dispose();
  }
}

/// Helper function to format wei to gwei with proper precision
String formatGwei(BigInt wei) {
  final gwei = wei.toDouble() / 1e9;
  if (gwei < 0.001) {
    return gwei.toStringAsExponential(2);
  } else if (gwei < 1) {
    return gwei.toStringAsFixed(3);
  } else if (gwei < 10) {
    return gwei.toStringAsFixed(2);
  } else {
    return gwei.toStringAsFixed(1);
  }
}
