//
//  Array.swift
//  Integrity Checker
//
//  Created by Marvin Peter on 2024-05-18.
//

import Foundation

extension Array: RawRepresentable where Element: Codable {
    public typealias RawValue = String

    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8) else {
            return nil
        }

        guard let res = try? JSONDecoder().decode(Self.self, from: data) else {
            return nil
        }

        self = res
    }

    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self) else {
            return ""
        }

        return String(data: data, encoding: .utf8) ?? ""
    }
}
