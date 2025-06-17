<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages). 
-->

# web3dart_get_fee_data

A comprehensive Dart package for retrieving Ethereum fee data, including full support for EIP-1559 transactions. This package provides an easy-to-use API that mirrors ethers.js `getFeeData()` functionality.

[![pub package](https://img.shields.io/pub/v/web3dart_get_fee_data.svg)](https://pub.dev/packages/web3dart_get_fee_data)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

- ✅ **EIP-1559 Support**: Get `maxFeePerGas` and `maxPriorityFeePerGas` for modern transactions
- ✅ **Legacy Compatibility**: Automatic fallback to traditional `gasPrice` for older networks  
- ✅ **Network Detection**: Seamlessly handles both EIP-1559 and legacy Ethereum networks
- ✅ **ethers.js Compatible**: API designed to match ethers.js behavior for easy migration
- ✅ **Comprehensive Testing**: Well-tested with real network integration tests
- ✅ **Type Safe**: Full Dart type safety with nullable types for optional fee parameters

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  web3dart_get_fee_data: ^0.0.1
```

Then run:

```bash
dart pub get
```

## Quick Start

```dart
import 'package:web3dart/web3dart.dart';
import 'package:web3dart_get_fee_data/web3dart_get_fee_data.dart';
import 'package:http/http.dart';

void main() async {
  // Create Web3Client instance
  final httpClient = Client();
  final ethClient = Web3Client('https://eth.llamarpc.com', httpClient);

  try {
    // Get current fee data
    final feeData = await getFeeData(ethClient);

    // Check if network supports EIP-1559
    if (feeData.maxFeePerGas != null) {
      print('✅ EIP-1559 Network Detected');
      print('Max Fee Per Gas: ${feeData.maxFeePerGas} wei');
      print('Max Priority Fee: ${feeData.maxPriorityFeePerGas} wei');
    } else {
      print('📜 Legacy Network - Using Gas Price');
      print('Gas Price: ${feeData.gasPrice} wei');
    }
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    ethClient.dispose();
  }
}
```

## Usage Examples

### Basic Fee Data Retrieval

```dart
import 'package:web3dart_get_fee_data/web3dart_get_fee_data.dart';

final feeData = await getFeeData(ethClient);
print('Current fee data: $feeData');
```

### EIP-1559 Transaction Estimation

```dart
final feeData = await getFeeData(ethClient);

if (feeData.maxFeePerGas != null && feeData.maxPriorityFeePerGas != null) {
  // Use EIP-1559 transaction
  final transaction = Transaction.callContract(
    contract: deployedContract,
    function: function,
    parameters: parameters,
    maxFeePerGas: EtherAmount.fromBigInt(EtherUnit.wei, feeData.maxFeePerGas!),
    maxPriorityFeePerGas: EtherAmount.fromBigInt(EtherUnit.wei, feeData.maxPriorityFeePerGas!),
  );
} else {
  // Fallback to legacy transaction
  final transaction = Transaction.callContract(
    contract: deployedContract,
    function: function,
    parameters: parameters,
    gasPrice: EtherAmount.fromBigInt(EtherUnit.wei, feeData.gasPrice!),
  );
}
```

## API Reference

### `getFeeData(Web3Client client)`

Retrieves current fee data from an Ethereum network.

**Parameters:**

- `client` - A connected `Web3Client` instance

**Returns:**

- `Future<FeeData>` - Fee data object containing current network fees

### `FeeData` Class

Represents Ethereum fee data for both legacy and EIP-1559 transactions.

**Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `gasPrice` | `BigInt?` | Legacy gas price in wei (always provided) |
| `maxFeePerGas` | `BigInt?` | Maximum fee per gas for EIP-1559 (null for legacy networks) |
| `maxPriorityFeePerGas` | `BigInt?` | Maximum priority fee per gas for EIP-1559 (null for legacy networks) |

## EIP-1559 vs Legacy Networks

### EIP-1559 Networks

For networks supporting EIP-1559, you'll receive:

- `gasPrice` - Current gas price (for compatibility)
- `maxFeePerGas` - Calculated as `2 * baseFee + priorityFee`
- `maxPriorityFeePerGas` - Current priority fee suggestion

### Legacy Networks  

For older networks, you'll receive:

- `gasPrice` - Current gas price
- `maxFeePerGas` - `null`
- `maxPriorityFeePerGas` - `null`

## Testing

Run the test suite:

```bash
dart test
```

The tests include:

- ✅ Real network integration tests
- ✅ Error handling verification
- ✅ Data validation checks
- ✅ EIP-1559 and legacy network compatibility

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Development Setup

1. Clone the repository
2. Run `dart pub get`
3. Make your changes
4. Run `dart test` to ensure tests pass
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed list of changes and version history.

## Support

- 📖 [Documentation](https://pub.dev/documentation/web3dart_get_fee_data/latest/)
- 🐛 [Issue Tracker](https://github.com/quoclewkm/web3dart_get_fee_data/issues)
- 💬 [Discussions](https://github.com/quoclewkm/web3dart_get_fee_data/discussions)
