//
//  AppState.swift
//  Integrity Checker
//
//  Created by Marvin Peter on 2024-05-18.
//

import struct FileKit.Path
import Foundation
import SwiftUI

final class AppState: ObservableObject {
    @AppStorage("Folders") var folders: [String] = []
    @AppStorage("IncludeHidden") var includeHidden: Bool = false {
        didSet {
            reload()
        }
    }

    @Published var items: [IntegrityItem] = []
    @Published var isLoading: Bool = true

    init() {
        reload()
    }

    /// Adds a new folder to the integrity check
    /// - Parameter path: Folder path
    func add(folder path: Path) {
        Task(priority: .high) {
            folders.append(path.absolute.rawValue)
            let item = await IntegrityItem(path: path, includeHidden: self.includeHidden)
            DispatchQueue.main.async {
                self.items.append(item)
            }
        }
    }

    /// Removes a folder from the integrity check
    /// - Parameter path: Folder path
    func remove(folder path: Path) {
        folders.removeAll { $0 == path.absolute.rawValue }
        items.removeAll { $0.path.absolute == path }
    }

    /// Starts integrity check for all folders
    func verify() {
        for i in items {
            i.verify()
        }
    }

    func reload() {
        Task(priority: .high) {
            let res = try! await self.folders
                .concurrentMap { await IntegrityItem(path: Path($0), includeHidden: self.includeHidden) }
                .sorted()

            DispatchQueue.main.async {
                self.items = res
                self.isLoading = false
            }
        }
    }
}
