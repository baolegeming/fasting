import Foundation
import AppKit

struct RGBA {
    var r: CGFloat
    var g: CGFloat
    var b: CGFloat
    var a: CGFloat
}

func loadBitmap(from path: String) -> NSBitmapImageRep {
    let url = URL(fileURLWithPath: path)
    guard let image = NSImage(contentsOf: url),
          let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff) else {
        fatalError("Unable to load image at \(path)")
    }
    return rep
}

func color(atX x: Int, y: Int, in rep: NSBitmapImageRep) -> RGBA {
    guard let color = rep.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB) else {
        return RGBA(r: 1, g: 1, b: 1, a: 1)
    }
    return RGBA(
        r: color.redComponent,
        g: color.greenComponent,
        b: color.blueComponent,
        a: color.alphaComponent
    )
}

func metrics(_ color: RGBA) -> (saturation: CGFloat, brightness: CGFloat) {
    let maxRGB = max(color.r, max(color.g, color.b))
    let minRGB = min(color.r, min(color.g, color.b))
    let saturation = maxRGB == 0 ? 0 : (maxRGB - minRGB) / maxRGB
    return (saturation, maxRGB)
}

func distance(_ lhs: RGBA, _ rhs: RGBA) -> CGFloat {
    let dr = lhs.r - rhs.r
    let dg = lhs.g - rhs.g
    let db = lhs.b - rhs.b
    return sqrt(dr * dr + dg * dg + db * db)
}

func makeBitmap(width: Int, height: Int) -> NSBitmapImageRep {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: width,
        pixelsHigh: height,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: width * 4,
        bitsPerPixel: 32
    ) else {
        fatalError("Unable to create bitmap")
    }
    return rep
}

func writePixel(_ color: RGBA, x: Int, y: Int, in rep: NSBitmapImageRep) {
    rep.setColor(
        NSColor(
            calibratedRed: color.r,
            green: color.g,
            blue: color.b,
            alpha: color.a
        ),
        atX: x,
        y: y
    )
}

let basePath = "/Users/guxiaoqiu/Documents/trae_projects/healthy_app_analysis"
let sourcePath = "\(basePath)/Screenshot 2026-03-24 at 14.10.38.png"
let transparentOutputPath = "\(basePath)/fastflow_logo_clean.png"
let iconOutputPath = "\(basePath)/fastflow_app_icon_master.png"

let source = loadBitmap(from: sourcePath)
let width = source.pixelsWide
let height = source.pixelsHigh

var borderColors: [RGBA] = []
for x in 0..<width {
    borderColors.append(color(atX: x, y: 0, in: source))
    borderColors.append(color(atX: x, y: height - 1, in: source))
}
for y in 1..<(height - 1) {
    borderColors.append(color(atX: 0, y: y, in: source))
    borderColors.append(color(atX: width - 1, y: y, in: source))
}

let background = borderColors.reduce(RGBA(r: 0, g: 0, b: 0, a: 0)) { partial, color in
    RGBA(
        r: partial.r + color.r,
        g: partial.g + color.g,
        b: partial.b + color.b,
        a: partial.a + color.a
    )
}
let borderCount = CGFloat(borderColors.count)
let backgroundColor = RGBA(
    r: background.r / borderCount,
    g: background.g / borderCount,
    b: background.b / borderCount,
    a: background.a / borderCount
)

let cleaned = makeBitmap(width: width, height: height)
var mask = Array(repeating: false, count: width * height)
var minX = width
var minY = height
var maxX = 0
var maxY = 0

for y in 0..<height {
    for x in 0..<width {
        let pixel = color(atX: x, y: y, in: source)
        let (saturation, brightness) = metrics(pixel)
        let d = distance(pixel, backgroundColor)
        let isGridLike = saturation < 0.16 && brightness > 0.68
        let keep = pixel.a > 0.01 && !isGridLike && (d > 0.12 || saturation > 0.20 || brightness < 0.58)
        let index = y * width + x
        mask[index] = keep
        if keep {
            minX = min(minX, x)
            minY = min(minY, y)
            maxX = max(maxX, x)
            maxY = max(maxY, y)
            writePixel(pixel, x: x, y: y, in: cleaned)
        } else {
            writePixel(RGBA(r: 1, g: 1, b: 1, a: 0), x: x, y: y, in: cleaned)
        }
    }
}

if minX >= maxX || minY >= maxY {
    fatalError("No foreground detected")
}

let padding = 24
minX = max(0, minX - padding)
minY = max(0, minY - padding)
maxX = min(width - 1, maxX + padding)
maxY = min(height - 1, maxY + padding)

let cropWidth = maxX - minX + 1
let cropHeight = maxY - minY + 1
let cropped = makeBitmap(width: cropWidth, height: cropHeight)

for y in 0..<cropHeight {
    for x in 0..<cropWidth {
        let pixel = color(atX: minX + x, y: minY + y, in: cleaned)
        writePixel(pixel, x: x, y: y, in: cropped)
    }
}

if let png = cropped.representation(using: .png, properties: [:]) {
    try png.write(to: URL(fileURLWithPath: transparentOutputPath))
}

let iconSize = 1024
let iconCanvas = makeBitmap(width: iconSize, height: iconSize)
let white = RGBA(r: 1, g: 1, b: 1, a: 1)
for y in 0..<iconSize {
    for x in 0..<iconSize {
        writePixel(white, x: x, y: y, in: iconCanvas)
    }
}

let contentMaxSize: CGFloat = 760
let scale = min(contentMaxSize / CGFloat(cropWidth), contentMaxSize / CGFloat(cropHeight))
let targetWidth = Int((CGFloat(cropWidth) * scale).rounded())
let targetHeight = Int((CGFloat(cropHeight) * scale).rounded())

let croppedImage = NSImage(size: NSSize(width: cropWidth, height: cropHeight))
croppedImage.addRepresentation(cropped)
let scaledImage = NSImage(size: NSSize(width: targetWidth, height: targetHeight))
scaledImage.lockFocus()
croppedImage.draw(
    in: NSRect(x: 0, y: 0, width: targetWidth, height: targetHeight),
    from: NSRect(x: 0, y: 0, width: cropWidth, height: cropHeight),
    operation: .sourceOver,
    fraction: 1
)
scaledImage.unlockFocus()

guard let scaledTiff = scaledImage.tiffRepresentation,
      let scaledRep = NSBitmapImageRep(data: scaledTiff) else {
    fatalError("Unable to scale cleaned logo")
}

let offsetX = (iconSize - targetWidth) / 2
let offsetY = (iconSize - targetHeight) / 2

for y in 0..<targetHeight {
    for x in 0..<targetWidth {
        let pixel = color(atX: x, y: y, in: scaledRep)
        let invY = iconSize - offsetY - targetHeight + y
        if pixel.a > 0.01 {
            let bg = white
            let alpha = pixel.a
            let blended = RGBA(
                r: pixel.r * alpha + bg.r * (1 - alpha),
                g: pixel.g * alpha + bg.g * (1 - alpha),
                b: pixel.b * alpha + bg.b * (1 - alpha),
                a: 1
            )
            writePixel(blended, x: offsetX + x, y: invY, in: iconCanvas)
        }
    }
}

if let png = iconCanvas.representation(using: .png, properties: [:]) {
    try png.write(to: URL(fileURLWithPath: iconOutputPath))
}

print("Saved cleaned logo to \(transparentOutputPath)")
print("Saved icon master to \(iconOutputPath)")
