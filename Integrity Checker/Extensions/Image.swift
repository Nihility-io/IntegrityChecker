//
//  Image.swift
//  Integrity Checker
//
//  Created by Marvin Peter on 2024-05-18.
//

import AppKit
import FileKit
import Foundation

extension NSImage {
    /// Returns the height of the current image.
    var height: CGFloat {
        return self.size.height
    }

    /// Returns the width of the current image.
    var width: CGFloat {
        return self.size.width
    }

    ///  Copies the current image and resizes it to the given size.
    ///
    ///  - parameter size: The size of the new image.
    ///
    ///  - returns: The resized copy of the given image.
    func copy(size: NSSize) -> NSImage? {
        // Create a new rect with given width and height
        let frame = NSMakeRect(0, 0, size.width, size.height)

        // Get the best representation for the given size.
        guard let rep = self.bestRepresentation(for: frame, context: nil, hints: nil) else {
            return nil
        }

        // Create an empty image with the given size.
        let img = NSImage(size: size)

        // Set the drawing context and make sure to remove the focus before returning.
        img.lockFocus()
        defer { img.unlockFocus() }

        // Draw the new image
        if rep.draw(in: frame) {
            return img
        }

        // Return nil in case something went wrong.
        return nil
    }

    ///  Copies the current image and resizes it to the size of the given NSSize, while
    ///  maintaining the aspect ratio of the original image.
    ///
    ///  - parameter maxSize: The size of the new image.
    ///
    ///  - returns: The resized copy of the given image.
    func resize(maxSize size: NSSize) -> NSImage? {
        let newSize: NSSize

        let widthRatio = size.width / self.width
        let heightRatio = size.height / self.height

        if widthRatio < heightRatio {
            newSize = NSSize(
                width: floor(self.width * widthRatio), height: floor(self.height * widthRatio))
        } else {
            newSize = NSSize(
                width: floor(self.width * heightRatio), height: floor(self.height * heightRatio))
        }

        return self.copy(size: newSize)
    }

    ///  Creates a new image in a given size with with original image centered and padded
    /// - Parameter s: Size
    /// - Returns: New image
    func square(size s: CGFloat) -> NSImage {
        let img = NSImage(size: CGSize(width: s, height: s))

        img.lockFocus()
        let ctx = NSGraphicsContext.current
        ctx?.imageInterpolation = .high

        let scaledImage = self.resize(maxSize: NSSize(width: s, height: s))!

        let inRect =
            size.width < size.height
            ? NSMakeRect((s - scaledImage.size.width) / 2, 0, scaledImage.size.width, s)
            : NSMakeRect(0, (s - scaledImage.size.height) / 2, s, scaledImage.size.height)

        let fromRect = NSMakeRect(0, 0, scaledImage.size.width, scaledImage.size.height)

        scaledImage.draw(in: inRect, from: fromRect, operation: .copy, fraction: 1)

        img.unlockFocus()

        return img
    }

    /// Returns a png representation of the current image.
    var pngRepresentation: Data? {
        if let tiff = self.tiffRepresentation, let tiffData = NSBitmapImageRep(data: tiff) {
            return tiffData.representation(using: .png, properties: [:])
        }

        return nil
    }

    ///  Saves the PNG representation of the current image to the HD.
    ///
    /// - parameter url: The location url to which to write the png file.
    func saveAsPng(to path: Path) throws {
        if let png = self.pngRepresentation {
            try png.write(to: path.url, options: .atomicWrite)
        }
    }
}
