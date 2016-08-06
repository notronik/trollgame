//
//  MoveBlocksComponent.swift
//  trollgame
//
//  Created by Nik on 04/08/2016.
//  Copyright © 2016 Niklas Vangerow. All rights reserved.
//

import Foundation

class MoveBlocksComponent: EntityComponent {
    weak var entity: Entity!
    
    let whitelist: Set<Tile>
    
    init(whitelist: [TileProvider] = []) {
        self.whitelist = flattenTileProviders(whitelist)
    }
    
    func update(world: World) {
        guard let newPosition = entity.newPosition,
            // the entity must already be facing the direction it is moving in to push a block
            Direction(delta: newPosition - entity.position) == entity.direction else { return }
        
        let sourcePosition = entity.position + entity.direction.deltaPosition
        let destinationPosition = sourcePosition + entity.direction.deltaPosition
        
        // the source must be a wall tile, the destination must be an empty tile
        guard world.inWorld(sourcePosition) && world.tile(at: sourcePosition) == .wallTile,
            world.inWorld(destinationPosition) && world.tile(at: destinationPosition) == .emptyTile else { return }
        
        // all entities at the destination position (if they exist) must be whitelisted, or the block cannot be moved
        if let entitiesAtPosition = world.entities(at: destinationPosition) {
            for pEntity in entitiesAtPosition {
                if !whitelist.contains(pEntity.currentTile) {
                    return
                }
            }
        }
        
        // if the previous conditions are met, the block is 'pushed' by swapping the two tiles
        swap(&world.matrix[sourcePosition.y][sourcePosition.x], &world.matrix[destinationPosition.y][destinationPosition.x])
    }
}
