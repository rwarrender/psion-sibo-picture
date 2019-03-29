//
//  SIBOOPLApp.swift
//  SIBOKit
//
//  Created by Richard Warrender on 02/03/2019.
//

import Foundation

public class SIBOPLApp: NSObject {
    
    enum Error : Swift.Error {
        case invalidFile
        case corruptData(String)
    }
    
    private let FileHeader: Data = Data(bytes: [0x4F, 0x50, 0x4C, 0x4F, 0x62, 0x6A, 0x65, 0x63, 0x74, 0x46, 0x69, 0x6C, 0x65, 0x2A, 0x2A, 0x00]) // OPLObjectFile**.
    
    public let formatVersion: Int
    public let sourcePath: String
    public let icon: SIBOBitmap?
    
    public convenience init(url: URL) throws {
        let data = try Data(contentsOf: url)
        try self.init(data: data)
    }
    
    public init(data: Data) throws {
        if (data.subdata(in: 0..<FileHeader.count) != FileHeader) {
            throw Error.invalidFile
        }
        
        formatVersion = Int(data.scanWord(at: 16))
        
        //let offset = data.scanWord(at: 18)
        
        let sourcePathLength = data.scanByte(at: 20)
        
        let sourceData = data.subdata(in: 21 ..< Int(21 + sourcePathLength))
        let sourceBytes = sourceData.scanArrayTillZero(at: 0)
        sourcePath = SIBOString(bytes: sourceBytes).string
        
        let startOfEmbeddedFiles = Int(21 + sourcePathLength)
        
        let picSize = data.scanWord(at: startOfEmbeddedFiles)
        
        let picStartIndex = startOfEmbeddedFiles.advanced(by: 2)
        let picEndIndex = picStartIndex.advanced(by: Int(picSize))
        let picData = data.subdata(in: picStartIndex ..< picEndIndex)
        
        if let bitmap = try? SIBOBitmap(data: picData) {
            self.icon = bitmap
        } else {
            self.icon = nil
        }
    }
}
