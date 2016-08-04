//
//  Game.swift
//  trollgame
//
//  Created by Nik on 03/08/2016.
//  Copyright © 2016 Niklas Vangerow. All rights reserved.
//

import Foundation

// MARK: Position -
struct Position: Hashable {
    var x, y: Int
    var tuple: (x: Int, y: Int) {
        return (x: x, y: y)
    }
    
    var hashValue: Int {
        return x.hashValue ^ y.hashValue
    }
}

func +(lhs: Position, rhs: Position) -> Position {
    return Position(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

func +=(lhs: inout Position, rhs: Position) {
    lhs = lhs + rhs
}

func -(lhs: Position, rhs: Position) -> Position {
    return Position(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}

func -=(lhs: inout Position, rhs: Position) {
    lhs = lhs - rhs
}

func ==(lhs: Position, rhs: Position) -> Bool {
    return lhs.tuple == rhs.tuple
}

// MARK: Game -
class Game {
    var running = true
    
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
        
        // Create player
        let player = Entity(position: world.randomPosition(.wallTile, .crossTile),
                            tile: DirectionalTile([
                                .up : .playerUpTile,
                                .down : .playerDownTile,
                                .left : .playerLeftTile,
                                .right : .playerRightTile
                                ]),
                            (PlayerInputComponent(), .input),
//                            (AIInputComponent(goal: Position(x: 2, y: 22)), .input), // AI component can even be the player
                            (MoveBlocksComponent(), .physics), // move blocks before position determined
                            (EntityPhysicsComponent(), .physics),
                            (FollowedByViewportComponent(), .preRender))
        world.entities.append(player)
        
        // Create trolls
        for _ in 0..<5 {
            world.entities.append(Entity(position: world.randomPosition(.wallTile),
                                         tile: SingleTile(.trollTile),
                                         (AIInputComponent(target: player), .input),
                                         (EntityPhysicsComponent(), .physics)))
        }
    }
    
    deinit {
        print("Shutting down…")
    }
    
    func terminate() {
        running = false
    }
    
    func run() {
        world.update(.preRender)
        renderer.render(world: world)
        world.update(.postRender)
        while running {
            inputHandler.handleInput()
            if !running {
                break
            }
            
            world.update(.input)
            world.update(.physics)
            world.update(.preRender)
            renderer.render(world: world)
            world.update(.postRender)
        }
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
