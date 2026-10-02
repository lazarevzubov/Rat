import Foundation
@testable
import Rat
import SwiftData
import Testing

struct ModelContainerFactoryTests {

    // MARK: - Properties

    // MARK: Private properties

    private var storeURL: URL { FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).store") }

    // MARK: - Methods

    @Test
    func make_returnsContainer_whenStoreIsValid() throws {
        let url = storeURL
        defer { removeStoreFiles(at: url) }

        let schema = Schema([ProgramEntity.self])
        let configuration = ModelConfiguration(schema: schema, url: url)

        _ = try ModelContainerFactory.makeModelContainer(schema: schema, configuration: configuration)
    }

    @Test
    func make_recoversFromCorruptedStore() throws {
        let url = storeURL
        defer { removeStoreFiles(at: url) }

        try Data("Not a valid SQLite store.".utf8).write(to: url)

        let schema = Schema([ProgramEntity.self])
        let configuration = ModelConfiguration(schema: schema, url: url)

        _ = try ModelContainerFactory.makeModelContainer(schema: schema, configuration: configuration)
    }

    // MARK: Private methods

    private func removeStoreFiles(at url: URL) {
        for suffix in [
            "",
            "-shm",
            "-wal"
        ] {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: url.path + suffix))
        }
    }

}
