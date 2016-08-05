//
//  Renderer.swift
//  trollgame
//
//  Created by Nik on 03/08/2016.
//  Copyright © 2016 Niklas Vangerow. All rights reserved.
//

import Foundation

extension NSNotification.Name {
    static let RendererDisplayMessage = NSNotification.Name(rawValue: "NVRendererDisplayMessage")
    static let RendererHideMessage = NSNotification.Name(rawValue: "NVRendererHideMessage")
}

protocol Renderer {
    func render(world: World)
}

class RenderMessage: NSObject {
    enum Kind {
        case positive, negative
    }
    
    let stringMessage: String
    let type: Kind
    
    init(_ type: Kind, message: String) {
        self.type = type
        self.stringMessage = message
    }
}

class StubRenderer: Renderer {
    init() {
        print("Initialising StubRenderer...")
    }
    
    deinit {
        print("Shutting down StubRenderer...")
    }
    
    func render(world: World) {
        // stub
    }
}
