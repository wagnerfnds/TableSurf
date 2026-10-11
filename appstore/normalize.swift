// Regrava PNGs com a orientação aplicada aos pixels. O XCUIScreen grava a captura do
// iPad em paisagem como retrato + tag de orientação, e o App Store Connect olha os pixels.
//
//   swift appstore/normalize.swift arquivo.png...
import AppKit
import ImageIO

for path in CommandLine.arguments.dropFirst() {
    let url = URL(fileURLWithPath: path) as CFURL
    guard let source = CGImageSourceCreateWithURL(url, nil),
          let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
              kCGImageSourceCreateThumbnailWithTransform: true,
              kCGImageSourceCreateThumbnailFromImageAlways: true,
              kCGImageSourceThumbnailMaxPixelSize: 100_000,
          ] as CFDictionary),
          let destination = CGImageDestinationCreateWithURL(url, "public.png" as CFString, 1, nil)
    else { print("falhou: \(path)"); continue }
    CGImageDestinationAddImage(destination, image, nil)
    CGImageDestinationFinalize(destination)
    print("\(image.width)x\(image.height) \(path)")
}
