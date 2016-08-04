//
//  FollowedByViewportComponent.swift
//  trollgame
//
//  Created by Nik on 04/08/2016.
//  Copyright © 2016 Niklas Vangerow. All rights reserved.
//

import Foundation

class FollowedByViewportComponent: EntityComponent {
    var entity: Entity!
    
    func update(world: World) {
        let (x, y) = entity.position
        
        let leftAnchor = world.vWidth / 2 - 0
        let rightAnchor = world.lWidth - world.vWidth / 2
        if x > leftAnchor && x < rightAnchor {
            world.origin.x = x - world.vWidth/2
        } else if x <= leftAnchor {
            world.origin.x = 0
        } else if x >= rightAnchor {
            world.origin.x = world.lWidth - world.vWidth
        }
        
        let topAnchor = world.vHeight / 2 - 0
        let bottomAnchor = world.lHeight - world.vHeight / 2
        if y > topAnchor && y < bottomAnchor {
            world.origin.y = y - world.vHeight/2
        } else if y <= topAnchor {
            world.origin.y = 0
        } else if y >= bottomAnchor {
            world.origin.y = world.lHeight - world.vHeight
        }
    }
}
