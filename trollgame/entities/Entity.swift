//
//  Entity.swift
//  trollgame
//
//  Created by Nik on 04/08/2016.
//  Copyright © 2016 Niklas Vangerow. All rights reserved.
//

import Foundation

protocol EntityComponent {
    weak var entity: Entity! { get set }
    func entityBecameAvailable()
    func update(world: World)
}

extension EntityComponent {
    func entityBecameAvailable() { }
    func update(world: World) { }
}

enum Direction: UInt32 {
    case up = 0, down, left, right
    
    init?(delta: Position) {
        switch delta.tuple {
        case (0, -1):
            self = .up
        case (0, 1):
            self = .down
        case (-1, 0):
            self = .left
        case (1, 0):
            self = .right
        default:
            return nil
        }
    }
    
    var deltaPosition: Position {
        switch self {
        case .up:
            return Position(x: 0, y: -1)
        case .down:
            return Position(x: 0, y: 1)
        case .left:
            return Position(x: -1, y: 0)
        case .right:
            return Position(x: 1, y: 0)
        }
    }
    
    static func random() -> Direction {
        return Direction(rawValue: arc4random_uniform(4))!
    }
}

class Entity {
    enum NominatedPass {
        case none
        case input
        case update
        case physics
        case preRender
        case postRender
    }
    
    var components = [NominatedPass: [EntityComponent]]()
    let notificationCenter = NotificationCenter()
    
    // Entity state // // // // // // /
    var position: Position
    var newPosition: Position? = nil
    var tile: TileProvider
    var direction: Direction
    // // // // // // // // // // // //
    
    init(position: Position, tile: TileProvider, direction: Direction = .down, components: [(EntityComponent, NominatedPass)]) {
        self.position = position
        self.tile = tile
        self.direction = direction
        for (component, pass) in components {
            if self.components[pass] == nil {
                self.components[pass] = []
            }
            var componentToInsert = component
            componentToInsert.entity = self
            componentToInsert.entityBecameAvailable()
            self.components[pass]!.append(componentToInsert)
        }
    }
    
    convenience init(position: Position, tile: TileProvider, direction: Direction = .down, _ components: (EntityComponent, NominatedPass)...) {
        self.init(position: position, tile: tile, direction: direction, components: components)
    }
    
    func update(_ pass: NominatedPass, world: World) {
        guard let components = components[pass] else { return } // no components for pass

        for component in components {
            component.update(world: world)
        }
    }
}
