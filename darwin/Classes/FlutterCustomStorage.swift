import Foundation
import AmplitudeSwift

/// Custom storage implementation for Flutter that implements the AmplitudeSwift Storage protocol
/// This allows Flutter developers to customize where Amplitude data is stored on iOS
public class FlutterCustomStorage: Storage {
    private let storageDirectory: URL
    private let fileManager = FileManager.default

    /// Initialize custom storage with a specific directory
    /// - Parameter storageDirectory: The directory where Amplitude data should be stored
    public init(storageDirectory: URL) {
        self.storageDirectory = storageDirectory

        // Ensure the directory exists
        do {
            try fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("FlutterCustomStorage: Failed to create storage directory: \(error)")
        }
    }

    /// Initialize custom storage from configuration string
    /// - Parameter configuration: Configuration string in format "type" or "type:directory"
    /// Examples: "documents", "library", "cache", "custom:/path/to/directory"
    public convenience init?(from configuration: String) {
        let components = configuration.split(separator: ":", maxSplits: 1)

        guard !components.isEmpty else {
            print("FlutterCustomStorage: Invalid configuration format")
            return nil
        }

        let storageType = String(components[0])
        let customDirectory = components.count > 1 ? String(components[1]) : nil

        // Get the custom storage directory path
        guard let storageDirectory = Self.getStorageDirectory(for: storageType, customPath: customDirectory) else {
            print("FlutterCustomStorage: Failed to determine storage directory for type: \(storageType)")
            return nil
        }

        self.init(storageDirectory: storageDirectory)
    }

    // MARK: - Storage Protocol Implementation

    public func write(key: StorageKey, value: Any?) throws {
        let fileURL = storageDirectory.appendingPathComponent(key.rawValue)

        if let value = value {
            // Wrap the value in a dictionary to ensure valid JSON serialization
            let wrappedValue = ["value": value]
            let data = try JSONSerialization.data(withJSONObject: wrappedValue, options: [])
            try data.write(to: fileURL)
        } else {
            // Remove file if value is nil
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
        }
    }

    public func read<T>(key: StorageKey) -> T? {
        let fileURL = storageDirectory.appendingPathComponent(key.rawValue)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])

            // Unwrap the value from the dictionary wrapper
            if let wrappedValue = jsonObject as? [String: Any],
               let actualValue = wrappedValue["value"] {
                return actualValue as? T
            }

            return nil
        } catch {
            print("FlutterCustomStorage: Failed to read value for key '\(key)': \(error)")
            return nil
        }
    }

    public func getEventsString(eventBlock: URL) -> String? {
        do {
            return try String(contentsOf: eventBlock, encoding: .utf8)
        } catch {
            print("FlutterCustomStorage: Failed to read events string from \(eventBlock): \(error)")
            return nil
        }
    }

    public func remove(eventBlock: URL) {
        do {
            if fileManager.fileExists(atPath: eventBlock.path) {
                try fileManager.removeItem(at: eventBlock)
            }
        } catch {
            print("FlutterCustomStorage: Failed to remove event block \(eventBlock): \(error)")
        }
    }

    public func splitBlock(eventBlock: URL, events: [BaseEvent]) {
        // Simple implementation: just log the operation
        print("FlutterCustomStorage: splitBlock called for \(eventBlock) with \(events.count) events")
        print("FlutterCustomStorage: Block splitting not implemented for file-based storage")
    }

    public func rollover() {
        // For file-based storage, rollover can be implemented as needed
        print("FlutterCustomStorage: Rollover called (no-op for file-based storage)")
    }

    public func reset() {
        do {
            if fileManager.fileExists(atPath: storageDirectory.path) {
                try fileManager.removeItem(at: storageDirectory)
                // Recreate the directory
                try fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: true, attributes: nil)
            }
        } catch {
            print("FlutterCustomStorage: Failed to reset storage: \(error)")
        }
    }

    public func getResponseHandler(
        configuration: Configuration,
        eventPipeline: EventPipeline,
        eventBlock: URL,
        eventsString: String
    ) -> ResponseHandler {
        // This method is for advanced HTTP response handling
        // For basic custom storage operations, this might not be called
        fatalError("FlutterCustomStorage: getResponseHandler not implemented. This is an advanced feature that may not be needed for basic custom storage operations.")
    }

    /// Get the storage directory URL based on storage type
    /// - Parameters:
    ///   - storageType: Type of storage ("documents", "library", "cache", or "custom")
    ///   - customPath: Custom directory path (required if storageType is "custom")
    /// - Returns: URL for the storage directory, or nil if invalid
    private static func getStorageDirectory(for storageType: String, customPath: String?) -> URL? {
        let fileManager = FileManager.default

        let baseDirectory: URL?
        switch storageType.lowercased() {
        case "documents":
            baseDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        case "library":
            baseDirectory = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first
        case "cache":
            baseDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
        case "custom":
            guard let customPath = customPath else {
                print("FlutterCustomStorage: Custom directory path is required for custom storage type")
                return nil
            }
            baseDirectory = URL(fileURLWithPath: customPath)
        default:
            print("FlutterCustomStorage: Unknown storage type '\(storageType)', falling back to documents")
            baseDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        }

        guard let base = baseDirectory else {
            return nil
        }

        // Create amplitude subdirectory to avoid conflicts
        return base.appendingPathComponent("amplitude_flutter")
    }
}