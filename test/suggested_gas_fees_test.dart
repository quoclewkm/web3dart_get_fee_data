import 'package:http/http.dart';
import 'package:test/test.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web3dart_get_fee_data/web3dart_get_fee_data.dart';

void main() {
  group('getSuggestedGasFees Tests', () {
    late Web3Client client;
    late Client httpClient;

    setUp(() {
      httpClient = Client();
      client = Web3Client('https://eth.llamarpc.com', httpClient);
    });

    tearDown(() {
      client.dispose();
    });

    test('getSuggestedGasFees returns valid fee estimates', () async {
      final suggestedFees = await getSuggestedGasFees(client);

      expect(suggestedFees, isNotNull);
      expect(suggestedFees.baseFeePerGas, greaterThan(BigInt.zero));

      // Verify slow, average, fast estimates are properly ordered
      expect(suggestedFees.slow.maxPriorityFeePerGas, greaterThan(BigInt.zero));
      expect(suggestedFees.average.maxPriorityFeePerGas, greaterThan(BigInt.zero));
      expect(suggestedFees.fast.maxPriorityFeePerGas, greaterThan(BigInt.zero));

      // Slow should be <= average <= fast
      expect(suggestedFees.slow.maxPriorityFeePerGas, lessThanOrEqualTo(suggestedFees.average.maxPriorityFeePerGas));
      expect(suggestedFees.average.maxPriorityFeePerGas, lessThanOrEqualTo(suggestedFees.fast.maxPriorityFeePerGas));

      // Max fee per gas should be at least base fee + priority fee (may include congestion multiplier)
      expect(suggestedFees.slow.maxFeePerGas, greaterThanOrEqualTo(suggestedFees.baseFeePerGas + suggestedFees.slow.maxPriorityFeePerGas));
      expect(suggestedFees.average.maxFeePerGas, greaterThanOrEqualTo(suggestedFees.baseFeePerGas + suggestedFees.average.maxPriorityFeePerGas));
      expect(suggestedFees.fast.maxFeePerGas, greaterThanOrEqualTo(suggestedFees.baseFeePerGas + suggestedFees.fast.maxPriorityFeePerGas));

      // But should not be unreasonably high (within 50% congestion multiplier for Ethereum)
      expect(
        suggestedFees.average.maxFeePerGas,
        lessThanOrEqualTo((suggestedFees.baseFeePerGas + suggestedFees.average.maxPriorityFeePerGas) * BigInt.from(150) ~/ BigInt.from(100)),
      );
      expect(
        suggestedFees.fast.maxFeePerGas,
        lessThanOrEqualTo((suggestedFees.baseFeePerGas + suggestedFees.fast.maxPriorityFeePerGas) * BigInt.from(150) ~/ BigInt.from(100)),
      );
    });

    test('getSuggestedGasFees with custom historical blocks', () async {
      final suggestedFees = await getSuggestedGasFees(client, historicalBlocks: 10);

      expect(suggestedFees, isNotNull);
      expect(suggestedFees.baseFeePerGas, greaterThan(BigInt.zero));
      expect(suggestedFees.slow.maxPriorityFeePerGas, greaterThan(BigInt.zero));
      expect(suggestedFees.average.maxPriorityFeePerGas, greaterThan(BigInt.zero));
      expect(suggestedFees.fast.maxPriorityFeePerGas, greaterThan(BigInt.zero));
    });

    test('getSuggestedGasFees handles network errors gracefully', () async {
      // Create client with invalid URL
      final invalidHttpClient = Client();
      final invalidClient = Web3Client('https://invalid-url-that-does-not-exist.com', invalidHttpClient);

      try {
        final suggestedFees = await getSuggestedGasFees(invalidClient);

        // Should return fallback values from the default network config
        expect(suggestedFees, isNotNull);
        expect(suggestedFees.baseFeePerGas, equals(BigInt.from(10e9))); // 10 gwei default (NetworkConfigs.defaultConfig)
        expect(suggestedFees.slow.maxPriorityFeePerGas, equals(BigInt.from(2e9))); // 2 gwei
        expect(suggestedFees.average.maxPriorityFeePerGas, equals(BigInt.from(4e9))); // 4 gwei
        expect(suggestedFees.fast.maxPriorityFeePerGas, equals(BigInt.from(8e9))); // 8 gwei
      } finally {
        invalidClient.dispose();
      }
    });

    test('getSuggestedGasFees with custom error handler', () async {
      bool errorHandlerCalled = false;

      // Create client with invalid URL to trigger error
      final invalidHttpClient = Client();
      final invalidClient = Web3Client('https://invalid-url-that-does-not-exist.com', invalidHttpClient);

      try {
        final suggestedFees = await getSuggestedGasFees(
          invalidClient,
          onError: (context) {
            errorHandlerCalled = true;
            expect(context.operation, equals('getSuggestedGasFees'));
            expect(context.error, isNotNull);
            expect(context.fallbackValue, isNotNull);
            return BigInt.from(3e9); // 3 gwei custom fallback
          },
        );

        expect(errorHandlerCalled, isTrue);
        expect(suggestedFees, isNotNull);
        expect(suggestedFees.average.maxPriorityFeePerGas, equals(BigInt.from(3e9)));
      } finally {
        invalidClient.dispose();
      }
    });

    test('GasFeeEstimate equality and toString', () {
      final estimate1 = GasFeeEstimate(maxPriorityFeePerGas: BigInt.from(1e9), maxFeePerGas: BigInt.from(21e9));

      final estimate2 = GasFeeEstimate(maxPriorityFeePerGas: BigInt.from(1e9), maxFeePerGas: BigInt.from(21e9));

      final estimate3 = GasFeeEstimate(maxPriorityFeePerGas: BigInt.from(2e9), maxFeePerGas: BigInt.from(22e9));

      expect(estimate1, equals(estimate2));
      expect(estimate1, isNot(equals(estimate3)));
      expect(estimate1.hashCode, equals(estimate2.hashCode));
      expect(estimate1.toString(), contains('maxPriorityFeePerGas'));
      expect(estimate1.toString(), contains('maxFeePerGas'));
    });

    test('SuggestedGasFees equality and toString', () {
      final fees1 = SuggestedGasFees(
        slow: GasFeeEstimate(maxPriorityFeePerGas: BigInt.from(1e9), maxFeePerGas: BigInt.from(21e9)),
        average: GasFeeEstimate(maxPriorityFeePerGas: BigInt.from(15e8), maxFeePerGas: BigInt.from(215e8)),
        fast: GasFeeEstimate(maxPriorityFeePerGas: BigInt.from(2e9), maxFeePerGas: BigInt.from(22e9)),
        baseFeePerGas: BigInt.from(20e9),
      );

      final fees2 = SuggestedGasFees(
        slow: GasFeeEstimate(maxPriorityFeePerGas: BigInt.from(1e9), maxFeePerGas: BigInt.from(21e9)),
        average: GasFeeEstimate(maxPriorityFeePerGas: BigInt.from(15e8), maxFeePerGas: BigInt.from(215e8)),
        fast: GasFeeEstimate(maxPriorityFeePerGas: BigInt.from(2e9), maxFeePerGas: BigInt.from(22e9)),
        baseFeePerGas: BigInt.from(20e9),
      );

      expect(fees1, equals(fees2));
      expect(fees1.hashCode, equals(fees2.hashCode));
      expect(fees1.toString(), contains('SuggestedGasFees'));
      expect(fees1.toString(), contains('slow'));
      expect(fees1.toString(), contains('average'));
      expect(fees1.toString(), contains('fast'));
      expect(fees1.toString(), contains('baseFeePerGas'));
    });

    test('HistoricalBlock toString', () {
      final block = HistoricalBlock(
        number: 12345,
        baseFeePerGas: BigInt.from(20e9),
        gasUsedRatio: 0.85,
        priorityFeePerGas: [BigInt.from(1e9), BigInt.from(15e8), BigInt.from(2e9)],
      );

      final blockString = block.toString();
      expect(blockString, contains('HistoricalBlock'));
      expect(blockString, contains('number: 12345'));
      expect(blockString, contains('baseFeePerGas'));
      expect(blockString, contains('gasUsedRatio: 0.85'));
      expect(blockString, contains('priorityFeePerGas'));
    });
  });
}
