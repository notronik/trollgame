//
//  Renderer.swift
//  trollgame
//
//  Created by Nik on 03/08/2016.
//  Copyright © 2016 Niklas Vangerow. All rights reserved.
//

import Foundation

protocol Renderer {
    func render(world: World)
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
