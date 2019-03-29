//
//  SIBOString.swift
//  SIBOKit
//
//  Created by Richard Warrender on 02/03/2019.
//

import Foundation

class SIBOString {
    let bytes: [UInt8]
    
    init(bytes: [UInt8]) {
        var bytes = bytes
        if (bytes.last == 0) {
            bytes.removeLast() // Remove the null byte
        }
        
        self.bytes = bytes
    }
    
    var string:String {
        get {
            return String(bytes: bytes, encoding: String.Encoding.isoLatin1) ?? ""
        }
    }
}
