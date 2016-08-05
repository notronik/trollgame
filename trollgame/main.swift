//
//  main.swift
//  trollgame
//
//  Created by Nik on 03/08/2016.
//  Copyright © 2016 Niklas Vangerow. All rights reserved.
//

import Foundation

func main() { // this way the deinitialisers are called
    let game = Game(renderer: TextRenderer(offset: Position(x: 6, y: 3)), inputHandler: TextInputHandler())

    game.run()
}

main()
