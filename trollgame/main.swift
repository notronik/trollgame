//
//  main.swift
//  trollgame
//
//  Created by Nik on 03/08/2016.
//  Copyright © 2016 Niklas Vangerow. All rights reserved.
//

import Foundation

func main() { // this way the deinitialisers are called
    let game = Game(renderer: TextRenderer(offset: (x: 6, y: 3)), inputHandler: TextInputHandler())
    
    let gameClock = CFRunLoopTimerCreateWithHandler(nil, CFAbsoluteTimeGetCurrent(), 1.0/60.0, 0, 0) { [weak weakGame = game] (timer) -> Void in
        weakGame?.update()
    }
    
    CFRunLoopAddTimer(CFRunLoopGetCurrent(), gameClock, CFRunLoopMode.defaultMode)
    CFRunLoopRun()
}

main()
