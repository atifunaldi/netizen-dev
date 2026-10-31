#!/usr/bin/env swift
import AppKit
import Foundation

let root = "NetizenApps/TV/App/Assets.xcassets/AppIcon.brandassets"
let red = NSColor(calibratedRed: 1, green: 0.04, blue: 0.22, alpha: 1)
let navy = NSColor(calibratedRed: 0.012, green: 0.082, blue: 0.176, alpha: 1)

func render(_ width: Int, _ height: Int, to path: String) throws {
    let image = NSImage(size: NSSize(width: width, height: height))
    image.lockFocus()
    navy.setFill()
    NSRect(x: 0, y: 0, width: width, height: height).fill()
    let diameter = CGFloat(height) * 0.67
    let x = (CGFloat(width) - diameter) / 2
    let y = (CGFloat(height) - diameter) / 2
    red.setFill()
    NSBezierPath(ovalIn: NSRect(x: x, y: y, width: diameter, height: diameter)).fill()
    NSColor.white.setFill()
    let bar = NSRect(x: CGFloat(width)/2 - diameter*0.07,
                     y: y + diameter*0.12,
                     width: diameter*0.14, height: diameter*0.76)
    NSBezierPath(roundedRect: bar, xRadius: bar.width/2, yRadius: bar.width/2).fill()
    image.unlockFocus()
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        fatalError("Cannot render tvOS asset")
    }
    let destination = URL(fileURLWithPath: path)
    try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
    try png.write(to: destination)
    print("Generated \(path)")
}

try render(400, 240, to: "\(root)/App Icon - Small.imagestack/Front.imagestacklayer/Content.imageset/NetizenSmall.png")
try render(1280, 768, to: "\(root)/App Icon - Large.imagestack/Front.imagestacklayer/Content.imageset/NetizenLarge.png")
try render(400, 240, to: "\(root)/App Icon - Small.imagestack/Back.imagestacklayer/Content.imageset/NetizenSmallBackground.png")
try render(1280, 768, to: "\(root)/App Icon - Large.imagestack/Back.imagestacklayer/Content.imageset/NetizenLargeBackground.png")
try render(1920, 720, to: "\(root)/Top Shelf Image.imageset/TopShelf.png")
