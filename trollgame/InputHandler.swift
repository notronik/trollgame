//
//  InputHandler.swift
//  trollgame
//
//  Created by Nik on 03/08/2016.
//  Copyright © 2016 Niklas Vangerow. All rights reserved.
//

import Foundation

protocol InputHandler {
    func handleInput()
}

class StubInputHandler: InputHandler {
    init() {
        print("Initialising StubInputHandler...")
    }
    
    deinit {
        print("Shutting down StubInputHandler...")
    }
    
    func handleInput() {
        // stub
    }
}

extension NSNotification.Name {
    static let InputKeyPressed = NSNotification.Name(rawValue: "NVInputKeyPressed")
}

enum Key: Int {
    case unknown
    case q
    case w, a, r, s
}
