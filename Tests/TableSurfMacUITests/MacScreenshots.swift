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

        let connection = app.staticTexts["Loja (demo)"].firstMatch
        XCTAssertTrue(connection.waitForExistence(timeout: 10))
        connection.click()

        let table = app.staticTexts["pedidos"].firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 10))
        table.click()
        sleep(3)
        shot("01-grid")

        // Console: nova aba de consulta (⌘T), digita e executa (⌘⏎).
        app.typeKey("t", modifierFlags: .command)
        sleep(1)
        app.typeText("""
        SELECT c.cidade, COUNT(*) AS pedidos, ROUND(SUM(p.total), 2) AS receita
        FROM pedidos p
        JOIN clientes c ON c.id = p.cliente_id
        WHERE p.status <> 'cancelado'
        GROUP BY c.cidade
        ORDER BY receita DESC;
        """)
        app.typeKey(.return, modifierFlags: .command)
        sleep(3)
        shot("02-console")

        let clients = app.staticTexts["clientes"].firstMatch
        clients.click()
        sleep(3)
        shot("03-clientes")
    }
}
