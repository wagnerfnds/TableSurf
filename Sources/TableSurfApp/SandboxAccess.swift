import AppKit
import TableSurfCore

/// Acesso a arquivos fora do container quando o app roda no sandbox (build da Mac App
/// Store). Fora do sandbox tudo aqui é no-op.
///
/// O sandbox só libera o que o usuário escolheu num painel, e só até o app fechar. Para
/// valer nas próximas aberturas, cada escolha vira um security-scoped bookmark guardado
/// no UserDefaults e reativado no lançamento.
enum SandboxAccess {
    static var isSandboxed: Bool { SSHTunnel.isSandboxed }

    private static let defaultsKey = "sandbox.bookmarks"

    /// Reativa os bookmarks gravados. O acesso fica aberto pela vida do processo —
    /// conexões SQLite e túneis SSH abrem a qualquer momento.
    static func restore() {
        guard isSandboxed else { return }
        var bookmarks = stored
        for (path, data) in bookmarks {
            var stale = false
            guard let url = try? URL(resolvingBookmarkData: data, options: .withSecurityScope, bookmarkDataIsStale: &stale) else {
                bookmarks[path] = nil
                continue
            }
            _ = url.startAccessingSecurityScopedResource()
            if stale, let fresh = try? url.bookmarkData(options: .withSecurityScope) {
                bookmarks[path] = fresh
            }
        }
        stored = bookmarks
    }

    /// Guarda o acesso a uma URL vinda de um painel (arquivo ou pasta).
    static func remember(_ url: URL) {
        guard isSandboxed,
              let data = try? url.bookmarkData(options: .withSecurityScope) else { return }
        var bookmarks = stored
        bookmarks[url.standardizedFileURL.path] = data
        stored = bookmarks
    }

    /// O SQLite cria `-journal`/`-wal`/`-shm` ao lado do banco: liberar só o arquivo deixa
    /// ler mas falha na primeira escrita. Pede a pasta, já apontada para a certa.
    @MainActor
    static func grantFolder(containing file: URL) {
        guard isSandboxed else { return }
        let folder = file.deletingLastPathComponent()
        guard !hasAccess(to: folder) else { return }
        let panel = NSOpenPanel()
        panel.message = "Para gravar no banco, o SQLite precisa criar arquivos temporários ao lado dele. Permita o acesso à pasta \(folder.lastPathComponent)."
        panel.prompt = "Permitir"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = folder
        if panel.runModal() == .OK, let url = panel.url {
            remember(url)
        } else {
            // Sem a pasta, ao menos o arquivo: leitura funciona.
            remember(file)
        }
    }

    /// Pasta ~/.ssh real (não a do container): com ela o `ssh` lê config, chaves e
    /// known_hosts como fora do sandbox.
    static var sshFolder: URL { URL(fileURLWithPath: SSHTunnel.realHomeDirectory).appending(path: ".ssh", directoryHint: .isDirectory) }

    static var hasSSHFolderAccess: Bool { !isSandboxed || hasAccess(to: sshFolder) }

    @MainActor
    static func requestSSHFolder() {
        let panel = NSOpenPanel()
        panel.message = "Escolha a pasta .ssh para o TableSurf usar o seu ~/.ssh/config, as chaves e o known_hosts."
        panel.prompt = "Permitir"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.showsHiddenFiles = true
        panel.directoryURL = sshFolder
        if panel.runModal() == .OK, let url = panel.url {
            remember(url)
        }
    }

    private static func hasAccess(to folder: URL) -> Bool {
        let path = folder.standardizedFileURL.path
        return stored.keys.contains { path == $0 || path.hasPrefix($0 + "/") }
    }

    private static var stored: [String: Data] {
        get { UserDefaults.standard.dictionary(forKey: defaultsKey) as? [String: Data] ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: defaultsKey) }
    }
}
