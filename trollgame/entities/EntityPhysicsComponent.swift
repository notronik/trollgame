//
//  EntityPhysicsComponent.swift
//  trollgame
//
//  Created by Nik on 04/08/2016.
//  Copyright © 2016 Niklas Vangerow. All rights reserved.
//

import Foundation

class EntityPhysicsComponent: EntityComponent {
    weak var entity: Entity!
    let impassable, whitelist: Set<Tile>
    let strength: Int
    
    init(impassable: [TileProvider] = [SingleTile(.wallTile)], whitelist: [TileProvider] = [], strength: Int = 1) {
        self.impassable = flattenTileProviders(impassable)
        self.whitelist = flattenTileProviders(whitelist)
        self.strength = strength
    }
    
    func update(world: World) {
        // determine whether to progress
        guard let newPosition = entity.newPosition else {
            return
        }
        
        // entity cannot pass over other entities unless those are whitelisted
        if let potentialEntity = world.entity(at: newPosition) {
            if !whitelist.contains(potentialEntity.currentTile) {
                return
            }
        }
        
        entity.newPosition = nil
        
        if world.inWorld(newPosition) && !impassable.contains(world.tile(at: newPosition)) {
            // Accept the new position, the tile is not impassable.
            entity.position = newPosition
        }
    }
}
