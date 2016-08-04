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
    
    enum Direction {
        case none
        case up, down, left, right
        
        init?(playerTile: World.Tile) {
            switch playerTile {
            case .playerUpTile:
                self = .up
            case .playerDownTile:
                self = .down
            case .playerLeftTile:
                self = .left
            case .playerRightTile:
                self = .right
            default:
                return nil
            }
        }
    }
    
    var lastMovement: Direction = .none
    
    func update(world: World) {
        guard lastMovement != .none,
            let currentDirection = Direction(playerTile: entity.tile) else { return }
        
        // should copy, as value type
        entity.newPosition = entity.position
        let shouldMove = currentDirection == lastMovement
        
        switch lastMovement {
        case .up:
            if shouldMove {
                entity.newPosition!.1 -= 1
            }
            entity.tile = .playerUpTile
            break
        case .down:
            if shouldMove {
                entity.newPosition!.1 += 1
            }
            entity.tile = .playerDownTile
        case .left:
            if shouldMove {
                entity.newPosition!.0 -= 1
            }
            entity.tile = .playerLeftTile
        case .right:
            if shouldMove {
                entity.newPosition!.0 += 1
            }
            entity.tile = .playerRightTile
        default:
            break
        }
        
        lastMovement = .none
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
            lastMovement = .up
            break
        case .a:
            lastMovement = .left
            break
        case .r:
            lastMovement = .down
            break
        case .s:
            lastMovement = .right
            break
        default:
            break
        }
    }
}
