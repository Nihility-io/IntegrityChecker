//
//  ContentView.swift
//  Integrity Checker
//
//  Created by Marvin Peter on 2024-05-18.
//

import FileKit
import struct FileKit.Path
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var state: AppState
    @State private var isImporting: Bool = false

    @ToolbarContentBuilder var toolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                isImporting.toggle()
            } label: {
                Label("Add Folder", systemImage: "plus").labelStyle(.titleAndIcon)
            }.buttonStyle(BorderlessButtonStyle.borderless)

            Button {
                state.verify()
            } label: {
                Label("Run", systemImage: "play.fill").labelStyle(.titleAndIcon)
            }.buttonStyle(BorderlessButtonStyle.borderless)

            Menu {
                Toggle(isOn: $state.includeHidden, label: {
                    Text("Include hidden files")
                })
            } label: {
                Image(systemName: "ellipsis.circle")
            }.buttonStyle(BorderlessButtonStyle.borderless)
        }
    }

    var body: some View {
        EntryList()
            .environmentObject(state)
            .fileImporter(isPresented: $isImporting, allowedContentTypes: [.folder]) {
                if case let .success(folder) = $0 {
                    state.add(folder: Path(url: folder)!)
                }
            }.listStyle(.sidebar)
            .toolbar { toolbar }
    }
}
