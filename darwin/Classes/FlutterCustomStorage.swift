import Foundation
import AmplitudeSwift

/// Custom storage implementation for Flutter that implements the AmplitudeSwift Storage protocol
/// This allows Flutter developers to customize where and how Amplitude data is stored on iOS
public class FlutterCustomStorage: Storage {
    private let storageType: String
    private let customDirectory: String?
    private let fileManager = FileManager.default
    
    /// Initialize custom storage with specified type and optional custom directory
    /// - Parameters:
    ///   - storageType: Type of storage ("documents", "library", "cache", or "custom")
    ///   - customDirectory: Custom directory path (required if storageType is "custom")
    public init(storageType: String, customDirectory: String? = nil) {
        self.storageType = storageType
        self.customDirectory = customDirectory
    }
    
    /// Get the base directory URL based on storage type
    private func getBaseDirectory() -> URL? {
        switch storageType.lowercased() {
        case "documents":
            return fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        case "library":
            return fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first
        case "cache":
            return fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
        case "custom":
            guard let customPath = customDirectory else {
                print("FlutterCustomStorage: Custom directory path is required for custom storage type")
                return nil
            }
            return URL(fileURLWithPath: customPath)
        default:
            print("FlutterCustomStorage: Unknown storage type '\(storageType)', falling back to documents")
            return fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        }
    }
    
    /// Get the full file URL for a given key
    private func getFileURL(for key: String) -> URL? {
        guard let baseDirectory = getBaseDirectory() else {
            return nil
        }
        
        // Create amplitude subdirectory to avoid conflicts
        let amplitudeDirectory = baseDirectory.appendingPathComponent("amplitude_flutter")
        
        // Ensure directory exists
        do {
            try fileManager.createDirectory(at: amplitudeDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("FlutterCustomStorage: Failed to create directory: \(error)")
            return nil
        }
        
        return amplitudeDirectory.appendingPathComponent(key)
    }
    
    // MARK: - Storage Protocol Implementation
    
    public func write(key: String, value: Any?) {
        guard let fileURL = getFileURL(for: key) else {
            print("FlutterCustomStorage: Failed to get file URL for key: \(key)")
            return
        }
        
        do {
            if let value = value {
                let data = try JSONSerialization.data(withJSONObject: value, options: [])
                try data.write(to: fileURL)
            } else {
                // Remove file if value is nil
                if fileManager.fileExists(atPath: fileURL.path) {
                    try fileManager.removeItem(at: fileURL)
                }
            }
        } catch {
            print("FlutterCustomStorage: Failed to write value for key '\(key)': \(error)")
        }
    }
    
    public func read(key: String) -> Any? {
        guard let fileURL = getFileURL(for: key) else {
            print("FlutterCustomStorage: Failed to get file URL for key: \(key)")
            return nil
        }
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONSerialization.jsonObject(with: data, options: [])
        } catch {
            print("FlutterCustomStorage: Failed to read value for key '\(key)': \(error)")
            return nil
        }
    }
    
    public func remove(key: String) {
        guard let fileURL = getFileURL(for: key) else {
            print("FlutterCustomStorage: Failed to get file URL for key: \(key)")
            return
        }
        
        do {
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
        } catch {
            print("FlutterCustomStorage: Failed to remove value for key '\(key)': \(error)")
        }
    }
    
    public func reset() {
        guard let baseDirectory = getBaseDirectory() else {
            print("FlutterCustomStorage: Failed to get base directory for reset")
            return
        }
        
        let amplitudeDirectory = baseDirectory.appendingPathComponent("amplitude_flutter")
        
        do {
            if fileManager.fileExists(atPath: amplitudeDirectory.path) {
                try fileManager.removeItem(at: amplitudeDirectory)
            }
        } catch {
            print("FlutterCustomStorage: Failed to reset storage: \(error)")
        }
    }
    
    public func rollover() {
        // For file-based storage, rollover can be implemented as needed
        // This is typically used for database-based storage
        print("FlutterCustomStorage: Rollover called (no-op for file-based storage)")
    }
}

/// Factory class to create custom storage instances based on configuration
public class FlutterCustomStorageFactory {
    
    /// Create a custom storage instance based on the provided configuration string
    /// Configuration format: "type:directory" where directory is optional
    /// Examples:
    /// - "documents" - Store in Documents directory
    /// - "library" - Store in Library directory
    /// - "cache" - Store in Caches directory
    /// - "custom:/path/to/directory" - Store in custom directory
    public static func createStorage(from configuration: String) -> Storage? {
        let components = configuration.split(separator: ":", maxSplits: 1)
        
        guard !components.isEmpty else {
            print("FlutterCustomStorageFactory: Invalid configuration format")
            return nil
        }
        
        let storageType = String(components[0])
        let customDirectory = components.count > 1 ? String(components[1]) : nil
        
        return FlutterCustomStorage(storageType: storageType, customDirectory: customDirectory)
    }
}
