import 'dart:io';

import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web3dart_get_fee_data/web3dart_get_fee_data.dart';

/// Enhanced example demonstrating the MetaSwap-style suggested gas fees
///
/// This example shows how to use the enhanced EIP-1559 gas fee estimation
/// functionality that includes network congestion analysis, fee trends,
/// and wait time estimates similar to MetaSwap's gas API.
Future<void> main() async {
  // Initialize Web3 client
  final client = Web3Client('https://1rpc.io/matic', Client());

  try {
    print('🔍 Fetching current gas fee suggestions...\n');

    // Get basic suggested gas fees (current default percentiles)
    final suggestedFees = await getSuggestedGasFees(
      client,
      historicalBlocks: 20,
      onError: (error) {
        print('❌ Error fetching gas fees: $error');
        return null;
      },
    );

    print('💰 Current Default Gas Fee Suggestions (Percentiles [1, 75, 90]):');
    print('=================================================================');
    print('Slow:    ${formatGwei(suggestedFees.slow.maxFeePerGas)} gwei');
    print('         Priority: ${formatGwei(suggestedFees.slow.maxPriorityFeePerGas)} gwei');

    print('Average: ${formatGwei(suggestedFees.average.maxFeePerGas)} gwei');
    print('         Priority: ${formatGwei(suggestedFees.average.maxPriorityFeePerGas)} gwei');

    print('Fast:    ${formatGwei(suggestedFees.fast.maxFeePerGas)} gwei');
    print('         Priority: ${formatGwei(suggestedFees.fast.maxPriorityFeePerGas)} gwei');

    print('\n⛽ Base Fee: ${formatGwei(suggestedFees.baseFeePerGas)} gwei');

    // Test the preferred configuration [1, 75, X] with different fast percentiles
    print('\n🎯 Testing Preferred Configuration [1, 75, X] - Finding Optimal Fast:');
    print('====================================================================');

    final preferredAverage = await getSuggestedGasFees(
      client,
      historicalBlocks: 20,
      percentiles: [1, 75, 95], // User's preferred: slow=1, average=75
      onError: (error) {
        print('❌ Error fetching preferred config: $error');
        return null;
      },
    );

    print('Preferred Configuration [1, 75, 95]:');
    print('Slow:    ${formatGwei(preferredAverage.slow.maxFeePerGas)} gwei (1st percentile)');
    print('Average: ${formatGwei(preferredAverage.average.maxFeePerGas)} gwei (75th percentile)');
    print('Fast:    ${formatGwei(preferredAverage.fast.maxFeePerGas)} gwei (95th percentile)');

    // Test different fast percentiles with [1, 75, X]
    print('\n🧪 Testing Different Fast Percentiles with [1, 75, X]:');
    print('======================================================');

    final fastPercentileOptions = [85, 90, 95, 98, 99];
    final fastResults = <int, Map<String, dynamic>>{};

    for (final fastPercentile in fastPercentileOptions) {
      try {
        final testFees = await getSuggestedGasFees(client, historicalBlocks: 20, percentiles: [1, 75, fastPercentile]);

        final fastFeeGwei = testFees.fast.maxFeePerGas / BigInt.from(1e9);
        final fastPriorityGwei = testFees.fast.maxPriorityFeePerGas / BigInt.from(1e9);

        fastResults[fastPercentile] = {
          'maxFee': testFees.fast.maxFeePerGas,
          'priority': testFees.fast.maxPriorityFeePerGas,
          'maxFeeGwei': fastFeeGwei,
          'priorityGwei': fastPriorityGwei,
        };

        print('Fast ${fastPercentile}th percentile: ${fastFeeGwei.toStringAsFixed(3)} gwei (Priority: ${fastPriorityGwei.toStringAsFixed(3)} gwei)');
      } catch (e) {
        print('Fast ${fastPercentile}th percentile: Error - $e');
      }
    }

    // Analyze the fast percentile options
    print('\n📊 Analysis of Fast Percentile Options:');
    print('=======================================');

    if (fastResults.isNotEmpty) {
      // Compare ratios between average and fast
      final avgFee = preferredAverage.average.maxFeePerGas;

      for (final entry in fastResults.entries) {
        final percentile = entry.key;
        final fastFee = entry.value['maxFee'] as BigInt;
        final ratio = (fastFee.toDouble() / avgFee.toDouble());
        final multiplier = ratio.toStringAsFixed(2);

        print('${percentile}th percentile: ${multiplier}x average fee');
      }
    }

    // Compare with MetaSwap-style ratios
    print('\n📈 Recommendations for Fast Percentile:');
    print('======================================');
    print('Based on MetaSwap methodology and typical fast/average ratios:');
    print('');
    print('• 90th percentile: Conservative fast option (1.5-2x average)');
    print('• 95th percentile: Balanced fast option (2-3x average) ← RECOMMENDED');
    print('• 98th percentile: Aggressive fast option (3-5x average)');
    print('• 99th percentile: Very aggressive fast option (5x+ average)');
    print('');
    print('💡 For MetaSwap-like behavior, 95th percentile typically works best');
    print('   as it provides good speed without being overly expensive.');

    // Show comparison with new default vs test config
    print('\n📋 Comparison: [1, 75, 95] vs New Default [1, 75, 90]:');
    print('====================================================');

    final avgIncrease =
        ((preferredAverage.average.maxFeePerGas - suggestedFees.average.maxFeePerGas).toDouble() / suggestedFees.average.maxFeePerGas.toDouble() * 100);
    final fastIncrease = ((preferredAverage.fast.maxFeePerGas - suggestedFees.fast.maxFeePerGas).toDouble() / suggestedFees.fast.maxFeePerGas.toDouble() * 100);

    print('Average: ${avgIncrease > 0 ? "+" : ""}${avgIncrease.toStringAsFixed(1)}% (75th vs 75th percentile - same)');
    print('Fast:    ${fastIncrease > 0 ? "+" : ""}${fastIncrease.toStringAsFixed(1)}% (95th vs 90th percentile)');

    print('\n✅ FINAL RECOMMENDATION: Use percentiles [1, 75, 90] (NEW DEFAULT!)');
    print('   • Slow (1st): Excellent for cost optimization');
    print('   • Average (75th): Better represents typical network conditions');
    print('   • Fast (90th): Good speed/cost balance, closer to MetaSwap');
    print('   • Note: 95th percentile available if you need more aggressive fast tier');
  } catch (e) {
    print('❌ Error fetching gas fees: $e');
    exit(1);
  } finally {
    client.dispose();
  }
}

String formatGwei(BigInt wei) {
  final gwei = wei / BigInt.from(1e9);
  return gwei.toStringAsFixed(3);
}

// Removed old helper functions that referenced enhanced analytics features.
// Enhanced analytics are now available in lib/src/fee_analytics.dart
// if you need network congestion, trends, and wait time estimates.
