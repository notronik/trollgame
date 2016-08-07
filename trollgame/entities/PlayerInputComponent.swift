//
//  PlayerInputComponent.swift
//  trollgame
//
//  Created by Nik on 04/08/2016.
//  Copyright © 2016 Niklas Vangerow. All rights reserved.
//

import Foundation

class PlayerInputComponent: EntityComponent {
    struct NotificationKeys {
        static let enableOppositeMotion = NSNotification.Name(rawValue: "NVInputEnableOppositeMotion")
        static let disableOppositeMotion = NSNotification.Name(rawValue: "NVInputDisableOppositeMotion")
    }
    
    weak var entity: Entity!
    
    var newDirection: Direction? = nil
    var oppositeMotion = false
    
    func update(world: World) {
        guard let newDirection = newDirection else { return }
        
        let shouldMove: Bool
        if !oppositeMotion {
            shouldMove = entity.direction == newDirection
            entity.direction = newDirection
        } else {
            shouldMove = entity.direction == newDirection.opposite
        }
        
        if shouldMove {
            entity.newPosition = entity.position + newDirection.deltaPosition
        }
        
        self.newDirection = nil
    }
    
    func entityBecameAvailable() {
        NotificationCenter.default.addObserver(self, selector: #selector(PlayerInputComponent.inputPressed(_:)), name: .InputKeyPressed, object: nil)
        entity.notificationCenter.addObserver(self, selector: #selector(PlayerInputComponent.enableOppositeMotionNotification(_:)), name: NotificationKeys.enableOppositeMotion, object: nil)
        entity.notificationCenter.addObserver(self, selector: #selector(PlayerInputComponent.disableOppositeMotionNotification(_:)), name: NotificationKeys.disableOppositeMotion, object: nil)
    }
    
    @objc func inputPressed(_ notification: Notification) {
        guard let keyRaw = notification.object as? Int,
            let key = Key(rawValue: keyRaw) else {
                return
        }
        
        switch key {
        case .w:
            newDirection = .up
        case .a:
            newDirection = .left
        case .r:
            newDirection = .down
        case .s:
            newDirection = .right
        case .f:
            NotificationCenter.default.post(name: .SkipTurn, object: nil)
            entity.notificationCenter.post(name: MoveBlocksComponent.NotificationKeys.toggleGrab, object: nil)
        default:
            break
        }
    }
    
    @objc func enableOppositeMotionNotification(_ notification: Notification) {
        oppositeMotion = true
    }
    
    @objc func disableOppositeMotionNotification(_ notification: Notification) {
        oppositeMotion = false
    }
}
