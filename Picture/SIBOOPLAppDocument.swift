//
//  SIBOOPLAppDocument.swift
//  Inspector
//
//  Created by Richard Warrender on 02/03/2019.
//

import Cocoa
import SIBOKit

class SIBOOPLAppDocument: SIBOBitmapDocument {
    
    var app: SIBOPLApp? {
        didSet {
            bitmap = app?.icon
        }
    }

    override var windowNibName: String? {
        return "SIBOOPLAppDocument"
    }

    override func windowControllerDidLoadNib(_ aController: NSWindowController) {
        super.windowControllerDidLoadNib(aController)
    }
    
    override func read(from data: Data, ofType typeName: String) throws {
        app = try? SIBOPLApp(data: data)
        
        if (app == nil) {
            throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        }
    }

    override class var autosavesInPlace: Bool {
        return false
    }
    
}
