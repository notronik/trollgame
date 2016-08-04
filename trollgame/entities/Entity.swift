//
//  Entity.swift
//  trollgame
//
//  Created by Nik on 04/08/2016.
//  Copyright © 2016 Niklas Vangerow. All rights reserved.
//

import Foundation

typealias Position = (x: Int, y: Int)

protocol EntityComponent {
    weak var entity: Entity! { get set }
    func entityBecameAvailable()
    func update(world: World)
}

extension EntityComponent {
    func entityBecameAvailable() { }
    func update(world: World) { }
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
    var tile: World.Tile
    // // // // // // // // // // // //
    
    init(position: Position, tile: World.Tile, components: [(EntityComponent, NominatedPass)]) {
        self.position = position
        self.tile = tile
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
    
    convenience init(position: Position, tile: World.Tile, _ components: (EntityComponent, NominatedPass)...) {
        self.init(position: position, tile: tile, components: components)
    }
    
    func update(_ pass: NominatedPass, world: World) {
        guard let components = components[pass] else { return } // no components for pass

        for component in components {
            component.update(world: world)
        }
    }
}
