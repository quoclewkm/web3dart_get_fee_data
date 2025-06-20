import 'package:web3dart/web3dart.dart';
import 'package:web3dart_get_fee_data/src/fee_data_model.dart';
import 'package:web3dart_get_fee_data/src/web3dart_get_fee_data_base.dart' show ErrorContext;

// Network types for smart categorization
enum NetworkType {
  ethereum, // High congestion L1 (Ethereum mainnet)
  layer2, // L2s with minimal priority fees (Arbitrum, Optimism, Base, etc.)
  sidechain, // Fast sidechains (Polygon, BSC, Avalanche)
  unknown, // Fallback for unrecognized networks
}

// Simplified network configuration based on network types
class NetworkConfig {
  final NetworkType type;
  final String name;
  final List<int> percentiles;
  final int historicalBlocks;
  final int minimumPriorityFeeWei;
  final int defaultSlowPriorityFeeWei;
  final int defaultAveragePriorityFeeWei;
  final int defaultFastPriorityFeeWei;
  final int defaultBaseFeeWei;
  final bool hasActivePriorityFees;

  const NetworkConfig({
    required this.type,
    required this.name,
    required this.percentiles,
    required this.historicalBlocks,
    required this.minimumPriorityFeeWei,
    required this.defaultSlowPriorityFeeWei,
    required this.defaultAveragePriorityFeeWei,
    required this.defaultFastPriorityFeeWei,
    required this.defaultBaseFeeWei,
    required this.hasActivePriorityFees,
  });
}

// Smart network categorization system
class NetworkClassifier {
  // Known L2 networks (minimal priority fees)
  static const Set<int> layer2Networks = {
    10, // Optimism
    42161, // Arbitrum One
    42170, // Arbitrum Nova
    421614, // Arbitrum Sepolia
    8453, // Base
    84532, // Base Sepolia
    324, // zkSync Era
    300, // zkSync Era Sepolia
    59144, // Linea
    59141, // Linea Sepolia
    534352, // Scroll
    534351, // Scroll Sepolia
    1284, // Moonbeam
    1285, // Moonriver
    5000, // Mantle
    81457, // Blast
    288, // Boba
  };

  // Known sidechains (fast blocks, moderate fees)
  static const Set<int> sidechainNetworks = {
    137, // Polygon
    80002, // Polygon Amoy
    56, // BSC
    97, // BSC Testnet
    43114, // Avalanche
    43113, // Avalanche Fuji
    250, // Fantom
    4002, // Fantom Testnet
    25, // Cronos
    100, // Gnosis
    42220, // Celo
    44787, // Celo Alfajores
  };

  // Ethereum mainnet and testnets (high congestion L1)
  static const Set<int> ethereumNetworks = {
    1, // Ethereum Mainnet
    11155111, // Sepolia
    17000, // Holesky
  };

  static NetworkType classifyNetwork(int chainId) {
    if (ethereumNetworks.contains(chainId)) {
      return NetworkType.ethereum;
    }
    if (layer2Networks.contains(chainId)) {
      return NetworkType.layer2;
    }
    if (sidechainNetworks.contains(chainId)) {
      return NetworkType.sidechain;
    }
    return NetworkType.unknown;
  }

  static String getNetworkName(int chainId, NetworkType type) {
    // Special cases for well-known networks
    const networkNames = {
      1: 'Ethereum Mainnet',
      137: 'Polygon Mainnet',
      42161: 'Arbitrum One',
      10: 'Optimism Mainnet',
      8453: 'Base Mainnet',
      56: 'BNB Smart Chain',
      43114: 'Avalanche C-Chain',
    };

    if (networkNames.containsKey(chainId)) {
      return networkNames[chainId]!;
    }

    // Generic names based on type
    switch (type) {
      case NetworkType.ethereum:
        return 'Ethereum Network';
      case NetworkType.layer2:
        return 'Layer 2 Network';
      case NetworkType.sidechain:
        return 'Sidechain Network';
      case NetworkType.unknown:
        return 'Unknown Network';
    }
  }
}

// Optimized configurations for each network type
class NetworkConfigs {
  static const Map<NetworkType, NetworkConfig> configs = {
    // Ethereum L1: High congestion, active priority fee market
    NetworkType.ethereum: NetworkConfig(
      type: NetworkType.ethereum,
      name: 'Ethereum L1',
      percentiles: [1, 75, 90], // Aggressive percentiles for high competition
      historicalBlocks: 20, // More history due to 12s blocks
      minimumPriorityFeeWei: 100000, // 0.0001 gwei
      defaultSlowPriorityFeeWei: 1000000000, // 1 gwei
      defaultAveragePriorityFeeWei: 1500000000, // 1.5 gwei
      defaultFastPriorityFeeWei: 2000000000, // 2 gwei
      defaultBaseFeeWei: 20000000000, // 20 gwei
      hasActivePriorityFees: true,
    ),

    // Layer 2: Minimal priority fees, very fast finality
    NetworkType.layer2: NetworkConfig(
      type: NetworkType.layer2,
      name: 'Layer 2',
      percentiles: [10, 50, 80], // Conservative due to low fee variance
      historicalBlocks: 15, // Fast finality, need less history
      minimumPriorityFeeWei: 1000, // Very low minimum
      defaultSlowPriorityFeeWei: 1000000, // 0.001 gwei
      defaultAveragePriorityFeeWei: 10000000, // 0.01 gwei
      defaultFastPriorityFeeWei: 100000000, // 0.1 gwei
      defaultBaseFeeWei: 100000000, // 0.1 gwei
      hasActivePriorityFees: false,
    ),

    // Sidechains: Fast blocks, moderate fees
    NetworkType.sidechain: NetworkConfig(
      type: NetworkType.sidechain,
      name: 'Sidechain',
      percentiles: [5, 50, 85], // Balanced for fast blocks
      historicalBlocks: 20, // Fast blocks, moderate history
      minimumPriorityFeeWei: 1000000000, // 1 gwei
      defaultSlowPriorityFeeWei: 5000000000, // 5 gwei
      defaultAveragePriorityFeeWei: 10000000000, // 10 gwei
      defaultFastPriorityFeeWei: 20000000000, // 20 gwei
      defaultBaseFeeWei: 10000000000, // 10 gwei
      hasActivePriorityFees: true,
    ),

    // Unknown networks: Conservative defaults
    NetworkType.unknown: NetworkConfig(
      type: NetworkType.unknown,
      name: 'Unknown Network',
      percentiles: [10, 60, 85], // Conservative percentiles
      historicalBlocks: 20,
      minimumPriorityFeeWei: 1000000000, // 1 gwei
      defaultSlowPriorityFeeWei: 2000000000, // 2 gwei
      defaultAveragePriorityFeeWei: 4000000000, // 4 gwei
      defaultFastPriorityFeeWei: 8000000000, // 8 gwei
      defaultBaseFeeWei: 10000000000, // 10 gwei
      hasActivePriorityFees: true,
    ),
  };

  static NetworkConfig getConfigForChainId(int chainId) {
    final networkType = NetworkClassifier.classifyNetwork(chainId);
    return configs[networkType]!;
  }

  static String getNetworkDisplayName(int chainId) {
    final networkType = NetworkClassifier.classifyNetwork(chainId);
    return NetworkClassifier.getNetworkName(chainId, networkType);
  }
}

// Default configuration constants for backward compatibility
/// Default percentiles for slow, average, and fast gas fee tiers.
/// Based on MetaSwap methodology for realistic fee estimates.
const List<int> kDefaultPercentiles = [1, 75, 90];

/// Default number of historical blocks to analyze for fee estimation.
const int kDefaultHistoricalBlocks = 20;

/// Minimum priority fee to ensure transaction inclusion (0.0001 gwei in wei).
/// Prevents zero-fee transactions that might not be processed.
const int kMinimumPriorityFeeWei = 100000; // 1e5 wei = 0.0001 gwei

// Default fallback values when network calls fail
/// Default slow priority fee fallback (1 gwei in wei).
const int kDefaultSlowPriorityFeeWei = 1000000000; // 1e9 wei = 1 gwei

/// Default average priority fee fallback (1.5 gwei in wei).
const int kDefaultAveragePriorityFeeWei = 1500000000; // 1.5e9 wei = 1.5 gwei

/// Default fast priority fee fallback (2 gwei in wei).
const int kDefaultFastPriorityFeeWei = 2000000000; // 2e9 wei = 2 gwei

/// Default base fee fallback (20 gwei in wei).
const int kDefaultBaseFeeWei = 20000000000; // 20e9 wei = 20 gwei

/// Detects the network chain ID from the Web3Client
Future<int?> _detectChainId(Web3Client client) async {
  try {
    final chainIdResponse = await client.makeRPCCall('eth_chainId');
    if (chainIdResponse is String) {
      final cleanChainId = chainIdResponse.startsWith('0x') ? chainIdResponse.substring(2) : chainIdResponse;
      return int.parse(cleanChainId, radix: 16);
    }
  } catch (e) {
    // Fallback: try to get network ID
    try {
      final networkIdResponse = await client.makeRPCCall('net_version');
      if (networkIdResponse is String) {
        return int.tryParse(networkIdResponse);
      }
    } catch (e) {
      // Could not determine network
    }
  }
  return null;
}

/// Retrieves intelligent suggested gas fees with automatic network categorization.
///
/// This function automatically detects and categorizes the blockchain network into one of four types:
/// - **Ethereum L1**: High congestion networks like Ethereum mainnet with active priority fee markets
/// - **Layer 2**: L2 networks like Arbitrum, Optimism, Base with minimal priority fees
/// - **Sidechain**: Fast networks like Polygon, BSC, Avalanche with moderate fees
/// - **Unknown**: Conservative defaults for unrecognized networks
///
/// **Smart Classification:**
/// Networks are automatically classified based on their chain ID, eliminating the need for
/// manual configuration while providing optimized parameters for each network type.
///
/// **Parameters:**
/// - [client]: A connected [Web3Client] instance for the target blockchain network
/// - [historicalBlocks]: Number of historical blocks to analyze (default: auto-detected per network type)
/// - [percentiles]: List of 3 percentiles for slow/average/fast tiers (default: auto-detected per network type)
/// - [forceChainId]: Override automatic chain detection for testing or specific configurations
/// - [onError]: Optional callback for custom error handling. Receives the error context
///   and can return a custom fallback value or rethrow the error.
///
/// **Returns:**
/// A [SuggestedGasFees] object containing three network-optimized fee tiers:
/// - `slow`: Conservative estimate optimized for the detected network type
/// - `average`: Standard estimate based on network-type-specific percentiles
/// - `fast`: Aggressive estimate tailored to network type characteristics
///
/// **Network Type Configurations:**
/// - **Ethereum L1**: [1, 75, 90] percentiles, 40 blocks, active priority fees
/// - **Layer 2**: [10, 50, 80] percentiles, 15 blocks, minimal priority fees
/// - **Sidechain**: [5, 50, 85] percentiles, 20 blocks, moderate priority fees
/// - **Unknown**: [10, 60, 85] percentiles, 20 blocks, conservative defaults
///
/// **Example:**
/// ```dart
/// final client = Web3Client('https://polygon-rpc.com', Client());
/// final suggestedFees = await getSuggestedGasFees(client);
/// // Automatically detects Polygon as "Sidechain" type
///
/// print('Network Type: Sidechain'); // Auto-classified
/// print('Slow: ${suggestedFees.slow.maxFeePerGas} wei');
/// print('Average: ${suggestedFees.average.maxFeePerGas} wei');
/// print('Fast: ${suggestedFees.fast.maxFeePerGas} wei');
/// ```
Future<SuggestedGasFees> getSuggestedGasFees(
  Web3Client client, {
  int? historicalBlocks,
  List<int>? percentiles,
  int? forceChainId,
  BigInt? Function(ErrorContext context)? onError,
}) async {
  late NetworkConfig networkConfig;
  int? detectedChainId;

  try {
    // Detect and classify network
    if (forceChainId != null) {
      detectedChainId = forceChainId;
      networkConfig = NetworkConfigs.getConfigForChainId(forceChainId);
    } else {
      detectedChainId = await _detectChainId(client);
      if (detectedChainId != null) {
        networkConfig = NetworkConfigs.getConfigForChainId(detectedChainId);
      } else {
        networkConfig = NetworkConfigs.configs[NetworkType.unknown]!;
      }
    }

    // Use network-type-specific parameters or user overrides
    final finalHistoricalBlocks = historicalBlocks ?? networkConfig.historicalBlocks;
    final finalPercentiles = percentiles ?? networkConfig.percentiles;

    // Validate percentiles parameter
    if (finalPercentiles.length != 3) {
      throw ArgumentError('Exactly 3 percentiles must be provided (slow, average, fast)');
    }

    if (finalPercentiles.any((p) => p < 1 || p > 99)) {
      throw ArgumentError('Percentiles must be between 1 and 99');
    }

    // Get fee history with network-type-optimized percentiles
    final feeHistoryResponse = await client.makeRPCCall('eth_feeHistory', [
      '0x${finalHistoricalBlocks.toRadixString(16)}', // number of blocks
      'pending', // newest block
      finalPercentiles, // network-type-optimized percentiles
    ]);

    // Get current pending block for base fee
    final pendingBlockResponse = await client.makeRPCCall('eth_getBlockByNumber', ['pending', false]);

    // Parse the responses
    final feeHistory = _parseFeeHistory(feeHistoryResponse, finalHistoricalBlocks);
    final baseFeePerGas = _parseBaseFeeFromBlock(pendingBlockResponse);

    // Calculate average priority fees for each percentile
    final rawSlowPriorityFee = _calculateAveragePriorityFee(feeHistory, 0, networkConfig); // percentiles[0]
    final averagePriorityFee = _calculateAveragePriorityFee(feeHistory, 1, networkConfig); // percentiles[1]
    final fastPriorityFee = _calculateAveragePriorityFee(feeHistory, 2, networkConfig); // percentiles[2]

    // Apply network-type-specific minimum priority fee
    final minPriorityFee = BigInt.from(networkConfig.minimumPriorityFeeWei);
    final slowPriorityFee = rawSlowPriorityFee > minPriorityFee ? rawSlowPriorityFee : minPriorityFee;

    // Calculate max fee per gas (base fee + priority fee)
    final slowMaxFee = baseFeePerGas + slowPriorityFee;
    final averageMaxFee = baseFeePerGas + averagePriorityFee;
    final fastMaxFee = baseFeePerGas + fastPriorityFee;

    return SuggestedGasFees(
      slow: GasFeeEstimate(maxPriorityFeePerGas: slowPriorityFee, maxFeePerGas: slowMaxFee),
      average: GasFeeEstimate(maxPriorityFeePerGas: averagePriorityFee, maxFeePerGas: averageMaxFee),
      fast: GasFeeEstimate(maxPriorityFeePerGas: fastPriorityFee, maxFeePerGas: fastMaxFee),
      baseFeePerGas: baseFeePerGas,
    );
  } catch (error, stackTrace) {
    // Enhanced fallback strategy using network-type-specific constants
    networkConfig = NetworkConfigs.configs[NetworkType.unknown]!;

    final defaultSlowFee = BigInt.from(networkConfig.defaultSlowPriorityFeeWei);
    final defaultAverageFee = BigInt.from(networkConfig.defaultAveragePriorityFeeWei);
    final defaultFastFee = BigInt.from(networkConfig.defaultFastPriorityFeeWei);
    final defaultBaseFee = BigInt.from(networkConfig.defaultBaseFeeWei);

    if (onError != null) {
      final context = ErrorContext(
        operation: 'getSuggestedGasFees',
        error: error,
        stackTrace: stackTrace,
        fallbackValue: defaultAverageFee,
        gasPrice: defaultBaseFee + defaultAverageFee,
        baseFeePerGas: defaultBaseFee,
      );

      final fallbackFee = onError(context);
      if (fallbackFee != null) {
        return SuggestedGasFees(
          slow: GasFeeEstimate(maxPriorityFeePerGas: fallbackFee ~/ BigInt.from(2), maxFeePerGas: defaultBaseFee + (fallbackFee ~/ BigInt.from(2))),
          average: GasFeeEstimate(maxPriorityFeePerGas: fallbackFee, maxFeePerGas: defaultBaseFee + fallbackFee),
          fast: GasFeeEstimate(maxPriorityFeePerGas: fallbackFee * BigInt.from(2), maxFeePerGas: defaultBaseFee + (fallbackFee * BigInt.from(2))),
          baseFeePerGas: defaultBaseFee,
        );
      }
    }

    // Default fallback values using network-type-specific constants
    return SuggestedGasFees(
      slow: GasFeeEstimate(maxPriorityFeePerGas: defaultSlowFee, maxFeePerGas: defaultBaseFee + defaultSlowFee),
      average: GasFeeEstimate(maxPriorityFeePerGas: defaultAverageFee, maxFeePerGas: defaultBaseFee + defaultAverageFee),
      fast: GasFeeEstimate(maxPriorityFeePerGas: defaultFastFee, maxFeePerGas: defaultBaseFee + defaultFastFee),
      baseFeePerGas: defaultBaseFee,
    );
  }
}

/// Parses the fee history response from eth_feeHistory into structured data.
List<HistoricalBlock> _parseFeeHistory(dynamic feeHistory, int expectedBlocks) {
  final Map<String, dynamic> history = feeHistory as Map<String, dynamic>;

  final oldestBlockHex = history['oldestBlock'] as String;
  final cleanOldestBlockHex = oldestBlockHex.startsWith('0x') ? oldestBlockHex.substring(2) : oldestBlockHex;
  final oldestBlock = int.parse(cleanOldestBlockHex, radix: 16);
  final baseFeePerGasHex = history['baseFeePerGas'] as List<dynamic>;
  final gasUsedRatio = history['gasUsedRatio'] as List<dynamic>;
  final reward = history['reward'] as List<dynamic>;

  final blocks = <HistoricalBlock>[];

  // Use the minimum of expected blocks and actual data length to avoid index errors
  final actualBlocks = [baseFeePerGasHex.length, gasUsedRatio.length, reward.length].reduce((a, b) => a < b ? a : b);

  final blocksToProcess = actualBlocks < expectedBlocks ? actualBlocks : expectedBlocks;

  for (int i = 0; i < blocksToProcess; i++) {
    final blockNumber = oldestBlock + i;

    // Handle base fee parsing with proper hex format checking
    final baseFeeHex = baseFeePerGasHex[i] as String;
    final cleanBaseFeeHex = baseFeeHex.startsWith('0x') ? baseFeeHex.substring(2) : baseFeeHex;
    final baseFee = BigInt.parse(cleanBaseFeeHex, radix: 16);

    final gasRatio = (gasUsedRatio[i] as num).toDouble();

    // Handle priority fee parsing with proper hex format checking
    final rewardsList = reward[i] as List<dynamic>;
    final priorityFees = rewardsList.map((hexString) {
      final rewardHex = hexString as String;
      final cleanRewardHex = rewardHex.startsWith('0x') ? rewardHex.substring(2) : rewardHex;
      // Handle edge case where hex might be empty or just '0x'
      if (cleanRewardHex.isEmpty) return BigInt.zero;
      return BigInt.parse(cleanRewardHex, radix: 16);
    }).toList();

    blocks.add(HistoricalBlock(number: blockNumber, baseFeePerGas: baseFee, gasUsedRatio: gasRatio, priorityFeePerGas: priorityFees));
  }

  return blocks;
}

/// Parses the base fee from a block response.
BigInt _parseBaseFeeFromBlock(dynamic blockResponse) {
  final Map<String, dynamic> block = blockResponse as Map<String, dynamic>;
  final baseFeeHex = block['baseFeePerGas'] as String?;

  if (baseFeeHex == null) {
    throw Exception('Block does not contain baseFeePerGas - EIP-1559 not supported');
  }

  // Handle proper hex format checking
  final cleanBaseFeeHex = baseFeeHex.startsWith('0x') ? baseFeeHex.substring(2) : baseFeeHex;
  if (cleanBaseFeeHex.isEmpty) {
    throw Exception('Invalid baseFeePerGas format');
  }

  return BigInt.parse(cleanBaseFeeHex, radix: 16);
}

/// Calculates the average priority fee for a specific percentile across all blocks with network-specific handling.
BigInt _calculateAveragePriorityFee(List<HistoricalBlock> blocks, int percentileIndex, NetworkConfig networkConfig) {
  if (blocks.isEmpty) {
    return BigInt.from(networkConfig.defaultAveragePriorityFeeWei);
  }

  BigInt sum = BigInt.zero;
  int validBlocks = 0;

  for (final block in blocks) {
    if (block.priorityFeePerGas.length > percentileIndex) {
      final priorityFee = block.priorityFeePerGas[percentileIndex];

      // For networks with minimal priority fees (like Arbitrum/Optimism),
      // if we get a zero fee, use the network's minimum
      if (!networkConfig.hasActivePriorityFees && priorityFee == BigInt.zero) {
        sum += BigInt.from(networkConfig.minimumPriorityFeeWei);
      } else {
        sum += priorityFee;
      }
      validBlocks++;
    }
  }

  if (validBlocks == 0) {
    return BigInt.from(networkConfig.defaultAveragePriorityFeeWei);
  }

  final average = sum ~/ BigInt.from(validBlocks);

  // Ensure minimum fee threshold for the network
  final minimum = BigInt.from(networkConfig.minimumPriorityFeeWei);
  return average > minimum ? average : minimum;
}
