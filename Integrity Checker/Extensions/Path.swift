//
//  Path.swift
//  Integrity Checker
//
//  Created by Marvin Peter on 2024-05-18.
//

import AppKit
import CryptoKit
import FileKit
import Foundation
import XAttr

extension Path {
    /// Get path without file extension
    public var withoutExtension: Path {
        parent + url.deletingPathExtension().lastPathComponent
    }

    /// Get a new path by replace the file extension
    /// - Parameter ext: New file extension
    public func replacingExtension(with ext: String) -> Path {
        parent + "\(url.deletingPathExtension().lastPathComponent).\(ext)"
    }

    // Gets or sets the preview icon for a file or folder
    var icon: NSImage {
        get {
            return NSWorkspace.shared.icon(forFile: rawValue)
        }
        set {
            NSWorkspace.shared.setIcon(newValue.square(size: 1024), forFile: rawValue)
        }
    }

    /// Resets the preview icon of a file or folder to the default
    func resetIcon() {
        NSWorkspace.shared.setIcon(nil, forFile: rawValue)
    }

    /// Gets or sets the hidden flag for a file or folder
    var hidden: Bool {
        get {
            guard let isHidden = try? url.resourceValues(forKeys: [.isHiddenKey]).isHidden else {
                return false
            }
            return isHidden
        }
        set {
            var resourceValues = URLResourceValues()
            resourceValues.isHidden = newValue
            var url = self.url
            try? url.setResourceValues(resourceValues)
        }
    }

    /// File system attributes
    var attributes: [FileAttributeKey: Any] {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: rawValue) else {
            return [:]
        }

        return attributes
    }

    /// Gets a file system attribute
    /// - Parameters:
    ///   - key: Attribute key
    ///   - t: Return type
    func getAttribute<T>(for key: FileAttributeKey, as _: T.Type = T.self) -> T? {
        guard
            let resAny = attributes[key],
            let res = resAny as? T
        else {
            return nil
        }

        return res
    }

    /// Sets a file system attribute
    /// - Parameters:
    ///   - key: Attribute key
    ///   - value: Attribute value
    func setAttribute(for key: FileAttributeKey, value: Any) {
        try? FileManager.default.setAttributes([key: value], ofItemAtPath: rawValue)
    }

    /// Gets a list of all extended attributes of a file or folder
    var extendedAtrributes: [String: Data] {
        return (try? url.extendedAttributeValues()) ?? [:]
    }

    /// Gets an extended attribute of a file or folder
    /// - Parameter name: Attribute name
    func getExtendedAttribute(for name: String) -> Data? {
        guard let value = try? url.extendedAttributeValue(forName: name) else {
            return nil
        }

        return value
    }

    /// Sets an extended attribute of a file or folder
    /// - Parameters:
    ///   - name: Attribute name
    ///   - data: Attribute data (nil removes the attribute)
    func setExtendedAttribute(for name: String, with value: Data?) throws {
        if let value {
            try? url.setExtendedAttribute(name: name, value: value)
        } else {
            try? url.removeExtendedAttribute(forName: name)
        }
    }

    /// Computes a SHA256 hash of a file
    func hash() async throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        var hasher = SHA256()

        while autoreleasepool(invoking: {
            let nextChunk = handle.readData(ofLength: SHA256.blockByteCount * 8 * 10)
            guard !nextChunk.isEmpty else { return false }
            hasher.update(data: nextChunk)
            return true
        }) {}

        return hasher.finalize().map { String(format: "%02hhx", $0) }.joined()
    }
}

extension Path: Comparable {
    public static func < (lhs: Path, rhs: Path) -> Bool {
        return lhs.absolute.rawValue < rhs.absolute.rawValue
    }
}
