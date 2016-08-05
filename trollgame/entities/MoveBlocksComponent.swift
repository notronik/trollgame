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
    
    func update(world: World) {
        guard let newPosition = entity.newPosition,
            // the entity must already be facing the direction it is moving in to push a block
            Direction(delta: newPosition - entity.position) == entity.direction else { return }
        
        let sourcePosition = entity.position + entity.direction.deltaPosition
        let destinationPosition = sourcePosition + entity.direction.deltaPosition
        // the source must be a wall tile, the destination must be an empty tile, no entity is at destination
        guard world.inWorld(sourcePosition) && world.tile(at: sourcePosition) == .wallTile,
            world.inWorld(destinationPosition) && world.tile(at: destinationPosition) == .emptyTile,
            world.entity(at: destinationPosition) == nil else { return }
        
        // if the previous conditions are met, the block is 'pushed' by swapping the two tiles
        swap(&world.matrix[sourcePosition.y][sourcePosition.x], &world.matrix[destinationPosition.y][destinationPosition.x])
    }
}
