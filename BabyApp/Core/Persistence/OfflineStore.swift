import Foundation
import SwiftData
import os

private let logger = Logger(subsystem: "com.babyapp", category: "offline")

// MARK: - Offline Queue Item

/// Represents a pending operation to sync when back online.
@Model
final class OfflineQueueItem {
    var id: UUID
    var tableName: String
    var operation: String // "insert", "update", "delete"
    var payload: Data // JSON-encoded data
    var createdAt: Date
    var retryCount: Int

    init(tableName: String, operation: String, payload: Data) {
        self.id = UUID()
        self.tableName = tableName
        self.operation = operation
        self.payload = payload
        self.createdAt = Date()
        self.retryCount = 0
    }
}

// MARK: - Offline Store

@Observable
final class OfflineStore {
    static let shared = OfflineStore()

    private var modelContainer: ModelContainer?
    var pendingCount = 0

    private init() {
        do {
            let schema = Schema([OfflineQueueItem.self])
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: config)
            logger.info("OfflineStore initialized")
        } catch {
            logger.error("Failed to initialize OfflineStore: \(error)")
        }
    }

    // MARK: - Queue Operations

    @MainActor
    func enqueue(tableName: String, operation: String, data: Encodable) {
        guard let container = modelContainer else { return }

        do {
            let jsonData = try JSONEncoder().encode(AnyEncodable(data))
            let item = OfflineQueueItem(
                tableName: tableName,
                operation: operation,
                payload: jsonData
            )
            let context = container.mainContext
            context.insert(item)
            try context.save()
            pendingCount += 1
            logger.info("Enqueued offline operation: \(operation) on \(tableName)")
        } catch {
            logger.error("Failed to enqueue offline operation: \(error)")
        }
    }

    @MainActor
    func fetchPending() -> [OfflineQueueItem] {
        guard let container = modelContainer else { return [] }

        let context = container.mainContext
        let descriptor = FetchDescriptor<OfflineQueueItem>(
            sortBy: [SortDescriptor(\.createdAt)]
        )

        do {
            let items = try context.fetch(descriptor)
            pendingCount = items.count
            return items
        } catch {
            logger.error("Failed to fetch pending items: \(error)")
            return []
        }
    }

    @MainActor
    func remove(_ item: OfflineQueueItem) {
        guard let container = modelContainer else { return }

        let context = container.mainContext
        context.delete(item)
        do {
            try context.save()
            pendingCount = max(0, pendingCount - 1)
        } catch {
            logger.error("Failed to remove offline item: \(error)")
        }
    }
}

// MARK: - Type Erasure Helper

private struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void

    init(_ value: Encodable) {
        self.encode = value.encode(to:)
    }

    func encode(to encoder: Encoder) throws {
        try encode(encoder)
    }
}
