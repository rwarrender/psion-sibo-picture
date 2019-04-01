//
//  ImageView.swift
//  Picture
//
//  Created by Richard Warrender on 01/04/2019.
//

import Cocoa

class ImageView: NSImageView {

    override func draw(_ dirtyRect: NSRect) {
        NSGraphicsContext.current?.imageInterpolation = .none
        super.draw(dirtyRect)
    }
    
}
