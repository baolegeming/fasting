import Foundation
import AppKit

let path = "/Users/guxiaoqiu/Documents/trae_projects/healthy_app_analysis/Screenshot 2026-03-24 at 14.10.38.png"
let url = URL(fileURLWithPath: path)
guard let image = NSImage(contentsOf: url) else { fatalError("load failed") }
guard let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff) else { fatalError("bitmap failed") }
let width = rep.pixelsWide
let height = rep.pixelsHigh
print("size \(width)x\(height)")
var minX = width, minY = height, maxX = 0, maxY = 0
var count = 0
var top: [String:Int] = [:]
func key(_ r:Int,_ g:Int,_ b:Int) -> String { "\(r),\(g),\(b)" }
for y in 0..<height {
  for x in 0..<width {
    guard let c = rep.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB) else { continue }
    let r = Int(round(c.redComponent * 255))
    let g = Int(round(c.greenComponent * 255))
    let b = Int(round(c.blueComponent * 255))
    let a = c.alphaComponent
    if a < 0.99 { continue }
    top[key(r,g,b), default: 0] += 1
    let maxRGB = max(r,max(g,b))
    let minRGB = min(r,min(g,b))
    let sat = maxRGB == 0 ? 0.0 : Double(maxRGB - minRGB) / Double(maxRGB)
    let bright = Double(maxRGB)/255.0
    if !(bright > 0.96 && sat < 0.06) {
      count += 1
      minX = min(minX,x); minY = min(minY,y); maxX = max(maxX,x); maxY = max(maxY,y)
    }
  }
}
print("non-bg count \(count)")
print("bbox \(minX),\(minY) -> \(maxX),\(maxY)")
for (k,v) in top.sorted(by: { $0.value > $1.value }).prefix(20) {
  print(v, k)
}
