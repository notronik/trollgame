//
//  TextInputHandler.swift
//  trollgame
//
//  Created by Nik on 03/08/2016.
//  Copyright © 2016 Niklas Vangerow. All rights reserved.
//

import Foundation
import ncurses

class TextInputHandler: InputHandler {
    init() {
        timeout(0)
    }
    
    deinit {
        print("Shutting down TextInputHandler...")
    }
    
    func handleInput() {
        // flush stdin
        fflush(stdin)
        let character = getch()
        
        // no character was obtained
        guard character != ERR else {
            return
        }
        
        flushinp()
        
        NotificationCenter.default.post(name: NSNotification.Name.InputKeyPressed, object: self.keyCodeToKey(character).rawValue)
    }
    
    func keyCodeToKey(_ keyCode: Int32) -> Key {
        switch keyCode {
        case 113:
            return .q
        case 119:
            return .w
        case 97:
            return .a
        case 114:
            return .r
        case 115:
            return .s
        default:
            return .unknown
        }
    }
}
