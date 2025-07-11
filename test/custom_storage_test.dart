import 'package:flutter_test/flutter_test.dart';
import 'package:amplitude_flutter/configuration.dart';
import 'package:amplitude_flutter/storage_provider.dart';

void main() {
  group('Custom Storage Configuration Tests', () {
    test('Configuration should accept storageProvider parameter', () {
      final config = Configuration(
        apiKey: 'test-api-key',
        storageProvider: StorageProvider.library,
      );

      expect(config.apiKey, equals('test-api-key'));
      expect(config.storageProvider, equals(StorageProvider.library));
    });
    
    test('Configuration should handle null storageProvider', () {
      final config = Configuration(
        apiKey: 'test-api-key',
        storageProvider: null,
      );

      expect(config.apiKey, equals('test-api-key'));
      expect(config.storageProvider, isNull);
    });

    test('Configuration toMap should include storageProvider', () {
      final config = Configuration(
        apiKey: 'test-api-key',
        storageProvider: StorageProvider.documents,
      );

      final map = config.toMap();
      expect(map['storageProvider'], equals('documents'));
    });

    test('Configuration toMap should handle null storageProvider', () {
      final config = Configuration(
        apiKey: 'test-api-key',
        storageProvider: null,
      );

      final map = config.toMap();
      expect(map.containsKey('storageProvider'), isTrue);
      expect(map['storageProvider'], isNull);
    });
    
    test('Configuration should work with all storage types', () {
      final storageProviders = [
        StorageProvider.documents,
        StorageProvider.library,
        StorageProvider.cache,
        StorageProvider.custom('/path/to/dir'),
      ];
      final expectedStrings = ['documents', 'library', 'cache', 'custom:/path/to/dir'];

      for (int i = 0; i < storageProviders.length; i++) {
        final config = Configuration(
          apiKey: 'test-api-key',
          storageProvider: storageProviders[i],
        );

        expect(config.storageProvider, equals(storageProviders[i]));

        final map = config.toMap();
        expect(map['storageProvider'], equals(expectedStrings[i]));
      }
    });
  });

  group('StorageProvider Tests', () {
    test('StorageProvider.custom should have correct configuration string', () {
      final storage = StorageProvider.custom('/custom/path');
      expect(storage.configurationString, equals('custom:/custom/path'));
    });

    test('StorageProvider equality should work correctly', () {
      expect(StorageProvider.documents, equals(StorageProvider.documents));
      expect(StorageProvider.library, equals(StorageProvider.library));
      expect(StorageProvider.cache, equals(StorageProvider.cache));
      expect(StorageProvider.custom('/path'), equals(StorageProvider.custom('/path')));
      expect(StorageProvider.custom('/path1'), isNot(equals(StorageProvider.custom('/path2'))));
    });

    test('StorageProvider should be const when possible', () {
      // These should be the same instance (const)
      expect(identical(StorageProvider.documents, StorageProvider.documents), isTrue);
      expect(identical(StorageProvider.library, StorageProvider.library), isTrue);
      expect(identical(StorageProvider.cache, StorageProvider.cache), isTrue);
    });
  });
}
