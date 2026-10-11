import Foundation

/// Pasta de dados do app em Application Support.
public enum AppSupport {
    public static var directory: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL.applicationSupportDirectory
        return support.appending(path: "TableSurf", directoryHint: .isDirectory)
    }

    /// Arquivo de dados. Na primeira leitura depois da troca de nome, copia o arquivo
    /// da pasta antiga ("DBDeck") — copia em vez de mover para uma versão anterior
    /// instalada ao lado continuar funcionando.
    public static func file(_ name: String) -> URL {
        let url = directory.appending(path: name)
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: url.path) {
            let legacy = directory.deletingLastPathComponent().appending(path: "DBDeck/\(name)")
            if fileManager.fileExists(atPath: legacy.path) {
                try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
                try? fileManager.copyItem(at: legacy, to: url)
            }
        }
        return url
    }
}
