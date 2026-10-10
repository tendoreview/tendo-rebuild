import Foundation
import UIKit

/// Local JSON database for the engine configuration, player state, and intake photos.
nonisolated enum PersistenceService {
    private static let configFile = "engine-configuration.json"
    private static let stateFile = "game-state.json"

    private static var directory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        let dir = base.appendingPathComponent("TendoRebuild", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private static var photoDirectory: URL {
        let dir = directory.appendingPathComponent("photos", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private static func encoder() -> JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }

    private static func decoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    static func loadConfiguration() -> EngineConfiguration? {
        load(EngineConfiguration.self, file: configFile)
    }

    static func saveConfiguration(_ configuration: EngineConfiguration) {
        save(configuration, file: configFile)
    }

    static func loadState() -> GameState? {
        load(GameState.self, file: stateFile)
    }

    static func saveState(_ state: GameState) {
        save(state, file: stateFile)
    }

    private static func load<T: Decodable>(_ type: T.Type, file: String) -> T? {
        let url = directory.appendingPathComponent(file)
        guard let data = try? Data(contentsOf: url) else { return nil }
        do {
            return try decoder().decode(T.self, from: data)
        } catch {
            print("[Persistence] Failed to decode \(file); falling back to defaults.")
            return nil
        }
    }

    private static func save<T: Encodable>(_ value: T, file: String) {
        let url = directory.appendingPathComponent(file)
        do {
            let data = try encoder().encode(value)
            try data.write(to: url, options: .atomic)
        } catch {
            print("[Persistence] Failed to save \(file).")
        }
    }

    static func savePhoto(_ data: Data) -> String? {
        guard let image = UIImage(data: data), let jpeg = image.jpegData(compressionQuality: 0.75) else { return nil }
        let name = "\(UUID().uuidString).jpg"
        do {
            try jpeg.write(to: photoDirectory.appendingPathComponent(name), options: .atomic)
            return name
        } catch {
            print("[Persistence] Failed to save photo.")
            return nil
        }
    }

    static func photo(named name: String) -> UIImage? {
        UIImage(contentsOfFile: photoDirectory.appendingPathComponent(name).path)
    }
}
