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
    static let SkipTurn = NSNotification.Name(rawValue: "NVSkipTurn")
}

// MARK: Game -
class Game {
    var running = true
    var terminateInput = false
    var skipTurn = false
    
    let renderer: Renderer
    let inputHandler: InputHandler
    let world: World
    
    init(renderer: Renderer, inputHandler: InputHandler) {
        self.renderer = renderer
        self.inputHandler = inputHandler
        // Generate a maze
        self.world = World(width: 40, height: 20, mazeWidth: 101, mazeHeight: 51)
        
        NotificationCenter.default.addObserver(self, selector: #selector(Game.keyPressed(_:)), name: .InputKeyPressed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(Game.terminateNotification(_:)), name: .TerminateGame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(Game.terminateAfterInputNotification(_:)), name: .TerminateGameAfterInput, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(Game.skipTurnNotification(_:)), name: .SkipTurn, object: nil)
        
        // Create player
        let player = Entity(position: world.randomPosition(.wallTile, .goalTile),
                            tile: StaticTileProviders.player,
                            (PlayerAttackableComponent(), .attribute),
                            (PlayerInputComponent(), .input),
                            (MoveBlocksComponent(whitelist: [StaticTileProviders.troll]), .priorityPhysics), // move blocks before position determined
                            // Allow the player to step on a troll (and die)
                            (EntityPhysicsComponent(whitelist: [StaticTileProviders.troll]), .priorityPhysics),
                            (CompleteLevelComponent(), .priorityPhysics),
                            (FollowedByViewportComponent(), .preRender))
        world.add(entity: player)
        
        // Create trolls
        for _ in 0..<20 {
            let troll = Entity(position: world.randomPosition(.wallTile),
                               tile: StaticTileProviders.troll,
                               (TrollAttackableComponent(), .attribute),
                               (AIInputComponent(target: player, maxLength: 100), .input),
                               // Allow trolls to be killed by wall tiles
                               (TileAttackComponent(attackedBy: [SingleTile(.wallTile)]), .physics),
                               // Allow a troll to step on a player and kill them
                               (EntityPhysicsComponent(whitelist: [StaticTileProviders.player]), .physics),
                               (AttackComponent(attackable: [player.tile]), .attack))
            world.add(entity: troll)
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
            
            if !skipTurn {
                world.update(.input)
                world.update(.priorityPhysics)
                world.update(.physics)
                world.update(.attack)
            } else {
                // A turn was skipped, so reset.
                // Turn skipping means that only the input and rendering stages run.
                skipTurn = false
            }
            
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
    
    @objc func skipTurnNotification(_ notification: Notification) {
        skipTurn = true
    }
}
