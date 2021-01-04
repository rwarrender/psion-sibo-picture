//
//  PKImage.swift
//  SIBOBitmap
//
//  Created by Richard Warrender on 01/03/2019.
//

import Foundation
import CoreGraphics

public class SIBOBitmap: NSObject {
    
    enum Error : Swift.Error {
        case invalidFile
        case corruptData(String)
    }
    
    public struct BitmapDescriptor {
        static let RecordSize:Int = 12
        
        public let crc: UInt16
        public let size: CGSize
        public let length: UInt16
        public let offset: UInt32
        public let data: Data
        
        func isCRCValid() -> Bool {
            let calculatedCRC = crc16(0, (data as NSData).bytes, data.count)
            return (calculatedCRC == crc)
        }
    }
    
    private let FileHeader: Data = Data([0x50, 0x49, 0x43, 0xdc])
    
    public struct ColorStyle {
        public let blackPlane: CGColor
        public let grayPlane: CGColor
        public let whitePlane: CGColor
    }
    
    public static let lcd: ColorStyle = {
        return ColorStyle(
                blackPlane: CGColor(red: 55/255.0, green: 50/255.0, blue: 45/255.0, alpha: 1.0),
                grayPlane: CGColor(red: 125/255.0, green: 117/255, blue:71/255.0, alpha: 1.0),
                whitePlane: CGColor(red: 215/255.0, green: 211/255.0, blue: 176/255.0, alpha: 1.0)
        )
    }()

    public static let bw: ColorStyle = {
        return ColorStyle(
            blackPlane: CGColor(red: 0, green: 0, blue: 0, alpha: 1.0),
            grayPlane: CGColor(gray: 0.5, alpha: 1.0),
            whitePlane: CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        )
    }()
    
    public let formatVersion: Int
    public let oplRuntimeVersion: Int
    public let bitmapDescriptors: [BitmapDescriptor]
    
    public convenience init(url:URL) throws {
        let data = try Data(contentsOf: url)
        try self.init(data: data)
    }
    
    public init(data: Data) throws {
        if (data.subdata(in: 0..<FileHeader.count) != FileHeader) {
            throw Error.invalidFile
        }
        
        formatVersion = Int(data[4])
        oplRuntimeVersion = Int(data[5])
        
        let bitmapCount = data.subdata(in: 6..<8).withUnsafeBytes { (pointer: UnsafePointer<UInt16>) -> Int in
            return Int(pointer.pointee)
        }
        
        var descriptorStartIndex = 8
        var bitmapDescriptors: [BitmapDescriptor] = []

        for _ in 0..<bitmapCount {
            let endIndex = UInt32(descriptorStartIndex + BitmapDescriptor.RecordSize)
            
            let crc = data.subdata(in: descriptorStartIndex..<descriptorStartIndex+2).withUnsafeBytes { (pointer:UnsafePointer<UInt16>) -> UInt16 in
                return pointer.pointee
            }
            
            let width = data.subdata(in: descriptorStartIndex+2..<descriptorStartIndex+4).withUnsafeBytes { (pointer:UnsafePointer<UInt16>) -> UInt16 in
                return pointer.pointee
            }
            
            let height = data.subdata(in: descriptorStartIndex+4..<descriptorStartIndex+6).withUnsafeBytes { (pointer:UnsafePointer<UInt16>) -> UInt16 in
                return pointer.pointee
            }
            
            let size = CGSize(width: Int(width), height: Int(height))
            
            let length = data.subdata(in: descriptorStartIndex+6..<descriptorStartIndex+8).withUnsafeBytes { (pointer:UnsafePointer<UInt16>) -> UInt16 in
                return pointer.pointee
            }
            
            let offset = data.subdata(in: descriptorStartIndex+8..<descriptorStartIndex+12).withUnsafeBytes { (pointer:UnsafePointer<UInt32>) -> UInt32 in
                return pointer.pointee
            }
            
            let bitmapStartIndex = Int(endIndex + offset) // End of current bitmap descriptor + offset
            let bitmapEndIndex = bitmapStartIndex.advanced(by: Int(length))
            let bitmapData = data.subdata(in: bitmapStartIndex ..< bitmapEndIndex)
    
            let descriptor = BitmapDescriptor(crc: crc, size: size, length: length, offset: offset, data: bitmapData)
            if (!descriptor.isCRCValid()) {
                throw Error.corruptData("CRCs don't match. Data could be corrupt")
            }
            
            bitmapDescriptors.append(descriptor)
            descriptorStartIndex += BitmapDescriptor.RecordSize
        }
        
        self.bitmapDescriptors = bitmapDescriptors
    }
    
    public func hasCompositeImage() -> Bool {
        guard self.bitmapDescriptors.count >= 2 else {
            return false
        }
        
        let blackBitmapDescriptor = self.bitmapDescriptors[0]
        let greyBitmapDescriptor = self.bitmapDescriptors[1]
        guard blackBitmapDescriptor.size == greyBitmapDescriptor.size else {
            return false // Not the same size so can't be a composite
        }
        
        return true
    }
    
    public func compositeImage(colorStyle: ColorStyle) -> CGImage? {
        
        guard hasCompositeImage() == true else {
            return nil
        }
        
        let blackBitmapDescriptor = self.bitmapDescriptors[0]
        let greyBitmapDescriptor = self.bitmapDescriptors[1]
        
        let size = blackBitmapDescriptor.size
        var context = createDrawingContext(size: size, transparent: false, background: colorStyle.whitePlane)
     
        drawPlane(context: &context, for: blackBitmapDescriptor, color: colorStyle.blackPlane)
        drawPlane(context: &context, for: greyBitmapDescriptor, color: colorStyle.grayPlane)
        
        return context.makeImage()!
    }
    
    public func bitmap(at index: Int, color: CGColor, background: CGColor) -> CGImage {
        let bitmapDescriptor = self.bitmapDescriptors[index]
        let size = bitmapDescriptor.size

        var context = createDrawingContext(size: size, transparent: false, background: background)
        drawPlane(context: &context, for: bitmapDescriptor, color: color)
        
        return context.makeImage()!
    }
    
    func createDrawingContext(size: CGSize, transparent: Bool, background: CGColor) -> CGContext {
        let scale: Int = 1
        
        // Set up context
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let context = CGContext(data: nil, width: Int(size.width)*scale, height: Int(size.height)*scale, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: bitmapInfo.rawValue)!
        
        // Invert context because Mac convention is to have bottom left corner as 0,0
        context.translateBy(x: 0, y: size.height * CGFloat(scale))
        context.scaleBy(x: CGFloat(scale), y: -CGFloat(scale))
        
        if (!transparent) {
            context.setFillColor(background)
            context.fill(CGRect(x: 0, y: 0, width: Int(size.width), height: Int(size.height)))
        }
        
        return context
    }
    
    func drawPlane(context: inout CGContext, for descriptor: BitmapDescriptor, color: CGColor = CGColor.black) {
        context.setFillColor(color)
        context.setBlendMode(.darken)
        
        // Row length should be rounded up to the nearest byte
        var rowLength = Int( ceil( descriptor.size.width / 8.0 ) )
        
        // Any odd row lengths should be made even
        if (rowLength % 2 != 0) {
            rowLength += 1
        }

        // Pull off a "row", e.g. 6 bytes or 48 bits for a 48 pixel wide image.
        for rowIndex in 0 ..< Int(descriptor.size.height) {
            let startIndex = (rowLength * rowIndex)
            let endIndex = startIndex.advanced(by: rowLength)
            let rowData = descriptor.data.subdata(in:  startIndex ..< endIndex)
            
            // Loop though each column in the given row
            for rowByteIndex in 0 ..< rowLength {
                
                // Now loop though each byte's bit
                for bitIndex in 0 ..< 8 {
                    
                    // Work out if the bit is set
                    let value = ((1 << bitIndex) & rowData[rowByteIndex] > 0)
                    if (value == true) {
                        
                        // Calculate the pixel x,y for the given bit
                        let x = CGFloat((rowByteIndex * 8) + bitIndex)
                        let y = CGFloat(rowIndex)
                        
                        let rect = CGRect(x: x, y: y, width: 1.0, height: 1.0)
                        context.fill(rect)
                    }
                }
            }
        }
    }
}

extension Data {
    func scanByte(at index: Int) -> UInt8 {
        return self[index]
    }
    
    func scanWord(at index: Int) -> UInt16 {
        let endIndex = index.advanced(by: 2)
        
        return subdata(in: index ..< endIndex).withUnsafeBytes { (pointer: UnsafePointer<UInt16>) -> UInt16 in
            return UInt16(pointer.pointee)
        }
    }
    
    func scanLong(at index: Int) -> UInt32 {
        let endIndex = index.advanced(by: 4)
        
        return subdata(in: index ..< endIndex).withUnsafeBytes { (pointer: UnsafePointer<UInt32>) -> UInt32 in
            return UInt32(pointer.pointee)
        }
    }
    
    func scanArrayTillZero(at startIndex: Int) -> [UInt8] {
        var chars: [UInt8] = []
        
        var byte: UInt8 = 0
        var index = startIndex
        repeat {
            byte = self[index]
            chars.append(byte)
            index = index.advanced(by: 1)
        } while byte != 0 && index < self.count;
        
        return chars
    }
}
