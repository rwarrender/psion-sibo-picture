//
//  ExportOptionsView.swift
//  Picture
//
//  Created by Richard Warrender on 04/01/2021.
//

import AppKit
import SIBOKit

enum ExportMode: Int {
    case composite = 1
    case individualBitmaps = 2
}

class ExportOptionsView: NSView {

    @IBOutlet var modePopupButton: NSPopUpButton!
    var selectedMode: ExportMode = .composite
    var hasComposite: Bool = false
    var bitmapIndex: Int?
    
    @IBAction func modeDidChange(id: Any?) {
        guard let selectedItem = modePopupButton.selectedItem else {
            return
        }
        if selectedItem.title == "Composite" {
            selectedMode = .composite
        } else {
            selectedMode = .individualBitmaps
            bitmapIndex = modePopupButton.indexOfSelectedItem - (hasComposite ? 1 : 0)
        }
    }
    
    static func fromNib() -> ExportOptionsView? {
        var objects: NSArray?
        Bundle.main.loadNibNamed("ExportOptionsView", owner: nil, topLevelObjects: &objects)
        for object in objects! {
            if let view = object as? ExportOptionsView {
                return view
            }
        }
        return nil
    }
    
    func setupView(bitmap: SIBOBitmap) {
        var planeTitle: [String] = []
        if bitmap.hasCompositeImage() {
            planeTitle.insert("Composite", at: 0)
            hasComposite = true
        }
        
        let planeCount = bitmap.bitmapDescriptors.count
        for i in 0 ..< planeCount {
            planeTitle.append("Bitmap \(i)")
        }
        
        modePopupButton.removeAllItems()
        modePopupButton.addItems(withTitles: planeTitle)
    }
}
