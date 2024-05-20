//
//  ListItem.swift
//  Integrity Checker
//
//  Created by Marvin Peter on 2024-05-18.
//

import FileKit
import struct FileKit.Path
import Foundation
import SwiftUI


struct EntryItem: View {
    @EnvironmentObject private var state: AppState
    @ObservedObject var item: IntegrityItem

    @ViewBuilder var leftActions: some View {
        Button {
            item.verify()
        } label: {
            Label("Run", systemImage: "play.fill")
        }.labelStyle(.titleAndIcon)

        Button {
            item.hash(newOnly: true)
        } label: {
            Label("Hash New", systemImage: "number")
        }.labelStyle(.titleAndIcon)
    }

    @ViewBuilder var rightActions: some View {
        if item.isRoot {
            Button(role: .destructive) {
                state.remove(folder: item.path)
            } label: {
                Label("Delete", systemImage: "trash")
            }.labelStyle(.titleAndIcon)
        } else {
            Button(role: .destructive) {
                item.hash()
            } label: {
                Label("Rehash", systemImage: "arrow.clockwise")
            }.labelStyle(.titleAndIcon)
        }
    }

    @ViewBuilder var status: some View { 
        if item.status == .checking || item.status == .hashing {
            let (current, total) = item.progress
            ProgressView(value: Double(current), total: Double(total))
                .progressViewStyle(.circular)
        } else {
            Label {
                Text(item.status.text)
            } icon: {
                Image(systemName: item.status.symbol)
                    .foregroundStyle(item.status.color)
            }
        }
    }

    var body: some View {
        HStack {
            Image(nsImage: item.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48, height: 48, alignment: .center)
            VStack(alignment: .leading) {
                Text(item.name).bold().lineLimit(2)
                Text(item.description).font(.footnote).lineLimit(1)
            }
            Spacer()
            status
        }.contextMenu {
            leftActions
            Divider()
            rightActions
        }.swipeActions(edge: .leading) {
            leftActions
        }.swipeActions(edge: .trailing) {
            rightActions
        }
    }
}
