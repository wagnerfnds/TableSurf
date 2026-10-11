// Monta a captura da Mac App Store (2880×1800): fundo, título, subtítulo e a janela.
//
//   swift appstore/compose-mac.swift janela.png saida.png light|dark "Título" "Subtítulo"
import AppKit

let args = CommandLine.arguments
let window = NSImage(contentsOfFile: args[1])!
let dark = args[3] == "dark"
let title = args[4].replacingOccurrences(of: "\\n", with: "\n")
let subtitle = args[5]
let size = NSSize(width: 2880, height: 1800)

let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 2880, pixelsHigh: 1800, bitsPerSample: 8,
                           samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                           bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// Fundo: o mesmo degradê do ícone.
let top = dark ? NSColor(displayP3Red: 0.05, green: 0.22, blue: 0.32, alpha: 1) : NSColor(displayP3Red: 0.18, green: 0.78, blue: 0.86, alpha: 1)
let bottom = dark ? NSColor(displayP3Red: 0.02, green: 0.08, blue: 0.16, alpha: 1) : NSColor(displayP3Red: 0.04, green: 0.40, blue: 0.78, alpha: 1)
NSGradient(starting: bottom, ending: top)!.draw(in: NSRect(origin: .zero, size: size), angle: 90)

// Janela à direita, com sombra.
let maxHeight = 1560.0
let scale = min(maxHeight / window.size.height, 1500 / window.size.width)
let winSize = NSSize(width: window.size.width * scale, height: window.size.height * scale)
let winRect = NSRect(x: size.width - 140 - winSize.width, y: (size.height - winSize.height) / 2, width: winSize.width, height: winSize.height)
NSGraphicsContext.saveGraphicsState()
let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.45)
shadow.shadowBlurRadius = 60
shadow.shadowOffset = NSSize(width: 0, height: -20)
shadow.set()
window.draw(in: winRect)
NSGraphicsContext.restoreGraphicsState()

// Textos à esquerda.
let textWidth = winRect.minX - 140 - 100
let paragraph = NSMutableParagraphStyle()
paragraph.lineSpacing = 6
let titleAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 112, weight: .bold), .foregroundColor: NSColor.white, .paragraphStyle: paragraph,
]
let subAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 52, weight: .medium), .foregroundColor: NSColor.white.withAlphaComponent(0.85), .paragraphStyle: paragraph,
]
let titleString = NSAttributedString(string: title, attributes: titleAttrs)
let subString = NSAttributedString(string: subtitle, attributes: subAttrs)
let titleBox = titleString.boundingRect(with: NSSize(width: textWidth, height: 1000), options: .usesLineFragmentOrigin)
let subBox = subString.boundingRect(with: NSSize(width: textWidth, height: 1000), options: .usesLineFragmentOrigin)
let total = titleBox.height + 50 + subBox.height
let originY = (size.height - total) / 2
subString.draw(with: NSRect(x: 140, y: originY, width: textWidth, height: subBox.height), options: .usesLineFragmentOrigin)
titleString.draw(with: NSRect(x: 140, y: originY + subBox.height + 50, width: textWidth, height: titleBox.height), options: .usesLineFragmentOrigin)

NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: args[2]))
