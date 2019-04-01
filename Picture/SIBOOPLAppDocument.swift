//
//  SIBOOPLAppDocument.swift
//  Inspector
//
//  Created by Richard Warrender on 02/03/2019.
//

import Cocoa
import SIBOKit

class SIBOOPLAppDocument: NSDocument {
    
    @IBOutlet var imageView: NSImageView!
    
    var app: SIBOPLApp?

    override var windowNibName: String? {
        // Override to return the nib file name of the document.
        // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override makeWindowControllers() instead.
        return "SIBOOPLAppDocument"
    }

    override func windowControllerDidLoadNib(_ aController: NSWindowController) {
        super.windowControllerDidLoadNib(aController)
        
//        if let cgImage = app?.icon?.compositeImage(),
//            let size = app?.icon?.bitmapDescriptors.first?.size {
//            imageView.image = NSImage(cgImage: cgImage, size: size.applying(CGAffineTransform.init(scaleX: 3.0, y: 3.0)))
//        }

    }
    
    override func read(from data: Data, ofType typeName: String) throws {
        // Insert code here to read your document from the given data of the specified type, throwing an error in case of failure.
        // Alternatively, you could remove this method and override read(from:ofType:) instead.  If you do, you should also override isEntireFileLoaded to return false if the contents are lazily loaded.
        
        app = try? SIBOPLApp(data: data)
        
        if (app == nil) {
            throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        }
        

        
    }

    override class var autosavesInPlace: Bool {
        return false
    }
    
}
