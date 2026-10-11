import XCTest

/// Capturas para a App Store. Roda pelo `appstore/screenshots.sh`, que instala o app,
/// semeia as conexões de exemplo e o banco "Loja (demo)" (dados inventados) e aponta
/// `TABLESURF_SHOTS` para a pasta de saída.
@MainActor
final class AppStoreScreenshots: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        // A interface é em português: o sistema (botões, teclado) também.
        app.launchArguments += ["-AppleLanguages", "(pt-BR)", "-AppleLocale", "pt_BR"]
        app.launch()
    }

    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    private func shot(_ name: String) {
        // Teclado, indicadores de rolagem e animações assentam antes da captura.
        sleep(1)
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        if let dir = ProcessInfo.processInfo.environment["TABLESURF_SHOTS"] {
            try? screenshot.pngRepresentation.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
        }
    }

    private func open(table: String) {
        let item = app.staticTexts[table].firstMatch
        XCTAssertTrue(item.waitForExistence(timeout: 10), "tabela \(table) não apareceu")
        item.tap()
        XCTAssertTrue(app.collectionViews.firstMatch.waitForExistence(timeout: 10))
        sleep(2)
    }

    func testScreenshots() throws {
        if isPad { XCUIDevice.shared.orientation = .landscapeLeft }
        XCTAssertTrue(app.staticTexts["Loja (demo)"].waitForExistence(timeout: 10))
        // A animação de abertura ainda está no ar quando a lista já existe.
        sleep(3)
        if !isPad { shot("01-conexoes") }

        app.staticTexts["Loja (demo)"].tap()
        XCTAssertTrue(app.staticTexts["pedidos"].waitForExistence(timeout: 10))
        if !isPad { shot("02-tabelas") }

        // Grid de clientes.
        open(table: "clientes")
        shot(isPad ? "01-grid" : "03-grid")

        // Detalhe da linha. Pelo texto da célula: no iPad a lista de tabelas também é
        // uma collection view, e vem antes da grade.
        app.staticTexts["Gabriela Cardoso"].firstMatch.tap()
        sleep(2)
        shot(isPad ? "02-detalhe-linha" : "04-detalhe-linha")
        app.buttons["Fechar"].firstMatch.tap()
        sleep(1)

        // Estrutura da tabela de pedidos.
        if !isPad {
            app.navigationBars.buttons.element(boundBy: 0).tap()
            sleep(1)
        }
        open(table: "pedidos")
        app.buttons["Estrutura"].tap()
        sleep(2)
        shot(isPad ? "03-estrutura" : "05-estrutura")
        app.buttons["Dados"].firstMatch.tap()
        sleep(1)

        // Console SQL com resultado.
        if !isPad {
            app.navigationBars.buttons.element(boundBy: 0).tap()
            sleep(1)
        }
        app.staticTexts["Console SQL"].tap()
        sleep(1)
        let editor = app.textViews["Editor SQL"]
        editor.tap()
        editor.typeText("SELECT cidade, pedidos, receita\nFROM vendas_por_cidade\nORDER BY receita DESC;")
        app.buttons["Executar"].firstMatch.tap()
        sleep(2)
        // Esconde o teclado para o resultado aparecer inteiro.
        if app.keyboards.firstMatch.exists {
            if app.buttons["Ocultar teclado"].exists { app.buttons["Ocultar teclado"].tap() }
            else { app.swipeDown() }
        }
        shot(isPad ? "04-console" : "06-console")
    }
}
