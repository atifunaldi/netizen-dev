#!/usr/bin/env swift
import AppKit

let output = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "CarPlayPrototype/App/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
let size = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()
NSColor.white.setFill()
NSRect(x: 0, y: 0, width: size, height: size).fill()
// Netizen Drive mark: vivid red circle with a white rounded vertical stroke.
NSColor(calibratedRed: 1.0, green: 0.04, blue: 0.22, alpha: 1).setFill()
NSBezierPath(ovalIn: NSRect(x: 49, y: 49, width: 926, height: 926)).fill()
NSColor.white.setFill()
let bar = NSBezierPath(roundedRect: NSRect(x: 449, y: 157, width: 126, height: 710), xRadius: 63, yRadius: 63)
bar.fill()
image.unlockFocus()
guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
  fatalError("Cannot render AppIcon.png")
}
try FileManager.default.createDirectory(at: URL(fileURLWithPath: output).deletingLastPathComponent(), withIntermediateDirectories: true)
try png.write(to: URL(fileURLWithPath: output))
print("Generated Netizen Drive AppIcon: \(output)")
