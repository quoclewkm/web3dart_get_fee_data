import 'package:http/http.dart';
import 'package:test/test.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web3dart_get_fee_data/web3dart_get_fee_data.dart';

void main() {
  group('getFeeData Tests', () {
    late Web3Client client;
    late Client httpClient;

    setUp(() {
      httpClient = Client();
      client = Web3Client('https://eth.llamarpc.com', httpClient);
    });

    tearDown(() {
      client.dispose();
    });

    test('getFeeData returns valid fee data', () async {
      final feeData = await getFeeData(client);

      expect(feeData, isNotNull);

      // Should have either gasPrice (legacy) or EIP-1559 fee data
      expect(feeData.gasPrice != null || (feeData.maxFeePerGas != null && feeData.maxPriorityFeePerGas != null), isTrue);

      // Verify the values are positive when present
      if (feeData.gasPrice != null) {
        expect(feeData.gasPrice!, greaterThan(BigInt.zero));
      }
      if (feeData.maxFeePerGas != null) {
        expect(feeData.maxFeePerGas!, greaterThan(BigInt.zero));
      }
      if (feeData.maxPriorityFeePerGas != null) {
        expect(feeData.maxPriorityFeePerGas!, greaterThan(BigInt.zero));
      }

      // Verify maxFeePerGas is greater than or equal to maxPriorityFeePerGas when both are present
      if (feeData.maxFeePerGas != null && feeData.maxPriorityFeePerGas != null) {
        expect(feeData.maxFeePerGas!, greaterThanOrEqualTo(feeData.maxPriorityFeePerGas!));
      }
    });

    test('getFeeData handles network errors gracefully', () async {
      // Create client with invalid URL
      final invalidHttpClient = Client();
      final invalidClient = Web3Client('https://invalid-url-that-does-not-exist.com', invalidHttpClient);

      try {
        await getFeeData(invalidClient);
        fail('Expected an exception to be thrown');
      } catch (e) {
        expect(e, isA<Exception>());
      } finally {
        invalidClient.dispose();
      }
    });

    test('FeeData toString returns correct format', () {
      final feeData = FeeData(BigInt.from(1000000000), BigInt.from(2000000000), BigInt.from(1500000000));

      final expectedString = 'FeeData(gasPrice: 1000000000, maxFeePerGas: 2000000000, maxPriorityFeePerGas: 1500000000)';
      expect(feeData.toString(), equals(expectedString));
    });

    test('FeeData with null values', () {
      final feeData = FeeData(null, null, null);

      final expectedString = 'FeeData(gasPrice: null, maxFeePerGas: null, maxPriorityFeePerGas: null)';
      expect(feeData.toString(), equals(expectedString));
    });
  });
}
