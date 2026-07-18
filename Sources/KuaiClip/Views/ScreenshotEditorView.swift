import SwiftUI
import AppKit
import CoreImage

enum AnnotationTool: String, CaseIterable, Identifiable {
    case rectangle, ellipse, line, arrow, pen, mosaic, text, number
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .rectangle: "rectangle"
        case .ellipse: "circle"
        case .line: "line.diagonal"
        case .arrow: "arrow.up.right"
        case .pen: "pencil"
        case .mosaic: "squareshape.split.3x3"
        case .text: "textformat"
        case .number: "1.circle.fill"
        }
    }
}

@MainActor
final class ScreenshotEditorModel: ObservableObject {
    @Published var selectedTool: AnnotationTool = .rectangle
    @Published var canUndo = false
    weak var canvas: ScreenshotCanvasView?

    func undo() { canvas?.undo() }
    func clear() { canvas?.clearAnnotations() }
    func pngData() -> Data? { canvas?.renderedPNGData() }
}

struct ScreenshotEditorView: View {
    let image: NSImage
    @StateObject private var model = ScreenshotEditorModel()
    @AppStorage("appearanceMode") private var appearanceMode = "light"

    private var theme: AppTheme { AppTheme(appearanceMode) }

    var body: some View {
        VStack(spacing: 0) {
            ScreenshotCanvasRepresentable(image: image, model: model)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.72))

            HStack(spacing: 5) {
                ForEach(AnnotationTool.allCases) { tool in
                    Button {
                        model.selectedTool = tool
                        model.canvas?.tool = tool
                    } label: {
                        Image(systemName: tool.symbol)
                            .frame(width: 25, height: 25)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(model.selectedTool == tool ? theme.accent : theme.foreground)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(model.selectedTool == tool ? theme.accent.opacity(0.14) : .clear)
                    )
                    .help(tool.title)
                }

                Divider().frame(height: 24).padding(.horizontal, 4)

                Button { model.undo() } label: {
                    Image(systemName: "arrow.uturn.backward").frame(width: 25, height: 25)
                }
                .buttonStyle(.plain)
                .disabled(!model.canUndo)
                .help(L10n.undo)

                Button { model.clear() } label: {
                    Image(systemName: "xmark").frame(width: 25, height: 25)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red)
                .disabled(!model.canUndo)
                .help(L10n.clearAnnotations)

                Spacer(minLength: 12)

                Button {
                    guard let data = model.pngData() else { return }
                    ScreenshotService.shared.saveToDownloads(data)
                } label: {
                    Label(L10n.download, systemImage: "arrow.down.to.line")
                }

                Button {
                    guard let data = model.pngData() else { return }
                    ScreenshotService.shared.copyToClipboard(data)
                } label: {
                    Label(L10n.copy, systemImage: "doc.on.doc")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 14)
            .frame(height: 58)
            .background(theme.background)
        }
        .preferredColorScheme(theme.colorScheme)
    }
}

private extension AnnotationTool {
    var title: String {
        switch self {
        case .rectangle: L10n.annotationRectangle
        case .ellipse: L10n.annotationEllipse
        case .line: L10n.annotationLine
        case .arrow: L10n.annotationArrow
        case .pen: L10n.annotationPen
        case .mosaic: L10n.annotationMosaic
        case .text: L10n.annotationText
        case .number: L10n.annotationNumber
        }
    }
}

private struct ScreenshotCanvasRepresentable: NSViewRepresentable {
    let image: NSImage
    let model: ScreenshotEditorModel

    func makeNSView(context: Context) -> ScreenshotCanvasView {
        let view = ScreenshotCanvasView(image: image)
        view.tool = model.selectedTool
        view.onHistoryChanged = { [weak model] canUndo in
            model?.canUndo = canUndo
        }
        model.canvas = view
        return view
    }

    func updateNSView(_ view: ScreenshotCanvasView, context: Context) {
        view.tool = model.selectedTool
    }
}

private enum Annotation {
    case shape(AnnotationTool, NSPoint, NSPoint)
    case stroke(AnnotationTool, [NSPoint])
    case label(String, NSPoint)
    case number(Int, NSPoint)
}

@MainActor
final class ScreenshotCanvasView: NSView {
    var tool: AnnotationTool = .rectangle
    var onHistoryChanged: ((Bool) -> Void)?

    private let image: NSImage
    private let mosaicImage: NSImage?
    private var annotations: [Annotation] = []
    private var working: Annotation?
    private var startPoint: NSPoint = .zero
    private var number = 1

    init(image: NSImage) {
        self.image = image
        self.mosaicImage = Self.makeMosaicImage(from: image)
        super.init(frame: .zero)
        wantsLayer = true
    }

    required init?(coder: NSCoder) { nil }
    override var acceptsFirstResponder: Bool { true }

    private var imageRect: NSRect {
        guard image.size.width > 0, image.size.height > 0 else { return bounds }
        let scale = min(bounds.width / image.size.width, bounds.height / image.size.height)
        let size = NSSize(width: image.size.width * scale, height: image.size.height * scale)
        return NSRect(x: bounds.midX - size.width / 2, y: bounds.midY - size.height / 2,
                      width: size.width, height: size.height)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        NSColor.black.withAlphaComponent(0.72).setFill()
        bounds.fill()
        image.draw(in: imageRect, from: .zero, operation: .sourceOver, fraction: 1)
        for annotation in annotations { draw(annotation) }
        if let working { draw(working) }
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        guard imageRect.contains(point) else { return }
        startPoint = point
        switch tool {
        case .pen, .mosaic:
            working = .stroke(tool, [point])
        case .text:
            requestText(at: point)
        case .number:
            annotations.append(.number(number, point))
            number += 1
            changed()
        default:
            working = .shape(tool, point, point)
        }
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        let point = clamped(convert(event.locationInWindow, from: nil))
        switch working {
        case .shape(let tool, let start, _):
            working = .shape(tool, start, point)
        case .stroke(let tool, var points):
            points.append(point)
            working = .stroke(tool, points)
        default:
            break
        }
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        if let working {
            annotations.append(working)
            self.working = nil
            changed()
        }
    }

    func undo() {
        guard !annotations.isEmpty else { return }
        annotations.removeLast()
        number = annotations.reduce(1) { count, annotation in
            if case .number = annotation { count + 1 } else { count }
        }
        changed()
    }

    func clearAnnotations() {
        annotations.removeAll()
        number = 1
        changed()
    }

    func renderedPNGData() -> Data? {
        let sourceRep = image.representations
            .compactMap { $0 as? NSBitmapImageRep }
            .max { $0.pixelsWide * $0.pixelsHigh < $1.pixelsWide * $1.pixelsHigh }
        let pixelWidth = sourceRep?.pixelsWide ?? max(Int(image.size.width), 1)
        let pixelHeight = sourceRep?.pixelsHigh ?? max(Int(image.size.height), 1)
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixelWidth,
            pixelsHigh: pixelHeight,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return nil }
        rep.size = imageRect.size
        cacheDisplay(in: imageRect, to: rep)
        return rep.representation(using: .png, properties: [:])
    }

    private func requestText(at point: NSPoint) {
        let alert = NSAlert()
        alert.messageText = L10n.enterText
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        alert.accessoryView = field
        alert.addButton(withTitle: L10n.ok)
        alert.addButton(withTitle: L10n.cancel)
        if alert.runModal() == .alertFirstButtonReturn, !field.stringValue.isEmpty {
            annotations.append(.label(field.stringValue, point))
            changed()
        }
    }

    private func changed() {
        onHistoryChanged?(!annotations.isEmpty)
        needsDisplay = true
    }

    private func clamped(_ point: NSPoint) -> NSPoint {
        NSPoint(x: min(max(point.x, imageRect.minX), imageRect.maxX),
                y: min(max(point.y, imageRect.minY), imageRect.maxY))
    }

    private func draw(_ annotation: Annotation) {
        let color = NSColor.systemRed
        color.setStroke()
        color.setFill()
        switch annotation {
        case .shape(let tool, let start, let end):
            let path = NSBezierPath()
            path.lineWidth = 3
            let rect = NSRect(x: min(start.x, end.x), y: min(start.y, end.y),
                              width: abs(end.x - start.x), height: abs(end.y - start.y))
            if tool == .rectangle {
                path.appendRect(rect)
            } else if tool == .ellipse {
                path.appendOval(in: rect)
            } else {
                path.move(to: start)
                path.line(to: end)
            }
            path.stroke()
            if tool == .arrow { drawArrowHead(from: start, to: end, color: color) }

        case .stroke(let tool, let points):
            guard let first = points.first else { return }
            let path = NSBezierPath()
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            path.lineWidth = tool == .mosaic ? 14 : 4
            path.move(to: first)
            points.dropFirst().forEach(path.line(to:))
            if tool == .mosaic {
                if let context = NSGraphicsContext.current?.cgContext, let mosaicImage {
                    context.saveGState()
                    context.addPath(path.cgPath)
                    context.setLineWidth(18)
                    context.setLineCap(.round)
                    context.setLineJoin(.round)
                    context.replacePathWithStrokedPath()
                    context.clip()
                    mosaicImage.draw(in: imageRect, from: .zero, operation: .sourceOver, fraction: 1)
                    context.restoreGState()
                    return
                }
                NSColor.gray.setStroke()
            }
            path.stroke()

        case .label(let text, let point):
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 22, weight: .semibold),
                .foregroundColor: color,
                .strokeColor: NSColor.white,
                .strokeWidth: -2
            ]
            text.draw(at: point, withAttributes: attrs)

        case .number(let value, let point):
            let circle = NSRect(x: point.x - 13, y: point.y - 13, width: 26, height: 26)
            NSBezierPath(ovalIn: circle).fill()
            let string = "\(value)" as NSString
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 15, weight: .bold),
                .foregroundColor: NSColor.white
            ]
            let size = string.size(withAttributes: attrs)
            string.draw(at: NSPoint(x: circle.midX - size.width / 2,
                                    y: circle.midY - size.height / 2), withAttributes: attrs)
        }
    }

    private func drawArrowHead(from start: NSPoint, to end: NSPoint, color: NSColor) {
        let angle = atan2(end.y - start.y, end.x - start.x)
        let length: CGFloat = 14
        let path = NSBezierPath()
        path.move(to: end)
        path.line(to: NSPoint(x: end.x - length * cos(angle - .pi / 6),
                              y: end.y - length * sin(angle - .pi / 6)))
        path.move(to: end)
        path.line(to: NSPoint(x: end.x - length * cos(angle + .pi / 6),
                              y: end.y - length * sin(angle + .pi / 6)))
        path.lineWidth = 3
        color.setStroke()
        path.stroke()
    }

    private static func makeMosaicImage(from image: NSImage) -> NSImage? {
        guard let data = image.tiffRepresentation,
              let input = CIImage(data: data),
              let filter = CIFilter(name: "CIPixellate") else { return nil }
        filter.setValue(input, forKey: kCIInputImageKey)
        filter.setValue(12, forKey: kCIInputScaleKey)
        guard let output = filter.outputImage else { return nil }
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(output, from: input.extent) else { return nil }
        return NSImage(cgImage: cgImage, size: image.size)
    }
}
