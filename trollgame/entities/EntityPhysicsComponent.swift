//
//  EntityPhysicsComponent.swift
//  trollgame
//
//  Created by Nik on 04/08/2016.
//  Copyright © 2016 Niklas Vangerow. All rights reserved.
//

import Foundation

class EntityPhysicsComponent: EntityComponent {
    static let impassable: [World.Tile] = [.wallTile]
    
    var entity: Entity!
    
    func update(world: World) {
        // determine whether to progress
        guard let newPosition = entity.newPosition else {
            return
        }
        entity.newPosition = nil
        
        if world.inWorld(newPosition) && !EntityPhysicsComponent.impassable.contains(world.tile(at: newPosition)) {
            // Accept the new position, the tile is not impassable.
            entity.position = newPosition
        }
    }
}
