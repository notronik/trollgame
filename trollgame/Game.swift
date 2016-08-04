//
//  Game.swift
//  trollgame
//
//  Created by Nik on 03/08/2016.
//  Copyright © 2016 Niklas Vangerow. All rights reserved.
//

import Foundation

typealias Position = (x: Int, y: Int)

func +(lhs: Position, rhs: Position) -> Position {
    return (x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

func +=(lhs: inout Position, rhs: Position) {
    lhs = lhs + rhs
}

func -(lhs: Position, rhs: Position) -> Position {
    return (x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}

func -=(lhs: inout Position, rhs: Position) {
    lhs = lhs - rhs
}

class Game {
    let renderer: Renderer
    let inputHandler: InputHandler
    let world: World
    
    init(renderer: Renderer, inputHandler: InputHandler) {
        self.renderer = renderer
        self.inputHandler = inputHandler
        do {
            self.world = try World(width: 40, height: 20, file: URL(fileURLWithPath: "/Users/nik/git/trollgame/level.txt")) // obvs change level dir
        } catch {
            fatalError("Cannot load world")
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(Game.keyPressed(_:)), name: .InputKeyPressed, object: nil)
        
        // Create entities
        world.entities.append(Entity(position: world.randomPosition(.wallTile),
                                     tile: World.Tile.playerDownTile,
                                     (PlayerInputComponent(), .input),
                                     (MoveBlocksComponent(), .physics), // move blocks before position determined
                                     (EntityPhysicsComponent(), .physics),
                                     (FollowedByViewportComponent(), .preRender)))
    }
    
    deinit {
        print("Shutting down…")
    }
    
    func terminate() {
        CFRunLoopStop(CFRunLoopGetMain())
    }
    
    func update() {
        inputHandler.handleInput()
        world.update(.input)
//        world.update(.update)
        world.update(.physics)
        world.update(.preRender)
        renderer.render(world: world)
        world.update(.postRender)
    }
    
    @objc func keyPressed(_ notification: Notification) {
        guard let keyRaw = notification.object as? Int,
            let key = Key(rawValue: keyRaw) else {
            return
        }
        
        switch key {
        case .q:
            terminate()
        default:
            break
        }
    }
}
