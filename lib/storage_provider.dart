/// Custom storage provider options for iOS
///
/// This sealed class defines the available storage options for iOS custom storage.
/// Each option represents a different location where Amplitude data can be stored.
sealed class StorageProvider {
  /// The configuration string used for native communication
  final String configurationString;

  const StorageProvider(this.configurationString);

  @override
  bool operator ==(Object other) =>
      other is StorageProvider && other.configurationString == configurationString;

  @override
  int get hashCode => configurationString.hashCode;

  /// Store Amplitude data in the Documents directory (visible in Files app)
  static const StorageProvider documents = _DocumentsStorage();

  /// Store Amplitude data in the Library directory (hidden from Files app) - Recommended
  static const StorageProvider library = _LibraryStorage();

  /// Store Amplitude data in the Cache directory (can be cleared by system)
  static const StorageProvider cache = _CacheStorage();

  /// Create a custom storage provider for a specific directory path
  ///
  /// The path should be an absolute path within your app's sandbox.
  /// The SDK will create an `amplitude_flutter` subdirectory within this path.
  ///
  /// Example:
  /// ```dart
  /// StorageProvider.custom('/var/mobile/Containers/Data/Application/MyApp/CustomAmplitude')
  /// ```
  static StorageProvider custom(String directoryPath) => _CustomStorage(directoryPath);
}

/// Store Amplitude data in the Documents directory
///
/// - **Location**: `/Documents/amplitude_flutter/`
/// - **Visibility**: Visible in iOS Files app
/// - **Backup**: Included in iTunes/iCloud backup
/// - **Use case**: When you want data to be visible and backed up
class _DocumentsStorage extends StorageProvider {
  const _DocumentsStorage() : super('documents');

  @override
  String toString() => 'DocumentsStorage()';
}



/// Store Amplitude data in the Library directory (Recommended)
///
/// - **Location**: `/Library/amplitude_flutter/`
/// - **Visibility**: Hidden from iOS Files app
/// - **Backup**: Included in iTunes/iCloud backup
/// - **Use case**: When you want to hide amplitude data from users while keeping it backed up
class _LibraryStorage extends StorageProvider {
  const _LibraryStorage() : super('library');

  @override
  String toString() => 'LibraryStorage()';
}

/// Store Amplitude data in the Cache directory
///
/// - **Location**: `/Library/Caches/amplitude_flutter/`
/// - **Visibility**: Hidden from iOS Files app
/// - **Backup**: Not included in backups
/// - **Use case**: For temporary data that can be cleared by the system
///
/// **Warning**: Data may be lost if system needs to free up space
class _CacheStorage extends StorageProvider {
  const _CacheStorage() : super('cache');

  @override
  String toString() => 'CacheStorage()';
}

/// Store Amplitude data in a custom directory
///
/// - **Location**: Your specified path + `/amplitude_flutter/`
/// - **Visibility**: Depends on the path
/// - **Backup**: Depends on the path
/// - **Use case**: When you have specific requirements for data location
class _CustomStorage extends StorageProvider {
  /// The custom directory path where Amplitude data should be stored
  final String directoryPath;

  /// Create a custom storage provider with the specified directory path
  ///
  /// The path should be an absolute path within your app's sandbox.
  /// The SDK will create an `amplitude_flutter` subdirectory within this path.
  const _CustomStorage(this.directoryPath) : super('custom:$directoryPath');

  @override
  String toString() => 'CustomStorage($directoryPath)';
}
