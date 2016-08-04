//
//  PlayerInputComponent.swift
//  trollgame
//
//  Created by Nik on 04/08/2016.
//  Copyright © 2016 Niklas Vangerow. All rights reserved.
//

import Foundation

class PlayerInputComponent: EntityComponent {
    weak var entity: Entity!
    
    var newDirection: Direction? = nil
    
    func update(world: World) {
        guard let newDirection = newDirection else { return }
        
        let shouldMove = entity.direction == newDirection
        
        switch newDirection {
        case .up:
            entity.tile = .playerUpTile
            break
        case .down:
            entity.tile = .playerDownTile
        case .left:
            entity.tile = .playerLeftTile
        case .right:
            entity.tile = .playerRightTile
        }
        
        entity.direction = newDirection
        
        if shouldMove {
            entity.newPosition = entity.position + newDirection.deltaPosition
        }
        
        self.newDirection = nil
    }
    
    func entityBecameAvailable() {
        NotificationCenter.default.addObserver(self, selector: #selector(PlayerInputComponent.inputPressed(_:)), name: .InputKeyPressed, object: nil)
    }
    
    @objc func inputPressed(_ notification: Notification) {
        guard let keyRaw = notification.object as? Int,
            let key = Key(rawValue: keyRaw) else {
                return
        }
        
        switch key {
        case .w:
            newDirection = .up
            break
        case .a:
            newDirection = .left
            break
        case .r:
            newDirection = .down
            break
        case .s:
            newDirection = .right
            break
        default:
            break
        }
    }
}
