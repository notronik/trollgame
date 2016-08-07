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
    
    static let cases: [Direction] = [.up, .down, .left, .right]
    
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
    
    var opposite: Direction {
        switch self {
        case .up:
            return .down
        case .down:
            return .up
        case .left:
            return .right
        case .right:
            return .left
        }
    }
    
    static func random() -> Direction {
        return Direction(rawValue: arc4random_uniform(UInt32(Direction.cases.count)))!
    }
}

// MARK: Entity -
/* 
 An Entity is a collection of EntityComponents and associated information.
 
 Components are added in 'nominated passes'. These are consecutive places in the game loop
 that run the update method on the component. They are roughly categorised and modify mostly
 their own information. There is also the `attribute` pass, which is never called from the main
 loop and is for data storage and manipulation operations using the notification centre.
 */
class Entity {
    enum NominatedPass {
        case attribute  // these are never called, they only serve to react to notifications or provide data
        case input      // called to handle input
        case update     // called to update entity in some unrelated way
        case priorityPhysics // called to affect the entity's position and interact with the world before other entities
        case physics    // called to affect the entity's position and interact with the world
        case attack     // called to process attacks
        case preRender  // called just before rendering, used for render setup
        case postRender // called just after rendering, used for render cleanup or some other stuff
    }
    
    private(set) var components = [NominatedPass: [EntityComponent]]()
    let notificationCenter = NotificationCenter()
    let id = UUID()
    
    // Entity state // // // // // // /
    var position: Position
    var newPosition: Position? = nil
    var tile: TileProvider
    var currentTile: Tile {
        return tile.tile(for: direction)
    }
    /// The newest position, even if it is non-final
    var latestPosition: Position {
        guard let new = newPosition else {
            return position
        }
        
        return new
    }
    var direction: Direction
    weak var world: World!
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
    
    func removeFromWorld() {
        self.world.removeEntity(id: id)
    }
}

// MARK: Entity Equatable conformance
extension Entity : Equatable { }

func ==(lhs: Entity, rhs: Entity) -> Bool {
    return lhs.id.uuidString == rhs.id.uuidString // the raw data didn't want to compare
}

// MARK: Static tile providers (pre-made tile providers for certain entity configurations) -
struct StaticTileProviders {
    static let player = DirectionalTile([
        .up : .playerUpTile,
        .down : .playerDownTile,
        .left : .playerLeftTile,
        .right : .playerRightTile
        ])
    static let troll = SingleTile(.trollTile)
}
