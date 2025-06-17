/// Represents Ethereum fee data including legacy gas price and EIP-1559 fee parameters.
///
/// This class mirrors the structure of ethers.js FeeData, providing compatibility
/// with both legacy transactions (using [gasPrice]) and EIP-1559 transactions
/// (using [maxFeePerGas] and [maxPriorityFeePerGas]).
///
/// For EIP-1559 transactions:
/// - [maxFeePerGas]: The maximum total fee per gas unit willing to pay
/// - [maxPriorityFeePerGas]: The maximum priority fee (tip) per gas unit
///
/// For legacy transactions:
/// - [gasPrice]: The gas price per unit
class FeeData {
  /// The legacy gas price in wei.
  ///
  /// This is used for pre-EIP-1559 transactions and as a fallback
  /// when EIP-1559 is not supported by the network.
  final BigInt? gasPrice;

  /// The maximum fee per gas in wei for EIP-1559 transactions.
  ///
  /// This represents the maximum total amount (base fee + priority fee)
  /// that the user is willing to pay per gas unit.
  final BigInt? maxFeePerGas;

  /// The maximum priority fee per gas in wei for EIP-1559 transactions.
  ///
  /// This represents the maximum tip amount per gas unit that the user
  /// is willing to pay to incentivize miners to include their transaction.
  final BigInt? maxPriorityFeePerGas;

  /// Creates a new [FeeData] instance.
  ///
  /// At least one of [gasPrice] or both [maxFeePerGas] and [maxPriorityFeePerGas]
  /// should be provided, depending on the transaction type and network support.
  FeeData(this.gasPrice, this.maxFeePerGas, this.maxPriorityFeePerGas);

  @override
  String toString() => 'FeeData(gasPrice: $gasPrice, maxFeePerGas: $maxFeePerGas, maxPriorityFeePerGas: $maxPriorityFeePerGas)';
}
