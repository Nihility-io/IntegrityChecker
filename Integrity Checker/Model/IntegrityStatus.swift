//
//  IntegrityStatus.swift
//  Integrity Checker
//
//  Created by Marvin Peter on 2024-05-19.
//

import Foundation
import SwiftUI

enum IntegrityStatus {
    case new
    case unchecked
    case match
    case mismatch
    case hashing
    case checking
}

extension IntegrityStatus {
    /// Text explaination of the status
    var text: String {
        switch self {
        case .new: "New"
        case .unchecked: "Unchecked"
        case .match: "Match"
        case .mismatch: "Mismatch"
        case .hashing: "Hashing"
        case .checking: "Checking"
        }
    }

    // Symbol for the current status
    var symbol: String {
        switch self {
        case .new: "plus"
        case .unchecked: "questionmark"
        case .match: "checkmark"
        case .mismatch: "exclamationmark"
        case .hashing: "ellipsis"
        case .checking: "ellipsis"
        }
    }

    // Color of the current status
    var color: Color {
        switch self {
        case .new: .yellow
        case .unchecked: .blue
        case .match: .green
        case .mismatch: .red
        case .hashing: .teal
        case .checking: .teal
        }
    }
}
