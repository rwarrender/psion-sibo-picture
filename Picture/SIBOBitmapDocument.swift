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
    
    unowned var selectedStyleItem: NSMenuItem?
    var selectedColorStyle: SIBOBitmap.ColorStyle = SIBOBitmap.lcd
    var bitmap: SIBOBitmap?
    var zoomFactor: CGFloat = 2.0
    
    var cgImage: CGImage?
    var size: CGSize?
    
    override func makeWindowControllers() {
        let windowController: WindowController = WindowController(windowNibName: NSNib.Name("SIBOBitmapDocument"), owner: self)
        addWindowController(windowController)
    }

    override func windowControllerDidLoadNib(_ aController: NSWindowController) {
        super.windowControllerDidLoadNib(aController)
        
        let rootMenu = NSApplication.shared.mainMenu
        if let viewMenu = rootMenu?.item(withTitle: "View")?.submenu, let styleMenu = viewMenu.item(withTitle: "Style")?.submenu {
            selectedStyleItem = styleMenu.item(at: 0)
        }
        
        imageView = ImageView(frame: scrollView.frame)
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
    
    @IBAction func toggleVisualStyle(_ sender: NSMenuItem) {
        selectedStyleItem?.state = .off
        selectedStyleItem = sender
        if (sender.tag == 0) {
            selectedColorStyle = SIBOBitmap.lcd
        } else if (sender.tag == 1) {
            selectedColorStyle = SIBOBitmap.bw
        }
        selectedStyleItem?.state = .on
        bitmapSegmentSelected(sender: sender)
    }
    
    @IBAction func export(_ sender:Any) {
        let pngExtension = UTTypeCopyPreferredTagWithClass(kUTTypePNG, kUTTagClassFilenameExtension)?.takeRetainedValue() as String?
        
        var fullName: String?
        if let name = fileURL?.lastPathComponent as NSString? {
            let baseName = name.deletingPathExtension as NSString
            fullName = baseName.appendingPathExtension(pngExtension ?? "")
        }
        
        guard let bitmap = self.bitmap else {
            return
        }
        
        let exportOptionsView = ExportOptionsView.fromNib()!
        exportOptionsView.setupView(bitmap: bitmap)
        
        let savePanel = NSSavePanel()
        savePanel.accessoryView = exportOptionsView
        savePanel.nameFieldStringValue = fullName ?? ""
        savePanel.begin { (response) in
            guard let saveURL = savePanel.url else {
                return
            }
            
            if response == NSApplication.ModalResponse.OK {
                if exportOptionsView.selectedMode == .composite {
                    let cgImage = bitmap.compositeImage(colorStyle: SIBOBitmap.lcd)
                    try? cgImage?.pngData.write(to: saveURL)
                } else {
                    guard let bitmapIndex = exportOptionsView.bitmapIndex else {
                        return
                    }
                    let cgImage = bitmap.bitmap(at: bitmapIndex,
                                                color: SIBOBitmap.bw.blackPlane,
                                                background: SIBOBitmap.bw.whitePlane)
                    try? cgImage.pngData.write(to: saveURL)
                }
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
        if let cgImage = bitmap?.compositeImage(colorStyle: selectedColorStyle),
            let size = bitmap?.bitmapDescriptors.first?.size {
            self.size = size
            self.cgImage = cgImage
        
            imageView.image = NSImage(cgImage: cgImage, size: size)
            imageView.needsDisplay = true

            return true
        }
        return false
    }
    
    func loadBitmap(at index:Int) -> Bool {
        if let descriptor = bitmap?.bitmapDescriptors[index],
            let cgImage = bitmap?.bitmap(at: index, color: selectedColorStyle.blackPlane, background: selectedColorStyle.whitePlane) {
            self.size = descriptor.size
            self.cgImage = cgImage
            
            imageView.image = NSImage(cgImage: cgImage, size: size!)
            imageView.needsDisplay = true
            return true
        }
        return false
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

extension CGImage {
    var pngData: Data {
        let imageRep = NSBitmapImageRep(cgImage: self)
        return imageRep.representation(using: NSBitmapImageRep.FileType.png, properties: [:]) ?? Data()
    }
}
