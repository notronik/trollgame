//
//  TrollAttackComponent.swift
//  trollgame
//
//  Created by Nik on 05/08/2016.
//  Copyright © 2016 Niklas Vangerow. All rights reserved.
//

import Foundation

// MARK: AttackInformation -
/// Provides information about an attack. Used for notifications.
class AttackInformation: NSObject {
    let attacker: Entity?
    let damage: Int
    
    init(attacker: Entity?, damage: Int) {
        self.attacker = attacker
        self.damage = damage
    }
}

// MARK: AttackNotificationKeys -
/// Notification keys used for attacks
struct AttackNotificationKeys {
    static let attack = NSNotification.Name(rawValue: "NVEntityAttacked")
}

// MARK: AttackComponent -
/// Component used by entities that want to have attack capabilities.
class AttackComponent: EntityComponent {
    weak var entity: Entity!
    
    let attackable: Set<Tile>
    let strength: Int
    
    init(attackable: [TileProvider], strength: Int = 1) {
        self.attackable = flattenTileProviders(attackable)
        self.strength = strength
    }
    
    func update(world: World) {
        // Test if entity is there and attackable
        guard let attackableEntities = world.entities(at: entity.position, excluding: [self.entity]) else { return }
        
        for attacking in attackableEntities where attackable.contains(attacking.currentTile) {
            attacking.notificationCenter.post(name: AttackNotificationKeys.attack, object: AttackInformation(attacker: entity, damage: strength))
        }
    }
}

// MARK: TileAttackComponent -
/// Component used by entities that are attacked by tiles
class TileAttackComponent: EntityComponent {
    weak var entity: Entity!
    
    let attackedBy: Set<Tile>
    let damage: Int
    
    init(attackedBy: [TileProvider], damage: Int = 1) {
        self.attackedBy = flattenTileProviders(attackedBy)
        self.damage = damage
    }
    
    func update(world: World) {
        // Test if standing on tile
        let tile = world.tile(at: entity.position)
        guard attackedBy.contains(tile) else { return }
        
        world.matrix[entity.position.y][entity.position.x] = tile.attributed
        
        // Post to notification center as attack so that it can be handled by the entity's attackable component
        entity.notificationCenter.post(name: AttackNotificationKeys.attack, object: AttackInformation(attacker: nil, damage: damage))
    }
}

// MARK: AttackableComponent -
/// Component subclassed by entity-specific attack handlers.
class AttackableComponent: EntityComponent {
    final weak var entity: Entity!
    
    final var health: Int
    
    init(health: Int = 1) {
        self.health = health
    }
    
    final func entityBecameAvailable() {
        entity.notificationCenter.addObserver(self, selector: #selector(AttackableComponent.attacked(_:)), name: AttackNotificationKeys.attack, object: nil)
    }
    
    @objc final func attacked(_ notification: Notification) {
        guard let information = notification.object as? AttackInformation else { return }
        
        handleAttack(by: information.attacker, damage: information.damage)
    }
    
    func handleAttack(by attacker: Entity?, damage: Int) {
        fatalError("Attack handling must be implemented by subclasses")
    }
}

/// Make this player entity attackable. The entity will obtain a health counter and listen to attack notifications.
class PlayerAttackableComponent: AttackableComponent {
    override func handleAttack(by attacker: Entity?, damage: Int) {
        self.health -= damage
        guard self.health <= 0 else { return }
        
        RenderMessage(.negative, message: "You died.").send()
        NotificationCenter.default.post(name: .TerminateGameAfterInput, object: nil)
    }
}

/// Make this troll entity attackable.
class TrollAttackableComponent: AttackableComponent {
    override func handleAttack(by attacker: Entity?, damage: Int) {
        self.health -= damage
        guard self.health <=  0 else { return }

        entity.removeFromWorld()
    }
}
