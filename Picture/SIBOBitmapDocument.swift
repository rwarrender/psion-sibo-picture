//
//  SIBOBitmapDocument.swift
//  Inspector
//
//  Created by Richard Warrender on 03/03/2019.
//

import Cocoa
import Quartz
import SIBOKit

class SIBOBitmapDocument: NSDocument {

    @IBOutlet var scrollView: NSScrollView!
    @IBOutlet var imageView: NSImageView!
    @IBOutlet var segmentedControl: NSSegmentedControl!
    @IBOutlet var zoomControl: NSSegmentedControl!
    @IBOutlet var zoomLabel: NSTextField!
    var bitmap: SIBOBitmap?
    var zoomFactor: CGFloat = 2.0
    
    var cgImage: CGImage?
    var size: CGSize?

    override var windowNibName: String? {
        // Override to return the nib file name of the document.
        // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override makeWindowControllers() instead.
        return "SIBOBitmapDocument"
    }

    override func windowControllerDidLoadNib(_ aController: NSWindowController) {
        super.windowControllerDidLoadNib(aController)
        // Add any code here that needs to be executed once the windowController has loaded the document's window.
        
        imageView = NSImageView(frame: scrollView.frame)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = imageView
        
        guard let bitmap = bitmap else {
            return
        }
        
        var planeTitle: [String] = []
        var planeCount = bitmap.bitmapDescriptors.count
        for i in 0 ..< planeCount {
            planeTitle.append("Bitmap \(i)")
        }
        
        if bitmap.hasCompositeImage() {
            planeCount += 1
            planeTitle.insert("Composite", at: 0)
        }
        
        // Update UI
        segmentedControl.segmentCount = planeCount
        for i in 0..<planeCount {
            segmentedControl.setLabel(planeTitle[i], forSegment: i)
        }
        segmentedControl.setSelected(true, forSegment: 0)
        bitmapSegmentSelected(sender: self)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didChangeMagnification),
                                               name: NSScrollView.didEndLiveMagnifyNotification,
                                               object: scrollView)
    }
    
    @IBAction func export(_ sender:Any) {
        let pngExtension = UTTypeCopyPreferredTagWithClass(kUTTypePNG, kUTTagClassFilenameExtension)?.takeRetainedValue() as String?
        
        var fullName: String?
        if let name = fileURL?.lastPathComponent as NSString? {
            let baseName = name.deletingPathExtension as NSString
            fullName = baseName.appendingPathExtension(pngExtension ?? "")
        }
        
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = fullName ?? ""
        savePanel.begin { (response) in
            if response == NSApplication.ModalResponse.OK {
                let imageRep = NSBitmapImageRep(cgImage: self.bitmap!.compositeImage()!)
                let imageData = imageRep.representation(using: NSBitmapImageRep.FileType.png, properties: [:])
                try? imageData?.write(to: savePanel.url!)
            }
        }
        
    }
    
    @objc func didChangeMagnification(notification: NSNotification) {
        zoomFactor = scrollView.magnification
        zoomLabel.stringValue = "Zoom: \(zoomFactor)x"
    }
    
    @IBAction func zoomSegementSelected(sender: Any) {
        if (zoomControl.selectedSegment == 0) {
            scrollView.magnification /= 2.0
        } else if (zoomControl.selectedSegment == 1) {
            scrollView.magnification *= 2.0
        }
        zoomFactor = scrollView.magnification
        zoomLabel.stringValue = "Zoom: \(zoomFactor)x"
    }
    
    @IBAction func bitmapSegmentSelected(sender: Any) {
        guard let bitmap = bitmap else {
            return
        }
        
        var bitmapIndex = segmentedControl.selectedSegment
        if (bitmap.hasCompositeImage()) {
           bitmapIndex -= 1
        }
        
        guard bitmapIndex >= 0 else {
            _ = loadComposite()
            return
        }
        
        _ = loadBitmap(at: bitmapIndex)
    }
    
    func loadComposite() -> Bool {
        if let cgImage = bitmap?.compositeImage(),
            let size = bitmap?.bitmapDescriptors.first?.size {
            self.size = size
            self.cgImage = cgImage
        
            imageView.image = NSImage(cgImage: cgImage, size: size)
            imageView.setNeedsDisplay()

            return true
        }
        return false
    }
    
    func loadBitmap(at index:Int) -> Bool {
        if let descriptor = bitmap?.bitmapDescriptors[index],
            let cgImage = bitmap?.bitmap(at: index) {
            self.size = descriptor.size
            self.cgImage = cgImage
            
            imageView.image = NSImage(cgImage: cgImage, size: size!)
            imageView.setNeedsDisplay()
            return true
        }
        return false
    }
    
    func imageProperties(size: CGSize) -> [AnyHashable : Any] {
        
        return [kCGImagePropertyPixelWidth: size.width,
                kCGImagePropertyPixelHeight: size.height,
                kCGImagePropertyDPIWidth: 96.0,
                kCGImagePropertyDPIHeight: 96.0]
    }
    
    override func read(from data: Data, ofType typeName: String) throws {
        // Insert code here to read your document from the given data of the specified type, throwing an error in case of failure.
        // Alternatively, you could remove this method and override read(from:ofType:) instead.  If you do, you should also override isEntireFileLoaded to return false if the contents are lazily loaded.
        bitmap = try? SIBOBitmap(data: data)
        
        if (bitmap == nil) {
            throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        }
    }

    override class var autosavesInPlace: Bool {
        return false
    }
    
}
