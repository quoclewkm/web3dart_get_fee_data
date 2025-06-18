import 'package:http/http.dart';
import 'package:test/test.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web3dart_get_fee_data/web3dart_get_fee_data.dart';

/// Network configuration for testing
class NetworkConfig {
  final String name;
  final String chainId;
  final String rpcUrl;
  final String category;

  NetworkConfig({required this.name, required this.chainId, required this.rpcUrl, required this.category});
}

void main() {
  group('Comprehensive Network Compatibility Tests', () {
    late Client httpClient;
    int legacyCount = 0;
    int eip1559Count = 0;

    // Network configurations based on Etherscan chainlist
    final networks = [
      // Ethereum Networks
      NetworkConfig(name: 'Ethereum Mainnet', chainId: '1', rpcUrl: 'https://eth.llamarpc.com', category: 'ethereum'),
      NetworkConfig(name: 'Sepolia Testnet', chainId: '11155111', rpcUrl: 'https://ethereum-sepolia-rpc.publicnode.com', category: 'ethereum'),
      NetworkConfig(name: 'Holesky Testnet', chainId: '17000', rpcUrl: 'https://ethereum-holesky-rpc.publicnode.com', category: 'ethereum'),

      // Polygon Networks
      NetworkConfig(name: 'Polygon Mainnet', chainId: '137', rpcUrl: 'https://1rpc.io/matic', category: 'polygon'),
      NetworkConfig(name: 'Polygon Amoy Testnet', chainId: '80002', rpcUrl: 'https://rpc-amoy.polygon.technology', category: 'polygon'),

      // BNB Smart Chain
      NetworkConfig(name: 'BNB Smart Chain Mainnet', chainId: '56', rpcUrl: 'https://bsc-dataseed.binance.org', category: 'bsc'),
      NetworkConfig(name: 'BNB Smart Chain Testnet', chainId: '97', rpcUrl: 'https://data-seed-prebsc-1-s1.binance.org:8545', category: 'bsc'),

      // Arbitrum Networks
      NetworkConfig(name: 'Arbitrum One', chainId: '42161', rpcUrl: 'https://arb1.arbitrum.io/rpc', category: 'arbitrum'),
      NetworkConfig(name: 'Arbitrum Nova', chainId: '42170', rpcUrl: 'https://nova.arbitrum.io/rpc', category: 'arbitrum'),
      NetworkConfig(name: 'Arbitrum Sepolia', chainId: '421614', rpcUrl: 'https://sepolia-rollup.arbitrum.io/rpc', category: 'arbitrum'),

      // Optimism Networks
      NetworkConfig(name: 'Optimism Mainnet', chainId: '10', rpcUrl: 'https://mainnet.optimism.io', category: 'optimism'),
      NetworkConfig(name: 'Optimism Sepolia', chainId: '11155420', rpcUrl: 'https://sepolia.optimism.io', category: 'optimism'),

      // Base Networks
      NetworkConfig(name: 'Base Mainnet', chainId: '8453', rpcUrl: 'https://mainnet.base.org', category: 'base'),
      NetworkConfig(name: 'Base Sepolia', chainId: '84532', rpcUrl: 'https://sepolia.base.org', category: 'base'),

      // Avalanche Networks
      NetworkConfig(name: 'Avalanche C-Chain', chainId: '43114', rpcUrl: 'https://api.avax.network/ext/bc/C/rpc', category: 'avalanche'),
      NetworkConfig(name: 'Avalanche Fuji', chainId: '43113', rpcUrl: 'https://api.avax-test.network/ext/bc/C/rpc', category: 'avalanche'),

      // Fantom Networks
      NetworkConfig(
        name: 'Fantom Opera',
        chainId: '250',
        rpcUrl: 'https://rpc3.fantom.network', // Using alternative RPC due to parsing issues

        category: 'fantom',
      ),
      NetworkConfig(name: 'Fantom Testnet', chainId: '4002', rpcUrl: 'https://rpc.testnet.fantom.network', category: 'fantom'),

      // Linea Networks
      NetworkConfig(name: 'Linea Mainnet', chainId: '59144', rpcUrl: 'https://rpc.linea.build', category: 'linea'),
      NetworkConfig(name: 'Linea Sepolia', chainId: '59141', rpcUrl: 'https://rpc.sepolia.linea.build', category: 'linea'),

      // zkSync Networks
      NetworkConfig(name: 'zkSync Era Mainnet', chainId: '324', rpcUrl: 'https://mainnet.era.zksync.io', category: 'zksync'),
      NetworkConfig(name: 'zkSync Era Sepolia', chainId: '300', rpcUrl: 'https://sepolia.era.zksync.dev', category: 'zksync'),

      // Polygon zkEVM
      NetworkConfig(name: 'Polygon zkEVM', chainId: '1101', rpcUrl: 'https://zkevm-rpc.com', category: 'polygon-zkevm'),

      // Blast Networks
      NetworkConfig(name: 'Blast Mainnet', chainId: '81457', rpcUrl: 'https://rpc.blast.io', category: 'blast'),

      // Scroll Networks
      NetworkConfig(name: 'Scroll Mainnet', chainId: '534352', rpcUrl: 'https://rpc.scroll.io', category: 'scroll'),
      NetworkConfig(name: 'Scroll Sepolia', chainId: '534351', rpcUrl: 'https://sepolia-rpc.scroll.io', category: 'scroll'),

      // Celo Networks
      NetworkConfig(name: 'Celo Mainnet', chainId: '42220', rpcUrl: 'https://forno.celo.org', category: 'celo'),
      NetworkConfig(name: 'Celo Alfajores', chainId: '44787', rpcUrl: 'https://alfajores-forno.celo-testnet.org', category: 'celo'),

      // Moonbeam Networks
      NetworkConfig(name: 'Moonbeam', chainId: '1284', rpcUrl: 'https://rpc.api.moonbeam.network', category: 'moonbeam'),
      NetworkConfig(name: 'Moonriver', chainId: '1285', rpcUrl: 'https://rpc.api.moonriver.moonbeam.network', category: 'moonbeam'),

      // Additional Networks from Etherscan Chainlist
      NetworkConfig(name: 'Gnosis Chain', chainId: '100', rpcUrl: 'https://rpc.gnosischain.com', category: 'gnosis'),
      NetworkConfig(name: 'Mantle Mainnet', chainId: '5000', rpcUrl: 'https://rpc.mantle.xyz', category: 'mantle'),

      // More Networks from Etherscan Chainlist
      NetworkConfig(name: 'BitTorrent Chain', chainId: '199', rpcUrl: 'https://rpc.bittorrentchain.io', category: 'bttc'),
      NetworkConfig(name: 'Cronos Mainnet', chainId: '25', rpcUrl: 'https://evm.cronos.org', category: 'cronos'),
      NetworkConfig(name: 'Aurora Mainnet', chainId: '1313161554', rpcUrl: 'https://mainnet.aurora.dev', category: 'aurora'),
      NetworkConfig(name: 'Metis Andromeda', chainId: '1088', rpcUrl: 'https://andromeda.metis.io/?owner=1088', category: 'metis'),
      NetworkConfig(name: 'Boba Network', chainId: '288', rpcUrl: 'https://mainnet.boba.network', category: 'boba'),
      NetworkConfig(name: 'Harmony Mainnet', chainId: '1666600000', rpcUrl: 'https://api.harmony.one', category: 'harmony'),
      NetworkConfig(name: 'KCC Mainnet', chainId: '321', rpcUrl: 'https://rpc-mainnet.kcc.network', category: 'kcc'),
      NetworkConfig(name: 'Milkomeda C1', chainId: '2001', rpcUrl: 'https://rpc-mainnet-cardano-evm.c1.milkomeda.com', category: 'milkomeda'),
      NetworkConfig(name: 'Evmos Mainnet', chainId: '9001', rpcUrl: 'https://evmos-evm-rpc.publicnode.com', category: 'evmos'),
      NetworkConfig(name: 'Oasis Emerald', chainId: '42262', rpcUrl: 'https://emerald.oasis.dev', category: 'oasis'),
    ];

    setUp(() {
      httpClient = Client();
    });

    tearDown(() {
      httpClient.close();
    });

    // Group tests by network category
    final categories = networks.map((n) => n.category).toSet();

    for (final category in categories) {
      group('$category Networks', () {
        final categoryNetworks = networks.where((n) => n.category == category).toList();

        for (final network in categoryNetworks) {
          test('${network.name} (Chain ID: ${network.chainId})', () async {
            final client = Web3Client(network.rpcUrl, httpClient);

            try {
              final feeData = await getFeeData(client);

              // Basic assertions
              expect(feeData.gasPrice, isNotNull, reason: 'Gas price should always be available');
              expect(feeData.gasPrice!.toInt(), greaterThan(0), reason: 'Gas price should be positive');

              // EIP-1559 specific assertions
              // Many networks support EIP-1559, but some might not have it enabled
              if (feeData.maxFeePerGas != null && feeData.maxPriorityFeePerGas != null) {
                expect(feeData.maxFeePerGas!.toInt(), greaterThan(0), reason: 'Max fee per gas should be positive when present');

                // Some networks may have zero priority fee but still support EIP-1559
                expect(feeData.maxPriorityFeePerGas!.toInt(), greaterThanOrEqualTo(0), reason: 'Max priority fee per gas should be non-negative when present');

                expect(feeData.maxFeePerGas!.toInt(), greaterThanOrEqualTo(feeData.maxPriorityFeePerGas!.toInt()), reason: 'Max fee should be >= priority fee');

                if (feeData.maxPriorityFeePerGas!.toInt() > 0) {
                  eip1559Count++;
                  print('✅ ${network.name}: EIP-1559 supported (with priority fee)');
                  print('   Gas Price: ${feeData.gasPrice} wei');
                  print('   Max Fee Per Gas: ${feeData.maxFeePerGas} wei');
                  print('   Max Priority Fee: ${feeData.maxPriorityFeePerGas} wei');
                } else {
                  legacyCount++;
                  print('✅ ${network.name}: EIP-1559 supported (zero priority fee)');
                  print('   Gas Price: ${feeData.gasPrice} wei');
                  print('   Max Fee Per Gas: ${feeData.maxFeePerGas} wei');
                  print('   Max Priority Fee: ${feeData.maxPriorityFeePerGas} wei (zero - network specific)');
                }
              } else {
                legacyCount++;
                print('ℹ️  ${network.name}: EIP-1559 expected but not available (legacy mode)');
                print('   Gas Price: ${feeData.gasPrice} wei');
              }
            } catch (e) {
              print('❌ ${network.name} failed: $e');
              // Handle specific network issues more gracefully
              if (e.toString().contains('String') && e.toString().contains('subtype')) {
                print('   ⚠️  Known parsing issue with this network RPC - may need alternative endpoint');
              } else if (e.toString().contains('timeout') || e.toString().contains('connection')) {
                print('   ⚠️  Network connectivity issue - RPC may be temporarily unavailable');
              } else {
                print('   ⚠️  Unexpected error - may indicate compatibility issue');
              }
              // Don't rethrow immediately - let's collect information about failures
              fail('Network ${network.name} test failed: $e');
            } finally {
              client.dispose();
            }
          }, timeout: const Timeout(Duration(seconds: 30)));
        }
      });
    }

    // Summary test to show network coverage
    test('Network Coverage Summary', () {
      print('\n📊 Network Coverage Summary:');
      print('Total networks tested: ${networks.length}');

      final categoryCount = <String, int>{};
      for (final network in networks) {
        categoryCount[network.category] = (categoryCount[network.category] ?? 0) + 1;
      }

      print('\nNetworks by category:');
      categoryCount.forEach((category, count) {
        print('  $category: $count networks');
      });

      print('\nEIP-1559 Support:');
      print('  Expected EIP-1559: $eip1559Count networks');
      print('  Legacy only: $legacyCount networks');

      expect(networks.length, greaterThan(20), reason: 'Should test a comprehensive set of networks');
    });
  });
}
