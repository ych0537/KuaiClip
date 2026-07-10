#!/usr/bin/env swift

import Foundation
import AppKit

/// Generates app icon PNGs for KuaiClip
/// Design: Rounded rectangle with clipboard symbol and "DX" monogram

func createIcon(size: CGFloat, outputPath: String) {
    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    let image = NSImage(size: rect.size)

    image.lockFocus()

    // Background: rounded rectangle with gradient
    let bgPath = NSBezierPath(
        roundedRect: rect.insetBy(dx: size * 0.05, dy: size * 0.05),
        xRadius: size * 0.22,
        yRadius: size * 0.22
    )

    // Deep blue gradient
    let gradient = NSGradient(
        colors: [
            NSColor(red: 0.15, green: 0.40, blue: 0.85, alpha: 1.0),
            NSColor(red: 0.10, green: 0.25, blue: 0.65, alpha: 1.0)
        ]
    )
    gradient?.draw(in: bgPath, angle: 135)

    // Clipboard shape (white)
    let clipboardColor = NSColor.white
    clipboardColor.setFill()

    let clipW = size * 0.52
    let clipH = size * 0.58
    let clipX = (size - clipW) / 2
    let clipY = size * 0.22

    let clipRect = CGRect(x: clipX, y: clipY, width: clipW, height: clipH)
    let clipPath = NSBezierPath(
        roundedRect: clipRect,
        xRadius: size * 0.06,
        yRadius: size * 0.06
    )
    clipPath.fill()

    // Clipboard top clip (blue accent)
    let accentColor = NSColor(red: 0.25, green: 0.55, blue: 0.95, alpha: 1.0)
    accentColor.setFill()

    let clipTopW = size * 0.20
    let clipTopH = size * 0.10
    let clipTopX = (size - clipTopW) / 2
    let clipTopY = clipY + clipH - clipTopH - size * 0.02

    let clipTopPath = NSBezierPath(
        roundedRect: CGRect(x: clipTopX, y: clipTopY, width: clipTopW, height: clipTopH),
        xRadius: size * 0.03,
        yRadius: size * 0.03
    )
    clipTopPath.fill()

    // "DX" text on the clipboard
    let textColor = NSColor(red: 0.12, green: 0.28, blue: 0.60, alpha: 1.0)
    let textAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size * 0.28, weight: .bold),
        .foregroundColor: textColor
    ]

    let text = "DX"
    let textSize = text.size(withAttributes: textAttributes)
    let textX = (size - textSize.width) / 2
    let textY = clipY + (clipH - textSize.height) / 2 + clipTopH / 2

    text.draw(at: NSPoint(x: textX, y: textY), withAttributes: textAttributes)

    image.unlockFocus()

    // Save as PNG
    guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        print("Failed to create CGImage for size \(size)")
        return
    }

    let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
    bitmapRep.size = NSSize(width: size, height: size)

    guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
        print("Failed to create PNG data for size \(size)")
        return
    }

    do {
        try pngData.write(to: URL(fileURLWithPath: outputPath))
        print("Created: \(outputPath) (\(size)x\(size))")
    } catch {
        print("Failed to write \(outputPath): \(error)")
    }
}

// Generate icons
let baseDir = "Sources/KuaiClip/Resources/Assets.xcassets/AppIcon.appiconset"

createIcon(size: 256, outputPath: "\(baseDir)/appicon-256.png")
createIcon(size: 512, outputPath: "\(baseDir)/appicon-512.png")

print("Icon generation complete.")
