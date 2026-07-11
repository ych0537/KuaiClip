#!/usr/bin/env swift

import AppKit
import Foundation

/// Generates the complete macOS icon set from the black-and-white seal artwork.
let iconDirectory = "Sources/KuaiClip/Resources/Assets.xcassets/AppIcon.appiconset"
let sourceURL = URL(fileURLWithPath: "\(iconDirectory)/appicon-master.png")

guard let source = NSImage(contentsOf: sourceURL) else {
    fatalError("Could not load \(sourceURL.path)")
}

let outputs: [(name: String, pixels: Int)] = [
    ("appicon-16.png", 16),
    ("appicon-16@2x.png", 32),
    ("appicon-32.png", 32),
    ("appicon-32@2x.png", 64),
    ("appicon-128.png", 128),
    ("appicon-128@2x.png", 256),
    ("appicon-256.png", 256),
    ("appicon-256@2x.png", 512),
    ("appicon-512.png", 512),
    ("appicon-512@2x.png", 1024),
]

for output in outputs {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: output.pixels,
        pixelsHigh: output.pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        fatalError("Could not create bitmap for \(output.name)")
    }

    bitmap.size = NSSize(width: output.pixels, height: output.pixels)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    NSGraphicsContext.current?.imageInterpolation = .high
    source.draw(in: NSRect(x: 0, y: 0, width: output.pixels, height: output.pixels))
    NSGraphicsContext.restoreGraphicsState()

    guard let png = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Could not render \(output.name)")
    }

    let destination = URL(fileURLWithPath: iconDirectory).appendingPathComponent(output.name)
    try png.write(to: destination)
    print("Created: \(destination.path) (\(output.pixels)x\(output.pixels))")
}

print("Icon generation complete.")
