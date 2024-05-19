//
//  FileSystemItem.swift
//  Integrity Checker
//
//  Created by Marvin Peter on 2024-05-18.
//

import AppKit
import FileKit
import Foundation
import OSLog

let hashKey = "io.nihlity.hash"
let hashQueue = TaskQueue(concurrency: 4)

final class IntegrityItem: ObservableObject, Identifiable, Comparable {
    let path: Path
    let icon: NSImage
    weak var parent: IntegrityItem?
    @Published var children: [IntegrityItem]?
    @Published var status: IntegrityStatus

    /// Creates a new integrity item
    /// - Parameters:
    ///   - path: Path to folder or file
    ///   - includeHidden: Set if hidden files and folders should be included in the children
    convenience init(path: Path, includeHidden: Bool) async {
        await self.init(path: path, includeHidden: includeHidden, parent: nil)
    }

    /// Creates a new integrity item
    /// - Parameters:
    ///   - path: Path to folder or file
    ///   - includeHidden: Set if hidden files and folders should be included in the children
    ///   - parent: Set the parent of the current item
    private init(path: Path, includeHidden: Bool, parent: IntegrityItem?) async {
        self.path = path
        self.icon = path.icon
        self.status = .new
        self.fileHash = nil
        self.parent = parent
        self.children = nil

        if path.isDirectory {
            self.status = .unchecked
        } else if fileHash != nil {
            self.status = .unchecked
        }

        if path.isDirectory {
            let children = try? await path.children()
                .filter { $0.isDirectory || $0.isRegular }
                .filter { includeHidden || $0.hidden == false }
                .concurrentMap { await IntegrityItem(path: $0, includeHidden: includeHidden, parent: self) }
                .sorted()
            DispatchQueue.main.async {
                self.children = children
            }
        }
    }

    /// Checks if the item has no parent
    var isRoot: Bool {
        return parent == nil
    }

    /// Checks if the item is backed by a file
    var isFile: Bool {
        return path.isRegular
    }

    /// Path befind the item
    var id: String {
        return path.absolute.rawValue
    }

    /// File or folder name of the current item
    var name: String {
        return path.fileName
    }

    // User-facing description for the item
    var description: String {
        if isFile {
            return "Hash: \(fileHash ?? "None")"
        } else {
            return "Folder"
        }
    }

    /// Hash of the given files as stored inside the extended attributes
    var fileHash: String? {
        get {
            if children != nil {
                return nil
            }

            guard let hash = path.getExtendedAttribute(for: hashKey) else {
                return nil
            }
            return String(data: hash, encoding: .utf8)
        }
        set {
            if children != nil {
                return
            }

            guard let newValue else {
                return
            }
            try! path.setExtendedAttribute(for: hashKey, with: newValue.data(using: .utf8)!)
        }
    }

    /// Current progress when hashing or checking
    var progress: (Int, Int) {
        if isFile {
            return status == .hashing || status == .checking ? (0, 1) : (1, 1)
        } else {
            return children?
                .map { $0.progress }
                .reduce((0, 0)) { ($0.0 + $1.0, $0.1 + $1.1) } ?? (1, 1)
        }
    }

    /// Generates hashes for the current item and it's children
    /// - Parameter newOnly: If true, do not rehash files if existing hashes
    func hash(newOnly: Bool = false) {
        status = .hashing
        parent?.updateStatus()

        // If the item is a folder, hash all children
        if let children {
            for c in children {
                c.hash()
            }
        } else {
            // If newOnly is set and the file already has a hash, skip it
            if newOnly && fileHash != nil {
                return
            }

            // If the item is a file, hash the file
            Task(priority: .high) {
                try? await hashQueue.async {
                    Logger.background.log("Hashing \(self.path.rawValue)")
                    do {
                        let chash = try await self.path.hash()
                        DispatchQueue.main.async {
                            self.fileHash = chash
                            self.status = .unchecked
                            self.parent?.updateStatus()
                        }
                    } catch {
                        Logger.background.error("Failed to hash \(self.path.rawValue): \(error.localizedDescription)")
                        self.status = .mismatch
                        self.parent?.updateStatus()
                    }
                }
            }
        }

        parent?.updateStatus()
    }

    /// Verifies the integrity of the item by comparing the current hash with the stored hash
    func verify() {
        status = .checking

        // If the item is a folder, verify all children
        if let children {
            for c in children {
                c.verify()
            }
        } else {
            // If the item is a file, verify its integrity
            Task(priority: .high) {
                try? await hashQueue.async {
                    Logger.background.log("Checking \(self.path.rawValue)")

                    do {
                        // Generate current file hash
                        let chash = try await self.path.hash()
                        DispatchQueue.main.async {
                            // Verify that the computed and stored hash match
                            if let hash = self.fileHash {
                                self.status = hash == chash ? .match : .mismatch
                            } else {
                                // If the file has no stored hash, store it now
                                self.status = .match
                                self.fileHash = chash
                            }
                            self.parent?.updateStatus()
                        }
                    } catch {
                        Logger.background.error("Failed to verify \(self.path.rawValue): \(error.localizedDescription)")
                        self.status = .mismatch
                        self.parent?.updateStatus()
                    }
                }
            }
        }
    }

    /// Updates the status of an item based on its children
    private func updateStatus() {
        // Do nothing for files
        guard let children else {
            return
        }

        // Determine the status of the folder
        let res = children.map(\.status)
        if res.allSatisfy({ $0 == .match }) {
            status = .match
        } else if res.contains(where: { $0 == .mismatch }) {
            status = .mismatch
        } else if res.contains(where: { $0 == .hashing }) {
            status = .hashing
        } else if res.contains(where: { $0 == .checking }) {
            status = .checking
        } else {
            status = .unchecked
        }

        parent?.updateStatus()
    }

    /// Checks if both items are equal
    /// - Parameters:
    ///   - lhs: First item
    ///   - rhs: Second item
    /// - Returns: True if equal
    static func == (lhs: IntegrityItem, rhs: IntegrityItem) -> Bool {
        return lhs.path == rhs.path
    }

    /// Compares two items
    /// - Parameters:
    ///   - lhs: First item
    ///   - rhs: Second item
    /// - Returns: True if the second item is alphabetically after the first
    static func < (lhs: IntegrityItem, rhs: IntegrityItem) -> Bool {
        return lhs.path < rhs.path
    }
}
