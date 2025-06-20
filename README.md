# web3dart_get_fee_data

A Dart package for retrieving Ethereum fee data with full EIP-1559 support. Provides an API similar to ethers.js [`getFeeData()`](https://github.com/ethers-io/ethers.js/blob/4eada383ab9833f9b4847ea9bdf39910c4eb508e/dist/ethers.js#L18874).

[![pub package](https://img.shields.io/pub/v/web3dart_get_fee_data.svg)](https://pub.dev/packages/web3dart_get_fee_data)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

- ✅ **EIP-1559 Support**: Get `maxFeePerGas` and `maxPriorityFeePerGas` for modern transactions
- ✅ **Legacy Compatibility**: Automatic fallback to `gasPrice` for older networks
- ✅ **Custom Error Handling**: Optional `onError` callback for custom fallback strategies
- 🚀 **Suggested Gas Fees**: Get slow, average, and fast fee estimates using EIP-1559 methodology
- 📊 **Smart Fee Tiers**: Historical analysis with 1st, 50th, and 99th percentiles
- 📈 **Real-time Data**: Uses `eth_feeHistory` for accurate fee predictions

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  web3dart_get_fee_data: ^1.2.0
```

Then run:

```bash
dart pub get
```

## Quick Start

### Basic Fee Data

```dart
import 'package:web3dart/web3dart.dart';
import 'package:web3dart_get_fee_data/web3dart_get_fee_data.dart';
import 'package:http/http.dart';

void main() async {
  final httpClient = Client();
  final ethClient = Web3Client('https://eth.llamarpc.com', httpClient);

  try {
    // Get current fee data
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

### Suggested Gas Fees (EIP-1559)

```dart
void main() async {
  final httpClient = Client();
  final ethClient = Web3Client('https://eth.llamarpc.com', httpClient);

  try {
    // Get suggested fee tiers based on historical data
    final suggestedFees = await getSuggestedGasFees(ethClient);

    print('Base Fee: ${suggestedFees.baseFeePerGas} wei');
    print('Slow: ${suggestedFees.slow.maxFeePerGas} wei');
    print('Average: ${suggestedFees.average.maxFeePerGas} wei');
    print('Fast: ${suggestedFees.fast.maxFeePerGas} wei');

    // Use in a transaction
    final transaction = Transaction.callContract(
      contract: contract,
      function: function,
      parameters: [],
      maxFeePerGas: EtherAmount.fromBigInt(
        EtherUnit.wei, 
        suggestedFees.average.maxFeePerGas,
      ),
      maxPriorityFeePerGas: EtherAmount.fromBigInt(
        EtherUnit.wei,
        suggestedFees.average.maxPriorityFeePerGas,
      ),
    );
  } finally {
    ethClient.dispose();
    httpClient.close();
  }
}
```

## Suggested Gas Fees Methodology

The `getSuggestedGasFees` function implements the EIP-1559 fee estimation methodology described in [Alchemy's documentation](https://www.alchemy.com/docs/how-to-build-a-gas-fee-estimator-using-eip-1559):

### How It Works

1. **Historical Analysis**: Analyzes recent blocks using `eth_feeHistory` RPC call
2. **Percentile Calculation**: Uses 1st, 75th, and 90th percentiles of priority fees
3. **Speed Tiers**: Provides three options:
   - `slow`: Conservative (1st percentile) - cheaper but slower
   - `average`: Standard (75th percentile) - balanced cost and speed
   - `fast`: Aggressive (90th percentile) - more expensive but faster
4. **Base Fee Addition**: Combines priority fees with current base fee

### When to Use Each Tier

- **🐌 Slow**: Non-urgent transactions, cost optimization
- **🚶 Average**: Typical transactions, balanced approach
- **🚀 Fast**: Time-sensitive transactions, faster confirmation

### Fallback Strategy

If the network doesn't support `eth_feeHistory` or errors occur, the function provides sensible defaults:

- Base fee: 20 gwei
- Slow priority: 1 gwei
- Average priority: 1.5 gwei  
- Fast priority: 2 gwei

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

### `getSuggestedGasFees(Web3Client client, {historicalBlocks, onError})`

**Parameters:**

- `client`: A connected `Web3Client` instance
- `historicalBlocks`: Number of historical blocks to analyze (default: 20)
- `onError`: Optional callback for custom error handling

**Returns:** `Future<SuggestedGasFees>` with three fee tiers

**Example:**

```dart
final suggestedFees = await getSuggestedGasFees(
  client,
  historicalBlocks: 10, // Analyze fewer blocks for faster response
  onError: (context) {
    print('Error: ${context.error}');
    return context.fallbackValue; // Use default fallback
  },
);
```

### `SuggestedGasFees`

| Property | Type | Description |
|----------|------|-------------|
| `slow` | `GasFeeEstimate` | Conservative estimate (1st percentile) |
| `average` | `GasFeeEstimate` | Standard estimate (50th percentile) |
| `fast` | `GasFeeEstimate` | Aggressive estimate (99th percentile) |
| `baseFeePerGas` | `BigInt` | Current base fee from latest block |

### `GasFeeEstimate`

| Property | Type | Description |
|----------|------|-------------|
| `maxPriorityFeePerGas` | `BigInt` | Priority fee (tip) for this estimate |
| `maxFeePerGas` | `BigInt` | Total max fee (base + priority) |

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
