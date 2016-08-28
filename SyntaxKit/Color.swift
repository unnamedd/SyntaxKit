//
//  Color.swift
//  X
//
//  Created by Sam Soffes on 4/28/15.
//  Copyright © 2015 Sam Soffes. All rights reserved.
//

#if os(OSX)
    import AppKit.NSColor
    public typealias ColorType = NSColor

    extension NSColor {
        public convenience init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
            self.init(SRGBRed: red, green: green, blue: blue, alpha: alpha)
        }
    }
#else
    import UIKit.UIColor
    public typealias ColorType = UIColor
#endif

public typealias Color = ColorType

extension Color {
    public convenience init?(hex s: String) {
        var hex: NSString = s

        // Remove `#` and `0x`
        if hex.hasPrefix("#") {
            hex = hex.substringFromIndex(1)
        } else if hex.hasPrefix("0x") {
            hex = hex.substringFromIndex(2)
        }

        // Invalid if not 3, 6, or 8 characters
        let length = hex.length
        if length != 3 && length != 6 && length != 8 {
            return nil
        }

        // Make the string 8 characters long for easier parsing
        if length == 3 {
            let r = hex.substringWithRange(NSRange(location: 0, length: 1))
            let g = hex.substringWithRange(NSRange(location: 1, length: 1))
            let b = hex.substringWithRange(NSRange(location: 2, length: 1))
            hex = r + r + g + g + b + b + "ff"
        } else if length == 6 {
            hex = String(hex) + "ff"
        }

        // Convert 2 character strings to CGFloats
        func hexValue(string: String) -> CGFloat {
            let value = Double(strtoul(string, nil, 16))
            return CGFloat(value / 255.0)
        }

        let red = hexValue(hex.substringWithRange(NSRange(location: 0, length: 2)))
        let green = hexValue(hex.substringWithRange(NSRange(location: 2, length: 2)))
        let blue = hexValue(hex.substringWithRange(NSRange(location: 4, length: 2)))
        let alpha = hexValue(hex.substringWithRange(NSRange(location: 6, length: 2)))

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
