//
//  GeneratorViewController.swift
//  Picture
//
//  Created by Richard Warrender on 10/04/2019.
//

import Cocoa
import SIBOKit

class GeneratorViewController: NSViewController, NSTableViewDataSource {
    
    @IBOutlet var tableView: NSTableView!    
    @IBOutlet var arrayController: NSArrayController!
    
    @IBOutlet var generateButton: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func fileAction(_ sender: NSSegmentedControl) {
        if (sender.selectedSegment == 0) {
            addFile()
        } else if (sender.selectedSegment == 1) {
            removeFile()
        }
    }
    
    func addFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedFileTypes = [kUTTypePNG as String]
        panel.begin { (response) in
            if (response ==  .OK) {
                for url in panel.urls {
                    let item = ["file": url.lastPathComponent, "url": url] as [String : Any]
                    self.arrayController.addObject(item)
                }
            }
        }
    }
    
    func removeFile() {
        if let selectedObject = arrayController.selectedObjects.first {
            arrayController.removeObject(selectedObject)
        }
    }
    
    @IBAction func generate(_ sender: Any) {
        guard let files = arrayController.arrangedObjects as? [[String: Any]] else {
            return
        }
        
        guard let urls = files.compactMap({ (result) -> Any? in
            return result["url"]
        }) as? [URL] else {
            return
        }
        
        
        let data = SIBOBitmap.dataForPlane(using: urls, to: URL(string:"https://www.google.co.uk/")!)
    }
}
