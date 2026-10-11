import AppKit
import XCTest

/// Capturas da Mac App Store. Roda pelo `appstore/screenshots-mac.sh`, que monta uma
/// home fictícia (`TABLESURF_DEMO_HOME`) com as conexões de exemplo e o banco
/// "Loja (demo)" — o app não enxerga as conexões reais de quem roda.
@MainActor
final class MacScreenshots: XCTestCase {
    private var app: XCUIApplication!

    private var env: [String: String] { ProcessInfo.processInfo.environment }

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        if let home = env["TABLESURF_DEMO_HOME"] { app.launchEnvironment["CFFIXED_USER_HOME"] = home }
        app.launchArguments += [
            "-AppleLanguages", "(pt-BR)", "-AppleLocale", "pt_BR",
            "-general.appearance", env["TABLESURF_APPEARANCE"] ?? "light",
            "-general.reconnectOnLaunch", "NO",
            // A digitação do teste é rápida demais: o autocomplete aceitaria sugestões no meio.
            "-editor.autoCompletion", "NO",
        ]
        app.launch()
    }

    private func shot(_ name: String) {
        sleep(1)
        let screenshot = app.windows.firstMatch.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        if let dir = env["TABLESURF_SHOTS"] {
            try? screenshot.pngRepresentation.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
        }
    }

    func testScreenshots() throws {
        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 10))
        // Janela larga: o frame salvo é ignorado quando o XCUITest lança o app, e
        // arrastar a borda não redimensiona. O Zoom ocupa a tela; a composição final
        // (appstore/compose-mac.swift) põe a janela em 2880×1800.
        app.menuBarItems["Window"].click()
        app.menuItems["Zoom"].click()
        sleep(1)

        let connection = app.staticTexts["Loja (demo)"].firstMatch
        XCTAssertTrue(connection.waitForExistence(timeout: 10))
        connection.click()

        // No Mac o texto do SwiftUI chega como `value`, não como `label`.
        let table = app.staticTexts.matching(NSPredicate(format: "value == 'pedidos'")).firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 10))
        table.click()
        sleep(3)
        shot("01-grid")

        // Console: nova aba de consulta (⌘T), digita e executa (⌘⏎).
        app.typeKey("t", modifierFlags: .command)
        sleep(1)
        app.textViews.firstMatch.click()
        app.typeKey("a", modifierFlags: .command)
        // Colada, não digitada: a digitação sintética perdia todo "c" neste Mac.
        let query = """
        SELECT c.cidade, COUNT(*) AS pedidos, ROUND(SUM(p.total), 2) AS receita
        FROM pedidos p
        JOIN clientes c ON c.id = p.cliente_id
        WHERE p.status <> 'cancelado'
        GROUP BY c.cidade
        ORDER BY receita DESC;
        """
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(query, forType: .string)
        app.typeKey("v", modifierFlags: .command)
        sleep(1)
        app.typeKey(.return, modifierFlags: .command)
        sleep(3)
        shot("02-console")

        let clients = app.staticTexts.matching(NSPredicate(format: "value == 'clientes'")).firstMatch
        clients.click()
        sleep(3)
        shot("03-clientes")
    }
}
