//
//  MoveBlocksComponent.swift
//  trollgame
//
//  Created by Nik on 04/08/2016.
//  Copyright © 2016 Niklas Vangerow. All rights reserved.
//

import Foundation

class MoveBlocksComponent: EntityComponent {
    struct NotificationKeys {
        static let toggleGrab = NSNotification.Name(rawValue: "NVToggleGrabOntoBlockNotification")
    }
    
    weak var entity: Entity!
    
    let whitelist: Set<Tile>
    
    var grabbing = false
    
    init(whitelist: [TileProvider] = []) {
        self.whitelist = flattenTileProviders(whitelist)
    }
    
    func entityBecameAvailable() {
        entity.notificationCenter.addObserver(self, selector: #selector(MoveBlocksComponent.toggleGrabNotification(_:)), name: NotificationKeys.toggleGrab, object: nil)
    }
    
    func update(world: World) {
        let direction = grabbing ? entity.direction.opposite : entity.direction
        guard let newPosition = entity.newPosition,
            // the entity must already be facing the direction it is moving in to push a block
            Direction(delta: newPosition - entity.position) == direction else { return }
        
        let sourcePosition, destinationPosition: Position
        
        if !grabbing {
            sourcePosition = entity.position + direction.deltaPosition
            destinationPosition = sourcePosition + direction.deltaPosition
        } else {
            sourcePosition = entity.position - direction.deltaPosition
            destinationPosition = entity.position
        }
        
        // the source must be a wall tile, the destination must be an empty tile
        guard world.inWorld(sourcePosition) && world.tile(at: sourcePosition) == .wallTile,
            world.inWorld(destinationPosition) && world.tile(at: destinationPosition) == .emptyTile else { return }
        
        // if grabbing, the tile behind the player must be an empty tile as well
        if grabbing {
            let behindPosition = entity.position + direction.deltaPosition
            guard world.inWorld(behindPosition) && world.tile(at: behindPosition) == .emptyTile else { return }
        }
        
        // all entities at the destination position (if they exist) must be whitelisted, or the block cannot be moved
        if let entitiesAtPosition = world.entities(at: destinationPosition) {
            for pEntity in entitiesAtPosition {
                if pEntity != entity && !whitelist.contains(pEntity.currentTile) {
                    return
                }
            }
        }
        
        // if the previous conditions are met, the block is 'pushed' by swapping the two tiles
        swap(&world.matrix[sourcePosition.y][sourcePosition.x], &world.matrix[destinationPosition.y][destinationPosition.x])
    }
    
    @objc func toggleGrabNotification(_ notification: Notification) {
        if !grabbing {
            let sourcePosition = entity.position + entity.direction.deltaPosition
            guard entity.world.inWorld(sourcePosition) && entity.world.tile(at: sourcePosition) == .wallTile else {
                RenderMessage(.information, message: "There is nothing to grab.", transient: true).send()
                return
            }
        }
        
        grabbing = !grabbing
        if grabbing {
            RenderMessage(.information, message: "You grab the block.").send()
            entity.notificationCenter.post(name: PlayerInputComponent.NotificationKeys.enableOppositeMotion, object: nil)
        } else {
            RenderMessage(.information, message: "You let go of the block.", transient: true).send()
            entity.notificationCenter.post(name: PlayerInputComponent.NotificationKeys.disableOppositeMotion, object: nil)
        }
    }
}
