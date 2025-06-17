# web3dart_get_fee_data

A Dart package for retrieving Ethereum fee data with full EIP-1559 support. Provides an API similar to ethers.js [`getFeeData()`](https://github.com/ethers-io/ethers.js/blob/4eada383ab9833f9b4847ea9bdf39910c4eb508e/dist/ethers.js#L18874).

[![pub package](https://img.shields.io/pub/v/web3dart_get_fee_data.svg)](https://pub.dev/packages/web3dart_get_fee_data)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

- ✅ **EIP-1559 Support**: Get `maxFeePerGas` and `maxPriorityFeePerGas`
- ✅ **Legacy Compatibility**: Automatic fallback to `gasPrice`
- ✅ **Network Detection**: Handles both EIP-1559 and legacy networks
- ✅ **Type Safe**: Full Dart type safety with nullable types

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
  }
}
```

## API

### `getFeeData(Web3Client client)`

Returns `Future<FeeData>` with current network fees.

### `FeeData`

| Property | Type | Description |
|----------|------|-------------|
| `gasPrice` | `BigInt?` | Legacy gas price in wei |
| `maxFeePerGas` | `BigInt?` | EIP-1559 max fee per gas |
| `maxPriorityFeePerGas` | `BigInt?` | EIP-1559 priority fee |

## Network Support

**EIP-1559 Networks:** Returns all three properties  
**Legacy Networks:** Returns only `gasPrice`

## License

MIT License - see [LICENSE](LICENSE) file.
