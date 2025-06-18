# web3dart_get_fee_data

A Dart package for retrieving Ethereum fee data with full EIP-1559 support. Provides an API similar to ethers.js [`getFeeData()`](https://github.com/ethers-io/ethers.js/blob/4eada383ab9833f9b4847ea9bdf39910c4eb508e/dist/ethers.js#L18874).

[![pub package](https://img.shields.io/pub/v/web3dart_get_fee_data.svg)](https://pub.dev/packages/web3dart_get_fee_data)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

- ✅ **EIP-1559 Support**: Get `maxFeePerGas` and `maxPriorityFeePerGas` for modern transactions
- ✅ **Legacy Compatibility**: Automatic fallback to `gasPrice` for older networks
- ✅ **Custom Error Handling**: Optional `onError` callback for custom fallback strategies

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  web3dart_get_fee_data: ^1.0.2
```

Then run:

```bash
dart pub get
```

## Usage

```dart
import 'package:web3dart/web3dart.dart';
import 'package:web3dart_get_fee_data/web3dart_get_fee_data.dart';
import 'package:http/http.dart';

void main() async {
  final httpClient = Client();
  final ethClient = Web3Client('https://eth.llamarpc.com', httpClient);

  try {
    final feeData = await getFeeData(ethClient);

    if (feeData.maxFeePerGas != null) {
      print('EIP-1559: ${feeData.maxFeePerGas} wei');
    } else {
      print('Legacy: ${feeData.gasPrice} wei');
    }
  } finally {
    ethClient.dispose();
    httpClient.close();
  }
}
```

## Advanced Usage

### Custom Error Handling

Use the `onError` callback for custom fallback strategies:

```dart
final feeData = await getFeeData(
  client,
  onError: (context) {
    print('Error in ${context.operation}: ${context.error}');
    print('Stack trace: ${context.stackTrace}');
    
    // Custom fallback strategies
    if (context.operation == 'eth_maxPriorityFeePerGas') {
      // Use zero priority fee for networks like Arbitrum
      return BigInt.zero;
    }
    
    // Use default fallback
    return context.fallbackValue;
  }
);
```

## API Reference

### `getFeeData(Web3Client client, {onError})`

**Parameters:**

- `client`: A connected `Web3Client` instance
- `onError`: Optional callback for custom error handling

**Returns:** `Future<FeeData>` with current network fees

**Example:**

```dart
Future<FeeData> getFeeData(
  Web3Client client, {
  BigInt? Function(ErrorContext context)? onError,
})
```

### `FeeData`

| Property | Type | Description |
|----------|------|-------------|
| `gasPrice` | `BigInt?` | Legacy gas price in wei (always provided) |
| `maxFeePerGas` | `BigInt?` | EIP-1559 max fee per gas (when supported) |
| `maxPriorityFeePerGas` | `BigInt?` | EIP-1559 priority fee (when supported) |

### `ErrorContext`

Provides comprehensive error information to `onError` callbacks:

| Property | Type | Description |
|----------|------|-------------|
| `operation` | `String` | The operation that failed (e.g., 'eth_maxPriorityFeePerGas') |
| `error` | `dynamic` | The original error that occurred |
| `stackTrace` | `StackTrace` | Stack trace when the error occurred |
| `fallbackValue` | `BigInt?` | Default fallback value that would be used |
| `gasPrice` | `BigInt` | Current gas price in wei |
| `baseFeePerGas` | `BigInt?` | Current base fee per gas in wei (EIP-1559 networks) |

## License

MIT License - see [LICENSE](LICENSE) file.
