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

// MARK: Notification keys -
extension NSNotification.Name {
    static let TerminateGame = NSNotification.Name(rawValue: "NVTerminateGame")
    static let TerminateGameAfterInput = NSNotification.Name(rawValue: "NVTerminateGameAfterInput")
}

// MARK: Game -
class Game {
    var running = true
    var terminateInput = false
    
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
        NotificationCenter.default.addObserver(self, selector: #selector(Game.terminateNotification(_:)), name: .TerminateGame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(Game.terminateAfterInputNotification(_:)), name: .TerminateGameAfterInput, object: nil)
        
        // Create player
        let player = Entity(position: world.randomPosition(.wallTile, .crossTile),
                            tile: DirectionalTile([
                                .up : .playerUpTile,
                                .down : .playerDownTile,
                                .left : .playerLeftTile,
                                .right : .playerRightTile
                                ]),
                            (PlayerAttackableComponent(), .attribute),
                            (PlayerInputComponent(), .input),
                            (MoveBlocksComponent(), .physics), // move blocks before position determined
                            (EntityPhysicsComponent(), .physics),
                            (FollowedByViewportComponent(), .preRender))
        world.entities.append(player)
        
        // Create trolls
        for _ in 0..<5 {
            let troll = Entity(position: world.randomPosition(.wallTile),
                               tile: SingleTile(.trollTile),
//                               tile: DirectionalTile([
//                                .up : .testUpTile,
//                                .down : .testDownTile,
//                                .left : .testLeftTile,
//                                .right : .testRightTile
//                                ]),
                               (AIInputComponent(target: player), .input),
                               (EntityPhysicsComponent(), .physics),
                               (AttackComponent(attackable: [player.tile]), .physics))
            world.entities.append(troll)
        }
    }
    
    deinit {
        print("Shutting down…")
    }
    
    func terminate(afterInput: Bool = false) {
        if afterInput {
            terminateInput = true
        } else {
            running = false
        }
    }
    
    func run() {
        world.update(.preRender)
        renderer.render(world: world)
        world.update(.postRender)
        while running {
            inputHandler.handleInput()
            if !running || terminateInput {
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
    
    @objc func terminateNotification(_ notification: Notification) {
        terminate()
    }
    
    @objc func terminateAfterInputNotification(_ notification: Notification) {
        terminate(afterInput: true)
    }
}
