import Foundation

/// Service to manage recent project folders (max 12)
@MainActor
class RecentFoldersService {
    static let shared = RecentFoldersService()

    private let maxCount = 12
    private let key = "recentProjectFolders"
    private let backupKey = "recentProjectFoldersBackup"

    private nonisolated(unsafe) var folders: [String] = []

    private init() {
        load()
    }

    /// Get all recent folders
    var recentFolders: [String] {
        folders
    }

    /// Add a folder to recent list (moves to front if exists)
    func addFolder(_ path: String) {
        guard !path.isEmpty else { return }

        // Remove if exists
        folders.removeAll { $0 == path }

        // Add to front
        folders.insert(path, at: 0)

        // Keep max 12
        if folders.count > maxCount {
            folders = Array(folders.prefix(maxCount))
        }

        save()
    }

    /// Remove a folder from the list
    func removeFolder(_ path: String) {
        folders.removeAll { $0 == path }
        save()
    }

    /// Clear all recent folders (previous list is kept so it can be restored)
    func clearAll() {
        if !folders.isEmpty {
            UserDefaults.standard.set(folders, forKey: backupKey)
        }
        folders.removeAll()
        save()
    }

    /// True when a cleared list is available to restore
    var canRestore: Bool {
        !(UserDefaults.standard.stringArray(forKey: backupKey) ?? []).isEmpty
    }

    /// Restore the list saved by the last clearAll()
    func restore() {
        let backup = UserDefaults.standard.stringArray(forKey: backupKey) ?? []
        guard !backup.isEmpty else { return }
        folders = Array((folders + backup.filter { !folders.contains($0) }).prefix(maxCount))
        UserDefaults.standard.removeObject(forKey: backupKey)
        save()
    }

    private func load() {
        folders = UserDefaults.standard.stringArray(forKey: key) ?? []
    }

    private func save() {
        UserDefaults.standard.set(folders, forKey: key)
    }
}
