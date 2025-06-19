# Changelog

## [1.2.0] - 2025-01-XX

### Added

- **🚀 Suggested Gas Fees**: New `getSuggestedGasFees()` function implementing EIP-1559 methodology
- **📊 Fee Tiers**: Provides slow, average, and fast fee estimates based on historical data
- **📈 Historical Analysis**: Uses `eth_feeHistory` to analyze recent block fee patterns
- **🎯 Smart Percentiles**: Calculates 1st, 50th, and 99th percentiles for optimal fee suggestions
- **⚙️ Customizable Parameters**: Configurable number of historical blocks to analyze
- **🛡️ Robust Fallbacks**: Enhanced error handling with sensible default values
- **📚 New Models**: `SuggestedGasFees`, `GasFeeEstimate`, and `HistoricalBlock` classes
- **📖 Comprehensive Examples**: Detailed usage examples and documentation
- **🧪 Full Test Coverage**: Extensive test suite for the new functionality

### Enhanced

- **📋 Extended Documentation**: Updated with EIP-1559 fee estimation methodology
- **🔗 Alchemy Integration**: Follows [Alchemy's gas fee estimator guidelines](https://www.alchemy.com/docs/how-to-build-a-gas-fee-estimator-using-eip-1559)
- **💡 Usage Examples**: Real-world transaction cost calculations and integration patterns

## [1.1.0] - 2025-06-18

- Add `onError` callback for custom error handling

## [1.0.2] - 2025-06-17

- Refactor for improved pub.dev scores

## [1.0.1] - 2025-06-17

- Update README.md

## [1.0.0] - 2025-06-17

- Initial release with `getFeeData()` function
- Support for both EIP-1559 and legacy networks
- Automatic network detection and fallback
- Type-safe `FeeData` class
