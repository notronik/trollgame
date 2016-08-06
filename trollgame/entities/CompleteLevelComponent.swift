//
//  CompleteLevelComponent.swift
//  trollgame
//
//  Created by Nik on 05/08/2016.
//  Copyright © 2016 Niklas Vangerow. All rights reserved.
//

import Foundation

class CompleteLevelComponent: EntityComponent {
    weak var entity: Entity!
    
    let completes: [Tile]
    
    init(completes: [Tile] = [.goalTile]) {
        self.completes = completes
    }
    
    func update(world: World) {
        // Runs after entity physics component
        // If tile is in completes list then complete
        guard completes.contains(world.tile(at: entity.position)) else { return }
        
        RenderMessage(.positive, message: "You win!").send()
        NotificationCenter.default.post(name: NSNotification.Name.TerminateGameAfterInput, object: nil)
    }
}
