# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-12-19

### Added

- ✨ Initial release of `web3dart_get_fee_data` package
- 🎯 `getFeeData()` function to retrieve current Ethereum fee data
- 📊 `FeeData` class supporting both legacy and EIP-1559 transactions
- 🔄 Automatic detection of EIP-1559 vs legacy network support
- 🛡️ Comprehensive error handling for network and RPC errors
- 📚 Full API documentation with dartdoc comments
- ✅ Comprehensive test suite with real network integration tests
- 🎨 ethers.js compatible API design
- 🌐 Support for all Ethereum-compatible networks (Mainnet, Polygon, Arbitrum, etc.)

### Features

- **EIP-1559 Support**: Returns `maxFeePerGas` and `maxPriorityFeePerGas` for supported networks
- **Legacy Compatibility**: Automatic fallback to traditional `gasPrice` for older networks
- **Type Safety**: Full Dart type safety with nullable types for optional parameters
- **Network Agnostic**: Works with any Ethereum-compatible network via Web3Client

### Dependencies

- `web3dart: ^3.0.1` - Core Ethereum client functionality
- `http: ^1.4.0` - HTTP client for RPC calls

### Example Usage

```dart
final client = Web3Client('https://eth.llamarpc.com', Client());
final feeData = await getFeeData(client);

if (feeData.maxFeePerGas != null) {
  // EIP-1559 network
  print('Max Fee: ${feeData.maxFeePerGas} wei');
  print('Priority Fee: ${feeData.maxPriorityFeePerGas} wei');
} else {
  // Legacy network
  print('Gas Price: ${feeData.gasPrice} wei');
}
```

## [Unreleased]

### Planned

- 🔧 Add gas estimation helpers
- 📈 Add fee history analysis
- ⚡ Add caching mechanism for fee data
- 🎯 Add network-specific optimizations

---

## Release Notes

### 1.0.0 - Initial Public Release

This is the first stable release of `web3dart_get_fee_data`. The package provides a simple, reliable way to get current Ethereum fee data with full support for both EIP-1559 and legacy transactions.

**Key Features:**

- Simple API mirroring ethers.js `getFeeData()`
- Automatic EIP-1559 detection and fallback
- Comprehensive documentation and examples
- Well-tested with real network integration

**Compatibility:**

- Dart SDK: `^3.8.1`
- All Ethereum-compatible networks
- Both EIP-1559 and legacy transaction types

---

*For more information, see the [README.md](README.md) and [API documentation](https://pub.dev/documentation/web3dart_get_fee_data/latest/).*
