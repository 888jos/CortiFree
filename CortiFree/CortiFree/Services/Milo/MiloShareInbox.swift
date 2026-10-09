//
//  MiloShareInbox.swift
//  CortiFree
//
//  Hand-off between the share extension (« Share › CortiFree » from ChatGPT, Claude,
//  Grok, Gemini, Files, Photos…) and the app. The extension drops what was shared
//  in the App Group container; the app picks it up, opens Milo and deletes it.
//  Compiled into both targets (see the exception set in the Xcode project).
//

import Foundation

enum MiloShareInbox {
    static let appGroupID = "group.com.solstys.cortifree"
    /// Opened by the extension so the app comes to the front on Milo.
    static let openURL = URL(string: "cortifree://milo-import")!

    struct Item: Codable, Equatable {
        enum Kind: String, Codable { case text, link, file }
        /// What the user asked Milo to do with it (nil = get to know me, for older shares).
        enum Mode: String, Codable { case story, decode }

        let id: UUID
        let kind: Kind
        var text: String?
        var link: String?
        var fileName: String?
        var mode: Mode? = nil
        let date: Date
    }

    private static var folder: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent("MiloInbox", isDirectory: true)
    }

    /// Keeps only the latest share: Milo reads one thing at a time.
    static func save(_ item: Item, fileData: Data? = nil) throws {
        guard let folder else { throw CocoaError(.fileNoSuchFile) }
        clear()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        if let fileData, let name = item.fileName {
            try fileData.write(to: folder.appendingPathComponent(name), options: .atomic)
        }
        try JSONEncoder().encode(item).write(to: folder.appendingPathComponent("item.json"), options: .atomic)
    }

    /// The pending share and its file (if any). Call `clear()` once it has been read.
    static func pending() -> (item: Item, file: URL?)? {
        guard let folder,
              let data = try? Data(contentsOf: folder.appendingPathComponent("item.json")),
              let item = try? JSONDecoder().decode(Item.self, from: data)
        else { return nil }
        // A share older than a day was abandoned: drop it rather than surprise the user.
        guard item.date > Date().addingTimeInterval(-86_400) else { clear(); return nil }
        let file = item.fileName.map { folder.appendingPathComponent($0) }
        return (item, file)
    }

    static func clear() {
        guard let folder else { return }
        try? FileManager.default.removeItem(at: folder)
    }
}
