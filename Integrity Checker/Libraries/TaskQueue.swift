//
//  TaskQueue.swift
//  Integrity Checker
//
//  Created by Marvin Peter on 2024-05-19.
//

import Foundation

public final actor TaskQueue {
    private let concurrency: Int
    private var running: Int = 0
    private var queue = [CheckedContinuation<Void, Error>]()

    /// Creates a task queue which only allows a defined number of tasks to run concurrently
    /// - Parameter concurrency: Number of concurrent tasks
    public init(concurrency: Int) {
        self.concurrency = concurrency
    }

    deinit {
        for continuation in queue {
            continuation.resume(throwing: CancellationError())
        }
    }

    /// Default task queue which allows running a concurrent task for each core
    public static let global: TaskQueue = .init(concurrency: ProcessInfo().activeProcessorCount)

    /// Pushes a new task into the task queue and runs it once a slot is available
    /// - Parameter operation: Task
    /// - Returns: Task returns
    public func async<T>(_ operation: @escaping @Sendable () async throws -> T) async throws -> T {
        try Task.checkCancellation()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.append(continuation)
            tryRunEnqueued()
        }

        defer {
            running -= 1
            tryRunEnqueued()
        }

        try Task.checkCancellation()
        return try await operation()
    }

    private func tryRunEnqueued() {
        guard !queue.isEmpty else { return }
        guard running < concurrency else { return }

        running += 1
        let continuation = queue.removeFirst()
        continuation.resume()
    }
}
