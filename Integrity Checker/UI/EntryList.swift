//
//  EntryList.swift
//  Integrity Checker
//
//  Created by Marvin Peter on 2024-05-18.
//

import struct FileKit.Path
import Foundation
import SwiftUI

struct EntryList: View {
    @EnvironmentObject private var state: AppState
    @State private var selection: Set<String> = []

    var body: some View {
        if state.isLoading {
            ProgressView("Loading Files")
        } else {
            List(state.items, id: \.id, children: \.children) {
                EntryItem(item: $0).environmentObject(state)
            }
        }
    }
}
