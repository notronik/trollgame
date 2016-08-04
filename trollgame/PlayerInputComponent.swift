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
    
    enum Directions {
        case up, down, left, right
    }
    
    var movements = [Directions]()
    
    func update(world: World) {
        // combine key events here.
        guard movements.count > 0 else {
            return
        }
        
        // should copy, as value type
        entity.newPosition = entity.position
        for movement in movements {
            switch movement {
            case .up:
                entity.newPosition!.1 -= 1
                break
            case .down:
                entity.newPosition!.1 += 1
            case .left:
                entity.newPosition!.0 -= 1
            case .right:
                entity.newPosition!.0 += 1
            }
        }
        // There must be a last direction as count > 0
        switch movements.last! {
        case .up:
            entity.tile = .playerUpTile
        case .down:
            entity.tile = .playerDownTile
        case .left:
            entity.tile = .playerLeftTile
        case .right:
            entity.tile = .playerRightTile
        }
        movements.removeAll()
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
            movements.append(.up)
            break
        case .a:
            movements.append(.left)
            break
        case .r:
            movements.append(.down)
            break
        case .s:
            movements.append(.right)
            break
        default:
            break
        }
    }
}
